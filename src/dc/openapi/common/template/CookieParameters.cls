Class dc.openapi.common.template.CookieParameters Extends dc.openapi.common.template.Code
{

XData DatatypeSimple [ MimeType = plain/text ]
{
    Do {{httpRequestObject}}.InsertCookie("{{Name}}", ..{{ModelProperty.Name}}, "/", {{httpRequestObject}}.Server, "", 0)
}

XData ArraySimple [ MimeType = plain/text ]
{
    Do ..{{ModelProperty.Name}}.%SerializeObject(.tmpList)
    Set tmpList = $List(tmpList), valueParameter = $ListToString(tmpList)
    Do {{httpRequestObject}}.InsertCookie("{{Name}}", valueParameter, "/", {{httpRequestObject}}.Server, "", 0)
    Kill tmpList, valueParameter
}

XData ObjectSimple [ MimeType = plain/text ]
{
    Do ..{{ModelProperty.Name}}.%JSONExportToString(.tmpString)
    Set tmpJSONObject = {}.%FromJSON(tmpString), parameterValue = ""
    Set iterator = tmpJSONObject.%GetIterator()
    While iterator.%GetNext(.key, .value) {
        Set parameterValue = parameterValue _ $s(parameterValue="":"",1:",") _ key_","_value
    }
    Do {{httpRequestObject}}.SetParam("{{Name}}", parameterValue)
    Do {{httpRequestObject}}.InsertCookie("{{Name}}", valueParameter, "/", {{httpRequestObject}}.Server, "", 0)
    Kill tmpString, tmpJSONObject, iterator, key, value, parameterValue
}

ClassMethod Decision(type As %String, style As %String, explode As %Boolean) As %String
{
    Set type = $$$LOWER(type), style = $$$LOWER(style), explode = $SELECT(explode="":"explode=true",explode=1:"explode=true",1:"explode=false")
    Set:style="" style = "form"

    ; primitive 
    Set decision("datatype", "form", "explode=true") = "DatatypeSimple"
    Set decision("datatype", "form", "explode=false") = "DatatypeSimple"

    ; array
    Set decision("array", "form", "explode=false") = "ArraySimple"
    
    ; object
    Set decision("object", "simple", "explode=false") = "ObjectSimple"

    Return $GET(decision(type, style, explode))
}

}
