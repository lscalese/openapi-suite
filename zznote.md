
```
Set oas = {}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/allOf1.json") Do ##class(dc.openapi.common.Flattener).Flatten(.oas),##class(%JSON.Formatter).%New().Format(oas)
```


SwaggerDocumentProcessor
SwaggerPreprocessor
SwaggerFormatHandler
SwaggerDocumentPreparer
SwaggerContentNormalizer



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