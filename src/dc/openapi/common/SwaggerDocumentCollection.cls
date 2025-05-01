Class dc.openapi.common.SwaggerDocumentCollection Extends %RegisteredObject
{

Property Items As array Of dc.openapi.common.SwaggerDocumentReference;

Method AddItem(document As %DynamicObject, key As %String, isAFullSpecification As %Boolean = "") As %Status
{
    Set item = ##class(dc.openapi.common.SwaggerDocumentReference).%New()
    Set item.Document = document
    Set item.Key = key

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

}
