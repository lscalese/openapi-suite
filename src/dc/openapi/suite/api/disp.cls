Class dc.openapi.suite.api.disp Extends %CSP.REST [ ProcedureBlock ]
{

Parameter CHARSET = "utf-8";

Parameter CONVERTINPUTSTREAM = 1;

Parameter IgnoreWrites = 1;

Parameter SpecificationClass = "dc.openapi.suite.api.Spec";

/// Process request post /generate/client
ClassMethod GenerateInteropClient() As %Status
{
	Set sc = $$$OK
	Try{
		Set acceptedMedia = $ListFromString("text/plain,application/json")
		If '$ListFind(acceptedMedia,$$$LOWER(%request.ContentType)) {
			 Do ##class(%REST.Impl).%ReportRESTError(..#HTTP415UNSUPPORTEDMEDIATYPE,$$$ERROR($$$RESTContentType,%request.ContentType)) Quit
		}
		Do ##class(%REST.Impl).%SetContentType($Get(%request.CgiEnvs("HTTP_ACCEPT")))
		If '##class(%REST.Impl).%CheckAccepts("application/xml,application/json") Do ##class(%REST.Impl).%ReportRESTError(..#HTTP406NOTACCEPTABLE,$$$ERROR($$$RESTBadAccepts)) Quit
		If '$isobject(%request.Content) Do ##class(%REST.Impl).%ReportRESTError(..#HTTP400BADREQUEST,$$$ERROR($$$RESTRequired,"body")) Quit
		Set requestMessage = ##class(dc.openapi.suite.api.requests.GenerateInteropClient).%New()
		Do requestMessage.LoadFromRequest(%request)
		Set scValidateRequest = requestMessage.RequestValidate()
		If $$$ISERR(scValidateRequest) Do ##class(%REST.Impl).%ReportRESTError(..#HTTP400BADREQUEST,$$$ERROR(5001,"Invalid requestMessage object.")) Quit
		Set response = ##class(dc.openapi.suite.api.impl).GenerateInteropClient(requestMessage)
		Do ##class(dc.openapi.suite.api.impl).%WriteResponse(response)
	} Catch(ex) {
		Do ##class(%REST.Impl).%ReportRESTError(..#HTTP500INTERNALSERVERERROR,ex.AsStatus(),$parameter("dc.openapi.suite.api.impl","ExposeServerExceptions"))
	}
	Quit sc
}

/// Process request post /generate/server
ClassMethod GenerateServer() As %Status
{
	Set sc = $$$OK
	Try{
		Set acceptedMedia = $ListFromString("text/plain,application/json")
		If '$ListFind(acceptedMedia,$$$LOWER(%request.ContentType)) {
			 Do ##class(%REST.Impl).%ReportRESTError(..#HTTP415UNSUPPORTEDMEDIATYPE,$$$ERROR($$$RESTContentType,%request.ContentType)) Quit
		}
		Do ##class(%REST.Impl).%SetContentType($Get(%request.CgiEnvs("HTTP_ACCEPT")))
		If '##class(%REST.Impl).%CheckAccepts("application/xml,application/json") Do ##class(%REST.Impl).%ReportRESTError(..#HTTP406NOTACCEPTABLE,$$$ERROR($$$RESTBadAccepts)) Quit
		If '$isobject(%request.Content) Do ##class(%REST.Impl).%ReportRESTError(..#HTTP400BADREQUEST,$$$ERROR($$$RESTRequired,"body")) Quit
		Set requestMessage = ##class(dc.openapi.suite.api.requests.GenerateServer).%New()
		Do requestMessage.LoadFromRequest(%request)
		Set scValidateRequest = requestMessage.RequestValidate()
		If $$$ISERR(scValidateRequest) Do ##class(%REST.Impl).%ReportRESTError(..#HTTP400BADREQUEST,$$$ERROR(5001,"Invalid requestMessage object.")) Quit
		Set response = ##class(dc.openapi.suite.api.impl).GenerateServer(requestMessage)
		Do ##class(dc.openapi.suite.api.impl).%WriteResponse(response)
	} Catch(ex) {
		Do ##class(%REST.Impl).%ReportRESTError(..#HTTP500INTERNALSERVERERROR,ex.AsStatus(),$parameter("dc.openapi.suite.api.impl","ExposeServerExceptions"))
	}
	Quit sc
}

