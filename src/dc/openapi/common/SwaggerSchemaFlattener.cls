/// This class is used to flatten the OpenAPI schema by moving nested schemas into the components section
/// 
/// How to use it:
/// 1. Create an instance of the class
/// 2. Set the OAS property with the OpenAPI Specification object
/// 3. Call the Lift() method to flatten the schemas
/// 4. The modified OpenAPI Specification object will be available in the OAS property
/// ex : 
/// Set flattener = ##class(dc.openapi.common.SwaggerSchemaFlattener).%New()
/// Set flattener.OAS = oas
/// Do flattener.Lift()
/// Do ##class(%JSON.Formatter).%New().Format(flattener.OAS)
/// 
/// If you want to keep the original swdagger object, Set a copy instead of the original one
/// Set flattener.OAS = {}.%FromJSON(oas.%ToJSON())
/// 
/// The class is designed to be used with the OpenAPI Specification version 3
/// If you are using a previous version, you need to convert it to version 3 first
/// using the Swagger Converter (dc.swaggerconverter.WebConverter)
/// 
/// The swagger file must be already validated before using this class with flatten set to true and fullyResolved set to true
/// use the Swagger Validator (dc.swaggervalidatorcli.WebSwaggerValidator)
Class dc.openapi.common.SwaggerSchemaFlattener Extends %RegisteredObject
{

/// The OpenAPI Specification (OAS) object
/// Represents the OpenAPI Specification object being processed
Property OAS As %DynamicObject;

/// Stores schemas that need to be moved to the components section
Property ToMove As %DynamicObject [ Private ];

Property ResolveDataType As %Boolean [ InitialExpression = 1 ];

/// Flag to remove data type components after ResolveDataType
Property RemoveDataTypeComponents As %Boolean [ InitialExpression = 0 ];

ClassMethod test()
{
    Set oas = {}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/components_schemas_allOf1.json")
    Set oas = {}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/flattened_example.json")
    
    Set flattener = ##class(dc.openapi.common.SwaggerSchemaFlattener).%New()
    Set flattener.OAS = oas
    Do flattener.Lift()
    Do ##class(%JSON.Formatter).%New().Format(oas)
}

Method Lift() As %Status
{
    Set sc = ..FlattenComponents()

    If $$$ISERR(sc) Return sc

    If ..ResolveDataType {
        Set sc = ..ResolveDataType()
    }

    Return sc
}

Method FlattenComponents() As %Status
{
    Set sc = $$$OK
    If '$ISOBJECT(..OAS.components) {
        ; nothing to do ...
        Return sc
    }

    If '$IsObject(..OAS.components.schemas) {
        Set ..OAS.components.schemas = {}
    }

    Do ..FlattenSchemasIns(..OAS.components.schemas, "auto", $$$YES)
    
    If $IsObject(..OAS.components.parameters) {
        Set iterator = ..OAS.components.parameters.%GetIterator()
        While iterator.%GetNext(.name, .parameter) {
            If '$IsObject(parameter.schema) {
                Continue
            }
            Set prefix = "auto_param_" _ name
            Do UniquePrefix ; add a number to the var prefix if already used
            Do ..FlattenSchemasIns(parameter, prefix, $$$NO)
        }
    }

    If $IsObject(..OAS.components.responses) {
        Set iterator = ..OAS.components.responses.%GetIterator()
        While iterator.%GetNext(.name, .response) {
            If '$IsObject(response.content) {
                Continue
            }
            Set iterator2 = response.content.%GetIterator()
            While iterator2.%GetNext(.mediaType, .mediaTypeItem) {
                If '$IsObject(mediaTypeItem.schema) {
                    Continue
                }
                Set prefix = "auto_response_" _ name
                Do UniquePrefix ; add a number to the var prefix if already used
                Do ..FlattenSchemasIns(mediaTypeItem, prefix, $$$NO)
            }
        }
    }

    If $IsObject(..OAS.components.requestBodies) {
        Set iterator = ..OAS.components.requestBodies.%GetIterator()
        While iterator.%GetNext(.name, .requestBody) {
            If '$IsObject(requestBody.content) {
                Continue
            }
            Set iterator2 = requestBody.content.%GetIterator()
            While iterator2.%GetNext(.mediaType, .mediaTypeItem) {
                If '$IsObject(mediaTypeItem.schema) {
                    Continue
                }
                Set prefix = "auto_requestbody_" _ name
                Do UniquePrefix ; add a number to the var prefix if already used
                Do ..FlattenSchemasIns(mediaTypeItem, prefix, $$$NO)
            }
        }
    }
    
    

    Set iterator = ..ToMove.%GetIterator()
    ; Browse all entries of the current object
    While iterator.%GetNext(.name, .schemaItem) {
        ; for each schemaItem, we need to move it to the components section
        Do ..OAS.components.schemas.%Set(name, schemaItem)
    }

    Return sc

