Class dc.openapi.common.ast.Test Extends %RegisteredObject
{

ClassMethod Test() As %Status
{
    Try{
        tro 
        ts
        Set oasFile = ##class(%Stream.FileCharacter).%New()
        ;Do oasFile.LinkToFile("/home/irisowner/irisdev/temp-dev-specs/v1.json")
        Do oasFile.LinkToFile("/home/irisowner/irisdev/temp-dev-specs/v1.yaml")
        Set oasStream = ##class(%Stream.GlobalCharacter).%New()
        Do oasStream.CopyFrom(oasFile)
        
        Set ssiFile = ##class(%Stream.FileCharacter).%New()
        Do ssiFile.LinkToFile("/home/irisowner/irisdev/temp-dev-specs/ssi_types.yaml")
        Set ssiStream = ##class(%Stream.GlobalCharacter).%New()
        Do ssiStream.CopyFrom(ssiFile)
        
        Set errFile = ##class(%Stream.FileCharacter).%New()
        Do errFile.LinkToFile("/home/irisowner/irisdev/temp-dev-specs/error_response.yaml")
        Set errStream = ##class(%Stream.GlobalCharacter).%New()
        Do errStream.CopyFrom(errFile)

        Set dataTypesFile = ##class(%Stream.FileCharacter).%New()
        Do dataTypesFile.LinkToFile("/home/irisowner/irisdev/temp-dev-specs/components_schemas_datatype.json")
        Set dataTypesStream = ##class(%Stream.GlobalCharacter).%New()
        Do dataTypesStream.CopyFrom(dataTypesFile)


        ;Set nested = {}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/components_schemas_nested.json")
        Set nested = {}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/test.json")
        
        Set preparer = ##class(dc.openapi.common.SwaggerDocumentPreparer).%New()
        ;Do preparer.SetMainDocument(nested,{"modelPackage":"myapp"})
        
        ;Do preparer.SetMainDocument(dataTypesStream)
        ;Do preparer.SetMainDocument({}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/flatten.json"),{"modelPackage":"myapp"})
        ; Do preparer.SetMainDocument(nested,{"modelPackage":"myapp"})
        
        Do preparer.SetMainDocument(oasStream,{"modelPackage":"myapp"})
        Do preparer.AddDocument(ssiStream, "../common/ssi_types.yaml", {"modelPackage":"ssi"})
        Do preparer.AddDocument(errStream, "../common/error_response.yaml", {"modelPackage":"err"})
        
        Set pp = ##class(dc.openapi.common.SwaggerSpecProcessor).%New()
        Set pp.DocumentCollection = preparer.GetDocumentCollection()
        
        Set tSc = pp.PreProcess()
        If $$$ISERR(tSc) {
            $$$ThrowStatus(tSc)
        }
        
        Set transformer = ##class(dc.openapi.common.SwaggerToASTConverter).%New()
        Set transformer.DocumentCollection = pp.DocumentCollection
        Set tSc = transformer.Transform()
        If $$$ISERR(tSc) {
            $$$ThrowStatus(tSc)
        }

        Set modelGenerator = ##class(dc.openapi.common.ModelGenerator).%New()
        Set modelGenerator.AST = transformer.AST
        
        Set tsc = modelGenerator.Generate()
        If $$$ISERR(tsc) {
            $$$ThrowStatus(tsc)
        }

        Set httpClientGenerator = ##class(dc.openapi.client.HttpRequestGenerator).%New()
        Set httpClientGenerator.AST = transformer.AST
        Set httpClientGenerator.Package = "myapplication.httpclient"
        Set tsc = httpClientGenerator.Generate()
        If $$$ISERR(tsc) {
            $$$ThrowStatus(tsc)
        }
        
    } Catch ex {
        Set tSc = ex.AsStatus()
        Do $SYSTEM.Status.DisplayError(tSc)
    }
    Return tSc
}

}