/// Process request post /install/client
ClassMethod InstallClient() As %Status
{
	Set sc = $$$OK
	Try{
		Set acceptedMedia = $ListFromString("text/plain,application/json")
		If '$ListFind(acceptedMedia,$$$LOWER(%request.ContentType)) {
			 Do ##class(%REST.Impl).%ReportRESTError(..#HTTP415UNSUPPORTEDMEDIATYPE,$$$ERROR($$$RESTContentType,%request.ContentType)) Quit
		}
		Do ##class(%REST.Impl).%SetContentType($Get(%request.CgiEnvs("HTTP_ACCEPT")))
		If '##class(%REST.Impl).%CheckAccepts("application/xml,application/json") Do ##class(%REST.Impl).%ReportRESTError(..#HTTP406NOTACCEPTABLE,$$$ERROR($$$RESTBadAccepts)) Quit
		If '$isobject(%request.Content) Do ##class(%REST.Impl).%ReportRESTError(..#HTTP400BADREQUEST,$$$ERROR($$$RESTRequired,"body")) Quit
		Set requestMessage = ##class(dc.openapi.suite.api.requests.InstallClient).%New()
		Do requestMessage.LoadFromRequest(%request)
		Set scValidateRequest = requestMessage.RequestValidate()
		If $$$ISERR(scValidateRequest) Do ##class(%REST.Impl).%ReportRESTError(..#HTTP400BADREQUEST,$$$ERROR(5001,"Invalid requestMessage object.")) Quit
		Set response = ##class(dc.openapi.suite.api.impl).InstallClient(requestMessage)
		Do ##class(dc.openapi.suite.api.impl).%WriteResponse(response)
	} Catch(ex) {
		Do ##class(%REST.Impl).%ReportRESTError(..#HTTP500INTERNALSERVERERROR,ex.AsStatus(),$parameter("dc.openapi.suite.api.impl","ExposeServerExceptions"))
	}
	Quit sc
}

/// Process request post /install/server
ClassMethod InstallServer() As %Status
{
	Set sc = $$$OK
	Try{
		Set acceptedMedia = $ListFromString("text/plain,application/json")
		If '$ListFind(acceptedMedia,$$$LOWER(%request.ContentType)) {
			 Do ##class(%REST.Impl).%ReportRESTError(..#HTTP415UNSUPPORTEDMEDIATYPE,$$$ERROR($$$RESTContentType,%request.ContentType)) Quit
		}
		Do ##class(%REST.Impl).%SetContentType($Get(%request.CgiEnvs("HTTP_ACCEPT")))
		If '##class(%REST.Impl).%CheckAccepts("application/xml,application/json") Do ##class(%REST.Impl).%ReportRESTError(..#HTTP406NOTACCEPTABLE,$$$ERROR($$$RESTBadAccepts)) Quit
		If '$isobject(%request.Content) Do ##class(%REST.Impl).%ReportRESTError(..#HTTP400BADREQUEST,$$$ERROR($$$RESTRequired,"body")) Quit
		Set requestMessage = ##class(dc.openapi.suite.api.requests.InstallServer).%New()
		Do requestMessage.LoadFromRequest(%request)
		Set scValidateRequest = requestMessage.RequestValidate()
		If $$$ISERR(scValidateRequest) Do ##class(%REST.Impl).%ReportRESTError(..#HTTP400BADREQUEST,$$$ERROR(5001,"Invalid requestMessage object.")) Quit
		Set response = ##class(dc.openapi.suite.api.impl).InstallServer(requestMessage)
		Do ##class(dc.openapi.suite.api.impl).%WriteResponse(response)
	} Catch(ex) {
		Do ##class(%REST.Impl).%ReportRESTError(..#HTTP500INTERNALSERVERERROR,ex.AsStatus(),$parameter("dc.openapi.suite.api.impl","ExposeServerExceptions"))
	}
	Quit sc
}

/// Process request SwaggerSpec /_spec
ClassMethod SwaggerSpec() As %Status
{
	Try {
		Do ##class(%REST.Impl).%SetContentType("application/json")
		If '##class(%REST.Impl).%CheckAccepts("application/json") Do ##class(%REST.Impl).%ReportRESTError(..#HTTP406NOTACCEPTABLE,$$$ERROR($$$RESTBadAccepts)) Quit
		Set response=##class(dc.openapi.suite.api.impl).SwaggerSpec()
		Do ##class(dc.openapi.suite.api.impl).%WriteResponse(response)
	} Catch(ex) {
		 Do ##class(%REST.Impl).%ReportRESTError(..#HTTP500INTERNALSERVERERROR,ex.AsStatus(),$parameter("dc.openapi.suite.api.disp","ExposeServerExceptions"))
	}
	Quit $$$OK
}

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
  <Route Url="/generate/client" Method="POST" Call="GenerateInteropClient" />
  <Route Url="/generate/server" Method="POST" Call="GenerateServer" />
  <Route Url="/install/client" Method="POST" Call="InstallClient" />
  <Route Url="/install/server" Method="POST" Call="InstallServer" />
  <Route Url="/_spec" Method="get" Call="SwaggerSpec" />
</Routes>
}

}
