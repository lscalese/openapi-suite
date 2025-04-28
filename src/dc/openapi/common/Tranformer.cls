/// This class transforms the OpenAPI Specification (OAS) to AST
Class dc.openapi.common.Tranformer Extends %RegisteredObject
{

Property OAS As %DynamicObject;

Property ast As dc.openapi.common.ast.OAS;

Property Warnings As list Of %String;

ClassMethod Test(oas = { {}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/additionalProperties.json")}) As %Status
{
    Set sc = $$$OK

    Set t = ##class(dc.openapi.common.Tranformer).%New()
    Set t.OAS = oas

    Set sc = t.Transform()
    If $$$ISERR(sc) {
        Write "Error: ", $SYSTEM.Status.GetErrorText(sc), !
        Quit sc
    }
    
    Do t.ast.%JSONExport()

    Write !,"Transform OK", !
    
    Quit sc
}

Method Transform() As %Status
{
    Set sc = $$$OK

    Set ..ast = ##class(dc.openapi.common.ast.OAS).%New()
    Set ..ast.openapi = ..OAS.openapi
    
    Do ..Info()
    Do ..Servers()
    Do ..Paths()
    Do ..Models()

    Return sc
}

Method Info() As %Status
{
    Set (..ast.info, info) = ##class(dc.openapi.common.ast.Info).%New()
    
    If '$IsObject(..OAS.info) {
        Return $$$OK
    }

    Set info.title = ..OAS.info.title
    Set info.version = ..OAS.info.version
    Set info.description = ..OAS.info.description
    Set info.termsOfService = ..OAS.info.termsOfService

    Return $$$OK
}

Method Models() As %Status
{
    Set sc = $$$OK

    If '$IsObject(..OAS.components) {
        Return sc
    }

    If '$IsObject(..OAS.components.schemas) {
        Return sc
    }

    #dim iterator As %Iterator.AbstractIterator
    Set iterator = ..OAS.components.schemas.%GetIterator()
    While iterator.%GetNext(.key, .schema, .type) {
        If '$IsObject(schema) {
            Continue
        }

        Set model = ##class(dc.openapi.common.ast.Model).%New()
        Set model.name = key

        If $IsObject(schema.allOf) {
            Do HandleAllOf
        } 
        ElseIf ..IsObjectComponent(schema) {
            If schema.%IsDefined("properties") {
            
            }
        }
        
        Do ..ast.models.Insert(model)
    }

    Return sc

HandleAllOf
    #dim allOfIterator As %Iterator.AbstractIterator
    Set allOfIterator = schema.allOf.%GetIterator()
    While allOfIterator.%GetNext(.allOfKey, .allOfItem, .allOfType) {

        If '$IsObject(allOfItem) {
            Continue
        }

        If allOfItem."$ref" '= "" {
            ; Handle $ref
            ; The referenced component can be an object, array or data type.
            Do HandleAllOfRef
        } ElseIf allOfItem.type = "array" {
            Do HandleAllOfArray
        } Else {
            ; Handle inline definition
            ; With the simplified swagger spec, the inline definition will be just data type (not object).
            Set modelProperty = ..GetDataTypeProperty(allOfItem)
            Set modelProperty.Name = "AllOf" _ allOfItem.type _ allOfKey
            Do model.Properties.Insert(modelProperty)
        }
    }
    Quit

HandleAllOfRef  
    Set refComponent = ..GetReference(allOfItem."$ref")

    If '$IsObject(refComponent) {
        Quit
    }

    If ..IsObjectComponent(refComponent) {
        
        Set model.Super = model.Super _ "," _ ..GetClassName(allOfItem."$ref")
        
    } ElseIf refComponent.type = "array" {
        If '..IsObjectComponent(refComponent.items) {
            Set modelProperty = ..GetDataTypeProperty(refComponent.items)
            Set modelProperty.Name = ..GetPropertyNameByRef(allOfItem."$ref")
            Set modelProperty.Collection = "list"
            Do model.Properties.Insert(modelProperty)
        } Else {
            ; allOf should be used like class inheritance.
            ; reference to an array is ambiguous for code generation.
            Do ..Warnings.Insert("Ambiguous reference to array type in allOf.")
        }
    } Else {
        Set modelProperty = ..GetDataTypeProperty(refComponent)
        Set modelProperty.Name = ..GetPropertyNameByRef(allOfItem."$ref")
        Do model.Properties.Insert(modelProperty)
    }

    Quit

