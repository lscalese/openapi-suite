Class dc.openapi.common.ValidationResult Extends (%JSON.Adaptor, %RegisteredObject)
{

Property IsValid As %Boolean(%JSONFIELDNAME = "isValid") [ InitialExpression = 0 ];

Property Errors As list Of %String(%JSONFIELDNAME = "errors");

Property ExpectedExternalDocuments As list Of %String(%JSONFIELDNAME = "expectedExternalDocuments");

Property MissingExternalDocuments As list Of %String(%JSONFIELDNAME = "missingExternalDocuments");

Property UndefinedReferences As list Of %String(%JSONFIELDNAME = "undefinedReferences");

}
