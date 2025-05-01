/// This class transforms the OpenAPI Specification (OAS) to AST
Class dc.openapi.common.SwaggerToASTConverter Extends %RegisteredObject
{

Property OAS As %DynamicObject;

Property AST As dc.openapi.common.ast.OAS;

Property PackageModel As %String;

Property Qualifiers As %String;

/// Index of the models
Property ModelIDX As dc.openapi.common.ast.Model [ MultiDimensional ];

/// d ##class(dc.openapi.common.SwaggerToASTConverter).Test({}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/flattened_components_schemas_allOf1.json"))
/// d ##class(dc.openapi.common.SwaggerToASTConverter).Test({}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/flattened_example.json"))
ClassMethod Test(oas = { {}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/components_schemas.json")}) As %Status
{
    Set sc = $$$OK

    Set t = ##class(dc.openapi.common.SwaggerToASTConverter).%New()
    Set t.OAS = oas
    Set t.PackageModel = "myapp.models"

    Set sc = t.Transform()
    If $$$ISERR(sc) {
        Write "Error: ", $SYSTEM.Status.GetErrorText(sc), !
        Quit sc
    }
    
    Do t.AST.%JSONExportToString(.tempString)
    Do ##class(%JSON.Formatter).%New().FormatToString(tempString, .string)
    w !,string,!
    Write !,"Transform OK", !

    Return sc
}

Method Transform() As %Status
{
    Set sc = $$$OK

    Set ..AST = ##class(dc.openapi.common.ast.OAS).%New()
    ;Set ..AST.OpenAPI = ..OAS.openapi
    
    Do ..Info()
    Do ..Servers()
    Do ..Paths()
    Do ..Models()

    Return sc
}

Method Info() As %Status
{
    Set (..AST.Info, info) = ##class(dc.openapi.common.ast.Info).%New()
    
    If '$IsObject(..OAS.info) {
        Return $$$OK
    }

    Set info.Title = ..OAS.info.title
    Set info.Version = ..OAS.info.version
    Set info.Description = ..OAS.info.description
    Set info.TermsOfService = ..OAS.info.termsOfService

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
        
        If '$IsObject(schema) Continue
        
        Set model = ..GetModel(..OAS.components.schemas, key)

        Do:$IsObject(model) ..AST.Models.Insert(model)
    }

    Return sc
}

Method GetModel(parentObj As %DynamicObject, modelName As %String) As dc.openapi.common.ast.Model
{
    ; schema is a swagger schema component
    Set schema = parentObj.%Get(modelName)

    If '$IsObject(schema) {
        Return ""
    }

    If schema.type '= "object" && '$IsObject(schema.allOf) && '$IsObject(schema.oneOf) && '$IsObject(schema.anyOf) {
        ; is not an object schema definition
        Return ""
    }

    Set model = ##class(dc.openapi.common.ast.Model).%New()
    Set model.Name = ..GetClassName(modelName)
    Set model.SchemaRef = "#/components/schemas/" _ modelName

    Set ..ModelIDX(model.SchemaRef) = model

    If schema.%IsDefined("description") {
        Set model.Description = schema.description
    }

    If $IsObject(schema.properties) {
        Set iterator = schema.properties.%GetIterator()
        While iterator.%GetNext(.key, .item, .type) {
            If '$IsObject(item) Continue

            Set modelProperty = ..GetModelProperty(schema.properties, key)
            Do:$IsObject(modelProperty) model.Properties.Insert(modelProperty)
        }
    }
    
    
    If schema.%IsDefined("allOf") {
        Set iterator = schema.allOf.%GetIterator()
        While iterator.%GetNext(.key, .allOfItem, .type) {
            If '$IsObject(allOfItem) Continue
            If allOfItem."$ref" '= "" {
                ; it's an object reference (flatten spec garantees that)
                Set model.Super = model.Super _ "," _ ..GetClassName(allOfItem."$ref")
            }
            ElseIf allOfItem.%IsDefined("type") {
                Set modelProperty = ..GetModelProperty(schema.allOf, key)
                Set modelProperty.Name = "AllOf" _ allOfItem.type _ key
                Do:$IsObject(modelProperty) model.Properties.Insert(modelProperty)
            }
        }
    }

    If schema.%IsDefined("oneOf") {
        Set iterator = schema.oneOf.%GetIterator()
        While iterator.%GetNext(.key, .oneOfItem, .type) {
            If '$IsObject(oneOfItem) Continue

            Set modelProperty = ..GetModelProperty(schema.oneOf, key)
            Set modelProperty.Name = "OneOf" _ oneOfItem.type _ key
            Do:$IsObject(modelProperty) model.Properties.Insert(modelProperty)
        }
    }

    If schema.%IsDefined("anyOf") {
        Set iterator = schema.anyOf.%GetIterator()
        While iterator.%GetNext(.key, .anyOfItem, .type) {
            If '$IsObject(anyOfItem) Continue

            Set modelProperty = ..GetModelProperty(schema.anyOf, key)
            Set modelProperty.Name = "AnyOf" _ anyOfItem.type _ key
            Do:$IsObject(modelProperty) model.Properties.Insert(modelProperty)
        }
    }

    Return model
}

