Class dc.openapi.suite.api.requests.generateCode Extends %RegisteredObject [ ProcedureBlock ]
{

Parameter METHOD = "post";

Parameter URL = "/generate";

Property %Consume As %String;

Property %ContentType As %String;

Property %URL As %String [ InitialExpression = {..#URL} ];

/// Use this property for body content with content-type = text/plain.<br/>
Property body1 As %String (MAXLEN = 2048);

/// Use this property for body content with content-type = application/json.<br/>
Property body2 As %DynamicObject;

/// package name of the generated classes.
Property querypackageName As %String (MAXLEN = 256) [ Required ];

/// Type of generation possible value are : client, production or rest.
Property querytype As %String [ Required ];

/// Load object properties from %CSP.Request object.
Method LoadFromRequest(request As %CSP.Request = {%request}) As %Status
{
	Set sc = $$$OK
	Set ..%ContentType = $Piece(request.ContentType, ";", 1)
	Set ..querypackageName = $Get(request.Data("packageName",1))
	Set ..querytype = $Get(request.Data("type",1))
	If ..%ContentType = "text/plain" {
		Set:$IsObject(request.Content)'="" ..body1 = request.Content.Read()
	}
	If ..%ContentType = "application/json" {
		Set:$IsObject(request.Content)'="" ..body2 = {}.%FromJSON(request.Content)
	}
	Quit sc
}

/// Load object properties from %CSP.Request object.
Method RequestValidate() As %Status
{
	Set sc = $$$OK
	
	$$$QuitOnError(..%ValidateObject())

	Set sc = ##class(%Dictionary.Classname).IsValid(..querypackageName _ ".test")
	If $$$ISERR(sc) {
		Quit $$$ERROR(5001, "Invalid packageName.")
	}

	If "clientproductionrest" '[ ..querytype {
		Quit $$$ERROR(5001, "type must be client, production or rest.")
	}

	If ..%ContentType = "text/plain", ..body1 = "" {
		Quit $$$ERROR(5659, "body1 required")
	}

	If ..%ContentType = "application/json", '$IsObject(..body2) {
		Quit $$$ERROR(5659, "body2 required")
	}
	
	Quit sc
}

}
