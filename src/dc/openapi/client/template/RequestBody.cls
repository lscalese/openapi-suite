Class dc.openapi.client.template.RequestBody Extends dc.openapi.common.template.Code
{

ClassMethod Decision(requestBody As dc.openapi.common.ast.RequestBody) As %String
{
    If requestBody.ModelProperty.TypeHelper = "" || (requestBody.ContentType = "") {
        Return ""
    }

    Set array = $select(requestBody.ModelProperty.Collection'="":"array=true", 1:"array=false")
    
    Set mimeType = requestBody.ContentType
    If ##class(dc.openapi.common.Utils).isJsonMimeType(mimeType) {
        Set mimeType = "json"
    }

    Set type = requestBody.ModelProperty.TypeHelper

    
    ; simple stream to add to the request body

    ; content-type application/json (or other json mime types)
    Set decision("array=false", "json", "object") = "JSON"
    Set decision("array=true", "json", "object") = "JSONList"
    Set decision("array=false", "json", "stream") = "Stream"
    Set decision("array=true", "json", "stream") = "Stream"
    Set decision("array=false", "json", "datatype") = "JSONString"
    Set decision("array=true", "json", "datatype") = "JSONString"
    
    
    ; x-www-form-urlencoded
    Set decision("array=false", "application/x-www-form-urlencoded", "object") = "JSONFormURLEncoded"
    Set decision("array=false", "application/x-www-form-urlencoded", "stream") = "Stream"
    Set decision("array=false", "application/x-www-form-urlencoded", "datatype") = "FormData"
    Set decision("array=true", "application/x-www-form-urlencoded", "datatype") = "FormDataList"
    

    ; attach file
    Set decision("array=false", "multipart/form-data", "stream") = "FormDataStream"
    Set decision("array=true", "multipart/form-data", "stream") = "FormDataListStream"
    
    ; multipart/form-data with object
    Set decision("array=false", "multipart/form-data", "object") = "FormDataObject"

    Return $Get(decision(array, mimeType, type))
}

XData JSON [ MimeType = text/plain ]
{
    If ..%ContentType = "{{ContentType}}"{
        Do ..{{ModelProperty.Name}}.%JSONExportToStream({{HttpRequestObject}}.EntityBody)
    }
}

XData JSONString [ MimeType = text/plain ]
{
    If ..%ContentType = "{{ContentType}}" {
        Do {{HttpRequestObject}}.EntityBody.Write({{ModelProperty.Name}})
    }
}

XData JSONList [ MimeType = text/plain ]
{
    If ..%ContentType = "{{ContentType}}" {
        Do {{HttpRequestObject}}.EntityBody.Write("["")
        Set key = "", addComma = 0
        For  {
            Set currentObject = ..{{ModelProperty.Name}}.GetNext(.key)
            Quit:key=""
            Do:addComma {{HttpRequestObject}}.EntityBody.Write(",")
            Do currentObject.%JSONExportToStream({{HttpRequestObject}}.EntityBody)
            Set:'addComma addComma = 1
        }
        Do {{HttpRequestObject}}.EntityBody.Write("]")
    }
    Kill addComma, key, currentObject
}

XData Stream [ MimeType = text/plain ]
{
    If ..%ContentType = "{{ContentType}}" {
        Do {{ModelProperty.Name}}.Rewind()
        Do {{HttpRequestObject}}.EntityBody.CopyFrom({{ModelProperty.Name}})
    }
}

XData DataType [ MimeType = text/plain ]
{
    If ..%ContentType = "{{ContentType}}" {
        Do {{HttpRequestObject}}.EntityBody.Write({{ModelProperty.Name}})
    }
}

XData JSONFormURLEncoded [ MimeType = text/plain ]
{
    If ..%ContentType = "{{ContentType}}" {
        Do {{ModelProperty.Name}}.%JSONExportToString(.jsonString)
        Set jsonObj = {}.%FromJSON(.jsonString)
        Set iterator = jsonObj.%GetIterator()
        While iterator.%GetNext(.name, .value) {
            Do:{{HttpRequestObject}}.EntityBody.Size>0 {{HttpRequestObject}}.EntityBody.Write("&")
            Do {{HttpRequestObject}}.EntityBody.Write(name _ "=" _ $$$URLENCODE(value))
        }
        Kill iterator, jsonString, jsonObj, name, value
    }
}

XData FormURLEncoded [ MimeType = text/plain ]
{
    If ..%ContentType = "{{ContentType}}" {
        Do:{{HttpRequestObject}}.EntityBody.Size>0 {{HttpRequestObject}}.EntityBody.Write("&")
        Do {{HttpRequestObject}}.EntityBody.Write({{Name}} _ "=" _ $$$URLENCODE({{ModelProperty.Name}}))
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
        Do mimeWriter.OutputToStream({{HttpRequestObject}}.EntityBody)
        Do mimeWriter.WriteMIMEBody(mParts)
        Kill mimeWriter, mimePart, mParts, valueStream
    }
}

XData FormDataListStream [ MimeType = text/plain ]
{
    If ..%ContentType = "{{ContentType}}" {
        Set mParts = ##class(%Net.MIMEPart).%New()
        Set key = ""
        For  {
            Set currentStreamObject = ..{{ModelProperty.Name}}.GetNext(.key)
            Quit:key=""
            Set valueStream = ##class(%Stream.GlobalBinary).%New()
            Do valueStream.CopyFrom(currentStreamObject)
            Set mimePart = ##class(%Net.MIMEPart).%New(valueStream)
            Set fName = "{{Name}}_" _ key
            Do mimePart.SetHeader("Content-Disposition", "form-data; name=""{{Name}}""; filename="""_fName_"""")
            Do mParts.Parts.Insert(mimePart)
            Kill valueStream, currentStreamObject, mimePart
        }
        Set mimeWriter = ##class(%Net.MIMEWriter).%New()
        Do mimeWriter.OutputToStream({{HttpRequestObject}}.EntityBody)
        Do mimeWriter.WriteMIMEBody(mParts)
        Kill mimeWriter, mParts
    }
}

/// multipart/form-data
XData FormDataObject [ MimeType = text/plain ]
{
    If ..%ContentType = "{{ContentType}}" {
        Set sourceClass = $classname({{ModelProperty}}), propertyName = ""
        Set mParts = ##class(%Net.MIMEPart).%New()
        For  {
            Set propertyName = $Order(^oddCOM(sourceClass, $$$cCLASSproperty, propertyName))
            Quit:propertyName=""
            Continue:$Extract(propertyName)="%"  
            Set propertyClass = $$$comMemberKeyGet(sourceClass,$$$cCLASSproperty,propertyName,$$$cPROPtype)
            Try {
                Set propertyValue = $Property(InputObject, propertyName)
            } Catch ex {
                Set tScPropertyValue = ex.AsStatus()
                If $SYSTEM.Status.GetErrorText(tScPropertyValue) [ "PRIVATE" {
                    ; it's a private property, ignore it and continue
                    Continue
                }
                Else {
                    Throw ex
                }
            }
            Set valueStream = ##class(%Stream.GlobalBinary).%New()
            Set mimePart = ##class(%Net.MIMEPart).%New(valueStream)            
            If '$IsObject(propertyValue) {
                Set valueStream.Write($ZConvert(property, "O", "UTF8"))
                Do mimePart.SetHeader("Content-Disposition", "form-data; name=""" _ propertyName _ """")
            }
            ElseIf propertyValue.%IsA("%Stream.Object") {
                Do valueStream.CopyFrom(propertyValue)
                Do mimePart.SetHeader("Content-Disposition", "form-data; name="""_ propertyName _"""; filename=""" _ propertyName _ """")
            }
            Else {
                $$$ThrowStatus($$$ERROR($$$NotImplemented))
            }
            Do mParts.Parts.Insert(mimePart)
            Kill valueStream, currentStreamObject, mimePart
        }
        Set mimeWriter = ##class(%Net.MIMEWriter).%New()
        Do mimeWriter.OutputToStream({{HttpRequestObject}}.EntityBody)
        Do mimeWriter.WriteMIMEBody(mParts)
        Kill mimeWriter, mParts
    }
}

/// application/x-www-form-urlencoded
XData FormData [ MimeType = text/plain ]
{
    If ..%ContentType = "{{ContentType}}" {
        Do {{HttpRequestObject}}.InsertFormData("{{ModelProperty.pJSONFieldName}}", {{ModelProperty.Name}})
    }
}

/// application/x-www-form-urlencoded
XData FormDataList [ MimeType = text/plain ]
{
    If ..%ContentType = "{{ContentType}}" {
        Set key = ""
        For  {
            Set item = ..{{ModelProperty.Name}}.GetNext(.key)
            Quit:key=""
            Do {{HttpRequestObject}}.InsertFormData("{{ModelProperty.pJSONFieldName}}", item)
        }
        Kill key, item
    }
}

}
