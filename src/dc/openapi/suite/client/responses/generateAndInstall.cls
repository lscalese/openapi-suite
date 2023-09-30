Class dc.openapi.suite.client.responses.generateAndInstall Extends dc.openapi.suite.client.responses.GenericResponse [ ProcedureBlock ]
{

/// http status code = 200 content-type = application/json
/// 
Property ImportStatus As dc.openapi.suite.client.model.ImportStatus;

/// Implement operationId : generateAndInstall
/// post /install
Method LoadFromResponse(httpResponse As %Net.HttpResponse, caller As %String = "") As %Status
{
	Set sc = $$$OK
	Do ##super(httpResponse, caller)
	If $$$LOWER($Piece(httpResponse.ContentType,";",1))="application/json",httpResponse.StatusCode = "200" {
		Set ..ImportStatus = ##class(dc.openapi.suite.client.model.ImportStatus).%New()
		Do ..ImportStatus.%JSONImport(httpResponse.Data)
		Return sc
	}
	Quit sc
}

}
