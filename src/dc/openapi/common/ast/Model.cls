Class dc.openapi.common.ast.Model Extends (%JSON.Adaptor, %RegisteredObject)
{

Property SchemaRef As %String;

Property Package As %String;

Property Name As %String;

Property Super As %String [ InitialExpression = "%JSON.Adaptor,%RegisteredObject" ];

Property Properties As list Of dc.openapi.common.ast.ModelProperty;

Property Description As %String;

}
