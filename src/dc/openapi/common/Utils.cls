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

}
