Include dc.openapi.common.macro

Class dc.openapi.client.generator.AbstractResponseClassGenerator Extends dc.openapi.common.GeneratorAbstract
{

Parameter NAME = "AbstractResponse";

Method GenerateAll() As %Status
{
    Set abstractResponseClass = ..Generate()
    Return abstractResponseClass.%Save()
}

Method Generate() As %Dictionary.ClassDefinition
{
    Set className = ..ClassName

    Set abstractResponseClass = ##class(%Dictionary.ClassDefinition).%New()
    Set abstractResponseClass.ProcedureBlock = $$$YES
    Set abstractResponseClass.Inheritance = "left"
    Set abstractResponseClass.Super = "%RegisteredObject"
    Set abstractResponseClass.Name = className

    Set contentBoundary = ##class(%Dictionary.PropertyDefinition).%New()
    Set contentBoundary.Name = "%ContentBoundary"
    Set contentBoundary.Type = "%String"
    Set contentBoundary.Description = "If specified the boundary signal for the Data"
    Do contentBoundary.Parameters.SetAt(2048,"MAXLEN")
    Do abstractResponseClass.Properties.Insert(contentBoundary)

    Set contentInfoProperty = ##class(%Dictionary.PropertyDefinition).%New()
    Set contentInfoProperty.Name = "%ContentInfo"
    Set contentInfoProperty.Type = "%String"
    Set contentInfoProperty.Description = "Additional information specified in the HTTP headers about the Data."
    Do contentInfoProperty.Parameters.SetAt(2048,"MAXLEN")
    Do abstractResponseClass.Properties.Insert(contentInfoProperty)

    Set contentLengthProperty = ##class(%Dictionary.PropertyDefinition).%New()
    Set contentLengthProperty.Name = "%ContentLength"
    Set contentLengthProperty.Type = "%Integer"
    Set contentLengthProperty.Description = "The length of the content in bytes"
    Do abstractResponseClass.Properties.Insert(contentLengthProperty)

    Set contentTypeProperty = ##class(%Dictionary.PropertyDefinition).%New()
    Set contentTypeProperty.Name = "%ContentType"
    Set contentTypeProperty.Type = "%String"
    Set contentTypeProperty.Description = "The Content-Type header for the operation"
    Do contentTypeProperty.Parameters.SetAt(256,"MAXLEN")
    Do abstractResponseClass.Properties.Insert(contentTypeProperty)

    Set dataProperty = ##class(%Dictionary.PropertyDefinition).%New()
    Set dataProperty.Name = "%Data"
    Set dataProperty.Type = "%Stream.GlobalBinary"
    Set dataProperty.Description = "The stream or a string contains all the data sent by the web server after the HTTP headers."
    Do abstractResponseClass.Properties.Insert(dataProperty)

    Set headersProperty = ##class(%Dictionary.PropertyDefinition).%New()
    Set headersProperty.Name = "%Headers"
    Set headersProperty.Type = "%String"
    Do headersProperty.Parameters.SetAt(4096,"MAXLEN")
    Set headersProperty.Collection = "array"
    Set headersProperty.Description = "The list of response headers for the operation"
    Do abstractResponseClass.Properties.Insert(headersProperty)

    Set reasonPhraseProperty = ##class(%Dictionary.PropertyDefinition).%New()
    Set reasonPhraseProperty.Name = "%ReasonPhrase"
    Set reasonPhraseProperty.Type = "%String"
    Do reasonPhraseProperty.Parameters.SetAt(4096,"MAXLEN")
    Set reasonPhraseProperty.Description = "The HTTP reason phrase response for the operation"
    Do abstractResponseClass.Properties.Insert(reasonPhraseProperty)

    Set statusCodeProperty = ##class(%Dictionary.PropertyDefinition).%New()
    Set statusCodeProperty.Name = "%StatusCode"
    Set statusCodeProperty.Type = "%Integer"
    Set statusCodeProperty.Description = "The HTTP status code response for the operation"
    Do abstractResponseClass.Properties.Insert(statusCodeProperty)

    Set statusLine = ##class(%Dictionary.PropertyDefinition).%New()
    Set statusLine.Name = "%StatusLine"
    Set statusLine.Type = "%String"
    Do statusLine.Parameters.SetAt(2048,"MAXLEN")
    Set statusLine.Description = "The HTTP status line. This is the first line of the response and signals if the request was successful or if there was a problem."
    Do abstractResponseClass.Properties.Insert(statusLine)

    Set fromHttpResponse = ##class(%Dictionary.MethodDefinition).%New()
    Set fromHttpResponse.Name = "%FromHttpResponse"
    Set fromHttpResponse.ReturnType = "%Status"
    Set fromHttpResponse.Description = "Load the properties from the HTTP response"
    Set fromHttpResponse.FormalSpec = "httpResponse:%Net.HttpResponse"
    
    Set template = ##class(dc.openapi.client.template.Response).ByName("CommonProperties")
    Do fromHttpResponse.Implementation.Write(template)
    Do abstractResponseClass.Methods.Insert(fromHttpResponse)

    Return abstractResponseClass
}

}
