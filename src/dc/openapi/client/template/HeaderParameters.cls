Class dc.openapi.client.template.HeaderParameters Extends dc.openapi.client.template.Parameters
{

XData DatatypeSimple [ MimeType = plain/text ]
{
    /// ex: X-MyHeader: 5
    Do {{HttpRequestObject}}.SetHeader("{{Name}}", ..{{ModelProperty.Name}})
}

XData ArraySimple [ MimeType = plain/text ]
{
    // X-MyHeader: 3,4,5
    Set tmpList =  ..{{ModelProperty.Name}}.Serialize()
    Do {{HttpRequestObject}}.SetHeader("{{Name}}", $ListToString(tmpList))
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
    Do {{HttpRequestObject}}.SetHeader("{{Name}}", parameterValue)
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
    Do {{HttpRequestObject}}.SetHeader("{{Name}}", parameterValue)
    Kill tmpString, tmpJSONObject, parameterValue, key, value
}

ClassMethod Decision(parameter As dc.openapi.common.ast.Parameter) As %String
{
    Set style = $s(parameter.Style="":"simple", 1:parameter.Style)  ; default is simple
    Set explode = parameter.Explode = 1
    Set type= $s(parameter.ModelProperty.Collection'="":"array",1:$$$LOWER(parameter.ModelProperty.TypeHelper))
    Set style = $$$LOWER(style), explode = $SELECT(explode="":"explode=true",explode=1:"explode=true",1:"explode=false")
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
