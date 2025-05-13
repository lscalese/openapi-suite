/// Represents a path in the OpenAPI specification
Class dc.openapi.common.ast.Path Extends (%JSON.Adaptor, %RegisteredObject)
{

Property Path As %String(MAXLEN = 1024);

Property Verb As %String;

Property OperationId As %String;

Property Summary As %String(MAXLEN = 32000);

Property Description As %String(MAXLEN = 32000);

Property Parameters As list Of dc.openapi.common.ast.Parameter;

Property RequestBodies As list Of dc.openapi.common.ast.RequestBody;

Property Responses As list Of dc.openapi.common.ast.Response;

Property IsGeneratedOperationId As %Boolean [ InitialExpression = 0 ];

}