UniquePrefix
    If $Data(prefix(prefix)) {
        Set n = $Increment(prefix(prefix))
        Set prefix = prefix _ n
    } Else {
        Do $Increment(prefix(prefix))
    }
    Quit 1
}

Method FlattenSchemasIns(currentObject As %DynamicObject, prefix As %String, ByRef isTopLevel As %Boolean = 0) As %Status
{
    Set sc = $$$OK
    Set iterator = currentObject.%GetIterator()
    
    ; Browse all entries of the current object
    While iterator.%GetNext(.name, .schemaItem) {
        
        If '$ISOBJECT(schemaItem) {
            ; If it's a primitive value, we do nothing
            Continue
        }

        Set fullPath = $SELECT(prefix = "": name, 1: prefix _ "_" _ name)

        If schemaItem.type = "object" && schemaItem.%IsDefined("properties") && $ISOBJECT(schemaItem.properties) {
            ; Browse the properties of this object and flatten recursively
            Do ..FlattenSchemasIns(schemaItem.properties, fullPath)
            
            If isTopLevel { 
                ; If we are at the top level, we don't need to move the schema
                ; we can stop here
                Continue
            }

            ; Pour les objets avec propriétés, les extraire comme nouveaux schémas
            Set newSchemaName = fullPath
            Set newSchema = {}.%FromJSON(schemaItem.%ToJSON())
            
            ; Add to the list of schemas to move
            Do ..ToMove.%Set(newSchemaName, newSchema)
            
            ; Remplacer l'objet original par une référence
            Do currentObject.%Set(name, {"$ref": ("#/components/schemas/" _ newSchemaName)})
        }
        ElseIf schemaItem.type = "array" && schemaItem.%IsDefined("items") && $ISOBJECT(schemaItem.items) {
            
            ; Handle arrays of objects
            If schemaItem.items.type = "object" && schemaItem.items.%IsDefined("properties") {
                ; Aplatir les propriétés de l'objet dans le tableau
                Set newSchemaName = fullPath _ "Item"
                Do ..FlattenSchemasIns(schemaItem.items.properties, newSchemaName)
                
                ; Extraire l'objet de tableau comme un nouveau schéma
                Set newSchema = {}.%FromJSON(schemaItem.items.%ToJSON())
                
                ; Ajout du nouveau schéma dans components
                Do ..ToMove.%Set(newSchemaName, newSchema)
                
                ; Remplacer l'objet original par une référence
                Do schemaItem.%Set("items",{"$ref": ("#/components/schemas/" _ newSchemaName)})
            }
            ElseIf schemaItem.items.%IsDefined("allOf") || schemaItem.items.%IsDefined("oneOf") || schemaItem.items.%IsDefined("anyOf") {
                ; An array can also contain allOf, oneOf, or anyOf ...

                For key = "allOf", "oneOf", "anyOf" {

                    If '(schemaItem.items.%IsDefined(key) && $ISOBJECT(schemaItem.items.%Get(key))) {
                        Continue
                    }

                    set iteratorXOf = schemaItem.items.%Get(key).%GetIterator()
                    While iteratorXOf.%GetNext(.xofKey, .xOfSchemaItem) {
                        
                        ; If it's not an object, we  skip it
                        If '(xOfSchemaItem.type = "object" && xOfSchemaItem.%IsDefined("properties")) {
                            Continue
                        }

                        Set newSchemaName = fullPath _ key _ xofKey
                        Do ..FlattenSchemasIns(xOfSchemaItem.properties, newSchemaName)
                        
                        ; Créer un nouveau schéma pour l'élément de tableau
                        Set newSchema = {}.%FromJSON(xOfSchemaItem.%ToJSON())
                        
                        ; Ajouter le nouveau schéma et référencer-le
                        Do ..ToMove.%Set(newSchemaName, newSchema)
                        
                        ; Référencer le nouveau schéma
                        Do schemaItem.items.%Get(key).%Set(xofKey, {"$ref": ("#/components/schemas/" _ newSchemaName)})
                        
                    }
                }
            }
        }
        ElseIf schemaItem.%IsDefined("allOf") || schemaItem.%IsDefined("oneOf") || schemaItem.%IsDefined("anyOf") {
            ; Handle allOf, oneOf, and anyOf

            For key = "allOf", "oneOf", "anyOf" {
                
                If '(schemaItem.%IsDefined(key) && $ISOBJECT(schemaItem.%Get(key))) {
                    Continue
                }

                Set iteratorXOf = schemaItem.%Get(key).%GetIterator()

                While iteratorXOf.%GetNext(.xofKey, .xOfSchemaItem) {
                    
                    ; If it's not an object, we  skip it
                    If '(xOfSchemaItem.type = "object" && xOfSchemaItem.%IsDefined("properties")) {
                        Continue
                    }

                    Set newSchemaName = fullPath _ key _ xofKey
                    Do ..FlattenSchemasIns(xOfSchemaItem.properties, newSchemaName)
                    
                    ; Créer un nouveau schéma pour l'élément de tableau
                    Set newSchema = {}.%FromJSON(xOfSchemaItem.%ToJSON())
                    
                    ; Ajouter le nouveau schéma et référencer-le
                    Do ..ToMove.%Set(newSchemaName, newSchema)
                    
                    ; Référencer le nouveau schéma
                    Do schemaItem.%Get(key).%Set(xofKey, {"$ref": ("#/components/schemas/" _ newSchemaName)})
                    
                }
            }
        }
    }
    
    Return sc
}

