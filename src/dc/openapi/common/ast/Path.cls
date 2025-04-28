/// Represents a path in the OpenAPI specification
Class dc.openapi.common.ast.Path Extends (%JSON.Adaptor, %RegisteredObject)
{

Property path As %String;

Property verb As %String;

Property operationId As %String;

Property summary As %String;

Property description As %String;

Property parameters As list Of dc.openapi.common.ast.Parameter;

Property requestBody As list Of dc.openapi.common.ast.RequestBody;

}
