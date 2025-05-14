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
    #dim requestBody As dc.openapi.common.ast.RequestBody = ""

    Set name = ""
    ; simple stream to add to the request body

    ; content-type application/json (or other json mime types)
    Set decision("array=false","json", "object") = "JSON"
    Set decision("array=true","json", "object") = "JSONList"
    
    ; x-www-form-urlencoded
    Set decision("application/x-www-form-urlencoded", "object") = "JSONFormURLEncoded"
    Set decision("application/x-www-form-urlencoded", "stream") = "Stream"
    
    Set decision("application/x-www-form-urlencoded", "datatype") = "FormURLEncoded"

    Set decision("multipart/form-data", "stream") = "todo"


    ; files
    ; type = string & format = binary (or base64)
    If requestBody.ModelProperty.TypeHelper = "stream" {
        Set name = "Stream"
    }

    Return name
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

XData DataType [ MimeType = text/plain ]
{
    If ..%ContentType = "{{ContentType}}" {
        Do {{httpRequestObject}}.EntityBody.Write({{ModelProperty.Name}})
    }
}

XData JSONFormURLEncoded [ MimeType = text/plain ]
{
    If ..%ContentType = "{{ContentType}}" {
        Do {{ModelProperty.Name}}.%JSONExportToString(.jsonString)
        Set jsonObj = {}.%FromJSON(.jsonString)
        Set iterator = jsonObj.%GetIterator()
        While iterator.%GetNext(.name, .value) {
            Do:{{httpRequestObject}}.EntityBody.Size>0 {{httpRequestObject}}.EntityBody.Write("&")
            Do {{httpRequestObject}}.EntityBody.Write(name _ "=" _ $$$URLENCODE(value))
        }
        Kill iterator, jsonString, jsonObj, name, value
    }
}

XData FormURLEncoded [ MimeType = text/plain ]
{
    If ..%ContentType = "{{ContentType}}" {
        Do:{{httpRequestObject}}.EntityBody.Size>0 {{httpRequestObject}}.EntityBody.Write("&")
        Do {{httpRequestObject}}.EntityBody.Write({{Name}} _ "=" _ $$$URLENCODE({{ModelProperty.Name}}))
    }
}

XData FormDataStream [ MimeType = text/plain ]
{
    If ..%ContentType = "{{ContentType}}" {
        Set valueStream = ##class(%Stream.GlobalBinary).%New()
        Do valueStream.CopyFrom({{ModelProperty.Name}})
        Set mParts = ##class(%Net.MIMEPart).%New()
        Set mimePart = ##class(%Net.MIMEPart).%New(valueStream)
        Do mimePart.SetHeader("Content-Disposition", "form-data; name=""{{Name}}""; filename=""{{Name}}""")
        Do mParts.Parts.Insert(mimePart)
        Set mimeWriter = ##class(%Net.MIMEWriter).%New()
        Do mimeWriter.OutputToStream({{httpRequestObject}}.EntityBody)
        Do mimeWriter.WriteMIMEBody(mParts)
        Kill mimeWriter, mimePart, mParts, valueStream
    }
}

}
