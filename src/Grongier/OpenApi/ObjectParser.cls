Class Grongier.OpenApi.ObjectParser Extends %RegisteredObject
{

/// The OpenAPI specification (version 3)
/// The specification must transformed with the validator using arguments flatten = true 
Property OAS As %DynamicObject;

/// Pakage name used to generate the classes
Property packageName As %String;

Method Parse() As %Status
{
    Set sc = ..CollectOASReferences(..OAS, .out)
    Return:$$$ISERR(sc) sc

    If '$IsObject(..OAS.components) {
        ; Skip there is no components
        Return $$$OK
    }

    If '$IsObject(..OAS.components.schemas) {
        ; Skip there is no schemas
        Return $$$OK
    }

    Set schemas = ..OAS.components.schemas

    #dim iterator As %Iterator.AbstractIterator
    Set iterator = schemas.%GetIterator()

    While iterator.%GetNext(.name, .item, .type) {
        ; We need to check if the item is a schema object
        ; If not, we skip it
        If '##class(dc.openapi.common.Utils).IsSchemaObject(item) {
            Continue
        }
        Do ..BuildClassDTO("components.schemas."_name)
        ;Do ..ParseSchemaObject(item)
    }

    Return sc
}

Method BuildClassDTO(OASReference As %String) As %Status
{
    Set sc = $$$OK

    Set classDTO = ##class(dc.openapi.common.dto.ClassDTO).%New()
    Set classDTO.OASReference = OASReference
    Set classDTO.Name = $Piece(OASReference, ".", *)

    Set sc = ..GetValueByReference(..OAS, OASReference, .schema)
    Return:$$$ISERR(sc) sc

    If '$IsObject(schema.properties) {
        ; No properties
        Return sc
    }

    

    Return sc
}

Method ParseComponents() As %Status
{
    Set sc = $$$OK
    
    Set components = ..OAS.components

    If '$IsObject(components) {
        ; No Components
        Return sc
    }

    If '$IsObject(components.schemas) {
        ; No Schemas
        Return sc
    }

    #dim iterator As %Iterator.AbstractIterator
    Set iterator = components.schemas.%GetIterator()

    While iterator.%GetNext(.name, .item, .type) {
        ; We need to check if the item is a schema object
        ; If not, we skip it
        If '##class(dc.openapi.common.Utils).IsSchemaObject(item) {
            Continue
        }

        Set classModels(name) = {
            "name": (name),
            "package": (..packageName),
            "internalRef":("")
        }
        Do ..ParseSchemaObject(item)
    }

    Return sc
}

Method ParseSchemaObject(item As %DynamicObject, internalPrefixRef As %String = "") As %Status
{
    Set sc = $$$OK

    Do ..ParseProperties(item.properties)

    Return sc
    /*
    If '$IsObject(schema) {
        Return $$$ERROR(5001, "Schema is not an object")
    }

    If schema.type = "object" {
        ; Parse the properties of the object
        Do ..ParseProperties(schema.properties)
    } ElseIf schema.type = "array" {
        ; Parse the items of the array
        Do ..ParseProperties(schema.items)
    } ElseIf schema."$ref" '= "" {
        ; Parse the reference
        Set refObject = ..GetObjectByRef(..OAS, schema."$ref", .name)
        Quit:'$IsObject(refObject) sc
        
        Do ..ParseSchema(refObject)
    }*/

    Return sc
}

Method ParseProperties(properties As %DynamicObject = "") As %Status
{
    Set sc = $$$OK

    If properties = "" { ; skip if no properties
        Return sc
    }

    #dim iterator As %Iterator.AbstractIterator
    Set iterator = properties.%GetIterator()

    While iterator.%GetNext(.name, .property, .type) {
        
        If property.type = "object" {

        } ElseIf property.type = "array" {
        
        } ElseIf property."$ref" '= "" {

        } Else {
            Set objectScriptType = ..GetObjectScriptType(property.type, property.format)
        }
    }

    Return sc
}

ClassMethod GetObjectScriptType(oaType As %DynamicObject, format As %String = "") As %String
{

    Quit:oaType="" "%VarString"

    Set:format="" format = " "  ; to avoid subscript error later.

    Set table("integer") = "%Integer"
    Set table("integer", "int32") = "%Integer"
    Set table("integer", "int64") = "%Integer"
    
    Set table("number") = "%Decimal"
    Set table("number", "float") = "%Decimal"
    Set table("number", "double") = "%Double"
    
    Set table("string") = "%String"
    Set table("string", "byte") = "%Stream.GlobalCharacter"
    Set table("string", "binary") = "%Stream.GlobalBinary"
    Set table("string", "date-time") = "%TimeStamp"
    Set table("string", "date") = "%Date"
    
    Set table("file") = "%Stream.Object"

    Set table("boolean") = "%Boolean"

    Quit $Get(table(oaType, format), $Get(table(oaType), "%VarString" ))
}

ClassMethod CollectOASReferences(oas = { {}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/additionalProperties.json")}, ByRef out As %Binary, prefix As %String = "") As %Status
{
    #dim iterator As %Iterator.AbstractIterator
    Set iterator = oas.%GetIterator()
    
    While iterator.%GetNext(.name, .item, .type) {
        
        Set ref = prefix_name 
        Set key = $Increment(out)
        Set out(key) = ref

        Write !, ref
        If $IsObject(item) {
            Return ..CollectOASReferences(item, .out, ref_".")
        }
    }
    Return $$$OK
}

/// Get the object by reference
/// example of reference : "components.schemas.PeerDiagnostics" 
ClassMethod GetValueByReference(oas As %DynamicObject, OASReference As %String, Output value) As %Status
{
    Set temp = oas
    Set keys = $ListFromString(OASReference, ".")
    Set ptr = 0

    While $ListNext(keys, ptr, key) {

        If '$IsObject(temp) {
            Return $$$ERROR($$$GeneralError, "Invalid reference "_OASReference)
        }

        Set temp = oas.%Get(key)
    }
    
    Set value = temp

    Return $$$OK
}

}
