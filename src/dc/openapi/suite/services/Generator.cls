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

ClassMethod ASTCollectionResolve(ASTCollection As dc.openapi.common.ASTCollection, ByRef variables As %Binary) As %Status
{
    #dim astRef As dc.openapi.common.ASTReference
    Set tSc = $$$OK
    Set index = ""
    For  {
        Set astRef = ASTCollection.ASTs.GetNext(.index)
        Quit:index=""
        Set astRef.AST = ##class(dc.openapi.suite.services.Generator).ASTRevolve(astRef.AST, .variables)
    }
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
