Class dc.openapi.client.HttpClientGeneratorV2 Extends %RegisteredObject
{

Parameter HTTPREQUESTOBJECT = "httpRequest";

Property AST As dc.openapi.common.ast.OAS;

Property Package As %String;

Method Generate() As %Status
{
    Set sc = $$$OK

    Set sc = $$$ADDSC(sc, ..GenerateModels())

    Set clientClassGenerator = ##class(dc.openapi.client.generator.ClientClassGenerator).%New()
    Set clientClassGenerator.ClassName = clientClassGenerator.GetClassName(..Package)
    Set clientClassGenerator.AST = ..AST
    Set httpClientClass = clientClassGenerator.Generate()

    Set abstractResponseClassGenerator = ##class(dc.openapi.client.generator.AbstractResponseClassGenerator).%New()
    Set abstractResponseClassGenerator.ClassName = abstractResponseClassGenerator.GetClassName(..Package)
    Set abstractResponseClass = abstractResponseClassGenerator.Generate()
    Set sc = $$$ADDSC(sc, abstractResponseClass.%Save())

    Set responseModelGenerator = ##class(dc.openapi.client.generator.ResponseModelGenerator).%New()
    Set responseModelGenerator.Super = abstractResponseClass.Name
    Set requestModelGenerator = ##class(dc.openapi.client.generator.RequestModelGenerator).%New()
    
    Set key = ""
    For  {
        Set path = ..AST.Paths.GetNext(.key)
        Quit:key=""

        Set requestModelGenerator.ClassName = requestModelGenerator.GetClassName(..Package, path)
        Set requestClassModel = requestModelGenerator.Generate(path)
        Set sc = $$$ADDSC(sc, requestClassModel.%Save())
        
        Set responseModelGenerator.ClassName = responseModelGenerator.GetClassName(..Package, path)
        Set responseClassModel =responseModelGenerator.Generate(path)
        Set sc = $$$ADDSC(sc, responseClassModel.%Save())
        
        Set operationMethod = clientClassGenerator.GetOperationMethod(path, requestClassModel.Name, responseClassModel.Name)
        Do httpClientClass.Methods.Insert(operationMethod)
        
    }

    Set sc = httpClientClass.%Save()

    Return sc
}

Method GenerateModels() As %Status
{
    Set tSc = $$$OK
    #dim model As dc.openapi.common.ast.Model
    #dim models As %ListOfObjects

    Set models = ..AST.Models
    Set key = ""
    For  {
        Set model = models.GetNext(.key)
        Quit:key=""
        Set modelGenerator = ##class(dc.openapi.common.generator.ModelGenerator).%New()
        Set modelGenerator.ClassName = model.Name
        Set modelGenerator.Super = model.Super
        Set classDef = modelGenerator.Generate(model)
        Set tSc = $$$ADDSC(tSc,classDef.%Save())
    }
    
    Return tSc
}

}
