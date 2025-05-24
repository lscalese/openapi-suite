Class dc.openapi.common.ASTReference Extends (%JSON.Adaptor, %RegisteredObject)
{

Property Key As %String;

Property AST As dc.openapi.common.ast.OAS;

Method %OnNew(Key As %String, AST As dc.openapi.common.ast.OAS) As %Status
{
    Set ..Key = Key
    Set ..AST = AST
    Return $$$OK
}

}
