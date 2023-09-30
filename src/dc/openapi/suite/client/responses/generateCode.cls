Class dc.openapi.suite.client.responses.generateCode Extends dc.openapi.suite.client.responses.GenericResponse [ ProcedureBlock ]
{

/// Implement operationId : generateCode
/// post /generate
Method LoadFromResponse(httpResponse As %Net.HttpResponse, caller As %String = "") As %Status
{
	Set sc = $$$OK
	Do ##super(httpResponse, caller)
	Quit sc
}

}
