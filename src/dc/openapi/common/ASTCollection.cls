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

}
