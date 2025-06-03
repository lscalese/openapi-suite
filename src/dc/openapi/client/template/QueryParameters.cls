Class dc.openapi.client.template.QueryParameters Extends dc.openapi.client.template.Parameters
{

XData DatatypeForm [ MimeType = plain/text ]
{
    // Serialize the parameter {{{Name}}}, ex path = /path?{{Name}}=1234
    Do {{HttpRequestObject}}.SetParam("{{Name}}", ..{{ModelProperty.Name}})
}

XData ArrayFormExplode [ MimeType = plain/text ]
{
    // Serialize the parameter list{{{Name}}}, ex path = /path?{{Name}}=1234&{{Name}}=5678
    Set tmpList = ..{{ModelProperty.Name}}.Serialize(), ptr = 0
    While $ListNext(tmpList, ptr, itemValue) {
        Do {{HttpRequestObject}}.InsertParam("{{Name}}", itemValue)
    }
    Kill tmpList, ptr, itemValue
}

XData ArrayForm [ MimeType = plain/text ]
{
    // Serialize the parameter list{{{Name}}}, ex path = /path?{{Name}}=1234,5678
    Set tmpList =  ..{{ModelProperty.Name}}.Serialize(), ptr = 0, valueParameter = ""
    While $ListNext(tmpList, ptr, itemValue) {
        Set valueParameter = valueParameter _ $s(valueParameter="":"",1:",") _ itemValue
    }
    Do {{HttpRequestObject}}.SetParam("{{Name}}", valueParameter)
    Kill tmpList, ptr, itemValue, valueParameter
}

XData ArraySpaceDelimited [ MimeType = plain/text ]
{
    // Serialize the parameter list{{{Name}}}, ex path = /path?{{Name}}=1234%205678
    Set tmpList =  ..{{ModelProperty.Name}}.Serialize(), ptr = 0, valueParameter = ""
    While $ListNext(tmpList, ptr, itemValue) {
        Set valueParameter = valueParameter _ $s(valueParameter="":"",1:" ") _ itemValue
    }
    Do {{HttpRequestObject}}.SetParam("{{Name}}", valueParameter)
    Kill tmpList, ptr, itemValue, valueParameter
}

XData ArrayPipeDelimited [ MimeType = plain/text ]
{

    // Serialize the parameter list{{{Name}}}, ex path = /path?{{Name}}=1234|5678
    Set tmpList =  ..{{ModelProperty.Name}}.Serialize(), ptr = 0, valueParameter = ""
    While $ListNext(tmpList, ptr, itemValue) {
        Set valueParameter = valueParameter _ $s(valueParameter="":"",1:"|") _ itemValue
    }
    Do {{HttpRequestObject}}.SetParam("{{Name}}", valueParameter)
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
        Do {{HttpRequestObject}}.SetParam(key, value)
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
    Do {{HttpRequestObject}}.SetParam("{{Name}}", parameterValue)
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
        Do {{HttpRequestObject}}.SetParam("{{Name}}["_key_"], value)
    }
    Kill tmpString, tmpJSONObject, iterator, key, value
}

ClassMethod Decision(parameter As dc.openapi.common.ast.Parameter) As %String
{
    Set style = $s(parameter.Style="":"form", 1:parameter.Style)    ; default is form
    Set explode = $s(parameter.Explode="": 1, 1:parameter.Explode)  ; default is true
    Set type= $s(parameter.ModelProperty.Collection'="":"array",1:$$$LOWER(parameter.ModelProperty.TypeHelper))
    Set style = $$$LOWER(style), explode = $SELECT(explode="":"explode=true",explode=1:"explode=true",1:"explode=false")
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
