Class dc.openapi.suite.samples.PetStore
{

ClassMethod GenerateHttpClient() As %Status
{
    Set packageName = "petstoreclient"
    
    Write !,"Delete previous code generation ..."

    Do $SYSTEM.OBJ.DeletePackage(packageName)

    Write !,"Generate client HTTP "_ packageName _"..."

    Set features("simpleHttpClientOnly") = 1
    ;Set features("compile") = 1

    Set sc = ##class(dc.openapi.client.Spec).generateApp(packageName, "https://petstore3.swagger.io/api/v3/openapi.json", .features)
    
    Write !,!,"Status : ", $SYSTEM.Status.GetOneErrorText(sc)

    Return sc
}

ClassMethod GenerateClientProduction() As %Status
{
    Set packageName = "petstoreproduction"
    
    Write !,"Delete previous code generation ..."

    Do $SYSTEM.OBJ.DeletePackage(packageName)

    Write !,"Generate client Production " _ packageName _"..."

    Set sc = ##class(dc.openapi.client.Spec).generateApp(packageName, "https://petstore3.swagger.io/api/v3/openapi.json")
    
    Write !,!,"Status : ", $SYSTEM.Status.GetOneErrorText(sc)

    Return sc
}

ClassMethod GenerateRestApplication() As %Status
{
    Set sc = $$$OK    

    Set packageName = "petstoreserver", webApplication = "/petstore/api"
    
    Write !,"Delete previous code generation ..."

    Do $SYSTEM.OBJ.DeletePackage(packageName)

    Write !,"Generate REST application " _ packageName _" with Web Application : " _ webApplication

    Set sc = ##class(dc.openapi.server.ServerAppGenerator).Generate("petstoreserver", "https://petstore3.swagger.io/api/v3/openapi.json", webApplication)
    
    Write !,!,"Status : ", $SYSTEM.Status.GetOneErrorText(sc)

    Return sc
}

ClassMethod addPetUsingProduction() As %Status
{
    Set sc = $$$OK
    
    Set messageRequest = ##class(petstoreproduction.requests.addPet).%New()
    Set messageRequest.%ContentType = "application/json"
    
    Do messageRequest.body1NewObject().%JSONImport({"id":123,"name":"Kitty Galore","photoUrls":["https://www.tippett.com/wp-content/uploads/2017/01/ca2DC049.130.1264.jpg"],"status":"pending"})
    
    ; MessageResponse will be an instance of petstoreclient.responses.addPet
    Set sc = ##class(petstoreproduction.Utils).invokeHostSync("petstoreproduction.bp.SyncProcess", messageRequest, "petstoreproduction.bs.ProxyService", , .messageResponse)

    Write !, "Take a look in visual trace (management portal)"

    If $$$ISERR(sc) Do $SYSTEM.Status.DisplayError(sc)

    Write !,"Http Status code : ", messageResponse.httpStatusCode,!
    Do messageResponse.Pet.%JSONExport()
    
    Return sc
}

ClassMethod addPetUsingHttpClient() As %Status
{
    Set sc = $$$OK
    
    Set messageRequest = ##class(petstoreclient.requests.addPet).%New()
    Set messageRequest.%ContentType = "application/json"
    
    Do messageRequest.body1NewObject().%JSONImport({"id":456,"name":"Mittens","photoUrls":["https://static.wikia.nocookie.net/disney/images/c/cb/Profile_-_Mittens.jpg/revision/latest?cb=20200709180903"],"status":"available"})
    
    Set httpClient = ##class(petstoreclient.HttpClient).%New("https://petstore3.swagger.io/api/v3","DefaultSSL")

    ; MessageResponse will be an instance of petstoreclient.responses.addPet
    Set sc = httpClient.addPet(messageRequest, .messageResponse)
    If $$$ISERR(sc) Do $SYSTEM.Status.DisplayError(sc) Quit sc
    
    Write !,"Http Status code : ", messageResponse.httpStatusCode,!
    Do messageResponse.Pet.%JSONExport()
    
    Return sc
}

}
