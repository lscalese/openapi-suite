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
        Set tSc = $$$ADDSC(sc,modelGenerator.GenerateAll())
    }
    Return tSc
}

}
