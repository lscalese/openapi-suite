Class dc.openapi.suite.samples.OASClient
{

/// This method allows to make an http request to a remote server of OpenAPI-Suite services <br/>
/// in order to generate the code and import\compile on the local instance.<br/>
/// 
/// Set server = "openapisuite.demo.community.intersystems.com" ;<br/>
/// Set specification="https://petstore3.swagger.io/api/v3/openapi.json" ;<br/>
/// Set packageName = "petstoreclient" <br/>
/// Set type = "client" ; possible value : client, production, rest <br/>
/// Set sc = ##class(dc.openapi.suite.samples.OASClient).GenerateFromRemoteServer(server,specification,packageName,type)
ClassMethod GenerateFromRemoteServer(server As %String, specfication As %String, packageName As %String, type As %String) As %Status
{
    Set sc = $$$OK

    New $Namespace
    Set ns = $Namespace

    
    Set ssl="DefaultSSL", $namespace="%SYS"  
    do ##class(Security.SSLConfigs).Create(ssl)
    Set $namespace = ns
    
    set type="client", packageName="petstoreclient"
    Set r=##class(%Net.HttpRequest).%New(),r.Server=server,r.Https=1,r.SSLConfiguration=ssl,r.ContentType="text/plain"
    Do r.SetParam("type",type), r.SetParam("packageName",packageName), r.SetHeader("accept","application/xml"), r.EntityBody.Write(specfication)

    Set sc = r.Post("/openapisuite/generate")

    If 'sc {
        Do $SYSTEM.Status.DisplayError(sc)
        Return sc
    }

    If r.HttpResponse.StatusCode '= 200 {
        Set sc = $SYSTEM.Status.Error(5001, "Server response is http status code " _ r.HttpResponse.StatusCode)
        
        Write !," ! Http status code : ", r.HttpResponse.httpStatusCode

        If $IsObject(r.HttpResponse.Data) {
            Write !,r.HttpResponse.Data.Read()
        } Else {
            Write !,r.HttpResponse.Data
        }
        
        Return sc
    }
    
    Set sc = $SYSTEM.OBJ.LoadStream(r.HttpResponse.Data,"ck")

    Return sc
}

}
