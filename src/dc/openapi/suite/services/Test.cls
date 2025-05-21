Include dc.openapi.common.macro

Class dc.openapi.suite.services.Test
{

ClassMethod Test() As %Status
{
    Set tSc = $$$OK
    Do ##class(dc.openapi.common.TinyLogger).StartSession({"verbose":1,"level":($$$LEVELINFO)})
    Try{
        tro 
        ts

        Set oasFile = ##class(%Stream.FileCharacter).%New()
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

        
        Set preparer = ##class(dc.openapi.common.SwaggerDocumentPreparer).%New()
        Do preparer.SetMainDocument(oasStream,{"modelPackage":"myapplication.models"})
        Do preparer.AddDocument(ssiStream, "../common/ssi_types.yaml", {"modelPackage":"ssi"})
        Do preparer.AddDocument(errStream, "../common/error_response.yaml", {"modelPackage":"err"})
        

        Set expectedExternalDocument =##class(dc.openapi.suite.services.Generator).GetExpectedExternalDocument(preparer.GetDocumentCollection(), .missing)
        If expectedExternalDocument '="" {
            $$$LOGINFO("Expected external document: "_ $lts(expectedExternalDocument))
            If missing '= "" {
                $$$LOGWARNING("Missing external documents: "_ $lts(missing))
                Quit
            }
        }
       
        
        Set pp = ##class(dc.openapi.common.SwaggerSpecProcessor).%New(preparer.GetDocumentCollection())
        
        Set tSc = pp.PreProcess()
        If $$$ISERR(tSc) {
            $$$ThrowStatus(tSc)
        }
        
        Set transformer = ##class(dc.openapi.common.SwaggerToASTConverter).%New(pp.DocumentCollection)
        Set tSc = transformer.Transform()
        If $$$ISERR(tSc) {
            $$$ThrowStatus(tSc)
        }

        Set httpClientGenConfig = ##class(dc.openapi.client.config.HttpClientGenConfig).%New("myapplication.httpclient", transformer.AST)
        Set httpClientGenerator = ##class(dc.openapi.client.HttpClientGeneratorV2).%New(httpClientGenConfig)
        Set tsc = httpClientGenerator.Generate()
        If $$$ISERR(tsc) {
            $$$ThrowStatus(tsc)
        }
        
    } Catch ex {
        Set tSc = ex.AsStatus()
        Do $SYSTEM.Status.DisplayError(tSc)
    }

    Do ##class(dc.openapi.common.TinyLogger).StopSession()
    Return tSc
}

}
