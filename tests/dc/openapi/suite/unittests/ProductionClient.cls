Class dc.openapi.suite.unittests.ProductionClient Extends %UnitTest.TestCase
{

Parameter PKGTEST = "unittestspetstoreprd";

Method OnBeforeAllTests() As %Status
{
	Do $SYSTEM.OBJ.DeletePackage(..#PKGTEST)
	Quit $$$OK
}

Method OnAfterAllTests() As %Status
{
	Do $SYSTEM.OBJ.DeletePackage(..#PKGTEST)
	
	Quit $$$OK
}

Method Test01GeneratePetStore()
{
	Set features("compile") = 0
 	Set sc = ##class(dc.openapi.client.Spec).generateApp(..#PKGTEST, "https://petstore3.swagger.io/api/v3/openapi.json", .features)
	Do $$$AssertStatusOK(sc, "Generate class for Petstore")
	Quit
}

Method Test02CompilePetStore()
{
	Set sc = $SYSTEM.OBJ.CompilePackage(..#PKGTEST)
	Do $$$AssertStatusOK(sc, "Generate class for Petstore")
	Quit
}

}
