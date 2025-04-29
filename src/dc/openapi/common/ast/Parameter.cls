/// Represents a path parameter in the OpenAPI specification
Class dc.openapi.common.ast.Parameter Extends (%JSON.Adaptor, %RegisteredObject)
{

/// The name of the parameter
Property Name As %String;

/// The location of the parameter (query, header, path, cookie)
Property In As %String;

/// A description of the parameter
Property Description As %String;

/// Whether the parameter is required or optional
Property Required As %Boolean;

Property ModelProperty As dc.openapi.common.ast.ModelProperty;

}
