/// Represents a reponse item in the OpenAPI specification
Class dc.openapi.common.ast.Response Extends (%JSON.Adaptor, %RegisteredObject)
{

Property StatusCode As %String;

Property Description As %String;

Property ContentType As %String;

Property Example As %String;

Property ModelProperty As dc.openapi.common.ast.ModelProperty;

}
