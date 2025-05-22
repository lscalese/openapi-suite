Class dc.openapi.suite.apiv2.Dispatcher Extends %CSP.REST [ ProcedureBlock ]
{

Parameter IgnoreWrites = 1;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <Route Url="/ping" Method="GET" Call="Ping" />
    <Route Url="/_spec" Method="GET" Call="SwaggerSpec" />
    <Route Url="/validate-document-collection" Method="POST" Call="ValidateDocumentCollection" />
    <Route Url="/generate-ast" Method="POST" Call="GenerateAST" />
</Routes>
}

ClassMethod Ping() As %Status
{
    Set sc = $$$OK
    Try {
        Do ##class(%REST.Impl).%SetContentType("application/json")
        Set response = ##class(dc.openapi.suite.apiv2.Implementation).Ping()
        Do ##class(dc.openapi.suite.apiv2.Implementation).%WriteResponse(response)
    } Catch(ex) {
        Do ##class(%REST.Impl).%ReportRESTError(..#HTTP500INTERNALSERVERERROR,ex.AsStatus(),$parameter("dc.openapi.suite.api.impl","ExposeServerExceptions"))
    }
    Quit sc
}

ClassMethod SwaggerSpec() As %Status
{
	Set sc = $$$OK
    Try {
        Do ##class(%REST.Impl).%SetContentType("application/json")
        Set response = ##class(dc.openapi.suite.apiv2.Implementation).SwaggerSpec()
        Do ##class(dc.openapi.suite.apiv2.Implementation).%WriteResponse(response)
    } Catch(ex) {
        Do ##class(%REST.Impl).%ReportRESTError(..#HTTP500INTERNALSERVERERROR,ex.AsStatus(),$parameter("dc.openapi.suite.api.impl","ExposeServerExceptions"))
    }
    Quit sc
}

ClassMethod ValidateDocumentCollection() As %Status
{
    Set sc = $$$OK
    Try {
        #dim %request As %CSP.Request
        Do ##class(%REST.Impl).%SetContentType("application/json")
        Set response = ##class(dc.openapi.suite.apiv2.Implementation).ValidateDocumentCollection()
        Do ##class(dc.openapi.suite.apiv2.Implementation).%WriteResponse(response)
    } Catch(ex) {
        Do ##class(%REST.Impl).%ReportRESTError(..#HTTP500INTERNALSERVERERROR,ex.AsStatus(),$parameter("dc.openapi.suite.api.impl","ExposeServerExceptions"))
    }
    Quit sc
}

ClassMethod GenerateAST() As %Status
{
    Set sc = $$$OK
    Try {
        #dim %request As %CSP.Request
        Do ##class(%REST.Impl).%SetContentType("application/json")
        Set response = ##class(dc.openapi.suite.apiv2.Implementation).GenerateAST()
        Do ##class(dc.openapi.suite.apiv2.Implementation).%WriteResponse(response)
    } Catch(ex) {
        Do ##class(%REST.Impl).%ReportRESTError(..#HTTP500INTERNALSERVERERROR,ex.AsStatus(),$parameter("dc.openapi.suite.api.impl","ExposeServerExceptions"))
    }
    Quit sc
}

}
