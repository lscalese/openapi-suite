Class dc.openapi.common.ast.ParameterType Extends (%JSON.Adaptor, %RegisteredObject)
{

/// ObjectScript class name type (ex : %String, %Integer, %Boolean, etc.)
Property Name As %String;

Property Type As %String;

Property Format As %String;

Property Collection As %String;

/// spaceDelimited, pipeDelimited, deepObject, form (default)
Property Style As %String;

Property Explode As %Boolean [ InitialExpression = 0 ];

Property SchemaRef As %String;

}
