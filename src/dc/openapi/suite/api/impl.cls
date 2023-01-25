Class dc.openapi.suite.api.impl Extends %REST.Impl [ ProcedureBlock ]
{

Parameter ExposeServerExceptions = 1;

/// Service implemntation for post /generate/client
ClassMethod GenerateInteropClient(messageRequest As dc.openapi.suite.api.requests.GenerateInteropClient) As %Status
{
	; Implement your service here.
	; Return {}
	$$$ThrowStatus($$$ERROR($$$NotImplemented))
}

/// Service implemntation for post /generate/server
ClassMethod GenerateServer(messageRequest As dc.openapi.suite.api.requests.GenerateServer) As %Status
{
	; Implement your service here.
	; Return {}
	$$$ThrowStatus($$$ERROR($$$NotImplemented))
}

/// Service implemntation for post /install/client
ClassMethod InstallClient(messageRequest As dc.openapi.suite.api.requests.InstallClient) As %Status
{
	; Implement your service here.
	; Return {}
	$$$ThrowStatus($$$ERROR($$$NotImplemented))
}

/// Service implemntation for post /install/server
ClassMethod InstallServer(messageRequest As dc.openapi.suite.api.requests.InstallServer) As %Status
{
	; Implement your service here.
	; Return {}
	$$$ThrowStatus($$$ERROR($$$NotImplemented))
}

/// Process request SwaggerSpec /_spec
ClassMethod SwaggerSpec() As %Status
{
	Set spec = {}.%FromJSON(##class(%Dictionary.CompiledXData).%OpenId("dc.openapi.suite.api.Spec||OpenAPI").Data)
	Set url = $Select(%request.Secure:"https",1:"http") _ "://"_$Get(%request.CgiEnvs("SERVER_NAME")) _ ":" _ $Get(%request.CgiEnvs("SERVER_PORT")) _ %request.Application
	Set spec.servers = [{"url" : (url)}]
	Quit spec
}

}
