/// Add Open APIs
Class Nuts.OpenApi Extends %RegisteredObject
{

/// Install openapi-suite - in fact I only need client-gen
ClassMethod Install()
{
    zpm "install openapi-suite"
}

/// Generate all APIs
ClassMethod GenerateAll()
{
    do ..Common()
    do ..DidManager()
    do ..Crypto()
    do ..Vcr()
    do ..Vdr()
    do ..Auth()
    do ..Network()
    do ..Monitoring()
}

ClassMethod GenerateAllServer()
{
    Do ##class(Nuts.OpenApi).GenerateServer("Nuts.Api.Common", "https://nuts-node.readthedocs.io/en/stable/_static/common/ssi_types.yaml", 1)
    Do ##class(Nuts.OpenApi).GenerateServer("Nuts.ApiServer.DidManager", "https://nuts-node.readthedocs.io/en/stable/_static/didman/v1.yaml")
    Do ##class(Nuts.OpenApi).GenerateServer("Nuts.ApiServer.Crypto", "https://nuts-node.readthedocs.io/en/stable/_static/crypto/v1.yaml")
    Do ##class(Nuts.OpenApi).GenerateServer("Nuts.ApiServer.Vcr", "https://nuts-node.readthedocs.io/en/stable/_static/vcr/vcr_v2.yaml")
    Do ##class(Nuts.OpenApi).GenerateServer("Nuts.ApiServer.Vdr", "https://nuts-node.readthedocs.io/en/stable/_static/vdr/v1.yaml")
    Do ##class(Nuts.OpenApi).GenerateServer("Nuts.ApiServer.Network", "https://nuts-node.readthedocs.io/en/stable/_static/network/v1.yaml")
    Do ##class(Nuts.OpenApi).GenerateServer("Nuts.ApiServer.Auth", "https://nuts-node.readthedocs.io/en/stable/_static/auth/v1.yaml")
    Do ##class(Nuts.OpenApi).GenerateServer("Nuts.ApiServer.Monitoring", "https://nuts-node.readthedocs.io/en/stable/_static/monitoring/v1.yaml")
}

ClassMethod DeleteAll()
{
    For pkg = "Nuts.Api.Common", "Nuts.Api.DidManager", "Nuts.Api.Crypto","Nuts.Api.Vcr", "Nuts.Api.Vdr", "Nuts.Api.Network", "Nuts.Api.Auth", "Nuts.Api.Monitoring"{
        Do $SYSTEM.OBJ.DeletePackage(pkg)
    }

    Do $SYSTEM.OBJ.DeletePackage("Nuts.ApiServer")
    Quit
}

/// Generate Common schemas
ClassMethod Common() As %Status
{
    // Only generate messages!!
    return ..Generate("Nuts.Api.Common", "https://nuts-node.readthedocs.io/en/stable/_static/common/ssi_types.yaml", 1)
}

/// Install DidManager API
ClassMethod DidManager() As %Status
{
    return ..Generate("Nuts.Api.DidManager", "https://nuts-node.readthedocs.io/en/stable/_static/didman/v1.yaml")
}

/// Install Nuts Crypto  API
ClassMethod Crypto() As %Status
{
    return ..Generate("Nuts.Api.Crypto", "https://nuts-node.readthedocs.io/en/stable/_static/crypto/v1.yaml")
}

/// Install Nuts Verifiable Credential API version 2
ClassMethod Vcr() As %Status
{
    return ..Generate("Nuts.Api.Vcr", "https://nuts-node.readthedocs.io/en/stable/_static/vcr/vcr_v2.yaml")
}

/// Install Nuts Verifiable Data Registry API
ClassMethod Vdr() As %Status
{
    return ..Generate("Nuts.Api.Vdr", "https://nuts-node.readthedocs.io/en/stable/_static/vdr/v1.yaml")
}

/// Install Nuts Network API
ClassMethod Network() As %Status
{
    return ..Generate("Nuts.Api.Network", "https://nuts-node.readthedocs.io/en/stable/_static/network/v1.yaml")
}

/// Install Nuts Auth API
ClassMethod Auth() As %Status
{
    return ..Generate("Nuts.Api.Auth", "https://nuts-node.readthedocs.io/en/stable/_static/auth/v1.yaml")
}

/// Install Nuts Monitoring API
ClassMethod Monitoring() As %Status
{
    return ..Generate("Nuts.Api.Monitoring", "https://nuts-node.readthedocs.io/en/stable/_static/monitoring/v1.yaml")
}

/// Generate API helper
ClassMethod Generate(
	packageName As %String,
	url As %String,
	modelOnly As %Boolean = 0) As %Status
{
    set %zverbose = 1
    // We want a Production and Operation; no Business Services, Business Processes or Utils

    set features("model.property.norequired")=1
    set features("noBS") = 1
    set features("noBP") = 1
    set features("noUtils") = 1
    set features("noExtRef") = 1    ; avoid resolving external ref by validator.swagger.io
    set features("modelOnly") = modelOnly
    set features("reponse-is-text") = 1 // Set Response stream in Generic response as %Stream.GlobalCharacter
    set features("common-package") = "Nuts.Api.Common"
    // Make sure that the common model is properly referenced!
    // for e.g.  "$ref":"../common/ssi_types.yaml#/components/schemas/DIDDocument"
    set externals =  {
        "../common/ssi_types.yaml": "Nuts.Api.Common.model",
        "../common/error_response.yaml": "Nuts.Api.Common.model.ErrorResponse"
    }

    Set sc = ##class(dc.openapi.suite.Generate).ProductionClient(packageName, url, .features,externals)
    ;set sc = ##class(dc.openapi.client.Spec).generateApp(packageName, url, .features, externals)

    if $$$ISERR(sc)
    {
        write "generateApp " _ packageName _ " failed, error ", $SYSTEM.Status.GetErrorText(sc),!
    }
    else
    {
        write "Successfully generated ",packageName,!
    }

    return sc
}

ClassMethod GenerateServer(
	packageName As %String,
	url As %String,
	modelOnly As %Boolean = 0) As %Status
{
    set %zverbose = 1
    // We want a Production and Operation; no Business Services, Business Processes or Utils
    set features("modelOnly") = modelOnly
    set features("noExtRef") = 1    ; avoid resolving external ref by validator.swagger.io
    set features("reponse-is-text") = 1 // Set Response stream in Generic response as %Stream.GlobalCharacter
    set features("common-package") = "Nuts.Api.Common"
    // Make sure that the common model is properly referenced!
    // for e.g.  "$ref":"../common/ssi_types.yaml#/components/schemas/DIDDocument"
    set externals =  {
        "../common/ssi_types.yaml": "Nuts.Api.Common.model"
    }

    set sc = ##class(dc.openapi.server.ServerAppGenerator).Generate(packageName, url, ,.features, externals)

    if $$$ISERR(sc)
    {
        write "generate server App " _ packageName _ " failed, error ", $SYSTEM.Status.GetErrorText(sc),!
    }
    else
    {
        write "Successfully generated ",packageName,!
    }

    return sc
}

}
