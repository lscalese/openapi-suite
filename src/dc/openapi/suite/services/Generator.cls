Class dc.openapi.suite.services.Generator
{

ClassMethod DocumentCollectionValidation(documentCollection As dc.openapi.common.SwaggerDocumentCollection) As dc.openapi.common.ValidationResult
{
    Set ssp = ##class(dc.openapi.common.SwaggerSpecProcessor).%New(documentCollection)
    Do ssp.Validate()
    Return ssp.ValidationResult
}

ClassMethod DocumentCollectionToAST(documentCollection As dc.openapi.common.SwaggerDocumentCollection, Output ASTCollection As dc.openapi.common.ASTCollection) As %Status
{
    Set tSc = $$$OK
    Set preProcessor = ##class(dc.openapi.common.SwaggerSpecProcessor).%New(documentCollection)
    $$$TOE(tSc,preProcessor.PreProcess())
    Set ASTCollection = ##class(dc.openapi.common.SwaggerToASTConverter).ToASTCollection(preProcessor.DocumentCollection, tSc)
    Return tSc
}

ClassMethod GenerateModels(ASTCollection As dc.openapi.common.ASTCollection) As %Status
{
    Set tSc = $$$OK
    Do ASTCollection.ASTCollectionResolve()
    Set modelGenerator = ##class(dc.openapi.common.generator.ModelGenerator).%New()
    #dim astRef As dc.openapi.common.ASTReference
    Set index = ""
    For  {
        Set astRef = ASTCollection.ASTs.GetNext(.index)
        Quit:index=""
        Set modelGenerator.ASTReference = astRef
        Set tSc = $$$ADDSC(tSc,modelGenerator.GenerateAll())
    }
    Return tSc
}

ClassMethod GetHttpClientGenConfig(Package As %String, ASTReference As dc.openapi.common.ASTReference) As dc.openapi.client.config.HttpClientGenConfig
{
   Return ##class(dc.openapi.client.config.HttpClientGenConfig).%New(Package, ASTReference)
}

ClassMethod GetGenerationResult() As dc.openapi.common.GenerationResult
{
    Set result = ##class(dc.openapi.common.GenerationResult).%New()
    Do ##class(dc.openapi.common.GeneratedItemRegistry).GetArray(.array)
    Set item = ""
    For  {
        Set item = $Order(array(item))
        Quit:item=""
        Do result.GeneratedItems.Insert(item)
    }
    Set result.Logs = ##class(dc.openapi.common.TinyLogger).GetInstance().Logs
    Set result.GeneratedCode = ..ExportGeneratedItemsToStream(.sc, $$$YES)
    Return result
}

ClassMethod ExportGeneratedItemsToStream(ByRef sc As %Status = {$$$OK}, base64 As %Boolean = {$$$NO}) As %Stream.GlobalCharacter
{
    Do ##class(dc.openapi.common.GeneratedItemRegistry).GetArray(.array)
    Set gcs = ##class(%Stream.GlobalCharacter).%New()
    Set:'$Data(array) array = ""
    Set sc = ##class(%SYSTEM.OBJ).ExportToStream(.array, .gcs, "-d")
    Return:'base64 gcs
    Return ##class(dc.openapi.common.Utils).ConvertStreamToBase64(gcs)
}

}
