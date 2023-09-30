Class Grongier.OpenApi.DefinitionV3 Extends %RegisteredObject
{

Parameter CFLAGS = "ck";

/// Swagger specification version 3<br/>
Property spec As %DynamicObject;

/// Target package for generated model<br/>
Property package As %String;

/// Extends for generated classes, ex : %Persistent,%JSON.Adaptor,%XML.Adaptor<br/>
Property super As %String [ InitialExpression = "%JSON.Adaptor,%RegisteredObject" ];

Property compile As %Boolean [ InitialExpression = 1 ];

Property compileFlags As %String [ InitialExpression = {..#CFLAGS} ];

Property allowPropertyOverride As %Boolean [ InitialExpression = {$$$YES} ];

Property generateInLineModel As %Boolean [ InitialExpression = {$$$NO} ];

Method %OnNew(
	specification As %DynamicObject,
	package As %String,
	super As %String,
	compile As %Boolean,
	flags As %String) As %Status
{
    Set ..spec = specification, ..package = package

    Set:$Data(super) ..super = super
    Set:$Data(compile) ..compile = compile
    Set:$Data(flags) ..compileFlags = flags

    Return $$$OK
}

Method GenerateClasses() As %Status
{
    Set sc = $$$OK

    If '..spec.%IsDefined("components") {
        Do ..log("components section is not defined.")
        Return sc
    }

    Do ..log("Components section is defined.")

    if ..spec.components.%IsDefined("schemas")
    {
        set schemas = ..spec.components.schemas
        set iter = schemas.%GetIterator()
        
        While iter.%GetNext(.key, .schema, .type )
        {
            do ..log("processing schema named " _ key)

            If schema."$ref" '= "" {
                // No need for generating, this is just an alternative way for defining externally defined common object!
                if ..GetObjectByRef(schema."$ref", .refName, .package) = ""
                {
                    Do ..log($c(9) _ schema."$ref" _ " does not resolve to an object type")
                }
            }
            Elseif (schema.type '= "object") && ('schema.%IsDefined("allOf")) && ('schema.%IsDefined("properties"))
            {
                Do ..log($c(9) _ key _ " is not an object type.")
            }
            else
            {
                Set sc = $$$ADDSC(sc, ..GenerateClassModel(schema, ..package _ "." _ $zstrip(key,"*P")))
            }
        }
    }
    else
    {
        do ..log("No schemas found")
    }

    Set:..generateInLineModel sc = $$$ADDSC(sc, ..GenerateInLineModel())

    set:..compile sc = $$$ADDSC(sc, $SYSTEM.OBJ.CompilePackage(..package, ..compileFlags))

    Quit sc
}

Method GenerateClassModel(
	schema As %DynamicObject,
	className As %String) As %Status
{
    Set sc = $$$OK, requiredArray = []

    Do ..log( $Char(9) _ "Generate model " _ className _ ".")

    $$$QuitOnError(..CreateClassDefInstance(className, .classDef))

    Set classDef.Super = ..super

    Set sc = $$$ADDSC(sc, ..ManageAllOf(classDef, schema))

    /// Add properties to class definition.
    $$$QuitOnError(..GenerateProperties(classDef, schema.properties))

    Do ..ManageRequiredProperties(classDef, schema.required)

    Set sc = classDef.%Save()

    Quit sc
}

Method GenerateProperties(
	classDef As %Dictionary.ClassDefinition,
	properties As %DynamicObject) As %Status
{
    Set sc = $$$OK

    Quit:'$IsObject(properties) sc

    Set iter = properties.%GetIterator()
        
    While iter.%GetNext(.key, .property, .type ) {
        
        Set propDef = ..FindPropertyName(classDef, key), pObj = property

        If '..allowPropertyOverride, $IsObject(propDef) {
            Do ..log($Char(9)_ "- Skip property " _ key _ " because override property is not allowed.")
            Continue
        }

        Set:'$IsObject(propDef) propDef = ##class(%Dictionary.PropertyDefinition).%New(classDef.Name _ ":" _ $zstrip(key,"*P"))

        If property.type = "object" {

            ; Embedded object ... a class must be generated.
            ; Recursive call ...
            
            Set propDef.Type = classDef.Name _ $zstrip(key,"*P")
            Do ..GenerateClassModel(property, propDef.Type)
        
        } ElseIf property.type = "array" {
            
            Do XMLParameters

            Set propDef.Collection = "list"
            
            If property.items.type = "object" {

                Set propDef.Type = classDef.Name _ $zstrip(key,"*P")
                Set sc = $$$ADDSC(sc, ..GenerateClassModel(property.items, propDef.Type))
            
            } ElseIf property.items."$ref" '= "" {
                
                ; This a a reference to another definition.
                ; We have to check if the reference is type object or a primitive.
                Set refObject = ..GetObjectByRef(property.items."$ref", .name, .package)
                Continue:'$IsObject(refObject)

                Set propDef.Type = $Select(refObject.type="object": package _ "." _name, 1: ..GetObjectScriptType(refObject.type, refObject.format))
                Set pObj = refObject
            } Else {

                Set propDef.Type = ..GetObjectScriptType(property.items.type, property.items.format)
            
            }

        } ElseIf property."$ref" '= "" {

            Set refObject = ..GetObjectByRef(property."$ref", .refName, .package)
            Continue:'$IsObject(refObject)

            Set propDef.Type = $Select(refObject.type="object": package _ "." _refName, 1: ..GetObjectScriptType(refObject.type, refObject.format))

            Set pObj = refObject
        } Else {
            
            set propDef.Type = ..GetObjectScriptType(property.type, property.format)
        
        }

        Do AdditionalPropertySettings

        Set:property.deprecated'="" propDef.Deprecated = property.deprecated
        
        Do ..log($Char(9) _ "+ Add property " _ propDef.Name _ " As " _ propDef.Type)
        Do classDef.Properties.Insert(propDef)
    }

    Quit sc

