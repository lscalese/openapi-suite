Class dc.openapi.suite.services.Generator
{

ClassMethod DocumentCollectionIsValid(documentCollection As dc.openapi.common.SwaggerDocumentCollection, ByRef Errors As %DynamicObject) As %Boolean
{
    Set ssp = ##class(dc.openapi.common.SwaggerSpecProcessor).%New(documentCollection)
    Set isValid = ssp.Validate()
    Set Errors = $Select(isValid:"", 1:ssp.Errors)
    Return isValid
}

ClassMethod GetExpectedExternalDocument(documentCollection As dc.openapi.common.SwaggerDocumentCollection, Output missing As %List) As %List
{
    Set expectedExternalDocument = "", missing = ""
    Set ssp = ##class(dc.openapi.common.SwaggerSpecProcessor).%New(documentCollection)
    Do ssp.Validate()
    Return:ssp.ExpectedExternalSwagger.Count()=0 expectedExternalDocument
    Set expectedExternalDocument = ssp.ExpectedExternalSwagger.Serialize()
    Set missing = ..GetMissingExternalDocumentFromSSP(ssp)
    Return expectedExternalDocument
}

ClassMethod GetMissingExternalDocument(documentCollection As dc.openapi.common.SwaggerDocumentCollection) As %List
{
    Set ssp = ##class(dc.openapi.common.SwaggerSpecProcessor).%New(documentCollection)
    Set isValid = ssp.Validate()
    Return ..GetMissingExternalDocumentFromSSP(ssp)
}

ClassMethod GetMissingExternalDocumentFromSSP(ssp As dc.openapi.common.SwaggerSpecProcessor) As %List [ Private ]
{
    Return:'$IsObject(ssp.Errors.MissingExternalSwagger) ""
    Set missingExternalDocument = ""
    Set iterator = ssp.Errors.MissingExternalSwagger.%GetIterator()
    While iterator.%GetNext(.key, .value) {
        Set $List(missingExternalDocument, *+1) = value
    } 
    Return missingExternalDocument
}

ClassMethod DocumentCollectionToAST(documentCollection As dc.openapi.common.SwaggerDocumentCollection, Output AST As dc.openapi.common.ast.OAS) As %Status
{
    Set transformer = ##class(dc.openapi.common.SwaggerToASTConverter).%New(documentCollection)
    Set tSc = transformer.Transform()
    Set AST = transformer.AST
    Return tSc
}

}
