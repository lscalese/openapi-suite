Class dc.openapi.common.SwaggerDocumentReference Extends %RegisteredObject
{

Property Key As %String;

Property IsAFullSpecification As %Boolean [ InitialExpression = {$$$NO} ];

Property Document As %DynamicObject;

Property Settings As %DynamicObject [ InitialExpression = {{}} ];

Method GetModelPackage() As %String
{
    Set modelPackage = ""
    If ..Settings.%IsDefined("modelPackage") {
        Set modelPackage = ..Settings.modelPackage
    }
    Return modelPackage
}

}
