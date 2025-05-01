Class dc.openapi.common.YAMLToJSON Extends %RegisteredObject
{

Parameter DEFAULTCONVERTER = "http://yaml2json:80/convert";

Parameter SSLCONFIGURATION = "default";

Property ConverterURL As %String [ InitialExpression = {$Get(^swaggerconverter("yaml2json"), ..#DEFAULTCONVERTER)} ];

Property SSLConfig As %String [ InitialExpression = {$Get(^swaggerconverter("SSLConfig"), ..#SSLCONFIGURATION)} ];

Property httpRequest As %Net.HttpRequest;

/// Set sc = ##class(dc.swaggerconverter.WebConverter).test()
ClassMethod test() As %Status
{
    Set path = "/home/irisowner/irisdev/temp-dev-specs/v1.yaml"
    Set path = "/home/irisowner/irisdev/temp-dev-specs/error_response.yaml"
    
    Set webConverter = ##class(dc.openapi.common.YAMLToJSON).%New()
    Set sc = webConverter.ConvertFromFile(path, .jsonDocument)
    If $$$ISERR(sc) {
        Write "Error: "_ $SYSTEM.Status.GetErrorText(sc)
    }
    Else {
        Do ##class(%JSON.Formatter).%New().Format(jsonDocument)
    }
    Quit sc
}

Method Convert(yamlDocument As %Stream.GlobalCharacter, Output jsonDocument As %DynamicObject, Output stack As %String = "") As %Status
{
    Set OpenAPIV3 = {}, sc = $$$OK
    Do:'$ISOBJECT(..httpRequest) ..initHttpRequestObject()

    Do ..httpRequest.EntityBody.Clear()
    Do ..httpRequest.EntityBody.CopyFrom(yamlDocument)

	$$$QuitOnError(..httpRequest.Send("POST", "/convert"))

    #dim pHttpResponse As %Net.HttpResponse = ..httpRequest.HttpResponse
	
    If pHttpResponse.StatusCode'="200" {
        Set sc = $$$ERROR($$$GeneralError, "Https Status code "_pHttpResponse.StatusCode)
        Set stack = pHttpResponse.Data.Read()
        Quit sc
    }
    
    Set jsonDocument = {}.%FromJSON(pHttpResponse.Data)
    
    Quit sc
}

Method ConvertFromFile(path As %String, Output jsonDocument As %DynamicObject, Output stack As %String = "") As %Status
{
    If '##class(%File).Exists(path) {
        Return $$$ERROR($$$GeneralError, "File not found: "_path)
    }
    Set file = ##class(%Stream.FileCharacter).%New()
    Do file.LinkToFile(path)

    Set documentStream = ##class(%Stream.GlobalCharacter).%New()
    Do documentStream.CopyFrom(file)

    Return ..Convert(documentStream, .jsonDocument, .stack)
}

Method initHttpRequestObject()
{
    Do ##class(%Net.URLParser).Decompose(..ConverterURL, .components)
    Set ..httpRequest = ##class(%Net.HttpRequest).%New()
    Set ..httpRequest.Server = components("host")

	If components("scheme") [ "https:" {
        Do ..AddSSLConfig(..SSLConfig)
        Set ..httpRequest.Https = $$$YES
        Set ..httpRequest.SSLConfiguration = ..SSLConfig
    }

    Set:$Get(components("port"))'="" ..httpRequest.Port = components("port")

    Set ..httpRequest.ContentType = "text/plain"
    Do ..httpRequest.SetHeader("accept", "application/json")

    Quit
}

ClassMethod AddSSLConfig(name As %String)
{
    New $NAMESPACE
    set $namespace="%SYS" do:'##class(Security.SSLConfigs).Exists(name) ##class(Security.SSLConfigs).Create(name)
    Quit
}

}
