Class dc.openapi.common.PreProcessing Extends %RegisteredObject
{

Property OAS As %DynamicObject;

Property ExternalRefs As dc.openapi.common.SwaggerExternalRefs;

Property errors As %DynamicObject;

ClassMethod Test() As %Status
{
    Set tSc = $$$OK
    
    Set oas = {}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/v1.json")
    Set ssi = {}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/ssi_types.json")
    Set err = {}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/error_response.json")
    
    Set pp = ##class(dc.openapi.common.PreProcessing).%New()
    Set pp.OAS = oas
    Set pp.ExternalRefs = ##class(dc.openapi.common.SwaggerExternalRefs).%New()
    Do pp.ExternalRefs.AddItem(ssi, "../common/ssi_types.yaml")
    ;Do pp.ExternalRefs.AddItem(err, "../common/error_response.yaml")
    
    ;w pp.ExternalRefs.GetDocument("../common/ssi_types.yaml", .found)

    Set tSc = pp.PreProcess()
    Quit tSc
}

Method PreProcess() As %Status
{
    Set tSc = $$$OK
    
    Set tSc = ..Validate()

    Return tSc
}

Method Validate() As %Status
{
    Set tSc = $$$OK
    Set document = ..OAS ; specification to process ...
    
    Set getInternal = $$$YES, getExternal = $$$YES
    Set references = ##class(dc.openapi.common.RefScanner).GetListOfRefs(document, getInternal, getExternal)
    
    Set ptr = 0
    While $ListNext(references, ptr, ref) {
        Set isDefined = ..ReferenceIsDefined(document, ref)
        If 'isDefined {
            Write !,"Reference not defined: ", ref
        }
    }

    ; Check if the external references are defined
    Set key = ""
    For  {
        Set item = ..ExternalRefs.Items.GetNext(.key)
        Quit:key=""
        w !,"item   : ", key
        Set document = item.Document
        Set references = ##class(dc.openapi.common.RefScanner).GetListOfRefs(document, getInternal, getExternal)
        Set ptr = 0
        While $ListNext(references, ptr, ref) {
            Set isDefined = ..ReferenceIsDefined(document, ref)
            If 'isDefined {
                Write !,"External reference not defined: ", ref, !
            }
        }
    }

    Quit $$$OK
}

Method ReferenceIsDefined(document As %DynamicObject, ref As %String) As %Boolean
{
    If $Extract(ref) = "#" {
        ; It's an internal reference
        Return ##class(dc.openapi.common.RefScanner).ReferenceIsDefined(document, ref)
    }

    ; It's an external reference
    ; Check if the external reference is already in the list
    Set key = $Piece(ref, "#", 1)
    Set document = ..ExternalRefs.GetDocument(key, .found)
    If 'found Return $$$NO

    Return ##class(dc.openapi.common.RefScanner).ReferenceIsDefined(document, ref)
}

}
