Class dc.openapi.suite.client.HttpClient Extends %RegisteredObject [ ProcedureBlock ]
{

Parameter SERVER = "https://openapisuite.demo.community.intersystems.comhttp://openapisuite.demo.community.intersystems.com/openapisuite/";

Parameter SSLCONFIGURATION = "DefaultSSL";

Property HttpRequest [ InitialExpression = {##class(%Net.HttpRequest).%New()} ];

Property SSLConfiguration As %String [ InitialExpression = {..#SSLCONFIGURATION} ];

Property Server As %String [ InitialExpression = {..#SERVER} ];

Property URLComponents [ MultiDimensional ];

Method %OnNew(Server As %String, SSLConfiguration As %String) As %Status
{
	Set:$Data(Server) ..Server = Server
	Set:$Data(SSLConfiguration) ..SSLConfiguration = SSLConfiguration
	Quit ..InitializeHttpRequestObject()
}

Method InitializeHttpRequestObject() As %Status
{
	Set ..HttpRequest = ##class(%Net.HttpRequest).%New()
	Do ##class(%Net.URLParser).Decompose(..Server, .components)
	Set:$Data(components("host"), host) ..HttpRequest.Server = host
	Set:$Data(components("port"), port) ..HttpRequest.Port = port
	Set:$$$LOWER($Get(components("scheme")))="https" ..HttpRequest.Https = $$$YES, ..HttpRequest.SSLConfiguration = ..SSLConfiguration
	Merge:$Data(components) ..URLComponents = components
	Quit $$$OK
}

/// Implement operationId : generateAndInstall
/// post /install
Method generateAndInstall(requestMessage As dc.openapi.suite.client.requests.generateAndInstall, Output responseMessage As dc.openapi.suite.client.responses.generateAndInstall = {##class(dc.openapi.suite.client.responses.generateAndInstall).%New()}) As %Status
{
	Set sc = $$$OK
	$$$QuitOnError(requestMessage.LoadHttpRequestObject(..HttpRequest))
	$$$QuitOnError(..HttpRequest.Send("POST", $Get(..URLComponents("path")) _ requestMessage.%URL))
	$$$QuitOnError(responseMessage.LoadFromResponse(..HttpRequest.HttpResponse, "generateAndInstall"))
	Quit sc
}

/// Implement operationId : generateCode
/// post /generate
Method generateCode(requestMessage As dc.openapi.suite.client.requests.generateCode, Output responseMessage As dc.openapi.suite.client.responses.generateCode = {##class(dc.openapi.suite.client.responses.generateCode).%New()}) As %Status
{
	Set sc = $$$OK
	$$$QuitOnError(requestMessage.LoadHttpRequestObject(..HttpRequest))
	$$$QuitOnError(..HttpRequest.Send("POST", $Get(..URLComponents("path")) _ requestMessage.%URL))
	$$$QuitOnError(responseMessage.LoadFromResponse(..HttpRequest.HttpResponse, "generateCode"))
	Quit sc
}

}
