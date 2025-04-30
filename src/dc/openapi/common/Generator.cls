Include dc.openapi.common.macro

Class dc.openapi.common.Generator
{

Parameter PKGMODEL = "model";

Parameter PKGREQUEST = "requests";

/// OpenAPI Version 3 specification.
Property spec As %DynamicObject;

/// this is the base package name where will be stored the generated classes.
Property application As %String [ Required ];

Property packageModel As %String [ Private ];

Property packageRequest As %String [ Private ];

Property superRequest As %String [ InitialExpression = "%RegisteredObject" ];

/// Helper to iterate operation object<br/>
/// the callback must be method with the parameters<br/>
/// (path As %String, pathItem As %DynamicObject, method As %String, operation As %DynamicObject)<br/>
Method IterateOnOperation(callBackMethod As %String) As %Status [ Private ]
{
    Set sc = $$$OK

    Quit:'..spec.%IsDefined("paths") sc

    Set pathIterator = ..spec.paths.%GetIterator()

    While pathIterator.%GetNext(.path, .pathItem) {
        
        Continue:'$IsObject(pathItem)

        For method = "get", "put", "post", "delete", "options", "head", "patch", "trace" {
            
            Set operation = pathItem.%Get(method)
            Continue:'$IsObject(operation)
            
            Set sc = $$$ADDSC(sc, $METHOD(##this, callBackMethod, path, pathItem, method, operation) )

        }

    }

    Quit sc
}

Method IterateOnResponses(callBackMethod As %String) As %Status [ Private ]
{
    Set sc = $$$OK

    Quit:'..spec.%IsDefined("paths") sc

    Set pathIterator = ..spec.paths.%GetIterator()

    While pathIterator.%GetNext(.path, .pathItem) {
        
        Continue:'$IsObject(pathItem)

        For method = "get", "put", "post", "delete", "options", "head", "patch", "trace" {
            
            Set operation = pathItem.%Get(method)
            Continue:'$IsObject(operation)
            
            Continue:'$IsObject(operation.responses)
            
            Set responseIterator = operation.responses.%GetIterator()

            While responseIterator.%GetNext(.response, .responseItem) {

                Set sc = $$$ADDSC(sc, $METHOD(##this, callBackMethod, path, pathItem, method, operation, response, responseItem) )

            }

        }

    }

    Quit sc
}

Method GenerateRequestClass(path As %String, pathItem As %DynamicObject, method As %String, operation As %DynamicObject) As %Status
{
    Set sc = $$$OK
    
    $$$zlog("* Generate Request class for " _path _ " "_ method _ "...")

    Do ..CheckAndGenerateOperationId(method, .operation, path)

    Set className = ..packageRequest _ "." _ $$$zNormalizeClassName(operation.operationId)
    $$$zlog($Char(9) _"Class name is " _ className)


    #dim classDef As %Dictionary.ClassDefinition
    $$$QuitOnError(##class(dc.openapi.common.Utils).CreateClassDefInstance(className, .classDef))
    Set classDef.Super = ..superRequest

    ; Create parameter URL with the path
    #dim classParameter As %Dictionary.ParameterDefinition = ##class(%Dictionary.ParameterDefinition).%New()
    Set classParameter.Name = "URL"
    Set classParameter.Default = path
    Do classDef.Parameters.Insert(classParameter)

    ; Create method parameter
    Set classParameter = ##class(%Dictionary.ParameterDefinition).%New()
    Set classParameter.Name = "METHOD"
    Set classParameter.Default = method
    Do classDef.Parameters.Insert(classParameter)

    /// Add property contentType
    Set propertyName = "%ContentType", propDef = $$$FindPropertyName(classDef, propertyName)
    Set:'$IsObject(propDef) propDef = ##class(%Dictionary.PropertyDefinition).%New(classDef.Name _ ":" _ propertyName )
    Set propDef.Type = "%String"
    $$$zlog($Char(9) _ "+ SET MAXLEN " _ propertyName)
    Do propDef.Parameters.SetAt("","MAXLEN")
    $$$zlog($Char(9) _ "+ Add property " _ propertyName)
    Do classDef.Properties.Insert(propDef)

    /// Add property %Consume (accept http header)
    Set propertyName = "%Consume", propDef = $$$FindPropertyName(classDef, propertyName)
    Set:'$IsObject(propDef) propDef = ##class(%Dictionary.PropertyDefinition).%New(classDef.Name _ ":" _ propertyName )
    Set propDef.Type = "%String"
    $$$zlog($Char(9) _ "+ SET MAXLEN " _ propertyName)
    Do propDef.Parameters.SetAt("","MAXLEN")
    $$$zlog($Char(9) _ "+ Add property " _ propertyName)
    Do classDef.Properties.Insert(propDef)

    /// Add property %URL
    Set propertyName = "%URL", propDef = $$$FindPropertyName(classDef, propertyName)
    Set:'$IsObject(propDef) propDef = ##class(%Dictionary.PropertyDefinition).%New(classDef.Name _ ":" _ propertyName )
    Set propDef.Type = "%String", propDef.InitialExpression = "..#URL"
    $$$zlog($Char(9) _ "+ SET MAXLEN " _ propertyName)
    Do propDef.Parameters.SetAt("","MAXLEN")
    $$$zlog($Char(9) _ "+ Add property " _ propertyName)
    Do classDef.Properties.Insert(propDef)
    

    ; If parameters array is defined in path and also in the operation,
    ; We merge these array.
    Set parameters = ..GetOperationParameters(pathItem, operation)

    Set parameterIterator = parameters.%GetIterator()
    While parameterIterator.%GetNext(.key, .parameter) {

        ; parameter is a parameter object https://swagger.io/specification/#parameter-object
        
        Set:parameter."$ref"'="" parameter = ##class(dc.openapi.common.Utils).GetObjectByRef(..spec, parameter."$ref", .name)
        
        Continue:'$IsObject(parameter)
        Continue:parameter.name=""
        Continue:parameter.in=""
        
        Set propDef = $$$FindPropertyName(classDef, $$$NormalizePropertyParamName(parameter.in_parameter.name))
        Set:'$IsObject(propDef) propDef = ##class(%Dictionary.PropertyDefinition).%New(classDef.Name _ ":" _ $$$NormalizePropertyParamName(parameter.in_parameter.name))

        Set propDef.Description = $REPLACE($ZSTRIP($ZSTRIP(parameter.description, "*", $Char(13)), "<>CW"), $Char(10), $Char(10) _ "/// ")
        
        If 'parameter.%IsDefined("schema") {
            Set propDef.Type = "%String"
            $$$zlog($Char(9) _ "+ SET MAXLEN " _ propDef.Name)
            Do propDef.Parameters.SetAt("","MAXLEN")
            Do propDef.%SetModified(1)
            Do classDef.Properties.Insert(propDef)
            Continue
        }

        Set sc = $$$ADDSC(sc, ##class(dc.openapi.common.Utils).CommonSchemaProcessForFlatteSpec(classDef, propDef, parameter.schema, ..packageModel, ..spec))
    }
    If $IsObject(operation.requestBody), operation.requestBody.%IsDefined("$ref") {
        Set refContent = ##class(dc.openapi.common.Utils).GetObjectByRef(..spec, operation.requestBody."$ref")
        Set:$IsObject(refContent) operation.requestBody.content = refContent.content
    }

    If '$ISOBJECT(operation.requestBody)||'$IsObject(operation.requestBody.content) Quit $$$ADDSC(sc, classDef.%Save())
    
    Set helperObj = ..RequestBodyHelper(operation.requestBody.content), helperObjIterator = helperObj.%GetIterator()

    While helperObjIterator.%GetNext(.propertyName, .propertyItem) {
        ; Add $$$CodeNormalizeProperty to avoid generate double quoted property like "my_property_with_special_char"
        Set propDef = $$$FindPropertyName(classDef, $$$CodeNormalizeProperty(propertyName)), newProp = $$$NO
        Set:'$IsObject(propDef) propDef = ##class(%Dictionary.PropertyDefinition).%New(classDef.Name _ ":" _ $$$CodeNormalizeProperty(propertyName)), newProp = $$$YES
        If propertyItem.%IsDefined("Type") {
            Set propDef.Type = propertyItem.Type
        } Else {
            Set sc = $$$ADDSC(sc, ##class(dc.openapi.common.Utils).CommonSchemaProcessForFlatteSpec(classDef, propDef, propertyItem.schema, ..packageModel, ..spec))
        }
        Set propDef.Description = propertyItem.Description

        If propDef.Type = "%String" Do propDef.Parameters.SetAt("","MAXLEN")

        Do ..GetXmlParameters(..spec, propertyItem.schema, .xmlTagName, .xmlItemName)

        Do:xmlTagName'="" propDef.Parameters.SetAt(xmlTagName, "XMLNAME")
        Do:xmlItemName'="" propDef.Parameters.SetAt(xmlItemName, "XMLITEMNAME")
        

        Do:newProp classDef.Properties.Insert(propDef)
    }

    Set sc = $$$ADDSC(sc, classDef.%Save())

    Quit sc
}

ClassMethod CheckAndGenerateOperationId(method As %String, operation As %DynamicObject, path As %String) As %Status
{
    If operation.operationId = "" { ; In order to ease the code generation, we generate an operationId
    
        Set operation.operationId = $$$zNormalizeClassName(path) _ $ZConvert(method, "U")
        $$$zlog($Char(9) _"! operationId field not defined, the following operationId has been auto-generated" _ operation.operationId)
    } Else {
        $$$zlog($Char(9) _"= operationId exists " _ operation.operationId)

    }

    ; force Normalize operationId
    Set operation.operationId = $$$zNormalizeClassName(operation.operationId)

    Quit $$$OK
}

ClassMethod GetOperationParameters(pathItem As %DynamicObject, operation As %DynamicObject) As %DynamicArray
{
    #dim parameters As %DynamicArray = []

    Set:$IsObject(operation.parameters) parameters = {}.%FromJSON(operation.parameters.%ToJSON())
    Set:$IsObject(pathItem.parameters)&&pathItem.parameters.%IsA("%DynamicArray") parameters = ##class(dc.openapi.common.Utils).MergeParametersArray(pathItem.parameters, parameters)
    
    Quit parameters
}

ClassMethod RequestBodyHelper(contentDefinition As %DynamicObject) As %DynamicObject
{
    Set bodyContentIterator = contentDefinition.%GetIterator(), bodyDef = {}

    While bodyContentIterator.%GetNext(.contentType, .contentTypeItem) {
    
        Set isEmptySchema = 'contentTypeItem.%IsDefined("schema")
        Set:'isEmptySchema isEmptySchema = (contentTypeItem.schema."$ref" = "") && (contentTypeItem.schema.type = "")

        Set type = "%Stream.Object", propertyName = "body" ; property name by default, if possible it will be changed with an appropriate name.

        If isEmptySchema {
            Set thePropType = $Select($$$LOWER(contentType)="application/json":"%DynamicObject",1:"%Stream.Object")
            If $$$LOWER(contentType)="application/json" {
                Set type = "%DynamicObject", propertyName = "bodyJSON"
            } Else {
                Set type = "%Stream.Object", propertyName = "bodyStream"
            }
        } ElseIf contentTypeItem.schema."$ref"'="" {
            Set propertyName = $zstrip($Piece(contentTypeItem.schema."$ref", "/", *), "*P")
            Set type = ##class(dc.openapi.common.Utils).GetTempData("model.package") _ "." _ propertyName
        }

        If contentTypeItem.schema.type = "array", contentTypeItem.schema.items.%IsDefined("$ref") {
            Set propertyName = "listOf" _ $Piece(contentTypeItem.schema.items."$ref", "/", *)
        }

        If 'bodyDef.%IsDefined(propertyName) {
            Set propertyDetail = {
                "Description": ("Use this property for body content with content-type = "_contentType _"."),
                "contentType": []
            }
            Do bodyDef.%Set(propertyName, propertyDetail)

        } Else {
            Set propertyDetail = bodyDef.%Get(propertyName)
            Set propertyDetail.Description = propertyDetail.Description _ "<br/>" _ $Char(13,10)
                _ "Use this property for body content with content-type = "_contentType _"."
        }

        Do propertyDetail.contentType.%Push(contentType)

        If type'="" {
            Set propertyDetail.Type = type
        } Else {
            Set propertyDetail.schema = contentTypeItem.schema
        }

    }

    Quit bodyDef
}

ClassMethod isBodyProperty(propertyName As %String, operation As %DynamicObject) As %Boolean
{
    If '$ISOBJECT(operation.requestBody)||'$IsObject(operation.requestBody.content) Quit $$$NO

    Set helperObj = ..RequestBodyHelper(operation.requestBody.content)

    Quit helperObj.%IsDefined(propertyName)
}

ClassMethod GetContentTypeListForProperty(propertyName, operation As %DynamicObject) As %String
{
    If '$ISOBJECT(operation.requestBody)||'$IsObject(operation.requestBody.content) Quit ""

    Set helperObj = ..RequestBodyHelper(operation.requestBody.content)

    Set propertyItem = helperObj.%Get(propertyName)
    If '$IsObject(propertyItem) Quit ""

    Set iter  = propertyItem.contentType.%GetIterator(), list = ""
    While iter.%GetNext(.key, .contentType) {
        Set list = list _ "," _ contentType
    }

    Quit $Extract(list, 2, *)
}

ClassMethod GetXmlParameters(spec As %DynamicObject, schema As %DynamicObject, Output xmlName, Output xmlItemName)
{
    Set (xmlName, xmlItemName) = ""

    Quit:'$ISOBJECT(schema)
    
    Set tSchema = {}.%FromJSON(schema.%ToJSON())

    If tSchema."$ref" '= "" Set tSchema = ##class(dc.openapi.common.Utils).GetObjectByRef(spec, tSchema."$ref")
    If tSchema.items."$ref" '= "" Set tSchema.items = ##class(dc.openapi.common.Utils).GetObjectByRef(spec, tSchema.items."$ref")

    If $IsObject(tSchema.xml), tSchema.xml.name '= "" Set xmlName = tSchema.xml.name
    If $IsObject(tSchema.items), $IsObject(tSchema.items.xml), tSchema.items.xml.name '= "" Set xmlItemName = tSchema.items.xml.name

    Quit
}

}
