Class dc.openapi.suite.client.responses.GenericResponse Extends %RegisteredObject [ Inheritance = left, ProcedureBlock ]
{

Property body As %Stream.GlobalBinary;

Property headers As array Of %String(MAXLEN = 128, TRUNCATE = 1);

Property httpStatusCode As %Integer;

Property operation As %String(MAXLEN = 128, TRUNCATE = 1);

Method LoadFromResponse(httpResponse As %Net.HttpResponse, caller As %String = "") As %Status
{
	Set sc = $$$OK
	Do ..body.CopyFrom(httpResponse.Data)
	Set ..httpStatusCode = httpResponse.StatusCode
	Set ..operation = caller
	Set key = ""
	For  {
		Set key = $Order(httpResponse.Headers(key), 1, headerValue)
		Quit:key=""
		Do ..headers.SetAt(headerValue, key)
	}
	Quit sc
}

}
