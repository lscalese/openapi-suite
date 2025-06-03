Class dc.openapi.client.template.HttpClient Extends dc.openapi.common.template.Code
{

XData %PrepareMethod [ MimeType = plain/text ]
{
    Do ##class(%Net.URLParser).Decompose(..Server, .components)
    Set ..HttpRequest = ##class(%Net.HttpRequest).%New()
    Set ..HttpRequest.Https = $Select($$$LOWER($Get(components("scheme")))="https":1,1:0)
    Set ..HttpRequest.Server = $Get(components("host"))
    Set ..HttpRequest.Port = $Get(components("port"))
    Set:..HttpRequest.Https ..HttpRequest.SSLConfiguration = ..SSLConfiguration
    Set ..BasePath = $Get(components("path"))
    Return $$$OK
}

}
