Include dc.openapi.common.macro

Class dc.openapi.client.generator.ResponseModelGenerator Extends dc.openapi.common.GeneratorAbstract
{

Parameter SUBPKG = "response";

ClassMethod GetClassName(rootPackageName As %String, path As dc.openapi.common.ast.Path) As %String [ CodeMode = expression ]
{
rootPackageName _ $Select(..#SUBPKG'="":"."_..#SUBPKG,1:"") _ "." _ path.OperationId
}

Method GenerateAll() As %Status
{
    Set tSc = $$$OK
    // Iterate over the paths in the AST and generate code for each one
    #dim path As dc.openapi.common.ast.Path
    #dim paths As %ListOfObjects

    Set paths = ..AST.Paths

    Set key = ""
    For  {
        Set path = paths.GetNext(.key)
        Quit:key=""
        Set responseClassModel = ..Generate(path)
        Set tSc = $$$ADDSC(tSc,responseClassModel.%Save())
    }

    Return tSc
}

ClassMethod GenerateByPath(path As dc.openapi.common.ast.Path, packageName As %String) As %Dictionary.ClassDefinition
{
    Set generator = ..%New()
    Set generator.Package = packageName
    Return generator.Generate(path)
}

Method Generate(path As dc.openapi.common.ast.Path) As %Dictionary.ClassDefinition
{
    If ..OverrideClassIfExists {
        Do ..DeleteIfExists()
    }
    
    Set className = ..ClassName

    Set responseClassModel = ##class(%Dictionary.ClassDefinition).%New()
    Set responseClassModel.ProcedureBlock = $$$YES
    Set responseClassModel.Inheritance = "left"
    Set responseClassModel.Super = ..Super
    Set responseClassModel.Name = className

    #dim response As dc.openapi.common.ast.Response

    Set key = ""
    For  {
        Set response = path.Responses.GetNext(.key)
        Quit:key=""

        If '$IsObject(response.ModelProperty) {
            Continue
        }

        If response.ModelProperty.TypeHelper = "stream" {
            ; don't need to generate a property because we can use the existing %Data property in th super class.
            Continue
        }

        Set propertyDefinition = ##class(dc.openapi.common.generator.ModelGenerator).GetPropertyDefinition(response.ModelProperty)
        If '$Data(createdResponseContent(" "_propertyDefinition.Type)) { ; avoid duplicate the property with the same type
            Set createdResponseContent(" "_propertyDefinition.Type) = ""
            Do responseClassModel.Properties.Insert(propertyDefinition)
        }
    }

    Do responseClassModel.Methods.Insert(..FromHttpResponseMethod(path))

    Return responseClassModel
}

Method FromHttpResponseMethod(path As dc.openapi.common.ast.Path) As %Dictionary.MethodDefinition
{
    Set methodDefinition = ##class(%Dictionary.MethodDefinition).%New()
    Set methodDefinition.Name = "%FromHttpResponse"
    Set methodDefinition.Description = "Build the response object from the HTTP response"
    Set methodDefinition.ReturnType = "%Status"
    Set methodDefinition.FormalSpec = "httpResponse:%Net.HttpResponse"

    Set template = ##class(dc.openapi.client.template.Response).ByName("FromHttpResponse")
    Set variables("ResponseCode") = ""

    For  {
        Set response = path.Responses.GetNext(.key)
        Quit:key=""

        If '$IsObject(response.ModelProperty) {
            Continue
        }

        Set variables("ResponseCode") = variables("ResponseCode") _ ##class(dc.openapi.client.template.Response).GetResolvedTemplate(response, .variables)
    }

    Set template = ##class(dc.openapi.common.TemplateProcessor).ProcessTemplate(template, .variables, path)
    Do methodDefinition.Implementation.Write(template)

    Return methodDefinition
}

}