Method GetModelProperty(parentObj As %DynamicObject, name As %String) As dc.openapi.common.ast.ModelProperty
{
    Set schema = parentObj.%Get(name)

    Set common = schema

    Set modelProperty = ##class(dc.openapi.common.ast.ModelProperty).%New()
    Set modelProperty.Name = ..GetPropertyNameByRef(name)
    Set modelProperty.pJSONFieldName = name

    If schema."$ref" '= "" {
        Set modelProperty.Type = ..GetClassName(schema."$ref")
    } 
    ElseIf schema.type = "array" {
        Set modelProperty.Collection = "list"
        If $IsObject(schema.items) {
            If schema.items."$ref" '= "" {
                Set modelProperty.Type = ..GetClassName(schema.items."$ref")
            }
            Else {
                Set modelProperty.Type = ..GetObjectScriptType(schema.items.type, schema.items.format)
                Set common = schema.items
            }
        }
    }
    Else {
        Set modelProperty.Type = ..GetObjectScriptType(schema.type, schema.format)
    }

    Set:common.%IsDefined("minimum") modelProperty.pMinimum = common.minimum
    Set:common.%IsDefined("maximum") modelProperty.pMaximum = common.maximum
    Set:common.%IsDefined("minLength") modelProperty.pMinLength = common.minLength
    Set:common.%IsDefined("maxLength") modelProperty.pMaxLength = common.maxLength

    If $IsObject(common.enum) {
        Set iterator = common.enum.%GetIterator()
        While iterator.%GetNext(.key, .item, .type) {
            If '$IsObject(item) Continue
            Set modelProperty.pEnum = modelProperty.pEnum _ "," _ item
        }
    }

    Return modelProperty
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
        Set server.Url = item.url
        Set server.Description = item.description

        Do ..AST.Servers.Insert(server)
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
        If '$IsObject(item)  Continue
        
        Do verbs    ; now iterate over the verbs
    }

    Return $$$OK

verbs
    For verb = "get", "put", "post", "delete", "options", "head", "patch", "trace" {
        Set verbItem = item.%Get(verb)
        
        If '$IsObject(verbItem) Continue

        Set path = ##class(dc.openapi.common.ast.Path).%New()
        Set path.Path = key
        Set path.Verb = verb
        Set path.OperationId = verbItem.operationId
        Set path.Summary = verbItem.summary
        Set path.Description = verbItem.description
        
        Do parameters   ; now iterate over the parameters and requestBody
        Do requestBody  ; now iterate over the requestBody
        Do responses
        Do ..AST.Paths.Insert(path)
    }

    Quit 1

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

        Set parameter = ..GetParameter(paramItem)
        Do path.Parameters.Insert(parameter)
        
    }
    Quit 1

requestBody

    If '$IsObject(verbItem.requestBody) Quit 1
    If '$IsObject(verbItem.requestBody.content) Quit 1
    /// maybe handle here requestBody.$ref if the flatten don't move it

    Set mimeTypeIterator = verbItem.requestBody.content.%GetIterator()
    While mimeTypeIterator.%GetNext(.mimeType, .mimeItem) {
        If '$IsObject(mimeItem) {
            Continue
        }
        

        Set requestBody = ##class(dc.openapi.common.ast.RequestBody).%New()
        Set requestBody.ContentType = mimeType
        Set requestBody.Required = verbItem.requestBody.required
        Set requestBody.Description = verbItem.requestBody.description

        ;Set modelProperty = ..GetModelProperty(verbItem.requestBody.content, mimeType)
        Set modelProperty = ..GetModelProperty(mimeItem, "schema")
        
        Set modelProperty.Name = ..GetPropertyNameByRef(mimeType)
        Set requestBody.ModelProperty = modelProperty

        Do path.RequestBodies.Insert(requestBody)
    }

    Quit 1

