Class dc.openapi.common.SwaggerDocumentPreparer Extends %RegisteredObject
{

Property DocumentCollection As dc.openapi.common.SwaggerDocumentCollection [ InitialExpression = {##class(dc.openapi.common.SwaggerDocumentCollection).%New()} ];

Parameter SWAGGERV2TYPE = "Swagger 2.0";

Parameter OPENAPIV3TYPE = "OpenAPI 3.x";

Parameter REFERENCETYPE = "Reference";

Method SetMainDocument(documentStream As %Stream.GlobalCharacter, settings As %DynamicObject = {{}}) As %Status
{
    Set tSc = $$$OK

    Try {
        Set key = ##class(dc.openapi.common.SwaggerDocumentCollection).#MAINKEY
        Do ..DocumentCollection.Items.RemoveAt(key)
        Set tSc = ..AddDocument(documentStream, key, settings)
        If $$$ISERR(tSc) {
            Return tSc
        }
    }
    Catch ex {
        Set tSc = ex.AsStatus()
    }

    Return tSc
}

Method AddDocument(documentStream As %Stream.GlobalCharacter, key As %String, settings As %DynamicObject = {{}}) As %Status
{
    Set tSc = $$$OK

    Try {
        
        If '..IsJSONDocument(documentStream, .document) {
            ; it's yaml document, convert it to JSON
            
            Set docString = ""
            Do documentStream.Rewind()
            While 'documentStream.AtEnd {
                Set docString = docString _ documentStream.Read()
            }
            Do documentStream.Rewind()
            Set jsonString = ..YamlToJSON(docString)
            Set document = {}.%FromJSON(jsonString)
        }

        Set documentType = ..GetDocumentType(document)
        Set isFullSpecification = $$$NO

        If documentType = ..#SWAGGERV2TYPE {
            ; convert to OpenAPI 3.x
            Set isFullSpecification = $$$YES

            Set webConverter = ##class(dc.swaggerconverter.WebConverter).%New()
            Set webConverter.specification = document
            $$$TOE(sc, webConverter.Convert(.OpenAPIV3))
            Set OpenAPI = OpenAPIV3

        }
        ElseIf documentType = ..#OPENAPIV3TYPE {
            ; it's already OpenAPI 3.x
            Set isFullSpecification = $$$YES
        }

        Do ..DocumentCollection.AddItem(document, key, isFullSpecification, settings)
    }
    Catch ex {
        Set tSc = ex.AsStatus()
    }

    Return tSc
}

Method GetDocumentCollection() As dc.openapi.common.SwaggerDocumentCollection
{
    Return ..DocumentCollection
}

/// Method to determine the type of a document
/// It could be a fulle specification or a part of a specification 
/// that is referenced in the main document using $ref
/// If it's a full specification, it could be a version 2 or 3
ClassMethod GetDocumentType(document As %DynamicObject) As %String
{
    Set docType = "Unknown"

    ; Check if the document has the "openapi" field
    If document.%IsDefined("openapi") {
        Set docType = ..#OPENAPIV3TYPE
    } ElseIf document.%IsDefined("swagger") {
        Set docType = ..#SWAGGERV2TYPE
    } Else {
        Set docType = ..#REFERENCETYPE
    }

    Return docType
}

ClassMethod IsJSONDocument(document As %Stream.GlobalCharacter, Output dynamicObject As %DynamicObject) As %Boolean
{
    Set isJSON = $$$YES

    ; Try to parse the document and get a %DynamicObject.  If it fails, it's not a JSON document.
    Try {
        If document.%IsA("%DynamicObject") { 
            Set dynamicObject = {}.%FromJSON(document.%ToJSON()) ; is already a %DynamicObject, just copy it
        } Else {
            Set dynamicObject = {}.%FromJSON(.document)
        }
    } Catch ex {
        Set isJSON = $$$NO
    }
    
    Return isJSON
}

ClassMethod YamlToJSON(yamlContent) As %String [ Language = python ]
{
    import yaml
    import json

    def YamlToJSON(yaml_content):
        try:
            # Parsing du contenu YAML
            parsed_yaml = yaml.safe_load(yaml_content)
            
            # Conversion en JSON
            json_str = json.dumps(parsed_yaml, default=json_serializer)
            
            return json_str
        except Exception as e:            
            raise ValueError(f"Error converting YAML to JSON: {str(e)}")

    def json_serializer(obj):
        """Fonction personnalisée pour sérialiser des types non-JSON standards"""
        if isinstance(obj, (yaml.YAMLError, Exception)):
            return str(obj)
        # Ajoutez ici d'autres types spéciaux si nécessaire
        raise TypeError(f"Object of type {type(obj)} is not JSON serializable")
    return str(YamlToJSON(str(yamlContent)))
}

}
