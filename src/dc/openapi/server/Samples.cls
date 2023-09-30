Class dc.openapi.server.Samples
{

ClassMethod PetStore() As %Status
{
    Set applicationName = "petshopsrv"

    Do $SYSTEM.OBJ.DeletePackage(applicationName)

    Write !,"Generate client app "_applicationName _"..."

    Set sc = ##class(dc.openapi.server.ServerAppGenerator).Generate(applicationName, "https://petstore3.swagger.io/api/v3/openapi.json", "/petstore/api")

    Write "Status : ", $SYSTEM.Status.GetOneErrorText(sc)

    Return sc
}

}
