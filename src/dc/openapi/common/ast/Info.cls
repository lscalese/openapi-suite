/// The OpenAPI Specification (OAS) info object
Class dc.openapi.common.ast.Info Extends (%JSON.Adaptor, %RegisteredObject)
{

Property Title As %String(MAXLEN = 1024);

Property Version As %String;

Property Description As %String(MAXLEN = 32000);

Property TermsOfService As %String(MAXLEN = 32000);

}
