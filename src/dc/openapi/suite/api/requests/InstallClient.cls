Class dc.openapi.suite.api.requests.InstallClient Extends %RegisteredObject [ ProcedureBlock ]
{

Parameter METHOD = "post";

Parameter URL = "/install/client";

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
		; To implement.  There is no code generation yet for this case.
		$$$ThrowStatus($$$ERROR($$$NotImplemented))
	}
	If ..%ContentType = "application/json" {
		Set:$Get(request.Content)'="" ..body2 = {}.%FromJSON(request.Content)
	}
	Quit sc
}

/// Load object properties from %CSP.Request object.
Method RequestValidate() As %Status
{
	Set sc = $$$OK
	$$$QuitOnError(..%ValidateObject())
	Quit:'$IsObject(..body1) $$$ERROR(5659, "body1")
	Quit:'$IsObject(..body2) $$$ERROR(5659, "body2")
	Quit sc
}

}
