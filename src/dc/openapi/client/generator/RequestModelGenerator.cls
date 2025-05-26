Include dc.openapi.common.macro

Class dc.openapi.client.generator.RequestModelGenerator Extends dc.openapi.common.GeneratorAbstract
{

Parameter SUBPKG = "request";

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
        Set requestClassModel = ..Generate(path)
        Set tSc = $$$ADDSC(tSc,requestClassModel.%Save())
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
    Return:'..HandleOverride(.classDef) classDef
    
    Set className = ..ClassName
    Do ##class(dc.openapi.common.GeneratedItemRegistry).RegisterClass(..ClassName)

    Set requestClassModel = ##class(%Dictionary.ClassDefinition).%New()
    Set requestClassModel.ProcedureBlock = $$$YES
    Set requestClassModel.Inheritance = "left"
    Set requestClassModel.Super = "%RegisteredObject"
    Set requestClassModel.Name = className

    Set pathParameter = ##class(%Dictionary.ParameterDefinition).%New()
    Set pathParameter.Name = "PATH"
    Set pathParameter.Default = path.Path
    Set pathParameter.Description = "Path for the operation, ex: /user/{userId}"
    Do requestClassModel.Parameters.Insert(pathParameter)

    Set pathProperty = ##class(%Dictionary.PropertyDefinition).%New()
    Set pathProperty.Name = "%Path"
    Set pathProperty.Type = "%String"
    Set pathProperty.InitialExpression = "..#PATH"
    Set pathProperty.Description = "The resolved path for the operation, ex: /user/{userId} --> /user/1"
    Do requestClassModel.Properties.Insert(pathProperty)

    Set supportedContentTypes = path.GetResponsesContentTypeList()
    Set acceptProperty = ##class(%Dictionary.PropertyDefinition).%New()
    Set acceptProperty.Name = "%Accept"
    Set acceptProperty.Type = "%String"
    Set acceptProperty.InitialExpression = """"_$ListGet(supportedContentTypes,1)_""""
    Set acceptProperty.Description = "The Accept header for the operation. " _ $ListToString(supportedContentTypes,", ")
    Do requestClassModel.Properties.Insert(acceptProperty)

    Set contentTypeList = path.GetRequestBodiesContentTypeList()
    Set contentTypeProperty = ##class(%Dictionary.PropertyDefinition).%New()
    Set contentTypeProperty.Name = "%ContentType"
    Set contentTypeProperty.Type = "%String"
    Set contentTypeProperty.InitialExpression = """"_$ListGet(contentTypeList,1)_""""
    Set contentTypeProperty.Description = "The Content-Type header for the operation.  "_ $ListToString(contentTypeList,", ")
    Do requestClassModel.Properties.Insert(contentTypeProperty)

    #dim parameter As dc.openapi.common.ast.Parameter
    Set key = ""
    For  {
        Set parameter = path.Parameters.GetNext(.key)
        Quit:key=""

        Set propertyDef = ##class(dc.openapi.common.generator.ModelGenerator).GetPropertyDefinition(parameter.ModelProperty)
        Do requestClassModel.Properties.Insert(propertyDef)
    }

    Set key = ""
    For  {
        Set requestBody = path.RequestBodies.GetNext(.key)
        Quit:key=""

        Set requestBodyPropDef = ##class(dc.openapi.common.generator.ModelGenerator).GetPropertyDefinition(requestBody.ModelProperty)
        If '$Data(createdRequestBody(" "_requestBodyPropDef.Type)) { ; avoid duplicate request body objects if it's the same type
            Set createdRequestBody(" "_requestBodyPropDef.Type) = requestBodyPropDef
            Do requestClassModel.Properties.Insert(requestBodyPropDef) 
        }
    }

    Do requestClassModel.Methods.Insert(..GetBuildRequestMethod(path))

    Return requestClassModel
}

ClassMethod GetBuildRequestMethod(path As dc.openapi.common.ast.Path) As %Dictionary.MethodDefinition
{
    Set methodDefinition = ##class(%Dictionary.MethodDefinition).%New()
    Set methodDefinition.Name = "%BuildRequest"
    Set methodDefinition.Description = "Build the HTTP request for the operation"
    Set methodDefinition.ReturnType = "%Status"
    Set methodDefinition.FormalSpec= ##class(dc.openapi.client.HttpClientGeneratorV2).#HTTPREQUESTOBJECT_":%Net.HttpRequest"

    Set variables("HttpRequestObject") = ##class(dc.openapi.client.HttpClientGeneratorV2).#HTTPREQUESTOBJECT

    #dim parameter As dc.openapi.common.ast.Parameter
    Set key = ""
    For  {
        Set parameter = path.Parameters.GetNext(.key)
        Quit:key=""
        Set variables(parameter.In) = $Get(variables(parameter.In)) _ ##class(dc.openapi.client.template.Parameters).GetResolvedTemplate(parameter, .variables) 
    }

    #dim requestBody As dc.openapi.common.ast.RequestBody
    Set key = ""
    For  {
        Set requestBody = path.RequestBodies.GetNext(.key)
        Quit:key=""
        Set variables("RequestBodies") = $Get(variables("RequestBodies")) _  ##class(dc.openapi.client.template.RequestBody).GetResolvedTemplate(requestBody, .variables) 
    }

    Set buildRequestTemplate = ##class(dc.openapi.client.template.Request).GetResolvedTemplate(path, .variables)
    Do methodDefinition.Implementation.Write(buildRequestTemplate)

    Return methodDefinition
}

}
