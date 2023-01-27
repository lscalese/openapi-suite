Class dc.openapi.suite.api.impl Extends %REST.Impl [ ProcedureBlock ]
{

Parameter ExposeServerExceptions = 1;

/// Process request SwaggerSpec /_spec
ClassMethod SwaggerSpec() As %Status
{
	Set spec = {}.%FromJSON(##class(%Dictionary.CompiledXData).%OpenId("dc.openapi.suite.api.Spec||OpenAPI").Data)
	Set url = $Select(%request.Secure:"https",1:"http") _ "://"_$Get(%request.CgiEnvs("SERVER_NAME")) _ ":" _ $Get(%request.CgiEnvs("SERVER_PORT")) _ %request.Application
	Set spec.servers = [{"url" : (url)}]
	Quit spec
}

/// Service implementation for post /install
ClassMethod generateAndInstall(messageRequest As dc.openapi.suite.api.requests.generateAndInstall) As %Status
{

	If '$Get(^openapisuite.config("web","enable-install-onserver"), 0) $$$ThrowStatus($$$ERROR(5001, "This service has been disabled on the server.  To enable :  Set ^openapisuite.config(""web"",""enable-install-onserver"")=1" ))

	Set ns = $NAMESPACE
	New $NAMESPACE
	
	Set sc = $$$OK

	Do:##class(community.utils.SSLClient).CreateSSLConfiguration("DefaultSSL")

	If messageRequest.querytype = "production", '##class(%EnsembleMgr).IsEnsembleNamespace(messageRequest.querynamespace) {
		$$$ThrowStatus($$$ERROR(5001, "Ensemble not enabled on the target namespace " _ messageRequest.querynamespace))
	}

	Lock +^zGenConcurrency(" "_messageRequest.querypackageName):10
	If '$Test {
		$$$ThrowStatus($$$ERROR(5001, "Failed to acquire exclusive lock on ^zGenConcurrency" ) )
	}

	If messageRequest.querytype = "production", '##class(%EnsembleMgr).IsEnsembleNamespace(messageRequest.querynamespace) $$$ThrowStatus($$$ERROR(5001, "Target namespace must be Ensemble enabled to install a production"))

	Set specification = $Select(messageRequest.body1'="": messageRequest.body1, 1: messageRequest.body2)

	Set installInThisNamespace = $ZConvert(messageRequest.querynamespace, "U") '= $NAMESPACE

	Set features("compile") = 0

	Set outputRedirect = ""

	If messageRequest.querytype = "client" {
		
		Set features("simpleHttpClientOnly") = 1
		Do ##class(IORedirect.Redirect).ToString()
    	Set sc = ##class(dc.openapi.client.Spec).generateApp(messageRequest.querypackageName, specification, .features)
		Set outputRedirect = ##class(IORedirect.Redirect).Get()
		Do ##class(IORedirect.Redirect).RestoreIO()

	} ElseIf messageRequest.querytype = "production" {
		
		Do ##class(IORedirect.Redirect).ToString()
		Set sc = ##class(dc.openapi.client.Spec).generateApp(messageRequest.querypackageName, specification, .features)
		Set outputRedirect = ##class(IORedirect.Redirect).Get()
		Do ##class(IORedirect.Redirect).RestoreIO()

	} ElseIf messageRequest.querytype = "rest" {
		
		Do ##class(IORedirect.Redirect).ToString()
		Set sc = ##class(dc.openapi.server.ServerAppGenerator).Generate(messageRequest.querypackageName, specification, messageRequest.querywebApplicationName)
		Set outputRedirect = ##class(IORedirect.Redirect).Get()
		Do ##class(IORedirect.Redirect).RestoreIO()

		If 'installInThisNamespace, messageRequest.querywebApplicationName '= "" {
			Set $NAMESPACE = "%SYS"
			Do ##class(Security.Applications).Get(messageRequest.querywebApplicationName, .webProperties)
			Set webProperties("NameSpace") = messageRequest.querynamespace
			Do ##class(Security.Applications).Modify(messageRequest.querywebApplicationName, .webProperties)
			Set $NAMESPACE = ns
		}

	} Else {
		$$$ThrowStatus($$$ERROR(5001, "type must be client, production or rest"))
	}

	
	If 'installInThisNamespace {
		Do $SYSTEM.OBJ.ExportPackageToStream(messageRequest.querypackageName, .xmlStream)
		Do $SYSTEM.OBJ.DeletePackage(messageRequest.querypackageName)
		
		Set $NAMESPACE = messageRequest.querynamespace
		Set scCompile = $$$ADDSC(sc, $SYSTEM.OBJ.LoadStream(.xmlStream, "ck", .err))
		
		Set $NAMESPACE = ns

	} Else {

		Set scCompile = $SYSTEM.OBJ.CompilePackage(messageRequest.querypackageName,"ck", .err)
	}

	Set key=""
	For  {
		Set key = $Order(err(key), 1, msg)
		Quit:key=""
		Set outputRedirect = outputRedirect _ $Char(13,10) _msg
	}

	Lock -^zGenConcurrency(" "_messageRequest.querypackageName)
	
	Return {
		"generateStatus" : ($SYSTEM.Status.GetOneErrorText(sc)),
		"compileStatus" : ($SYSTEM.Status.GetOneErrorText(scCompile)),
		"logs":(outputRedirect)
	}
}

/// Service implemntation for post /generate
ClassMethod generateCode(messageRequest As dc.openapi.suite.api.requests.generateCode) As %Status
{
	; Implement your service here.
	; Return {}
	; 
	Set sc = $$$OK

	Lock +^zGenConcurrency(" "_messageRequest.querypackageName):10
	If '$Test {
		$$$ThrowStatus($$$ERROR(5001, "Failed to acquire exclusive lock on ^zGenConcurrency" ) )
	}

	Set specification = $Select(messageRequest.body1'="": messageRequest.body1, 1: messageRequest.body2)

	Do:##class(community.utils.SSLClient).CreateSSLConfiguration("DefaultSSL")

	TSTART
	
	Set features("compile") = 0
    	
	If messageRequest.querytype = "client" {
		
		Set features("simpleHttpClientOnly") = 1
    	Set sc = ##class(dc.openapi.client.Spec).generateApp(messageRequest.querypackageName, specification, .features)

	} ElseIf messageRequest.querytype = "production" {

		Set sc = ##class(dc.openapi.client.Spec).generateApp(messageRequest.querypackageName, specification, .features)

	} ElseIf messageRequest.querytype = "rest" {

		Set sc = ##class(dc.openapi.server.ServerAppGenerator).Generate(messageRequest.querypackageName, specification)

	}

	Do:$$$ISOK(sc) $SYSTEM.OBJ.ExportPackageToStream(messageRequest.querypackageName, .xmlStream)
	
	TROLLBACK
	
	Lock -^zGenConcurrency(" "_messageRequest.querypackageName)

	If $$$ISERR(sc) $$$ThrowStatus(sc)

	Return xmlStream
}

}
