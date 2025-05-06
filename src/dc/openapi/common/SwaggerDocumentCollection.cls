Class dc.openapi.common.SwaggerDocumentCollection Extends %RegisteredObject
{

Parameter MAINKEY = "$MAIN";

Property Items As array Of dc.openapi.common.SwaggerDocumentReference;

Method AddItem(document As %DynamicObject, key As %String, isAFullSpecification As %Boolean = "", settings As %DynamicObject = {{}}) As %Status
{
    Set item = ##class(dc.openapi.common.SwaggerDocumentReference).%New()
    Set item.Document = document
    Set item.Key = key
    Set item.Settings = settings

    If isAFullSpecification = "" { ; try to guess if the document is a full specification
        If document.%IsDefined("openapi") {
            Set item.IsAFullSpecification = $$$YES
        } Else {
            Set item.IsAFullSpecification = $$$NO
        }
    } Else {
        Set item.IsAFullSpecification = isAFullSpecification
    }

    Return ..Items.SetAt(item, key)
}

Method GetItem(key As %String) As dc.openapi.common.SwaggerDocumentReference
{
    If key = "" {
        Set key = ..#MAINKEY
    }
    Return ..Items.GetAt(key)
}

Method GetDocument(key As %String, Output found As %Boolean) As %DynamicObject
{
    Set found = $$$NO, item = ..Items.GetAt(key)
    If '$IsObject(item) Return ""
    Set found = $$$YES
    Return item.Document
}

Method ItemExists(key As %String) As %Boolean
{
    Return ..Items.IsDefined(key)
}

Method GetMainItem() As %DynamicObject
{
    Set item = ..Items.GetAt(..#MAINKEY)
    If '$IsObject(item) {
        Return ""
    }
    Return item
}

Method GetMainDocument() As %DynamicObject
{
    Set item = ..Items.GetAt(..#MAINKEY)
    If '$IsObject(item) {
        Return ""
    }
    Return item.Document
}

}
