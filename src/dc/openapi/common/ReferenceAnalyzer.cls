Class dc.openapi.common.ReferenceAnalyzer Extends %RegisteredObject
{

Parameter SEPARATOR = ".";

ClassMethod Test()
{
    Set oas = {}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/flattened_example.json")
    ;Do ..CollectOASReferences(oas, .out)
    Set list = ..GetListOfRefs(oas)
    zw list
    Return $$$OK
}

ClassMethod GetListOfRefs(oas As %DynamicObject, internal As %Boolean = {$$$YES}, external As %Boolean = {$$$NO}) As %List
{
    Set list = "", k = ""
    Do ..CollectOASReferences(oas, .out)
    
    For  {
        Set k = $Order(out(k), 1, line)
        Quit:k=""
        
        If $Extract(line, *-3, *) '= "$ref" Continue
        
        Set reference = ..GetValue(oas, line)
        
        If internal {
            If $Extract(reference)="#" && '$Data(unique(" "_reference)) {
                Set $List(list, *+1) = reference, unique(" "_reference) = ""
            }
        }
        If external {
            If $Extract(reference)'="#" && '$Data(unique(" "_reference)) {
                Set $List(list, *+1) = reference, unique(" "_reference) = ""
            }
        }
    }
    
    Return list
}

/// in this case ref is a string look like : components.schemas.objectName.oneOf.1.$ref
ClassMethod GetValue(oas As %DynamicObject, ref As %String) As %String
{
    Set list = $ListFromString(ref, ..#SEPARATOR), ptr = 0

    Set value = oas
    While $ListNext(list, ptr, key) {
        Set value = value.%Get(key) 
    }

    Return value
}

ClassMethod ReferenceIsDefined(oas As %DynamicObject, ref As %String) As %Boolean
{
    If '$IsObject(oas) {
        Return $$$NO
    }

    Set subPart = $Piece(ref, "#/", 2)
    If subPart = "" {
        ; The reference is the received object itself
        Return $$$YES
    }
    
    Set list = $ListFromString(subPart, "/"), ptr = 0, value = oas
    While $ListNext(list, ptr, key) {
        Try {
            If value.%IsDefined(key) {
                Set value = value.%Get(key)
            }
            Else {
                Return $$$NO
            }
        }
        Catch ex {
            Return $$$NO
        }
    }

    Return $$$YES
}

ClassMethod GetObjectByRef(currentDocument As %DynamicObject, ref As %String, documentCollection As dc.openapi.common.SwaggerDocumentCollection) As %DynamicObject
{
    Set document = currentDocument
    Set externalPart = $Piece(ref, "#", 1)
    If externalPart '= "" {
        Set documentReference = documentCollection.GetItem(externalPart)
        Set document = documentReference.Document
    }
    Return ##class(dc.openapi.common.ReferenceAnalyzer).GetObjectByDocumentAndRef(document, ref)
}

ClassMethod GetObjectByDocumentAndRef(document As %DynamicObject, ref As %String) As %DynamicObject
{
    Set subPart = $Piece(ref, "#/", 2)
    Set list = $ListFromString(subPart, "/"), ptr = 0, value = document

    While $ListNext(list, ptr, key) {
        Set value = value.%Get(key) 
    }

    Return value
}

ClassMethod CollectOASReferences(oas As %DynamicObject, ByRef out As %Binary, prefix As %String = "") As %Status
{
    #dim iterator As %Iterator.AbstractIterator
    Set iterator = oas.%GetIterator()
    
    While iterator.%GetNext(.name, .item, .type) {
        
        Set ref = prefix_name 
        Set key = $Increment(out)
        Set out(key) = ref

        If $IsObject(item) {
            Do ..CollectOASReferences(item, .out, ref_..#SEPARATOR)
        }
    }
    Return $$$OK
}

ClassMethod DecomposeRef(ref As %String, Output externalPart As %String, Output internalPart As %String) As %Status
{
    Set (externalPart, internalPart) = ""
    Set externalPart = $Piece(ref, "#", 1)
    Set internalPart = $Piece(ref, "#/", 2)
    Return $$$OK
}

}
