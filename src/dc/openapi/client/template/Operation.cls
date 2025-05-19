Class dc.openapi.client.template.Operation Extends dc.openapi.common.template.Code
{

ClassMethod Decision(path As dc.openapi.common.ast.Path) As %String
{
    Return "OperationMethod"
}

XData OperationMethod [ MimeType = plain/text ]
{
    Set sc = $$$OK
    Try {
        Set {{responseModel}} = ##class({{responseObject}}).%New()
        $$$TOE(sc, {{requestModel}}.%BuildRequest(..HttpRequest))
        $$$TOE(sc, ..HttpRequest.Send("{{Verb}}", ..BasePath _ {{requestModel}}.%Path))
        $$$TOE(sc, {{responseModel}}.%FromHttpResponse(..HttpRequest.HttpResponse))
    }
    Catch ex {
        Set sc = ex.AsStatus()
    }
    Return sc
}

}