AdditionalPropertySettings
    Set propDef.Description = $Select(pObj.description[$Char(13,10):$Replace(pObj.description,$Char(13,10),$Char(13,10)_"/// "),1:$Replace(pObj.description,$Char(10),$Char(10)_"/// "))
    Do:pObj.maxLength'="" propDef.Parameters.SetAt(pObj.maxLength,"MAXLEN")        
    Do:pObj.minLength'="" propDef.Parameters.SetAt(pObj.minLength,"MINLEN")        
    Do:pObj.minimum'="" propDef.Parameters.SetAt(pObj.minimum,"MINVAL")        
    Do:pObj.maximum'="" propDef.Parameters.SetAt(pObj.maximum,"MAXVAL")
    If ..super [ "%JSON.Adaptor",$zstrip(key,"*P") '= key Do propDef.Parameters.SetAt(key,"%JSONFIELDNAME")        
    Set:pObj.default'="" propDef.InitialExpression = """" _ pObj.default _""""
    
    If pObj.%IsDefined("enum"), $IsObject(pObj.enum), pObj.enum.%IsA("%DynamicArray") {
        Set valueList = ""

        Set enumIterator = pObj.enum.%GetIterator()
        While enumIterator.%GetNext(.enumIdx, .enumValue, .enumType) {
            Set valueList = valueList _ "," _ enumValue
        }

        Do propDef.Parameters.SetAt(valueList,"VALUELIST")        
    }
    
    Do XMLParameters

    Quit

XMLParameters
    If ..super [ "%XML.Adaptor" {
        If $IsObject(pObj.xml), pObj.xml.name '= "" Do propDef.Parameters.SetAt(pObj.xml.name, $Select(propDef.Collection = "list":"XMLITEMNAME",1:"XMLNAME"))
        If $IsObject(pObj.items), $IsObject(pObj.items.xml), pObj.items.xml.name '= "" Do propDef.Parameters.SetAt(pObj.items.xml.name, "XMLITEMNAME")
    }

    Quit
}

Method ManageAllOf(
	classDef As %Dictionary.ClassDefinition,
	schema As %DynamicObject) As %Status
{
    Set sc = $$$OK, superClasses = ""
    
    If schema.%IsDefined("allOf"), schema.allOf.%IsA("%DynamicArray") {
            
        Set iterator = schema.allOf.%GetIterator()

        While iterator.%GetNext(.key, .allOfItem) {
            
            If allOfItem.%IsDefined("$ref") {
                
                Set superClassName = ..package _ "." _ $Piece(allOfItem."$ref", "/", *)
                Set classDef.Super = $Select(classDef.Super'="": classDef.Super _ "," _ superClassName, 1: superClassName)
                Continue

            } ElseIf allOfItem.type = "object" {
                
                Set sc = ..GenerateProperties(classDef, allOfItem.properties)
                Return:$$$ISERR(sc) sc

                Do ..ManageRequiredProperties(classDef, allOfItem.required)
            }
        }
    }

    Quit sc
}

Method ManageRequiredProperties(
	classDef As %Dictionary.ClassDefinition,
	requiredArray As %DynamicArray) As %Status
{
    Set sc = $$$OK

    If $IsObject(requiredArray), requiredArray.%IsA("%DynamicArray") {
        Set requiredIterator = requiredArray.%GetIterator()
        
        Do ..log($Char(9) _ "* Add Required keyword to properties : ")

        While requiredIterator.%GetNext(.key, .propertyName, .type) {
            Set property = ..FindPropertyName(classDef, propertyName)
            Continue:property="" ; property not found ...
            Do ..log($Char(9) _ "  - " _ propertyName)
            Set property.Required = $$$YES
        }
    }

    Quit sc
}

/// Search inline model definition.
/// In line model could be defined in operation parameters and responses.
/// 
Method GenerateInLineModel(paths As %DynamicObject = {..spec.paths}) As %Status
{
    Set sc = $$$OK
    Quit:'$ISOBJECT(paths) sc

    Do ..log($Char(9)_"* Search inline model definition in operation parameters and response")

    Set iterator = paths.%GetIterator()

    While iterator.%GetNext(.key, .path, .type) {
        Continue:type'="object"

        Set:path."$ref"'="" path = ..GetObjectByRef(path."$ref")
        Continue:'$IsObject(path)

        Set parameters = path.parameters, method = "commonparam"
        Do parametersObject
        
        For method = "get", "put", "post", "delete", "options", "head", "patch", "trace" {
            
            Set operation = path.%Get(method)
            Continue:'$IsObject(operation)

            Set parameters = operation.parameters
            Do parametersObject

            If $IsObject(operation.requestBody) && $IsObject(operation.requestBody.content) {
                Set pName = "requestBody"

                Set contentTypeIterator = operation.requestBody.content.%GetIterator()
                While contentTypeIterator.%GetNext(.contentType, .contentTypeItem) {
                    Continue:'$IsObject(contentTypeItem.schema)

                    Set schema = contentTypeItem.schema
                    Do commonCheck
                }
            }

            If $IsObject(operation.responses) {
                Set responseIterator = operation.responses.%GetIterator()
                While responseIterator.%GetNext(.code, .responseItem) {
                    Continue:'$IsObject(responseItem.content)
                    Set pName = "response"_code, contentType = ""

                    Set contentTypeIterator = responseItem.content.%GetIterator()
                    While contentTypeIterator.%GetNext(.contentType, .contentTypeItem) {
                        Continue:'$IsObject(contentTypeItem.schema)

                        Set schema = contentTypeItem.schema
                        Do commonCheck
                    }

                }
            }
        }
    }

    Quit sc
commonCheck
    Set clsName = ..package _ "." _..GetClsNameForAnonymObject(key, method, pName, contentType)
    
    Set schemaToGenerate = ""
    If schema.type = "object" {
        Set schemaToGenerate = schema
    } ElseIf (schema.type = "array") && (schema.item.type = "object") {
        Set schemaToGenerate = schema.item
    }
    
    If $IsObject(schemaToGenerate) {
        Do ..log($Char(9) _ "  + "_pName _" is a in line definition object " _ key _" "_method _ " " _pName _ " "_contentType _", "_clsName _" will be generated.")
        Set sc = $$$ADDSC(sc, ..GenerateClassModel(schemaToGenerate, clsName))
    } Else {
        Do ..log($Char(9) _ "  - There is no in line object definition found in " _ key _" "_method _ " " _pName _ " "_contentType)
    }

    Quit

parametersObject

    If $IsObject(parameters) && parameters.%IsA("%DynamicArray") {
        Set parametersIterator = parameters.%GetIterator()
        While parametersIterator.%GetNext(.keyParameters, .parameter) {
            Continue:'$IsObject(parameter.schema)

            Set schema = parameter.schema, pName = parameter.name, contentType = ""
            Do commonCheck

        }
    }

    Quit
}

ClassMethod log(
	msg As %String,
	nl As %Boolean = {$$$YES},
	dtOnNL As %Boolean = {$$$YES})
{
    Quit:$Get(%zverbose)=0

    Write:nl !
    Write:nl&&dtOnNL $ZDateTime($Horolog, 3, 1), " "
    Write msg

    Quit
}

ClassMethod GetObjectScriptType(
	oaType As %DynamicObject,
	format As %String = "") As %String
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

Method GetObjectByRef(
	reference As %String,
	Output name As %String,
	Output package As %String) As %DynamicObject
{
    // Example references
    //  "$ref":"#/components/schemas/ContactInformation"
    //  "$ref":"../common/ssi_types.yaml#/components/schemas/DIDDocument"
    // This second form can be used to point to a common package by setting ..spec.externals to 
    // {
    //    "../common/ssi_types.yaml": "Nuts.Api.Common.model"
    // }


    ; First check if externals are present, and if so, try to find object!
    Set prefix = $PIECE(reference, "#", 1)
    If $ISOBJECT(..spec.externals) && ($LENGTH(reference, "#") > 1) && (prefix '= "") && (..spec.externals.%Get(prefix) '= "") {
        Set package = ..spec.externals.%Get(prefix)
        Set tmpObjRef =  ..GetSpecForPackage(package)

        if tmpObjRef = ""
        {
            do ..log("Failed to load spec for package " _ package _ ", so type cannot be resolved")
            return ""
        }

        Set reference = $PIECE(reference, "#", 2)
    }
    Else {
        Set tmpObjRef =  ..spec
        Set package = ..package
    }

    Set name = $Piece(reference, "/", *)

    For i=2:1:$Length(reference, "/") {
        Set tmpObjRef = tmpObjRef.%Get($Piece(reference, "/", i))
        Quit:tmpObjRef=""
    }

    ; strip name 
    Set name = $zstrip(name,"*P")

    // Make sure that local synonyms for common objects are properly resolved!

    If ($ISOBJECT(tmpObjRef)) && (tmpObjRef."$ref" '= "") {
        // change to the linked common object!
        do ..log($Char(9) _ "! found local synonym named " _ name _ " referring to """ _ reference _ "")
        set tmpObjRef = ..GetObjectByRef(tmpObjRef."$ref", .name, .package)
        do ..log($Char(9) _ "! Found object in package " _ package)
    }

    Do:'$ISOBJECT(tmpObjRef) ..log($Char(9) _ "! reference : """ _ reference _ """ not found.")

    Quit tmpObjRef
}

/// Get spec for Package
/// TBD: Add caching
ClassMethod GetSpecForPackage(package As %String) As %DynamicObject
{
    Set srvGenModelSpec = $Piece(package, ".", 1, *-1) _ ".Spec||OpenAPI"
    If ##class(%Dictionary.XDataDefinition).%ExistsId(srvGenModelSpec) { ; case server gen
        ; Todo change server generator to generate the same class structure as client generator
        Return {}.%FromJSON(##class(%Dictionary.XDataDefinition).%OpenId(srvGenModelSpec).Data)
    }
    return {}.%FromJSON(##class(%Dictionary.XDataDefinition).%OpenId(package _ ".spec||OpenAPI").Data)
}

ClassMethod CreateClassDefInstance(
	className As %String,
	Output classDef As %Dictionary.ClassDefinition = "") As %Dictionary.ClassDefinition
{
    If $$$defClassDefined(className) {
        Set sc = $$Delete^%apiOBJ(className,"-d")
        If $$$ISERR(sc) Quit sc
    }

    Kill %objlasterror

    Set classDef = ##class(%Dictionary.ClassDefinition).%New(className)
	If '$IsObject(classDef) {
		Quit $Get(%objlasterror, $$$ERROR($$$FailedToCreateClass, className))
	}

    Set classDef.ProcedureBlock = $$$YES

    Quit $$$OK
}

Method CommonSchemaProcess(
	classDef As %Dictionary.ClassDefinition,
	propDef As %Dictionary.PropertyDefinition,
	schema As %DynamicObject,
	name As %String) As %Status
{
    Set sc = $$$OK

    If schema.%IsDefined("$ref") {
        Set schema = ..GetObjectByRef(schema."$ref", .refName, .package)
        Quit:'$IsObject(schema) sc

        If schema.type = "object" {
            Set propDef.Type = package _ "." _ refName
            Do classDef.Properties.Insert(propDef)
            Quit sc
        }
    }

    If schema.type = "object" {
        Set propDef.Type = ..package _ "." _ propDef.Name
        Set sc = $$$ADDSC(sc, ..GenerateClassModel(schema, propDef.Type ))
        Do classDef.Properties.Insert(propDef)
        Quit sc
    }
    
    If schema.type = "array" {

        Set propDef.Collection = "list"

        If schema.items.type = "object" {
        
            Set propDef.Type = classDef.Name _ $Tr(name, "%-_", "")
            Set sc = $$$ADDSC(sc, ..GenerateClassModel(schema.items, propDef.type))
        
        } ElseIf schema.items."$ref" '="" {
            Set refObject = ..GetObjectByRef(schema.items."$ref", .refName, .package)
            Quit:'$IsObject(refObject) sc
            
            Set propDef.Type = $Select(refObject.type="object": package _ "." _ refName, 1: ..GetObjectScriptType(refObject.type, refObject.format))
            
        } Else {

            Set propDef.Type = ..GetObjectScriptType(schema.items.type, schema.items.format)
        
        }
    
    } Else {

        Set propDef.Type = ..GetObjectScriptType(schema.type, schema.format)
    }

    Do classDef.Properties.Insert(propDef)

    Quit sc
}

ClassMethod FindPropertyName(
	classDefinition As %Dictionary.ClassDefinition,
	propertyName As %String) As %Dictionary.PropertyDefinition
{
    #dim property As %Dictionary.PropertyDefinition
    Set key = ""

    Set property = classDefinition.Properties.GetNext(.key)
    While key '= "" {
        
        Return:property.Name=propertyName property

        Set property = classDefinition.Properties.GetNext(.key)
    }

    Return ""
}

ClassMethod GetClsNameForAnonymObject(
	path As %String = "",
	method As %String = "",
	name As %String = "",
	contentType As %String = "") As %String
{
    Quit "Z"_name _ $ZCRC(path_method_name_contentType,0)
}

}
