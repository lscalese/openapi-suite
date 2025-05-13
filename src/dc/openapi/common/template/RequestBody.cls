Class dc.openapi.common.template.RequestBody Extends dc.openapi.common.template.Code
{

ClassMethod GetTemplateByRB(requestBody As dc.openapi.common.ast.RequestBody) As %String
{

    ;Set decision("mimeType", "type") = ""
    Set decision("application/x-www-form-urlencoded", "object") = "todo"
    Set decision("application/x-www-form-urlencoded", "stream") = "todo"
    Set decision("application/x-www-form-urlencoded", "datatype") = "todo"

    If requestBody.ModelProperty.TypeHelper = "stream" {
        Return ..ByName("Stream")
    }
    
    If ##class(dc.openapi.common.Utils).isJsonMimeType(requestBody.ContentType) {
        If requestBody.ModelProperty.Collection = "list" {
            Return ..ByName("JSONList")
        }
        Return ..ByName("JSON")
    }

    Return ""
}

ClassMethod Decision() As %String
{
    Set decision("array=false","*JSON*", "object") = "JSON"
    Set decision("array=true","*JSON*", "object") = "JSONList"
    
    Set decision("application/x-www-form-urlencoded", "object") = "todo"
    Set decision("application/x-www-form-urlencoded", "stream") = "Stream"
    Set decision("application/x-www-form-urlencoded", "datatype") = "todo"

    Set decision("multipart/form-data", "stream") = "todo"
}

XData JSON [ MimeType = text/plain ]
{
    If ..%ContentType = "{{ContentType}}"{
        Do ..{{ModelProperty.Name}}.%JSONExportToStream({{httpRequestObject}}.EntityBody)
    }
}

XData JSONList [ MimeType = text/plain ]
{
    If ..%ContentType = "{{ContentType}}" {
        Do {{httpRequestObject}}.EntityBody.Write("["")
        Set key = "", addComma = 0
        For  {
            Set currentObject = ..{{ModelProperty.Name}}.GetNext(.key)
            Quit:key=""
            Do:addComma {{httpRequestObject}}.EntityBody.Write(",")
            Do currentObject.%JSONExportToStream({{httpRequestObject}}.EntityBody)
            Set:'addComma addComma = 1
        }
        Do {{httpRequestObject}}.EntityBody.Write("]")
    }
    Kill addComma, key, currentObject
}

XData Stream [ MimeType = text/plain ]
{
    If ..%ContentType = "{{ContentType}}" {
        Do {{ModelProperty.Name}}.Rewind()
        Do {{httpRequestObject}}.EntityBody.CopyFrom({{ModelProperty.Name}})
    }
}

}
