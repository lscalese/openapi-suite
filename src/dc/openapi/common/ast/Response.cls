/// Represents a reponse item in the OpenAPI specification
Class dc.openapi.common.ast.Response Extends (%JSON.Adaptor, %RegisteredObject)
{

Property httpStatusCode As %String;

Property description As %String;

Property contentType As %String;

Property type As %String;

/// Can be empty, "oneOf", "anyOf" Or "allOf"
Property compositionType As %String;

/// if compositionType is "oneOf", "anyOf" Or "allOf"
/// this property contains the list of schemas
Property schemas As list Of %String;

Property collection As %String;

Property example As %String;

}
