Class dc.openapi.client.template.CookieParameters Extends dc.openapi.client.template.Parameters
{

XData DatatypeSimple [ MimeType = plain/text ]
{
    Do {{HttpRequestObject}}.InsertCookie("{{Name}}", ..{{ModelProperty.Name}}, "/", {{HttpRequestObject}}.Server, "", 0)
}

XData ArraySimple [ MimeType = plain/text ]
{
    Do ..{{ModelProperty.Name}}.%SerializeObject(.tmpList)
    Set tmpList = $List(tmpList), valueParameter = $ListToString(tmpList)
    Do {{HttpRequestObject}}.InsertCookie("{{Name}}", valueParameter, "/", {{HttpRequestObject}}.Server, "", 0)
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
    Do {{HttpRequestObject}}.SetParam("{{Name}}", parameterValue)
    Do {{HttpRequestObject}}.InsertCookie("{{Name}}", valueParameter, "/", {{HttpRequestObject}}.Server, "", 0)
    Kill tmpString, tmpJSONObject, iterator, key, value, parameterValue
}

ClassMethod Decision(parameter As dc.openapi.common.ast.Parameter) As %String
{
    Set style = $s(parameter.Style="":"form", 1:parameter.Style)    ; default is form
    Set explode = $s(parameter.Explode="": 1, 1:parameter.Explode)  ; default is true
    Set type= $s(parameter.ModelProperty.Collection'="":"array",1:$$$LOWER(parameter.ModelProperty.TypeHelper))
    Set style = $$$LOWER(style), explode = $SELECT(explode="":"explode=true",explode=1:"explode=true",1:"explode=false")
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
