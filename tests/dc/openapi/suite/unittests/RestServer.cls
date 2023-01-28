Class dc.openapi.suite.unittests.RestServer Extends %UnitTest.TestCase
{

Parameter PKGTEST = "unittestspetstoresrv";

Method OnBeforeAllTests() As %Status
{
	Do $SYSTEM.OBJ.DeletePackage(..#PKGTEST)
	Quit $$$OK
}

Method OnAfterAllTests() As %Status
{
	Do $SYSTEM.OBJ.DeletePackage(..#PKGTEST)
	
	Set ns = $NameSpace
	New $NameSpace
	Set $NameSpace = "%SYS"

	Do ##class(Security.Applications).Delete("/petstore/unittests")
	
	Set $NameSpace = ns
	
	Quit $$$OK
}

Method Test01GeneratePetStore()
{
	Set features("compile") = 0
 	Set sc = ##class(dc.openapi.server.ServerAppGenerator).Generate(..#PKGTEST, "https://petstore3.swagger.io/api/v3/openapi.json", "/petstore/unittests", .features)
	Do $$$AssertStatusOK(sc, "Generate class for Petstore")
	Quit
}

Method Test03WebApp()
{
	Set ns = $NameSpace
	New $NameSpace
	Set $NameSpace = "%SYS"

	Set exists = ##class(Security.Applications).Exists("/petstore/unittests")
	Set $NameSpace = ns
	Do $$$AssertTrue(exists, "Web Application exists.")

	Quit
}

Method Test02CompilePetStore()
{
	Set sc = $SYSTEM.OBJ.CompilePackage(..#PKGTEST)
	Do $$$AssertStatusOK(sc, "Generate class for Petstore")
	Quit
}

}
