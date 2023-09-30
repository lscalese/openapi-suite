Class dc.openapi.suite.client.requests.generateAndInstall Extends %RegisteredObject [ ProcedureBlock ]
{

Parameter METHOD = "post";

Parameter URL = "/install";

Property %Consume As %String;

Property %ContentType As %String;

Property %URL As %String [ InitialExpression = {..#URL} ];

/// Use this property for body content with content-type = text/plain.
Property body As %String(MAXLEN = 2048);

/// Use this property for body content with content-type = application/json.
Property bodyJSON As %DynamicObject;

/// Namespace to install the generated code.
Property querynamespace As %String;

/// package name of the generated classes.
Property querypackageName As %String;

/// Type of generation possible value are : client, production or rest.
Property querytype As %String;

/// WebApplication name to create, if empty web application won't be created.
Property querywebApplicationName As %String;

/// Load %Net.HttpRequest with this property object.
Method LoadHttpRequestObject(ByRef httpRequest As %Net.HttpRequest) As %Status
{
	Set sc = $$$OK
	Set httpRequest.ContentType = ..%ContentType
	Do httpRequest.SetHeader("accept", ..%Consume)
	Do httpRequest.SetParam("packageName",..querypackageName)
	Do httpRequest.SetParam("type",..querytype)
	Do httpRequest.SetParam("namespace",..querynamespace)
	Do httpRequest.SetParam("webApplicationName",..querywebApplicationName)
	If $Piece($$$LOWER(..%ContentType),";",1) = "text/plain" {
		; To implement.  There is no code generation yet for this case.
		$$$ThrowStatus($$$ERROR($$$NotImplemented))
	}
	If $Piece($$$LOWER(..%ContentType),";",1) = "application/json" Do ..bodyJSON.%JSONExportToStream(httpRequest.EntityBody)
	Quit sc
}

}