Method ResolveDataType() As %Status
{
    Set sc = $$$OK
    
    ; If there's no components or no schemas, nothing to do
    If '$IsObject(..OAS.components) || '$IsObject(..OAS.components.schemas) {
        Return sc
    }
    
    ; Step 1: Mark simple schemas
    Set simpleSchemas = {}
    Set iterator = ..OAS.components.schemas.%GetIterator()
    While iterator.%GetNext(.schemaName, .schemaDef) {
        
        If '($IsObject(schemaDef) && schemaDef.%IsDefined("type")) {
            Continue ; Skip if not a valid schema
        }

        Set schemaType = schemaDef.type
        If ((schemaType = "string") || (schemaType = "integer") || (schemaType = "number") || 
            (schemaType = "boolean") || (schemaType = "array")) {
            Do simpleSchemas.%Set(schemaName, {}.%FromJSON(schemaDef.%ToJSON()))
        }
        
    }

    ; resolve simpleSchemas themselves
    Set iterator = simpleSchemas.%GetIterator()
    Set copy = {}.%FromJSON(simpleSchemas.%ToJSON())
    While iterator.%GetNext(.schemaName, .schemaDef) {
        If schemaDef.type '= "array" continue
        Do ..ResolveSimpleSchemaRef(schemaDef, "items", copy)
    }
    
    ; Step 2: Resolve $ref pointing to simple schemas
    ; First handle paths section
    If $IsObject(..OAS.paths) {
        Set pathIterator = ..OAS.paths.%GetIterator()
        While pathIterator.%GetNext(.path, .methods) {
            If '$IsObject(methods) Continue
            
            Set methodIterator = methods.%GetIterator()
            While methodIterator.%GetNext(.method, .operation) {
                If '$IsObject(operation) Continue
                
                ; Handle parameters
                If operation.%IsDefined("parameters") && $IsObject(operation.parameters) {
                    For i=0:1:operation.parameters.%Size()-1 {
                        Set param = operation.parameters.%Get(i)
                        If '$IsObject(param) || '$IsObject(param.schema) Continue
                        
                        Do ..ResolveSimpleSchemaRef(param, "schema", simpleSchemas)
                    }
                }
                
                ; Handle requestBody
                If operation.%IsDefined("requestBody") && $IsObject(operation.requestBody) {
                    If operation.requestBody.%IsDefined("content") && $IsObject(operation.requestBody.content) {
                        Set contentIterator = operation.requestBody.content.%GetIterator()
                        While contentIterator.%GetNext(.mediaType, .mediaTypeObj) {
                            If '$IsObject(mediaTypeObj) || '$IsObject(mediaTypeObj.schema) Continue
                            
                            Do ..ResolveSimpleSchemaRef(mediaTypeObj, "schema", simpleSchemas)
                        }
                    }
                }
                
                ; Handle responses
                If operation.%IsDefined("responses") && $IsObject(operation.responses) {
                    Set responseIterator = operation.responses.%GetIterator()
                    While responseIterator.%GetNext(.statusCode, .response) {
                        If '$IsObject(response) Continue
                        
                        If response.%IsDefined("content") && $IsObject(response.content) {
                            Set contentIterator = response.content.%GetIterator()
                            While contentIterator.%GetNext(.mediaType, .mediaTypeObj) {
                                If '$IsObject(mediaTypeObj) || '$IsObject(mediaTypeObj.schema) Continue
                                
                                Do ..ResolveSimpleSchemaRef(mediaTypeObj, "schema", simpleSchemas)
                            }
                        }
                    }
                }
            }
        }
    }
    
    ; Also handle components section (for nested references)
    If $IsObject(..OAS.components) {
        ; Handle parameters
        If $IsObject(..OAS.components.parameters) {
            Set paramIterator = ..OAS.components.parameters.%GetIterator()
            While paramIterator.%GetNext(.paramName, .param) {
                If '$IsObject(param) || '$IsObject(param.schema) Continue
                
                Do ..ResolveSimpleSchemaRef(param, "schema", simpleSchemas)
            }
        }
        
        ; Handle requestBodies
        If $IsObject(..OAS.components.requestBodies) {
            Set requestBodyIterator = ..OAS.components.requestBodies.%GetIterator()
            While requestBodyIterator.%GetNext(.requestBodyName, .requestBody) {
                If '$IsObject(requestBody) || '$IsObject(requestBody.content) Continue
                
                Set contentIterator = requestBody.content.%GetIterator()
                While contentIterator.%GetNext(.mediaType, .mediaTypeObj) {
                    If '$IsObject(mediaTypeObj) || '$IsObject(mediaTypeObj.schema) Continue
                    
                    Do ..ResolveSimpleSchemaRef(mediaTypeObj, "schema", simpleSchemas)
                }
            }
        }
        
        ; Handle responses
        If $IsObject(..OAS.components.responses) {
            Set responseIterator = ..OAS.components.responses.%GetIterator()
            While responseIterator.%GetNext(.responseName, .response) {
                If '$IsObject(response) || '$IsObject(response.content) Continue
                
                Set contentIterator = response.content.%GetIterator()
                While contentIterator.%GetNext(.mediaType, .mediaTypeObj) {
                    If '$IsObject(mediaTypeObj) || '$IsObject(mediaTypeObj.schema) Continue
                    
                    Do ..ResolveSimpleSchemaRef(mediaTypeObj, "schema", simpleSchemas)
                }
            }
        }
        
        ; Handle schemas themselves (could have $ref to other simple schemas)
        If $IsObject(..OAS.components.schemas) {
            Set schemaIterator = ..OAS.components.schemas.%GetIterator()
            While schemaIterator.%GetNext(.schemaName, .schema) {
                If '$IsObject(schema) Continue
                
                ; Parse properties if object type
                If schema.%IsDefined("properties") && $IsObject(schema.properties) {
                    Set propIterator = schema.properties.%GetIterator()
                    While propIterator.%GetNext(.propName, .propObj) {
                        If '$IsObject(propObj) Continue
                        
                        Do ..ResolveSimpleSchemaRef(schema.properties, propName, simpleSchemas)
                    }
                }
                ElseIf schema.%IsDefined("allOf") || schema.%IsDefined("oneOf") || schema.%IsDefined("anyOf") {
                    ; Handle allOf, oneOf, and anyOf
                    For key = "allOf", "oneOf", "anyOf" {
                        If '(schema.%IsDefined(key) && $IsObject(schema.%Get(key))) {
                            Continue
                        }
                        
                        Set xOfIterator = schema.%Get(key).%GetIterator()
                        While xOfIterator.%GetNext(.xofKey, .xofSchemaItem) {
                            If '$IsObject(xofSchemaItem) Continue
                            
                            Do ..ResolveSimpleSchemaRef(schema.%Get(key), xofKey, simpleSchemas)
                        }
                    }
                }
            }
        }
    }
    
    ; Step 3: Clean up components.schemas
    ; This would require tracking references which is complex - not implementing removal for now
    ; as it would require a full reference analysis of the entire document
    
    If ..RemoveDataTypeComponents {
        Set iterator = simpleSchemas.%GetIterator()
        While iterator.%GetNext(.schemaName, .schemaDef) {
            ; Remove the schema from components.schemas
            Do:..OAS.components.schemas.%IsDefined(schemaName) ..OAS.components.schemas.remove(schemaName)
        }
    }
    Return sc
}

Method ResolveSimpleSchemaRef(parentObj As %DynamicObject, propertyName As %String, simpleSchemas As %DynamicObject) As %Status
{
    Set sc = $$$OK
    
    ; Get the property
    Set refObj = parentObj.%Get(propertyName)
    
    ; Check if it's a reference to a simple schema
    If $IsObject(refObj) && refObj.%IsDefined("$ref") {
        Set schemaName = $Piece(refObj."$ref", "/", *)
        
        ; If it's a simple schema, replace with the actual schema definition
        If simpleSchemas.%IsDefined(schemaName) {
            Set simpleSchemaDef = simpleSchemas.%Get(schemaName)
            
            ; Replace with a copy of the actual schema
            Set newSchemaDef = {}.%FromJSON(simpleSchemaDef.%ToJSON())
            Do parentObj.%Set(propertyName, newSchemaDef)
        }
    }
    
    Return sc
}

}
