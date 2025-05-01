Class dc.openapi.common.SwaggerDocumentReference Extends %RegisteredObject
{

Property Key As %String;

Property IsAFullSpecification As %Boolean [ InitialExpression = {$$$NO} ];

Property Document As %DynamicObject;

Property PackageModel As %String;

}
