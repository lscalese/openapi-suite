Class dc.openapi.client.template.Request Extends dc.openapi.common.template.Code
{

ClassMethod Decision(request As dc.openapi.common.ast.Path) As %String
{
    Return "BuildRequest"
}

XData BuildRequest [ MimeType = plain/text ]
{
    Set sc = $$$OK
    Set ..%Path = ..#PATH

    /// Set http header
    Do {{HttpRequestObject}}.SetHeader("Accept", ..%Accept)
    Do {{HttpRequestObject}}.SetHeader("Content-Type", ..%ContentType)
    {{header}}
    /// Set path parameters
    {{path}}
    /// Set query parameters
    {{query}}
    /// Set cookie parameters
    {{cookie}}
    /// Set request body
    {{RequestBodies}}
    Return sc
}

}
