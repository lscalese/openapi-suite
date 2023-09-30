Class dc.openapi.suite.client.requests.generateCode Extends %RegisteredObject [ ProcedureBlock ]
{

Parameter METHOD = "post";

Parameter URL = "/generate";

Property %Consume As %String;

Property %ContentType As %String;

Property %URL As %String [ InitialExpression = {..#URL} ];

/// Use this property for body content with content-type = text/plain.
Property body As %String(MAXLEN = 2048);

/// Use this property for body content with content-type = application/json.
Property bodyJSON As %DynamicObject;

/// package name of the generated classes.
Property querypackageName As %String;

/// Type of generation possible value are : client, production or rest.
Property querytype As %String;

/// Load %Net.HttpRequest with this property object.
Method LoadHttpRequestObject(ByRef httpRequest As %Net.HttpRequest) As %Status
{
	Set sc = $$$OK
	Set httpRequest.ContentType = ..%ContentType
	Do httpRequest.SetHeader("accept", ..%Consume)
	Do httpRequest.SetParam("packageName",..querypackageName)
	Do httpRequest.SetParam("type",..querytype)
	If $Piece($$$LOWER(..%ContentType),";",1) = "text/plain" {
		Do httpRequest.EntityBody.Write(..body)
	}
	If $Piece($$$LOWER(..%ContentType),";",1) = "application/json" Do ..bodyJSON.%JSONExportToStream(httpRequest.EntityBody)
	Quit sc
}

}
