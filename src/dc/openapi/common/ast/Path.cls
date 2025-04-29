/// Represents a path in the OpenAPI specification
Class dc.openapi.common.ast.Path Extends (%JSON.Adaptor, %RegisteredObject)
{

Property Path As %String;

Property Verb As %String;

Property OperationId As %String;

Property Summary As %String;

Property Description As %String;

Property Parameters As list Of dc.openapi.common.ast.Parameter;

Property RequestBodies As list Of dc.openapi.common.ast.RequestBody;

Property Responses As list Of dc.openapi.common.ast.Response;

}
