/// Represents a path parameter in the OpenAPI specification
Class dc.openapi.common.ast.Parameter Extends (%JSON.Adaptor, %RegisteredObject)
{

/// The name of the parameter
Property name As %String;

/// The location of the parameter (query, header, path, cookie)
Property in As %String;

/// The type of the parameter (string, number, boolean, etc.)
Property type As dc.openapi.common.ast.ParameterType;

/// A description of the parameter
Property description As %String;

/// Whether the parameter is required or optional
Property required As %Boolean;

/// The default value of the parameter
Property defaultValue As %String;

}
