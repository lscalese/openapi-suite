Class dc.openapi.common.Flattener Extends %RegisteredObject
{

/// Internal use, current specification to process
Property OAS As %DynamicObject [ Private ];

Property DocumentCollection As dc.openapi.common.SwaggerDocumentCollection [ InitialExpression = {##class(dc.openapi.common.SwaggerDocumentCollection).%New()} ];

/// Stores schemas that need to be moved to the components section
Property ToMove As %DynamicObject;

Property HashComponentsSchemas As %String [ MultiDimensional ];

ClassMethod test()
{
    Set oas = {}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/components_schemas_allOf1.json")
    Set oas = {}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/flattened_example.json")
    Set oas = {}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/f1.json")
    
    
    Set documentCollection = ##class(dc.openapi.common.SwaggerDocumentCollection).%New()
    Do documentCollection.AddItem(oas, "$MAIN")

    Set flattener = ##class(dc.openapi.common.Flattener).%New()
    Set flattener.DocumentCollection = documentCollection
    Do flattener.Lift()
    Do ##class(%JSON.Formatter).%New().Format(oas)
}

Method Lift() As %Status
{
    #dim item As dc.openapi.common.SwaggerDocumentReference
    Set sc = $$$OK, key = ""
    For  {
        Set item = ..DocumentCollection.Items.GetNext(.key)
        Quit:key=""
        Set ..OAS = item.Document
        Set sc = $$$ADDSC(sc, ..FlattenComponents())
    }
    Return sc
}

Method FlattenComponents() As %Status
{
    Set ..ToMove = {}
    
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
            Set newSchemaName = fullPath, newSchemaStr = schemaItem.%ToJSON(), hash = $ZCRC(newSchemaStr,7)
            If '$Data(..HashComponentsSchemas(hash), schemaRefToSet) {
                Set (schemaRefToSet,..HashComponentsSchemas(hash)) = "#/components/schemas/" _ newSchemaName
                Set newSchema = {}.%FromJSON(newSchemaStr)
                ; Add to the list of schemas to move
                Do ..ToMove.%Set(newSchemaName, newSchema)
            }
            
            ; Remplacer l'objet original par une référence
            Do currentObject.%Set(name, {"$ref": (schemaRefToSet)})
        }
        ElseIf schemaItem.type = "array" && schemaItem.%IsDefined("items") && $ISOBJECT(schemaItem.items) {
            
            ; Handle arrays of objects
            If schemaItem.items.type = "object" && schemaItem.items.%IsDefined("properties") {
                ; Aplatir les propriétés de l'objet dans le tableau
                Set newSchemaName = fullPath _ "Item"
                Do ..FlattenSchemasIns(schemaItem.items.properties, newSchemaName)
                
                Set newSchemaStr = schemaItem.items.%ToJSON(), hash = $ZCRC(newSchemaStr,7)
                If '$Data(..HashComponentsSchemas(hash), schemaRefToSet) {
                    Set (schemaRefToSet,..HashComponentsSchemas(hash)) = "#/components/schemas/" _ newSchemaName
                    ; Extraire l'objet de tableau comme un nouveau schéma
                    Set newSchema = {}.%FromJSON(newSchemaStr)
                    ; Add to the list of schemas to move
                    Do ..ToMove.%Set(newSchemaName, newSchema)
                }

                ; Remplacer l'objet original par une référence
                Do schemaItem.%Set("items",{"$ref": (schemaRefToSet)})
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
                        
                        Set newSchemaStr = xOfSchemaItem.%ToJSON(), hash = $ZCRC(newSchemaStr,7)
                        If '$Data(..HashComponentsSchemas(hash), schemaRefToSet) {
                            Set (schemaRefToSet,..HashComponentsSchemas(hash)) = "#/components/schemas/" _ newSchemaName
                            ; Extraire l'objet de tableau comme un nouveau schéma
                            Set newSchema = {}.%FromJSON(newSchemaStr)
                            ; Add to the list of schemas to move
                            Do ..ToMove.%Set(newSchemaName, newSchema)
                        }

                        ; Référencer le nouveau schéma
                        Do schemaItem.items.%Get(key).%Set(xofKey, {"$ref": (schemaRefToSet)})
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
                    
                    Set newSchemaStr = xOfSchemaItem.%ToJSON(), hash = $ZCRC(newSchemaStr,7)
                    If '$Data(..HashComponentsSchemas(hash), schemaRefToSet) {
                        Set (schemaRefToSet,..HashComponentsSchemas(hash)) = "#/components/schemas/" _ newSchemaName
                        ; Extraire l'objet de tableau comme un nouveau schéma
                        Set newSchema = {}.%FromJSON(newSchemaStr)
                        ; Add to the list of schemas to move
                        Do ..ToMove.%Set(newSchemaName, newSchema)
                    }
                    
                    ; Référencer le nouveau schéma
                    Do schemaItem.%Get(key).%Set(xofKey, {"$ref": ("#/components/schemas/" _ newSchemaName)})
                    
                }
            }
        }
    }
    
    Return sc
}

}
