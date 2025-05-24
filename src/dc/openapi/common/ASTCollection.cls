Class dc.openapi.common.ASTCollection Extends (%JSON.Adaptor, %RegisteredObject)
{

Property ASTs As list Of dc.openapi.common.ASTReference;

/// insert the ASTReference into the collection
/// if the key already exists, it will be replaced
/// if the key does not exist, it will be added
/// @param astRef the ASTReference to insert
/// @return %Status indicating success or failure
Method SafeInsert(astRef As dc.openapi.common.ASTReference) As %Status
{
    #dim existingASTRef As dc.openapi.common.ASTReference

    Set index = ""
    For  {
        Set existingASTRef = ..ASTs.GetNext(.index)
        Quit:index=""
        If existingASTRef.Key = astRef.Key {
            Return ..ASTs.SetAt(astRef, index)
        }
    }
    Return ..ASTs.Insert(astRef)
}

Method GetByKey(key As %String) As dc.openapi.common.ASTReference
{
    #dim astRef As dc.openapi.common.ASTReference
    Set index = ""
    For  {
        Set astRef = ..ASTs.GetNext(.index)
        Quit:index=""
        If astRef.Key = key {
            Return astRef
        }
    }
    Return $$$NULLOREF
}

Method ASTCollectionResolve() As %Status
{
    #dim astRef As dc.openapi.common.ASTReference
    Set tSc = $$$OK
    Set index = ""
    For  {
        Set astRef = ..ASTs.GetNext(.index)
        Quit:index=""
        Set variables(astRef.Key) = astRef.PackageModel
    }

    Set index = ""
    For  {
        Set astRef = ..ASTs.GetNext(.index)
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
