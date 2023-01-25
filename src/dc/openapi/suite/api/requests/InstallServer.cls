Class dc.openapi.suite.api.requests.InstallServer Extends %RegisteredObject [ ProcedureBlock ]
{

Parameter METHOD = "post";

Parameter URL = "/install/server";

Property %Consume As %String;

Property %ContentType As %String;

Property %URL As %String [ InitialExpression = {..#URL} ];

/// Use this property for body content with content-type = text/plain.<br/>
Property body1 As %String [ Required ];

/// Use this property for body content with content-type = application/json.<br/>
Property body2 As %DynamicObject [ Required ];

/// If true the code will be compiled after import.
Property querycompile As %Boolean;

/// If webapplication is not empty set here the name of the dispatch class.
Property querydispatchclass As %String;

/// Name of the package used for code generation.
Property querypackagename As %String;

/// WebApplication name to create, if empty no web application won't be created.
Property querywebapplication As %String;

/// Load object properties from %CSP.Request object.
Method LoadFromRequest(request As %CSP.Request = {%request}) As %Status
{
	Set sc = $$$OK
	Set ..%ContentType = $Piece(request.ContentType, ";", 1)
	Set ..querypackagename = $Get(request.Data("packagename",1))
	Set ..querycompile = $Get(request.Data("compile",1))
	Set ..querywebapplication = $Get(request.Data("webapplication",1))
	Set ..querydispatchclass = $Get(request.Data("dispatchclass",1))
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
