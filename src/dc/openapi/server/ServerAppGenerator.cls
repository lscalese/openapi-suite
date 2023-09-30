Include dc.openapi.common.macro

Class dc.openapi.server.ServerAppGenerator
{

Parameter XDataName = "OpenAPI";

ClassMethod Generate(
	application As %String,
	specification,
	webApplicationname As %String = "",
	ByRef features As %Binary,
	externals As %DynamicObject = "") As %Status
{
    $$$zlog("Generate server-side application " _ application)

    Do ##class(community.utils.SSLClient).CreateSSLConfiguration("DefaultSSL")

    Set spec = ##class(dc.openapi.common.SpecificationLoader).AbstractSpecLoader(specification, .sc, '$Get(features("noExtRef"),0))
    
    If $$$ISERR(sc) Do $SYSTEM.Status.DisplayError(sc) Quit sc

    Set sc = ..%CreateServerApplication(application, spec, .features, .newApplication, externals)

    If $$$ISERR(sc),$Get(%zverbose,1) Do $SYSTEM.Status.DisplayError(sc)

    If webApplicationname '= "" Set sc = $$$ADDSC(sc, ..CreateWebApplication(webApplicationname, application_".disp"))
    
    Return sc
}

ClassMethod %CreateServerApplication(
	applicationName As %String,
	swagger As %DynamicObject,
	ByRef features As %Binary,
	Output newApplication As %Boolean,
	externals As %DynamicObject = "") As %Status
{
    Set sc = $$$OK
   
    Try {
        
        Set specClass = applicationName _ ".Spec"
        $$$zlog("* Create a class with the specification in a XData block " _ specClass)
        
        Set cDef=##class(%Dictionary.ClassDefinition).%OpenId(specClass,4,.sc)
        
        If $Isobject(cDef) {

            Do ##class(dc.openapi.common.Utils).RemoveXDataBlock(cDef, ..#XDataName)
            Set newApplication = $$$NO

        } Else {

            Set cDef=##class(%Dictionary.ClassDefinition).%New(specClass)
            Set newApplication = $$$YES

        }

        ; Security to avoid overwrite an existing package on the server ...
        If newApplication && ##class(dc.openapi.common.Utils).packageExists(applicationName)  { 
            
            Set sc = $$$ERROR(5001, "Overwritting code protection.  This package already exist on the server, please choose an other appName "_applicationName)
            $$$ThrowStatus(sc)
        }

        Set cDef.Super = "%RegisteredObject"
        Set cDef.ProcedureBlock = $$$YES

        Set xData = ##class(%Dictionary.XDataDefinition).%New()
        Set xData.Name = ..#XDataName
        Set xData.MimeType = "application/json"

        $$$ThrowOnError(##class(%JSON.Formatter).%New().FormatToStream(swagger, xData.Data))
        $$$ThrowOnError(cDef.XDatas.Insert(xData))
        $$$ThrowOnError(cDef.%Save())
        $$$ThrowOnError($system.OBJ.Compile(specClass,"ck"))

        set swagger.externals = externals

        Set generator = ##class(dc.openapi.server.RESTGenerator).%New(swagger, applicationName)

        Set sc = generator.Generate(.features)

    } Catch (ex) {
        Set sc = ex.AsStatus()
    }

    If $$$ISOK(sc), $Get(features("compile"), 1) {
        ; no error -> compile
        Set sc = $SYSTEM.OBJ.CompilePackage(applicationName)
    }
    
    Return sc
}

ClassMethod CreateWebApplication(
	webAppName As %String,
	dispatchClassName As %String) As %Status
{
    Set ns = $NameSpace, sc = $$$OK
    New $NameSpace
    Set $NameSpace = "%SYS"

    If ##class(Security.Applications).Exists(webAppName) {
        Set $NameSpace = ns
        $$$zlog("= Web application " _ webAppName _ " already exists, skip ...") 
        Quit sc
    }

    set webProperties("NameSpace") = ns
    set webProperties("Enabled") = 1
    set webProperties("CSPZENEnabled") = 1
    set webProperties("AutheEnabled") = 64
    set webProperties("iKnowEnabled") = 1
    set webProperties("DeepSeeEnabled") = 1
    set webProperties("DeepSeeEnabled") = 1
    Set webProperties("DispatchClass") = dispatchClassName
    Set webProperties("MatchRoles")=":%DB_" _ ns
    set sc = ##class(Security.Applications).Create(webAppName, .webProperties)

    Set $NameSpace = ns
    $$$zlog("= Web application " _ webAppName _ "status : " _ $SYSTEM.Status.GetOneErrorText(sc) )

    Return sc
}

}
