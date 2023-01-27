Class dc.openapi.suite.api.requests.generateAndInstall Extends %RegisteredObject [ ProcedureBlock ]
{

Parameter METHOD = "post";

Parameter URL = "/install";

Property %Consume As %String;

Property %ContentType As %String;

Property %URL As %String [ InitialExpression = {..#URL} ];

/// Use this property for body content with content-type = text/plain.<br/>
Property body1 As %String [ Required ];

/// Use this property for body content with content-type = application/json.<br/>
Property body2 As %DynamicObject [ Required ];

/// Namespace to install the generated code.
Property querynamespace As %String [ Required ];

/// package name of the generated classes.
Property querypackageName As %String;

/// Type of generation possible value are : client, production or rest.
Property querytype As %String;

/// WebApplication name to create, if empty web application won't be created.
Property querywebApplicationName As %String;

/// Load object properties from %CSP.Request object.
Method LoadFromRequest(request As %CSP.Request = {%request}) As %Status
{
	Set sc = $$$OK
	Set ..%ContentType = $Piece(request.ContentType, ";", 1)
	Set ..querypackageName = $Get(request.Data("packageName",1))
	Set ..querytype = $Get(request.Data("type",1))
	Set ..querynamespace = $Get(request.Data("namespace",1))
	Set ..querywebApplicationName = $Get(request.Data("webApplicationName",1))
	If ..%ContentType = "text/plain" {
		Set:$IsObject(request.Content) ..body1 = request.Content.Read()
	}
	If ..%ContentType = "application/json" {
		Set:$IsObject(request.Content) ..body2 = {}.%FromJSON(request.Content)
	}
	Quit sc
}

/// Load object properties from %CSP.Request object.
Method RequestValidate() As %Status
{
	Set sc = $$$OK
	
	$$$QuitOnError(..%ValidateObject())

	If '$ListFind($ListBuild("client","production","rest"), ..querytype) {
		Quit $$$ERROR(5001, "type must be client, production or rest.")
	}

	Set sc = ##class(%Dictionary.Classname).IsValid(..querypackageName _ ".test")
	If $$$ISERR(sc) {
		Quit $$$ERROR(5001, "Invalid packageName.")
	}

	If ..querywebApplicationName'="", $Extract(..querywebApplicationName) '= "/" {
		Quit $$$ERROR(5001, "Invalid webApplicationName.")
	}

	If ..%ContentType = "text/plain", ..body1 = "" {
		Quit $$$ERROR(5659, "body1 required")
	}

	If ..%ContentType = "application/json", '$IsObject(..body1) {
		Quit $$$ERROR(5659, "body2 required")
	}
	
	Quit sc
}

}
