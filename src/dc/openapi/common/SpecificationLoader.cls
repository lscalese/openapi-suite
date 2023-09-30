Include dc.openapi.common.macro

/// Load a specification and convert in OpenAPI versoin 3 if needed
Class dc.openapi.common.SpecificationLoader
{

/// Return the swagger specification in a dynamic object <br/>
/// spec argument could be a stream, a dynamic object or an URL.<br/>
ClassMethod AbstractSpecLoader(
	spec,
	ByRef sc As %Status = {$$$OK},
	resolveExternalRef As %Boolean = {$$$YES}) As %DynamicObject
{
    Set sc = $$$OK, OpenAPI = ""

    Try{

        $$$zlog("* Parse the definition with flatten=true to simplify the structure ... ")

        Set webValidator = ##class(dc.swaggervalidatorcli.WebSwaggerValidator).%New()
        Set queryParameters("flatten")="true"
        Set:resolveExternalRef queryParameters("resolveFully")="true", queryParameters("validateExternalRefs")="true"
        Set sc = webValidator.Parse(.queryParameters, .OpenAPI, spec)

        If $$$ISERR(sc) $$$ThrowStatus(sc)

        
        ; Now check if it's a OpenAPI 3 specification and convert if it's a previous version.

        If OpenAPI.%IsDefined("swagger") {
            ; This is not an OpenAPI 3 specification
            ; The library does not support only version 3
            ; We attempt to convert this specification to version 3 https://converter.swagger.io/

            $$$zlog("Not an OpenAPI V3 specification, try to convert using swagger converter... ")

            Set webConverter = ##class(dc.swaggerconverter.WebConverter).%New()
            Set webConverter.specification = OpenAPI
            $$$TOE(sc, webConverter.Convert(.OpenAPIV3))
            Set OpenAPI = OpenAPIV3

            $$$zlog("Conversion to version 3 done.")
        }

        If '$Isobject(OpenAPI) || ( $Extract(OpenAPI.openapi) '= "3" ) $$$ThrowStatus($$$ERROR($$$GeneralError,"Not an OpenAPI version 3 specification."))

    } Catch(ex) {
        Set sc = ex.AsStatus()
        Set msg = $SYSTEM.Status.GetOneErrorText(sc)
        $$$zlog(msg)
    }

    Return OpenAPI
}

}
