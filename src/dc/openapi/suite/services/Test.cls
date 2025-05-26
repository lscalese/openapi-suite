Include dc.openapi.common.macro

Class dc.openapi.suite.services.Test
{

ClassMethod Test() As %Status
{
    Set tSc = $$$OK
    Do ##class(dc.openapi.common.GeneratedItemRegistry).Clear()
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
        Do preparer.SetMainDocument(oasStream)
        Do preparer.AddDocument(ssiStream, "../common/ssi_types.yaml")
        Do preparer.AddDocument(errStream, "../common/error_response.yaml")
        
        Set documentCollection = preparer.GetDocumentCollection()

        Set validationResult = ##class(dc.openapi.suite.services.Generator).DocumentCollectionValidation(documentCollection)
        if 'validationResult.IsValid {
            $$$LOGERROR("Validation failed")
        }
        Set pp = ##class(dc.openapi.common.SwaggerSpecProcessor).%New(documentCollection)
        
        Set tSc = pp.PreProcess()
        If $$$ISERR(tSc) {
            $$$ThrowStatus(tSc)
        }

        #dim astCollection As dc.openapi.common.ASTCollection
        Set astCollection = ##class(dc.openapi.common.SwaggerToASTConverter).ToASTCollection(documentCollection)
        Set astCollection.GetByKey(##class(dc.openapi.common.SwaggerDocumentCollection).#MAINKEY).PackageModel = "myapplication.models.common"
        Set astCollection.GetByKey("../common/ssi_types.yaml").PackageModel = "myapplication.models.ssi"
        Set astCollection.GetByKey("../common/error_response.yaml").PackageModel = "myapplication.models.err"
        Do astCollection.ASTCollectionResolve()
        
        Do ##class(dc.openapi.common.Utils).DumpToFile(astCollection, "/home/irisowner/irisdev/debug/ast-collection.json", $$$YES)
       
        Set httpClientGenConfig = ##class(dc.openapi.client.config.HttpClientGenConfig).%New("myapplication.httpclient", astCollection.ASTs.GetAt(1))
        
        Set httpClientGenerator = ##class(dc.openapi.client.HttpClientGeneratorV2).%New(httpClientGenConfig)
        Set tsc = httpClientGenerator.Generate()
        If $$$ISERR(tsc) {
            $$$ThrowStatus(tsc)
        }
        s httpClientGenConfig.ASTReference = ""
        s str=httpClientGenConfig.ToJSONWithArraysAsKeyValue()
        
        zw str
        ;w !,##class(%JSON.Formatter).%New().Format(str),!
    } Catch ex {
        Set tSc = ex.AsStatus()
        Do $SYSTEM.Status.DisplayError(tSc)
    }

    ;Zw ##class(dc.openapi.common.GeneratedItemRegistry).GetInstance().GeneratedClasses.Serialize()

    Do ##class(dc.openapi.common.TinyLogger).StopSession()
    Return tSc
}

}
