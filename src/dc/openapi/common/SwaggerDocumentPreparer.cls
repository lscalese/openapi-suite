Class dc.openapi.common.SwaggerDocumentPreparer Extends %RegisteredObject
{

Property DocumentCollection As dc.openapi.common.SwaggerDocumentCollection [ InitialExpression = {##class(dc.openapi.common.SwaggerDocumentCollection).%New()} ];

Parameter SWAGGERV2TYPE = "Swagger 2.0";

Parameter OPENAPIV3TYPE = "OpenAPI 3.x";

Parameter REFERENCETYPE = "Reference";

Method AddDocument(documentStream As %Stream.GlobalCharacter, key As %String) As %Status
{
    Set tSc = $$$OK

    If '..IsJSONDocument(documentStream, .document) {
        ; it's yaml document, convert it to JSON
        ; todo ...

        Set yamlToJSON = ##class(dc.openapi.common.YAMLToJSON).%New()
        Set tSc = yamlToJSON.Convert(documentStream, .document, .stack)
        If $$$ISERR(tSc) {
            Return tSc
        }
    }

    Set documentType = ..GetDocumentType(document)
    Set isFullSpecification = $$$NO

    If documentType = ..#SWAGGERV2TYPE {
        ; convert to OpenAPI 3.x
        Set isFullSpecification = $$$YES
    }
    ElseIf documentType = ..#OPENAPIV3TYPE {
        ; it's already OpenAPI 3.x
        Set isFullSpecification = $$$YES
    }

    Do ..DocumentCollection.AddItem(document, key, isFullSpecification)

    Return tSc
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
        Set json = {}.%FromJSON(.document)
    } Catch ex {
        Set isJSON = $$$NO
    }
    
    Return isJSON
}

}
