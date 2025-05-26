/// Registry for managing generated items from AST.
/// This class provides functionality to register.
/// It's useful to retrieve the list of generated classes and export them.
/// Generator classes shoud simply use `##class(dc.openapi.common.GeneratedItemRegistry).RegisterClass(<className>)`
/// for each class they generate.
Class dc.openapi.common.GeneratedItemRegistry Extends %RegisteredObject
{

Property GeneratedClasses As list Of %String;

ClassMethod GetInstance() As dc.openapi.common.GeneratedItemRegistry
{
    If '$IsObject($Get(%zGeneratedClassRegistry)) {
        Set %zGeneratedClassRegistry = ..%New()
    }
    Return %zGeneratedClassRegistry
}

ClassMethod KillInstance() As %Status
{
    Kill %zGeneratedClassRegistry
    Return $$$OK
}

/// Constructeur privé pour implémenter le pattern Singleton
Method %OnNew() As %Status [ Private ]
{
    Return $$$OK
}

ClassMethod RegisterClass(ClassName As %String) As %Status
{
    Return ..GetInstance().SafeClassInsert(ClassName)
}

ClassMethod Clear() As %Status
{
    Return ..GetInstance().GeneratedClasses.Clear()
}

/// Avoid class name duplication
Method SafeClassInsert(className As %String) As %Status
{
    If ..GeneratedClasses.Find(className, "") '= "" {
        Return $$$OK ; do nothing, class already registered
    }
   
    Return ..GeneratedClasses.Insert(className)
}

/// Return an array formatted for $SYSTEM.OBJ.Export
ClassMethod GetArray(Output array As %Binary) As %Status
{
    #dim instance As dc.openapi.common.GeneratedItemRegistry = ..GetInstance()
    Set sc = $$$OK
    Set key = ""
    For  {
        Set class = instance.GeneratedClasses.GetNext(.key)
        Quit:key=""
        Set array(class_".cls") = ""
    }
    Return sc
}

}