responses

    If '$IsObject(verbItem.responses) Quit 1

    Set codeIterator = verbItem.responses.%GetIterator()
    While codeIterator.%GetNext(.code, .responseItem, .type) {
        If '$IsObject(responseItem) {
            Continue
        }

        If responseItem."$ref" '= "" {
            Set ref = ..GetReference(responseItem."$ref", .found)
            If found {
                Set responseItem = ref
            } Else {
                ; not found
            }
        }

        If $IsObject(responseItem.content) {
            Set mimeTypeIterator = responseItem.content.%GetIterator()
            While mimeTypeIterator.%GetNext(.mimeType, .mimeItem) {
                If '$IsObject(mimeItem) {
                    Continue
                }
                Set response = ##class(dc.openapi.common.ast.Response).%New()
                Set response.StatusCode = code
                Set response.Description = responseItem.description
                Set response.ContentType = mimeType
                Set response.Example = $Select($IsObject(mimeItem.example):mimeItem.example.%ToJSON(), 1: mimeItem.examples)
                Set modelProperty = ..GetModelProperty(mimeItem, "schema")
                Set modelProperty.Name = "Content"
                Set response.ModelProperty = modelProperty
                Do path.Responses.Insert(response)
            }
        }
    }

    Quit 1
}

Method GetParameter(paramItem As %DynamicObject) As dc.openapi.common.ast.Parameter
{
    If paramItem."$ref" '= "" {
        Set ref = ..GetReference(paramItem."$ref", .found)
        If found {
            Set paramItem = ref
        } Else {
            ; not found
        }
    }

    Set parameter = ##class(dc.openapi.common.ast.Parameter).%New()
    Set parameter.Name = paramItem.name
    Set parameter.In = paramItem.in
    Set parameter.Required = paramItem.required
    Set parameter.Description = paramItem.description
    Set modelProperty = ..GetModelProperty(paramItem, "schema")
    Set modelProperty.Name = ..GetPropertyNameByRef(paramItem.name)
    Set parameter.ModelProperty = modelProperty
    Return parameter
}

/// Return the class name from a "$ref" components.schemas.
Method GetClassName(ref As %String) As %String
{
    ;Set package = ..PackageModel
    Set package = ""
    Set temp = $Piece(ref, "/", *)

    If temp [ "." {
        Set package = $tr($Piece(temp, ".", 1 , *-1)," -%@","")
        Set className = $Piece(temp, ".", *)
    } 
    Else {
        Set className = temp
    }

    ; Pascal Case transformation
    Set className = ..ToPascalCase(className)
    Set package = $$$LOWER(package)
    
    If package '= "" {
        Set package = ..GetPrefixedModelPackage(ref) _ "." _ package
    } Else {
        Set package = ..GetPrefixedModelPackage(ref)
    }

    Return package _ "." _ className
}

Method GetPropertyNameByRef(ref As %String) As %String
{
    Set className = $Piece(ref, "/", *)
    Set className = ..ToPascalCase(className)
    Return className
}

ClassMethod ToPascalCase(name As %String) As %String
{
    Set name = $Translate(name, " -%@","__")
    Set pascalCase = ""
    Set list = $ListFromString(name, "_"), ptr = 0
    While $ListNext(list, ptr, value) {
        Set pascalCase = pascalCase _ $$$UPPER($Extract(value, 1, 1)) _ $Extract(value, 2, *)
    }
    Return pascalCase
}

Method GetReference(ref As %String, Output found As %Boolean) As %DynamicObject
{
    Set object = {}, found = $$$NO

    If $Extract(ref, 1, 1) = "#" { ; it's an internal reference
        
        Set section = $Piece(ref, "/", 2)
        Set type = $Piece(ref, "/", 3)
        Set name = $Piece(ref, "/", 4)
        Try {
            Set object = ..OAS.%Get(section).%Get(type).%Get(name)
            Set found = $IsObject(object)
        } Catch ex { ; not found

        }

    }
    Else {; it's an external reference to do ...
    }

    Return object
}

Method GetPrefixedModelPackage(ref As %String) As %String
{
    Set package = ..PackageModel
    ; may add other rules depending the ref later...
    Return package
}

ClassMethod GetObjectScriptType(oaType As %DynamicObject, format As %String = "") As %String
{
    Return ##class(dc.openapi.common.Utils).GetObjectScriptType(oaType, format)
}

}
