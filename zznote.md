
```
Set oas = {}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/allOf1.json") Do ##class(dc.openapi.common.SwaggerSchemaFlattener).Flatten(.oas),##class(%JSON.Formatter).%New().Format(oas)
```


ClassMethod CollectOASReferences(oas = { {}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/flatten.json")}, ByRef out As %Binary, prefix As %String = "") As %Status
{
    #dim iterator As %Iterator.AbstractIterator
    Set iterator = oas.%GetIterator()
    
    While iterator.%GetNext(.name, .item, .type) {
        
        Set ref = prefix_name 
        Set key = $Increment(out)
        Set out(key) = ref

        Write !, ref
        If $IsObject(item) {
            Do ..CollectOASReferences(item, .out, ref_".")
        }
    }
    Return $$$OK
}