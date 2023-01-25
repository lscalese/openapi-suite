Class dc.openapi.suite.api.requests.GenerateInteropClient Extends %RegisteredObject [ ProcedureBlock ]
{

Parameter METHOD = "post";

Parameter URL = "/generate/client";

Property %Consume As %String;

Property %ContentType As %String;

Property %URL As %String [ InitialExpression = {..#URL} ];

/// Use this property for body content with content-type = text/plain.<br/>
Property body1 As %String [ Required ];

/// Use this property for body content with content-type = application/json.<br/>
Property body2 As %DynamicObject [ Required ];

/// If true interoperability classes will be generated otherwise only a simple HTTP client.
Property queryinteroperability As %Boolean;

/// Name of the package used for code generation.
Property querypackagename As %String;

/// Load object properties from %CSP.Request object.
Method LoadFromRequest(request As %CSP.Request = {%request}) As %Status
{
	Set sc = $$$OK
	Set ..%ContentType = $Piece(request.ContentType, ";", 1)
	Set ..queryinteroperability = $Get(request.Data("interoperability",1))
	Set ..querypackagename = $Get(request.Data("packagename",1))
	If ..%ContentType = "text/plain" {
		Set:$Get(request.Content)'="" ..body1 = request.Content.Read()
	}
	If ..%ContentType = "application/json" {
		Set:$Get(request.Content)'="" ..body2 = {}.%FromJSON(request.Content)
	}
	Quit sc
}

Method RequestValidate() As %Status
{
	Set sc = $$$OK
	$$$QuitOnError(..%ValidateObject())
	Quit:..body1=""&&'$IsObject(..body2) $$$ERROR(5659, "body1 or body2 are required")
	Quit sc
}

}