HandleAllOfArray
    ; The swagger spec is simplified, so inline definition will be just data type (not object).
    ; Object will be always defined in the components section.
    If '$IsObject(allOfItem.items) {
        Quit
    }

    If allOfItem.items."$ref" '= "" {
        Do ..Warnings.Insert("Inline definition of array with $ref used in allOf is not supported.")

        Set refComponent = ..GetReference(allOfItem.items."$ref")

        If '$IsObject(refComponent) {
            Quit
        }



        If ..IsObjectComponent(refComponent) {
            ; allOf should be used like class inheritance.
            ; reference to an array is ambiguous for code generation.
            Do ..Warnings.Insert("Ambiguous reference to array type in allOf.")
        } ElseIf refComponent.type = "array" {
            ; Array which references another array is ambiguous for code generation.
            Do ..Warnings.Insert("Ambiguous reference an array type in allOf array.")
        } Else {
            ; It's a reference to a simple data type.
            ; We can add a property to the model.
            Set modelProperty = ..GetDataTypeProperty(refComponent)
            Set modelProperty.Name = ..GetPropertyNameByRef(allOfItem.items."$ref")
            Set modelProperty.Collection = "list"
            Do model.Properties.Insert(modelProperty)
            Kill modelProperty
        }

    } ElseIf allOfItem.items.type = "array" {
        ; Array which references another array is ambiguous for code generation.
        Do ..Warnings.Insert("Ambiguous reference an array type in allOf array.")
    } Else {
        ; It's a reference to a simple data type.
        ; We can add a property to the model.
        Set modelProperty = ..GetDataTypeProperty(allOfItem.items)
        Set modelProperty.Name = "AllOf" _ allOfItem.items _ allOfKey
        Set modelProperty.Collection = "list"
        Do model.Properties.Insert(modelProperty)
        Kill modelProperty
    }
    
    Quit
}

ClassMethod CreateModel(parentObj As %DynamicObject, modelName As %String) As dc.openapi.common.ast.Model
{
    Set objectDefinition = parentObj.%Get(modelName)
    If '$IsObject(objectDefinition) {
        Return ""
    }

    Set model = ##class(dc.openapi.common.ast.Model).%New()
    Set model.Name = modelName

    
    If parentObj.%IsDefined("description") {
        Set model.Description = parentObj.description
    }

    
    Return model
}

ClassMethod IsObjectComponent(components As %DynamicObject) As %Boolean
{
    Set isObject = $$$NO

    If '$IsObject(components) {
        Return isObject
    }

    If components.type = "object" || components.%IsDefined("allOf") {
        Set isObject = $$$YES
    } 

    Return isObject
}

Method GetDataTypeProperty(schema As %DynamicObject) As dc.openapi.common.ast.ModelProperty
{
    Set property = ##class(dc.openapi.common.ast.ModelProperty).%New()

    Set property.Type = ..GetObjectScriptType(schema.type, schema.format)
    Set property.pMinimum = schema.minimum
    Set property.pMaximum = schema.maximum
    Set property.pMinLength = schema.minLength
    Set property.pMaxLength = schema.maxLength

    Set iterator = schema.enum.%GetIterator()
    While iterator.%GetNext(.key, .item, .type) {
        If '$IsObject(item) {
            Continue
        }
        Set property.pEnum = property.pEnum _ "," _ item
    }

    Return property
}

