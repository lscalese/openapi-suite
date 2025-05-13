Include dc.openapi.common.macro

Class dc.openapi.common.Utils
{

ClassMethod log(msg As %String, nl As %Boolean = {$$$YES}, dtOnNL As %Boolean = {$$$YES})
{
    Quit:$Get(%zverbose)=0

    Write:nl !
    Write:nl&&dtOnNL $ZDateTime($Horolog, 3, 1), " "
    Write msg

    Quit
}

ClassMethod CreateClassDefInstance(className As %String, Output classDef As %Dictionary.ClassDefinition = "") As %Dictionary.ClassDefinition
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

ClassMethod FindPropertyName(classDefinition As %Dictionary.ClassDefinition, propertyName As %String) As %Dictionary.PropertyDefinition
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

ClassMethod ForceNotDefinedMAXLEN(package As %String, maxLenValue As %String = "") As %Status
{
    #dim propDef As %Dictionary.PropertyDefinition
    Set sc = $$$OK, (startKey, className) = package _"."
    
    For  {
        Set className = $Order(^oddDEF(className))
        Quit:$Extract(className, 1, $LENGTH(startKey))'=startKey

        Set classDef = ##class(%Dictionary.ClassDefinition).%OpenId(className,, .scO)
        If $$$ISERR(sc) {
            Set sc = $$$ADDSC(sc, scO)
            Continue
        }

        Set key = ""
        For  {
            Set propDef = classDef.Properties.GetNext(.key)
            Quit:key=""
            If "%String,%Library.String,%VarString"[propDef.Type, propDef.Parameters.GetAt("MAXLEN") = "" {
                $$$zlog("Force " _ className _" " _ propDef.Name _" with MAXLEN=" _ maxLenValue)
                Do propDef.Parameters.SetAt(maxLenValue, "MAXLEN")
                Set sc = $$$ADDSC(sc, propDef.%Save()) 
            }
        }
    }

    Quit sc
}

ClassMethod packageExists(packageName As %String) As %Boolean
{
    Set packageList = ##class(%Dictionary.PackageDefinition).GetPackageList()
    Return ''packageList.Find($zcvt(packageName, "U"))
}

ClassMethod RemoveXDataBlock(cDef, blockName)
{
 	Set key = cDef.XDatas.FindObjectId(cDef.Name_"||"_blockName)
 	If (key'="") {
 		Set oid = cDef.XDatas.RemoveAt(key)
	}
}

/// Is this schema an object?
ClassMethod IsSchemaObject(schema As %DynamicObject) As %Boolean
{
    Return (schema.type = "object") || schema.%IsDefined("allOf") || schema.%IsDefined("properties")
}

ClassMethod CommonSchemaProcessForFlatteSpec(classDef As %Dictionary.ClassDefinition, propDef As %Dictionary.PropertyDefinition, schema As %DynamicObject, package As %String, specification) As %Status
{
    Set sc = $$$OK

    If schema.%IsDefined("$ref") {
        Set schema = ..GetObjectByRef(specification, schema."$ref", .refName)
        Quit:'$IsObject(schema) sc

        If ..IsSchemaObject(schema) {
            Set propDef.Type = package _ "." _ $$$zNormalizeClassName(refName)
            Do classDef.Properties.Insert(propDef)
            Quit sc
        }
    }

    If schema.type = "array" {

        Set propDef.Collection = "list"

        If schema.items."$ref" '="" {
            Set refObject = ..GetObjectByRef(specification, schema.items."$ref", .refName)
            Quit:'$IsObject(refObject) sc
            
            Set propDef.Type = $Select(..IsSchemaObject(refObject): package _ "." _ $$$zNormalizeClassName(refName), 1: $$$GetObjectScriptType(refObject.type,refObject.format))
            
        } Else {

            Set propDef.Type = $$$GetObjectScriptType(schema.items.type,schema.items.format)
        
        }
    
    } Else {
        w !,schema.type,schema.format
        Set propDef.Type = $$$GetObjectScriptType(schema.type,schema.format)
    }

    If propDef.Type = "%String" Do propDef.Parameters.SetAt("","MAXLEN"), propDef.%SetModified(1)
    
    Do classDef.Properties.Insert(propDef)

    Quit sc
}

ClassMethod GetObjectByRef(spec As %DynamicObject, reference As %String, Output name As %String, Output package As %String) As %DynamicObject
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
    If $ISOBJECT(spec.externals) && ($LENGTH(reference, "#") > 1) && (prefix '= "") && (spec.externals.%Get(prefix) '= "") {
        Set package = spec.externals.%Get(prefix)
        Set tmpObjRef = ..GetSpecForPackage(package)

        if tmpObjRef = ""
        {
            do ..log("Failed to load spec for package " _ package _ ", so type cannot be resolved")
            return ""
        }

        Set reference = $PIECE(reference, "#", 2)
    }
    Else {
        Set tmpObjRef =  spec
        ; required: the generator make Do ##class(dc.openapi.common.Utils).SetTempData("model.package", <model package name>)
        Set package = ##class(dc.openapi.common.Utils).GetTempData("model.package")
        
        If package = "" {
             do ..log($Char(9) _ "! The generator must set model.package with the package name (common.Utils:SetTempData).")
        }
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
        do ..log($Char(9) _ "! found local synonym named " _ name _ " referring to """ _ tmpObjRef."$ref" _ "")
        set tmpObjRef = ..GetObjectByRef(spec, tmpObjRef."$ref", .name, .package)
        do ..log($Char(9) _ "! Found object in package " _ package)
    }

    Do:'$ISOBJECT(tmpObjRef) ..log($Char(9) _ "! reference : """ _ reference _ """ not found.")

    return tmpObjRef
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

ClassMethod MergeParametersArray(from As %DynamicArray, to As %DynamicArray) As %DynamicArray
{
    #dim target As %DynamicArray = {}.%FromJSON(from.%ToJSON())

    Set names = ""
    Set iter = from.%GetIterator()
    While iter.%GetNext(.key, .parameter) {
        Set names(" "_parameter.name)=key
    }

    Set iter = to.%GetIterator()
    While iter.%GetNext(.key, .parameter) {
        Set:$Data(names(" "_parameter.name), key) del(key) = ""
        Do target.%Push(parameter)
    }

    Set key = ""
    For  {
        Set key = $Order(del(key), -1, pos)
        Quit:key=""
        Do target.%Remove(pos)
    }

    Quit target
}

ClassMethod SetTempData(key As %String, value As %String) As %Status
{
    Set %zTempOASGen(key) = value
    Quit $$$OK
}

ClassMethod GetTempData(key As %String, default As %String = "") As %Status
{
    Quit $Get(%zTempOASGen(key), default)
}

ClassMethod KillTempData(key As %String = "") As %Status
{
    Kill:key'="" %zTempOASGen Quit $$$OK
    Kill %zTempOASGen(key) 
    Quit $$$OK
}

/// Format comment for class, method or property
ClassMethod FormatDescription(description As %String) As %String
{
    Return $REPLACE($ZSTRIP($ZSTRIP(description, "*", $Char(13)), "<>CW"), $Char(10), $Char(10) _ "/// ")
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

/// Determine if a given mimetype represents JSON content
/// @param mimetype The MIME type to check (e.g., "application/json", "application/vnd.api+json")
/// @return Returns 1 if the mimetype is JSON-related, 0 otherwise
ClassMethod isJsonMimeType(mimetype As %String) As %Boolean
{
    // Normalize: convert to lowercase and trim
    Set mimetype = $ZCONVERT($ZSTRIP(mimetype, "<>W"), "L")
    
    // Standard JSON mimetypes
    If mimetype = "application/json" Quit 1
    If mimetype = "text/json" Quit 1
    
    // JSON with suffixes (RFC 6839)
    If $EXTRACT(mimetype, 1, 12) = "application/" && ($FIND(mimetype, "+json") > 0) Quit 1
    If $EXTRACT(mimetype, 1, 5) = "text/" && ($FIND(mimetype, "+json") > 0) Quit 1
    
    // Vendor specific JSON formats
    If $MATCH(mimetype, "application/vnd\..*[+]json") Quit 1
    If $MATCH(mimetype, "application/.*[+]json") Quit 1
    
    // Common specific JSON types
    If mimetype = "application/problem+json" Quit 1
    If mimetype = "application/geo+json" Quit 1
    If mimetype = "application/ld+json" Quit 1
    If mimetype = "application/json-patch+json" Quit 1
    If mimetype = "application/merge-patch+json" Quit 1
    If mimetype = "application/schema+json" Quit 1
    If mimetype = "application/hal+json" Quit 1
    
    // Not a JSON mimetype
    Quit 0
}

/// Determine if a given mimetype represents XML content
/// @param mimetype The MIME type to check (e.g., "application/xml", "text/xml", "application/atom+xml")
/// @return Returns 1 if the mimetype is XML-related, 0 otherwise
ClassMethod isXmlMimeType(mimetype As %String) As %Boolean
{
    // Normalize: convert to lowercase and trim
    Set mimetype = $ZCONVERT($ZSTRIP(mimetype, "<>W"), "L")
    
    // Standard XML mimetypes
    If mimetype = "application/xml" Quit 1
    If mimetype = "text/xml" Quit 1
    
    // XML with suffixes (RFC 6839)
    If $EXTRACT(mimetype, 1, 12) = "application/" && ($FIND(mimetype, "+xml") > 0) Quit 1
    If $EXTRACT(mimetype, 1, 5) = "text/" && ($FIND(mimetype, "+xml") > 0) Quit 1
    
    // Vendor specific XML formats
    If $MATCH(mimetype, "application/vnd\..*[+]xml") Quit 1
    
    // Common specific XML types
    If mimetype = "application/atom+xml" Quit 1
    If mimetype = "application/rss+xml" Quit 1
    If mimetype = "application/xhtml+xml" Quit 1
    If mimetype = "application/soap+xml" Quit 1
    If mimetype = "application/xslt+xml" Quit 1
    If mimetype = "application/mathml+xml" Quit 1
    If mimetype = "application/voicexml+xml" Quit 1
    If mimetype = "application/wsdl+xml" Quit 1
    If mimetype = "application/svg+xml" Quit 1
    
    // Not an XML mimetype
    Quit 0
}

ClassMethod DumpToFile(object As %RegisteredObject, fileName As %String, deleteIfExists As %Boolean = {$$$YES}) As %Status
{
    Set sc = $$$OK
    Try {
        Set directory = ##class(%File).GetDirectory(fileName)

        If ##class(%File).DirectoryExists(directory) {
            Do:##class(%File).Exists(fileName) ##class(%File).Delete(fileName)
        }
        Else {
            Do ##class(%File).CreateDirectoryChain(directory)
        }
        
        Set file = ##class(%Stream.FileCharacter).%New()
        $$$TOE(sc,file.LinkToFile(fileName))
        
        If object.%IsA("%DynamicObject") {
            Do object.%ToJSON(file)
        } 
        Else {
            Do object.%JSONExportToStream(file)
        }

        Set sc =  file.%Save()
    } Catch ex {
        Set sc = ex.AsStatus()
        Do $SYSTEM.Status.DisplayError(sc)
    }
    Return sc
}

}
