/// Represents a path request body in the OpenAPI specification
Class dc.openapi.common.ast.RequestBody Extends (%JSON.Adaptor, %RegisteredObject)
{

Property Required As %Boolean;

Property ContentType As %String(MAXLEN = 256);

Property ModelProperty As dc.openapi.common.ast.ModelProperty;

Property Description As %String(MAXLEN = 32000);

}
