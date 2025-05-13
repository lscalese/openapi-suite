/// Represents a path parameter in the OpenAPI specification
Class dc.openapi.common.ast.Parameter Extends (%JSON.Adaptor, %RegisteredObject)
{

/// The name of the parameter
Property Name As %String(MAXLEN = 256);

/// The location of the parameter (query, header, path, cookie)
Property In As %String;

/// A description of the parameter
Property Description As %String(MAXLEN = 32000);

/// Whether the parameter is required or optional
Property Required As %Boolean;

Property ModelProperty As dc.openapi.common.ast.ModelProperty;

Property Style As %String;

Property Explode As %Boolean;

}