Method Servers() As %Status
{
    If '$IsObject(..OAS.servers) {
        Return $$$OK
    }

    #dim iterator As %Iterator.AbstractIterator
    Set iterator = ..OAS.servers.%GetIterator()

    While iterator.%GetNext(.key, .item, .type) {
        If '$IsObject(item) {
            Continue
        }

        Set server = ##class(dc.openapi.common.ast.Server).%New()
        Set server.url = item.url
        Set server.description = item.description

        Do ..ast.servers.Insert(server)
    }
}

Method Paths() As %Status
{
    If '$IsObject(..OAS.paths) {
        Return $$$OK
    }

    #dim iterator As %Iterator.AbstractIterator
    Set iterator = ..OAS.paths.%GetIterator()

    While iterator.%GetNext(.key, .item, .type) {
        If '$IsObject(item) {
            Continue
        }
        ; now iterate over the verbs
        Do verbs
    }

    Return $$$OK

verbs
    #dim verbIterator As %Iterator.AbstractIterator
    Set verbIterator = item.%GetIterator()
    While verbIterator.%GetNext(.verb, .verbItem, .verbType) {
        If '$IsObject(verbItem) {
            Continue
        }

        Set path = ##class(dc.openapi.common.ast.Path).%New()
        Set path.path = key
        Set path.verb = verb
        Set path.operationId = verbItem.operationId
        Set path.summary = verbItem.summary
        Set path.description = verbItem.description
        
        ; now iterate over the parameters
        Do parameters

        Do ..ast.paths.Insert(path)
    }
    Quit

parameters

    #dim paramIterator As %Iterator.AbstractIterator

    If '$IsObject(verbItem.parameters) {
        Quit
    }

    Set paramIterator = verbItem.parameters.%GetIterator()
    While paramIterator.%GetNext(.paramKey, .paramItem, .paramType) {
        If '$IsObject(paramItem) {
            Continue
        }

        Set parameter = ##class(dc.openapi.common.ast.Parameter).%New()
        Set parameter.name = paramItem.name
        Set parameter.in = paramItem.in
        Set parameter.required = paramItem.required
        Set parameter.description = paramItem.description

        Set parameter.type = ..ParameterType(paramItem.schema)
        

        Do path.parameters.Insert(parameter)
    }
    Quit
}

Method ParameterType(parameter As %DynamicObject) As dc.openapi.common.ast.ParameterType
{
    Set parameterType = ##class(dc.openapi.common.ast.ParameterType).%New()
    
    If parameter.%IsDefined("$ref") {
         Set parameterType.Name = $Piece(parameter."$ref" , "/", *)
    }
    
    
    Set parameterType.Format = parameter.format

    Set:parameter.items.%IsDefined("explode") parameterType.Explode = parameter.items.explode
    Set:parameter.items.%IsDefined("style") parameterType.Style = parameter.items.style

    If parameter.Type = "array" {
        Set parameterType.Collection = "list"
        Set parameterType.Type = "string"
        Set parameterType.Name = "%String"

        If parameterType.%IsDefined("items") {
            
            Set itemType = ""
            Set itemFormat = ""
            Set itemRef = parameter.items
            
            If parameter.items."$ref" '= "" {
                Set itemRef = ..GetReference(parameter.items."$ref")
            } 
            
            Set:itemRef.%IsDefined("type") itemType = itemRef.type
            Set:itemRef.%IsDefined("format") itemFormat = itemRef.format

            If itemType = "object" {
                ; todo
            } 

        }

    } ElseIf parameter.Type = "object" {

    } Else {
        Set parameterType.Name = ..GetObjectScriptType(parameter.type, parameter.format)
    }

    Return parameterType
}

ClassMethod GetPropertyNameByRef(ref As %String) As %String
{
    Return $Piece(ref, "/", *)
}

ClassMethod GetClassName(ref As %String, Output package As %String) As %String
{
    Return $Piece(ref, "/", *)
}

Method GetReference(ref As %String) As %String
{
    Return {}
}

ClassMethod GetObjectScriptType(oaType As %DynamicObject, format As %String = "") As %String
{
    Return ##class(dc.openapi.common.Utils).GetObjectScriptType(oaType, format)
}

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

}
