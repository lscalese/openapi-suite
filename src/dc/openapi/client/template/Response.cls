Class dc.openapi.client.template.Response Extends dc.openapi.common.template.Code
{

ClassMethod Decision(response As dc.openapi.common.ast.Response) As %String
{
    If '$IsObject(response.ModelProperty) {
        Return ""
    }

    Set array = $Select(response.ModelProperty.Collection'="":"array=true",1:"array=false")

    Set isJsonMimeType =##class(dc.openapi.common.Utils).isJsonMimeType(response.ContentType)

    If isJsonMimeType {
        Set mimeType = "json"
    }
    Else {
        Set mimeType = response.ContentType
    }

    Set default = $Select(response.StatusCode="default":"default=true",1:"default=false")

    Set decision("array=false", "json", "object","default=false") = "JSONObject"
    Set decision("array=false", "json", "object","default=true") = "JSONObjectDefault"
    Set decision("array=true", "json", "object","default=false") = "JSONList"

    Set decision("array=false", "json", "datatype","default=false") = "DataType"
    Set decision("array=false", "json", "datatype","default=true") = "DataTypeDefault"

    Return $Get(decision(array, mimeType, response.ModelProperty.TypeHelper, default))
}

/// %FromHttpResponse method in subclass of AbstractResponse
XData FromHttpResponse [ MimeType = plain/text ]
{
    Set sc = $$$OK
    Try {
        $$$TOE(sc, ##super(httpResponse))
        
        ; This flag is used to determine if the default response should be loaded
        ; It remains $$$YES only if no specific response status code handler is matched
        Set useDefault = $$$YES
        
        {{ResponseCode}}

    }
    Catch ex {
        Set sc = ex.AsStatus()
    }
    Return sc
}

XData DataType [ MimeType = plain/text ]
{
        If ..%StatusCode = "{{StatusCode}}" && (..%ContentType = "{{ContentType}}") {
            Set useDefault = $$$NO
            Set ..{{ModelProperty.Name}} = ..%Data.Read()
        }
}

XData DataTypeDefault [ MimeType = plain/text ]
{
        If useDefault && (..%ContentType = "{{ContentType}}") {
            Set useDefault = $$$NO
            Set ..{{ModelProperty.Name}} = ..%Data.Read()
        }
}

XData JSONObject [ MimeType = plain/text ]
{
        If ..%StatusCode = "{{StatusCode}}" && (..%ContentType = "{{ContentType}}") {
            Set useDefault = $$$NO
            Set ..{{ModelProperty.Name}} = ##class({{ModelProperty.Type}}).%New()
            Do ..{{ModelProperty.Name}}.%JSONImport(..%Data)
        }
}

XData JSONObjectDefault [ MimeType = plain/text ]
{
        If useDefault && (..%ContentType = "{{ContentType}}") {
            Set ..{{ModelProperty.Name}} = ##class({{ModelProperty.Type}}).%New()
            Do ..{{ModelProperty.Name}}.%JSONImport(..%Data)
        }
}

XData JSONList [ MimeType = plain/text ]
{
        If ..%StatusCode = "{{StatusCode}}" && (..%ContentType = "{{ContentType}}") {
            Set useDefault = $$$NO
            Set array = [].%FromJSON(..%Data)
            Set iterator = array.%GetIterator()
            While iterator.%GetNext(.key, .value) {
                Set currentObject = ##class({{ModelProperty.Type}}).%New()
                Do currentObject.%JSONImport(value)
                Do ..{{ModelProperty.Name}}.%Insert(currentObject)
            }
            Kill iterator, key, value, currentObject, array
        }
}

/// Load common properties from the HTTP response
/// used by the %FromHttpResponse method in the AbstractResponse class
XData CommonProperties [ MimeType = plain/text ]
{
    Set sc = $$$OK

    Set ..%ContentBoundary = httpResponse.ContentBoundary
    Set ..%ContentInfo = httpResponse.ContentInfo
    Set ..%ContentType = httpResponse.ContentType
    Set ..%ContentLength = httpResponse.ContentLength
    Set ..%ReasonPhrase = httpResponse.ReasonPhrase
    Set ..%StatusCode = httpResponse.StatusCode
    Set ..%StatusLine = httpResponse.StatusLine
    
    Set headerName = ""
    For {
        Set headerName = $Order(httpResponse.Headers(headerName), 1, headerValue)
        Quit:headerName=""
        Do ..%Headers.Set(headerValue, headerName)
    }

    If '$IsObject(..HttpResponse.Data) { 
        Do ..%Data.Write(httpResponse.Data)
    }
    Else {
        Do ..%Data.CopyFrom(httpResponse.Data)
    }
    
    Return sc
}

}
