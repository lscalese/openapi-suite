Class dc.openapi.common.ExternalRefScanner Extends %RegisteredObject
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
    Set status = ..CollectOASReferences(oas, .out)
    
    For  {
        Set k = $Order(out(k), 1, line)
        Quit:k=""
        
        If $Extract(line, *-3, *) '= "$ref" Continue

        Set reference = ..GetValue(oas, line)
        If internal {
            Set:$Extract(reference)="#" $List(list, *+1) = reference
        }
        If external {
            Set:$Extract(reference)'="#" $List(list, *+1) = reference
        }
    }
    
    Return list
}

ClassMethod GetValue(oas As %DynamicObject, ref As %String) As %String
{
    Set list = $ListFromString(ref, ..#SEPARATOR), ptr = 0

    Set value = oas
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

        Write !, ref
        If $IsObject(item) {
            Do ..CollectOASReferences(item, .out, ref_..#SEPARATOR)
        }
    }
    Return $$$OK
}

}
