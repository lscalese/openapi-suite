Class dc.openapi.suite.services.Generator
{

ClassMethod DocumentCollectionValidation(documentCollection As dc.openapi.common.SwaggerDocumentCollection) As dc.openapi.common.ValidationResult
{
    Set ssp = ##class(dc.openapi.common.SwaggerSpecProcessor).%New(documentCollection)
    Do ssp.Validate()
    Return ssp.ValidationResult
}

ClassMethod DocumentCollectionToAST(documentCollection As dc.openapi.common.SwaggerDocumentCollection, Output AST As dc.openapi.common.ast.OAS) As %Status
{
    Set transformer = ##class(dc.openapi.common.SwaggerToASTConverter).%New(documentCollection)
    Set tSc = transformer.Transform()
    Set AST = transformer.AST
    Return tSc
}

ClassMethod ASTRevolve(ASTInput As dc.openapi.common.ast.OAS, ByRef variables As %Binary) As dc.openapi.common.ast.OAS
{
    Set gcs = ##class(%Stream.GlobalCharacter).%New(), resolvedGCS = ##class(%Stream.GlobalCharacter).%New()
    Do ASTInput.%JSONExportToStream(.gcs)

    While 'gcs.AtEnd {
        Set line = gcs.ReadLine()

        Set key = ""
        For  {
            Set key = $Order(variables(key), 1, value)
            Quit:key=""
            Set line = $Replace(line, "{{" _ key _ "}}", value)
        }
        Do resolvedGCS.WriteLine(line)
    }

    Do resolvedGCS.Rewind()
    Set outAST = ##class(dc.openapi.common.ast.OAS).%New()
    Do outAST.%JSONImport(resolvedGCS)
    Return outAST
}

}
