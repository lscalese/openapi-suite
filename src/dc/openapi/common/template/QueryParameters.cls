Class dc.openapi.common.template.QueryParameters Extends dc.openapi.common.template.Code
{

XData DatatypeForm [ MimeType = plain/text ]
{
    // Serialize the parameter {{{Name}}}, ex path = /path?{{Name}}=1234
    Do {{httpRequestObject}}.SetParam("{{Name}}", ..{{ModelProperty.Name}})
}

XData ArrayFormExplode [ MimeType = plain/text ]
{
    // Serialize the parameter list{{{Name}}}, ex path = /path?{{Name}}=1234&{{Name}}=5678
    Do ..{{ModelProperty.Name}}.%SerializeObject(.tmpList)
    Set tmpList = $List(tmpList), ptr = 0, index = 0
    While $ListNext(tmpList, ptr, itemValue) {
        Do {{httpRequestObject}}.SetParam("{{Name}}", itemValue, $Increment(index))
    }
    Kill tmpList, ptr, index, itemValue
}

XData ArrayForm [ MimeType = plain/text ]
{
    // Serialize the parameter list{{{Name}}}, ex path = /path?{{Name}}=1234,5678
    Do ..{{ModelProperty.Name}}.%SerializeObject(.tmpList)
    Set tmpList = $List(tmpList), ptr = 0, valueParameter = ""
    While $ListNext(tmpList, ptr, itemValue) {
        Set valueParameter = valueParameter _ $s(valueParameter="":"",1:",") _ itemValue
    }
    Do {{httpRequestObject}}.SetParam("{{Name}}", valueParameter)
    Kill tmpList, ptr, itemValue, valueParameter
}

XData ArraySpaceDelimited [ MimeType = plain/text ]
{
    // Serialize the parameter list{{{Name}}}, ex path = /path?{{Name}}=1234%205678
    Do ..{{ModelProperty.Name}}.%SerializeObject(.tmpList)
    Set tmpList = $List(tmpList), ptr = 0, valueParameter = ""
    While $ListNext(tmpList, ptr, itemValue) {
        Set valueParameter = valueParameter _ $s(valueParameter="":"",1:" ") _ itemValue
    }
    Do {{httpRequestObject}}.SetParam("{{Name}}", valueParameter)
    Kill tmpList, ptr, itemValue, valueParameter
}

XData ArrayPipeDelimited [ MimeType = plain/text ]
{
    // Serialize the parameter list{{{Name}}}, ex path = /path?{{Name}}=1234|5678
    Do ..{{ModelProperty.Name}}.%SerializeObject(.tmpList)
    Set tmpList = $List(tmpList), ptr = 0, valueParameter = ""
    While $ListNext(tmpList, ptr, itemValue) {
        Set valueParameter = valueParameter _ $s(valueParameter="":"",1:"|") _ itemValue
    }
    Do {{httpRequestObject}}.SetParam("{{Name}}", valueParameter)
    Kill tmpList, ptr, itemValue, valueParameter
}

XData ObjectFormExplode [ MimeType = plain/text ]
{
    // example : Object id = {"role": "admin", "firstName": "Alex"}
    // /users?role=admin&firstName=Alex

    Do ..{{ModelProperty.Name}}.%JSONExportToString(.tmpString)
    Set tmpJSONObject = {}.%FromJSON(tmpString)
    Set iterator = tmpJSONObject.%GetIterator()
    While iterator.%GetNext(.key, .value) {
        Do {{httpRequestObject}}.SetParam(key, value)
    }
    Kill tmpString, tmpJSONObject, iterator, key, value
}

XData ObjectForm [ MimeType = plain/text ]
{
    // example : Object id = {"role": "admin", "firstName": "Alex"}
    // /users?id=role,admin,firstName,Alex

    Do ..{{ModelProperty.Name}}.%JSONExportToString(.tmpString)
    Set tmpJSONObject = {}.%FromJSON(tmpString), parameterValue = ""
    Set iterator = tmpJSONObject.%GetIterator()
    While iterator.%GetNext(.key, .value) {
        Set parameterValue = parameterValue _ $s(parameterValue="":"",1:",") _ key_","_value
    }
    Do {{httpRequestObject}}.SetParam("{{Name}}", parameterValue)
    Kill tmpString, tmpJSONObject, iterator, key, value, parameterValue
}

XData ObjectDeepObjectExplode [ MimeType = plain/text ]
{
    // example : Object id = {"role": "admin", "firstName": "Alex"}
    // /users?role=admin&firstName=Alex

    Do ..{{ModelProperty.Name}}.%JSONExportToString(.tmpString)
    Set tmpJSONObject = {}.%FromJSON(tmpString)
    Set iterator = tmpJSONObject.%GetIterator()
    While iterator.%GetNext(.key, .value) {
        Do {{httpRequestObject}}.SetParam("{{Name}}["_key_"], value)
    }
    Kill tmpString, tmpJSONObject, iterator, key, value
}

ClassMethod Decision(type As %String, style As %String, explode As %Boolean) As %String
{
    Set type = $$$LOWER(type), style = $$$LOWER(style), explode = $SELECT(explode="":"explode=true",explode=1:"explode=true",1:"explode=false")
    Set:style="" style = "form"

    ; primitive 
    Set decision("datatype", "form", "explode=true") = "DatatypeForm"
    Set decision("datatype", "form", "explode=false") = "DatatypeForm"                          ; same as explode=true

    ; array
    Set decision("array", "form", "explode=true") = "ArrayFormExplode"
    Set decision("array", "form", "explode=false") = "ArrayForm"
    Set decision("array", "spaceDelimited", "explode=true") = "ArrayFormExplode"                ; same as form
    Set decision("array", "spaceDelimited", "explode=false") = "ArraySpaceDelimited"
    Set decision("array", "pipeDelimited", "explode=true") = "ArrayFormExplode"                 ; same as form
    Set decision("array", "pipeDelimited", "explode=false") = "ArrayPipeDelimited"
    
    ; object
    Set decision("object", "form", "explode=true") = "ObjectFormExplode"
    Set decision("object", "form", "explode=false") = "ObjectForm"
    Set decision("object", "deepObject", "explode=true") = "ObjectDeepObjectExplode"


    Return $GET(decision(type, style, explode))
}

}
