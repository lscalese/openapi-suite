Class dc.openapi.suite.Generate
{

/// Generate HTTP Client (without interoperability production)<br/>
/// 
ClassMethod Client(
	PackageName As %String,
	Specfication,
	ByRef Features,
	ExternalRefMap As %DynamicObject = "") As %Status
{
    Set %zverbose = 1
    Set Features("simpleHttpClientOnly") = 1
    
    ; If we have an external ref mapping, set noExtRef to 1
    ; It avoid validator.swagger.io to resolve external references.
    If $IsObject(ExternalRefMap), '$Data(Features("noExtRef")) Set Features("noExtRef") = 1

    Quit ##class(dc.openapi.client.Spec).generateApp(PackageName, Specfication, .Features, ExternalRefMap)
}

ClassMethod ProductionClient(
	PackageName As %String,
	Specfication,
	ByRef Features,
	ExternalRefMap As %DynamicObject = "") As %Status
{
    Set %zverbose = 1
    Set Features("simpleHttpClientOnly") = 0

    ; If we have an external ref mapping, set noExtRef to 1
    ; It avoid validator.swagger.io to resolve external references.
    If $IsObject(ExternalRefMap), '$Data(Features("noExtRef")) Set Features("noExtRef") = 1

    Quit ##class(dc.openapi.client.Spec).generateApp(PackageName, Specfication, .Features, ExternalRefMap)
}

ClassMethod Server(
	PackageName As %String,
	Specfication,
	ByRef Features,
	ExternalRefMap As %DynamicObject = "") As %Status
{
    Set %zverbose = 1
    
    ; If we have an external ref mapping, set noExtRef to 1
    ; It avoid validator.swagger.io to resolve external references.
    If $IsObject(ExternalRefMap), '$Data(Features("noExtRef")) Set Features("noExtRef") = 1
    
    Quit ##class(dc.openapi.server.ServerAppGenerator).Generate(PackageName, Specfication, , .Features, ExternalRefMap)
}

ClassMethod Models(
	PackageName As %String,
	Specfication,
	ByRef Features,
	ExternalRefMap As %DynamicObject = "") As %Status
{
    Set %zverbose = 1
    
    Set Features("simpleHttpClientOnly") = 1
    set Features("modelOnly") = 1

    ; If we have an external ref mapping, set noExtRef to 1
    ; It avoid validator.swagger.io to resolve external references.
    If $IsObject(ExternalRefMap), '$Data(Features("noExtRef")) Set Features("noExtRef") = 1
    
    Quit ##class(dc.openapi.client.Spec).generateApp(PackageName, Specfication, .Features, ExternalRefMap)
}

}
