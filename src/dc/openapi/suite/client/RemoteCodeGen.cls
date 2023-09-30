/// This class allows to request a remote openapi-suite application to generate the code and install 
/// on this local instance
Class dc.openapi.suite.client.RemoteCodeGen
{

ClassMethod Generate(specification, packageName As %String, type As %String, server As %String) As %Status
{
    Set sc = $$$OK

    If specification = "" {
        Return $$$ERROR(5001, "specification is mandatory.")
    }

    Do ..configSSL()

    Set httpClient = ##class(dc.openapi.suite.client.HttpClient).%New(server)
    Set messageRequest = ##class(dc.openapi.suite.client.requests.generateCode).%New()
    Set messageRequest.querytype = type
    Set messageRequest.querypackageName = packageName
    Set messageRequest.%Consume = "application/xml"
 
    If $IsObject(specification) {
    
        Set messageRequest.%ContentType = "application/json"

        If specification.%IsA("%DynamicObject") {
            
            Set messageRequest.bodyJSON = specification

        } ElseIf specification.%IsA("%Stream.Object") {
            
            Set messageRequest.bodyJSON = {}.%FromJSON(specification)

        } Else {
            Set sc = $$$ERROR(5001, "Unsupported specification object type (only url, file path, Stream.Object or %DynamicObject are supported.")
        }
    
    } Else {

        Set messageRequest.%ContentType = "text/plain"

        If $$$LOWER($Extract(specification, 1, 4)) = "http" {
            
            Set messageRequest.body = specification
        
        } ElseIf ##class(%File).Exists(specification) { 
            
            Set fileCharacter = ##class(%Stream.FileCharacter).%New()
            Do fileCharacter.LinkToFile(specification)
            Set messageRequest.bodyJSON = {}.%FromJSON(fileCharacter)

        } Else {
            Set sc = $$$ERROR(5001, "Specification file not found.")
        }

    }

    If $$$ISERR(sc) Quit sc

    #dim messageResponse As dc.openapi.suite.client.responses.generateCode
    
    $$$QuitOnError(httpClient.generateCode(.messageRequest, .messageResponse))    

    If messageResponse.httpStatusCode = 200 {

        Set sc = $SYSTEM.OBJ.LoadStream(httpClient.HttpRequest.HttpResponse.Data, "ck")
    
    } Else {
    
        Set sc = $$$ERROR(5001, "Not a http response 200 : " _ messageResponse.httpStatusCode)
    
    } 

    Quit sc
}

ClassMethod configSSL() [ Private ]
{
    New $NAMESPACE
    set $namespace="%SYS", name="DefaultSSL" do:'##class(Security.SSLConfigs).Exists(name) ##class(Security.SSLConfigs).Create(name)
}

ClassMethod GenerateFromDCDemo(specification, packageName As %String, type As %String) As %Status
{
    Set dcDemoServer = "https://openapisuite.demo.community.intersystems.com/openapisuite"
    Return ..Generate(specification, packageName, type, dcDemoServer)
}

ClassMethod Test()
{
    Set sc = ..GenerateFromDCDemo("https://petstore3.swagger.io/api/v3/openapi.json","petstoreclient", "client")
    zw sc
}

}
