Class dc.openapi.common.template.HeaderParameters Extends dc.openapi.common.template.Code
{

XData DatatypeSimple [ MimeType = plain/text ]
{
    /// ex: X-MyHeader: 5
    Do {{httpRequestObject}}.SetHeader("{{Name}}", ..{{ModelProperty.Name}})
}

XData ArraySimple [ MimeType = plain/text ]
{
    // X-MyHeader: 3,4,5
    Do ..{{ModelProperty.Name}}.%SerializeObject(.tmpList)
    Set tmpList = $List(tmpList)
    Do {{httpRequestObject}}.SetHeader("{{Name}}", $ListToString(tmpList))
    Kill tmpList
}

XData ObjectSimple [ MimeType = plain/text ]
{
    // example : Object {"role": "admin", "firstName": "Alex"}
    // X-MyHeader: role,admin,firstName,Alex

    Do ..{{ModelProperty.Name}}.%JSONExportToString(.tmpString)
    Set tmpJSONObject = {}.%FromJSON(tmpString)
    Set iterator = tmpJSONObject.%GetIterator(), parameterValue = ""
    While iterator.%GetNext(.key, .value) {
        Set parameterValue = parameterValue _ $s(parameterValue="":"",1:",") _ key_","_value
    }
    Do {{httpRequestObject}}.SetHeader("{{Name}}", parameterValue)
    Kill tmpString, tmpJSONObject, parameterValue, key, value
}

XData ObjectSimpleExplode [ MimeType = plain/text ]
{
    // example : Object {"role": "admin", "firstName": "Alex"}
    // X-MyHeader: role,admin,firstName,Alex

    Do ..{{ModelProperty.Name}}.%JSONExportToString(.tmpString)
    Set tmpJSONObject = {}.%FromJSON(tmpString)
    Set iterator = tmpJSONObject.%GetIterator(), parameterValue = ""
    While iterator.%GetNext(.key, .value) {
        Set parameterValue = parameterValue _ $s(parameterValue="":"",1:",") _ key_"="_value
    }
    Do {{httpRequestObject}}.SetHeader("{{Name}}", parameterValue)
    Kill tmpString, tmpJSONObject, parameterValue, key, value
}

ClassMethod Decision(type As %String, style As %String, explode As %Boolean) As %String
{
    Set type = $$$LOWER(type), style = $$$LOWER(style), explode = $SELECT(explode="":"explode=true",explode=1:"explode=true",1:"explode=false")
    Set:style="" style = "form"

    ; primitive 
    Set decision("datatype", "simple", "explode=true") = "DatatypeSimple"
    Set decision("datatype", "simple", "explode=false") = "DatatypeSimple"       ; same as explode=true

    ; array
    Set decision("array", "simple", "explode=true") = "ArraySimple"
    Set decision("array", "simple", "explode=false") = "ArraySimple"
    
    ; object
    Set decision("object", "simple", "explode=true") = "ObjectSimpleExplode"
    Set decision("object", "simple", "explode=false") = "ObjectSimple"

    Return $GET(decision(type, style, explode))
}

}
