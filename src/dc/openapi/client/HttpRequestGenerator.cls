Class dc.openapi.client.HttpRequestGenerator Extends %RegisteredObject
{

Property AST As dc.openapi.common.ast.OAS;

Property Package As %String [ InitialExpression = "testclient" ];

Property httpClientClass As %Dictionary.ClassDefinition [ Private ];

Method Generate() As %Status
{
    Set sc = ..GenerateHttpClientRequest()

    Set key = ""
    For  {
        Set path = ..AST.Paths.GetNext(.key)
        Quit:key=""
        Set sc = $$$ADDSC(sc, ..GenerateRequestClassModel(path))
    }
    Return sc
}

Method GenerateHttpClientRequest() As %Status
{
    Set (..httpClientClass, httpClientClass) = ##class(%Dictionary.ClassDefinition).%New()
    Set httpClientClass.ProcedureBlock = $$$YES
    Set httpClientClass.Inheritance = "left"
    Set httpClientClass.Super = "%RegisteredObject"
    Set httpClientClass.Name = ..Package _ ".HttpClient"

    Set httpClientClass.Description = "HTTP Client for: " _ ..AST.Info.Title_$c(13) 
        _ "/// Version: " _ ..AST.Info.Version_$c(13) 
        _ "/// Description: " _ ##class(dc.openapi.common.Utils).FormatDescription(..AST.Info.Description)

    
    #dim server As dc.openapi.common.ast.Server
    Set key = ""
    For  {
        Set server = ..AST.Servers.GetNext(.key)
        Quit:key=""
        Set parameter = ##class(%Dictionary.ParameterDefinition).%New()
        Set parameter.Name = "SERVER" _ key
        Set parameter.Default = server.Url
        Set parameter.Description = ##class(dc.openapi.common.Utils).FormatDescription(server.Description)
        Do httpClientClass.Parameters.Insert(parameter)
    }

    Set ServerProperty = ##class(%Dictionary.PropertyDefinition).%New()
    Set ServerProperty.Name = "Server"
    Set ServerProperty.Type = "%String"
    Set ServerProperty.Description = "Server URL, ex: http://localhost:8080/basepath, https:username:password@localhost:8080/basepath"
    Do httpClientClass.Properties.Insert(ServerProperty)

    Set SSLConfigProperty = ##class(%Dictionary.PropertyDefinition).%New()
    Set SSLConfigProperty.Name = "SSLConfiguration"
    Set SSLConfigProperty.Type = "%String"
    Set SSLConfigProperty.Description = "SSL Configuration name, used if https is used"
    Do httpClientClass.Properties.Insert(SSLConfigProperty)

    Set HttpRequestProperty = ##class(%Dictionary.PropertyDefinition).%New()
    Set HttpRequestProperty.Name = "HttpRequest"
    Set HttpRequestProperty.Type = "%Net.HttpRequest"
    Set HttpRequestProperty.Description = "HTTP Request object"
    Set HttpRequestProperty.InitialExpression = "##class(%Net.HttpRequest).%New()"
    Do httpClientClass.Properties.Insert(HttpRequestProperty)

    Set BasePathProperty = ##class(%Dictionary.PropertyDefinition).%New()
    Set BasePathProperty.Name = "BasePath"
    Set BasePathProperty.Type = "%String"
    Set BasePathProperty.Description = "Base path for the API, ex: /api/v1 (can be set in the server URL)"
    Do httpClientClass.Properties.Insert(BasePathProperty)


    Set PrepareMethod = ##class(%Dictionary.MethodDefinition).%New()
    Set PrepareMethod.Name = "%Prepare"
    Set PrepareMethod.Description = "Prepare the HttpRequest Object"
    Set PrepareMethod.ReturnType = "%Status"
    Set code = ##class(%Dictionary.CompiledXData).%OpenId($classname() _ "||%PrepareMethod").Data
    Do PrepareMethod.Implementation.CopyFrom(code)
    Do httpClientClass.Methods.Insert(PrepareMethod)

    Return httpClientClass.%Save()
}

Method GenerateRequestClassModel(path As dc.openapi.common.ast.Path) As %Status
{
    Set requestClassModel = ##class(%Dictionary.ClassDefinition).%New()
    Set requestClassModel.ProcedureBlock = $$$YES
    Set requestClassModel.Inheritance = "left"
    Set requestClassModel.Super = "%RegisteredObject"
    Set requestClassModel.Name = ..Package _ ".request." _ path.OperationId

    Set pathParameter = ##class(%Dictionary.ParameterDefinition).%New()
    Set pathParameter.Name = "PATH"
    Set pathParameter.Default = path.Path
    Set pathParameter.Description = "Path for the operation, ex: /user/{userId}"
    Do requestClassModel.Parameters.Insert(pathParameter)

    Set pathProperty = ##class(%Dictionary.PropertyDefinition).%New()
    Set pathProperty.Name = "Path"
    Set pathProperty.Type = "%String"
    Set pathProperty.InitialExpression = "..#PATH"
    Set pathProperty.Description = "The resolved path for the operation, ex: /user/{userId} --> /user/1"
    Do requestClassModel.Properties.Insert(pathProperty)

    Set acceptProperty = ##class(%Dictionary.PropertyDefinition).%New()
    Set acceptProperty.Name = "%Accept"
    Set acceptProperty.Type = "%String"
    Set acceptProperty.InitialExpression = "application/json"
    Set acceptProperty.Description = "The Accept header for the operation, ex: application/json"
    Do requestClassModel.Properties.Insert(acceptProperty)

    Set contentTypeProperty = ##class(%Dictionary.PropertyDefinition).%New()
    Set contentTypeProperty.Name = "%ContentType"
    Set contentTypeProperty.Type = "%String"
    Set contentTypeProperty.InitialExpression = "application/json"
    Set contentTypeProperty.Description = "The Content-Type header for the operation, ex: application/json"
    Do requestClassModel.Properties.Insert(contentTypeProperty)



    #dim parameter As dc.openapi.common.ast.Parameter
    Set key = ""
    For  {
        Set parameter = path.Parameters.GetNext(.key)
        Quit:key=""

        Set propertyDef = ##class(dc.openapi.common.ModelGenerator).GetPropertyDefinition(parameter.ModelProperty)
        Do requestClassModel.Properties.Insert(propertyDef)
    }

    Do requestClassModel.Methods.Insert(..GetBuildRequestMethod(path))

    Return requestClassModel.%Save()
}

ClassMethod GetBuildRequestMethod(path As dc.openapi.common.ast.Path) As %String
{
    Set methodDefinition = ##class(%Dictionary.MethodDefinition).%New()
    Set methodDefinition.Name = "BuildRequest"
    Set methodDefinition.Description = "Build the HTTP request for the operation"
    Set methodDefinition.ReturnType = "%Status"
    Set methodDefinition.FormalSpec= "&httpRequest:%Net.HttpRequest"

    #dim parameter As dc.openapi.common.ast.Parameter
    Set PathParameterCode = "", QueryParameterCode = "", HeaderParameterCode = ""
    
    Set key = ""
    For  {
        Set parameter = path.Parameters.GetNext(.key)
        Quit:key=""
        
        If parameter.In = "path" {
            Set inPath = ##class(%Dictionary.CompiledXData).%OpenId($classname() _ "||PathParameter").Data.Read()
            Set inPath = $Replace(inPath, "{{Name}}", parameter.Name)
            Set inPath = $Replace(inPath, "{{ModelProperty.Name}}", parameter.ModelProperty.Name)
            Set PathParameterCode = PathParameterCode _ inPath
        }
    }

    Set buildRequestTemplate = ##class(%Dictionary.CompiledXData).%OpenId($classname() _ "||BuildRequest").Data.Read()

    Set buildRequestTemplate = $Replace(buildRequestTemplate, "{{PathParameterCode}}", $zstrip(PathParameterCode,"<W"))
    Set buildRequestTemplate = $Replace(buildRequestTemplate, "{{QueryParameterCode}}", QueryParameterCode)
    Set buildRequestTemplate = $Replace(buildRequestTemplate, "{{HeaderParameterCode}}", HeaderParameterCode)

    Do methodDefinition.Implementation.Write(buildRequestTemplate)

    Return methodDefinition
}

ClassMethod t()
{
    Set decision("datatype", "simple", "explode=false") = "PathParameterDatatypeSimple"
    Set decision("datatype", "simple", "explode=true") = "PathParameterDatatypeSimpleExplode"
    Set decision("array", "simple", "explode=false") = "PathParameterArraySimple"
    Set decision("array", "simple", "explode=true") = "PathParameterArraySimpleExplode"
    Set decision("object", "simple", "explode=false") = "PathParameterObjectSimple"
    Set decision("object", "simple", "explode=true") = "PathParameterObjectSimpleExplode"
}

XData %PrepareMethod [ MimeType = plain/text ]
{
    Do ##class(%Net.URLParser).Decompose(..server, .components)
    Set ..HttpRequest = ##class(%Net.HttpRequest).%New()
    Set ..HttpRequest.Https = $Select($$$LOWER($Get(components("scheme")))="https":1,1:0)
    Set ..HttpRequest.Server = $Get(components("host"))
    Set ..HttpRequest.Port = $Get(components("port"))
    Set:..HttpRequest.Https ..HttpRequest.SSLConfiguration = ..SSLConfiguration
    Set ..BasePath = $Get(components("path"))
    Return $$$OK
}

XData BuildRequest [ MimeType = plain/text ]
{
    // Initialisation de base de la requête
    Set ..Path = ..#PATH
    
    // Traitement des path parameters
    {{PathParameterCode}}
    
    // Traitement des query parameters
    {{QueryParameterCode}}
    
    // Traitement des header parameters
    {{HeaderParameterCode}}
}

/// template for path parameters style = simple, explode = false
XData PathParameterDatatypeSimple [ MimeType = plain/text ]
{
    Set ..Path = $Replace(..Path, "{{{Name}}}", ..{{ModelProperty.Name}})
}

/// template for path parameters style = simple, explode = true
XData PathParameterDatatypeSimpleExplode [ MimeType = plain/text ]
{
    Set ..Path = $Replace(..Path, "{{{Name}}*}", ..{{ModelProperty.Name}})
}

/// template for path parameters array style = simple, explode = false
XData PathParameterArraySimple [ MimeType = plain/text ]
{
    Do ..{{ModelProperty.Name}}.%SerializeObject(.tmpList)
    Set ..Path = $Replace(..Path, "{{{Name}}}", $ListToString($List(tmpList)))
    Kill tmpList
}

/// template for path parameters array style = simple, explode = false
XData PathParameterArraySimpleExplode [ MimeType = plain/text ]
{
    Do ..{{ModelProperty.Name}}.%SerializeObject(.tmpList)
    Set ..Path = $Replace(..Path, "{{{Name}}*}", $ListToString($List(tmpList)))
    Kill tmpList
}

///  template for path parameters object style = simple, explode = false
XData PathParameterObjectSimple [ MimeType = plain/text ]
{
    Do ..{{ModelProperty.Name}}.%JSONExportToString(.tmp)
    Set tmp = $tr($e(tmp,2,*-1),":""",",")
    Set ..Path = $Replace(..Path, "{{{Name}}}", tmp)
    Kill tmp
}

///  template for path parameters object style = simple, explode = true
XData PathParameterObjectSimpleExplode [ MimeType = plain/text ]
{
    Do ..{{ModelProperty.Name}}.%JSONExportToString(.tmp)
    Set tmp = $tr($e(tmp,2,*-1),":""","=")
    Set ..Path = $Replace(..Path, "{{{Name}}}", tmp)
    Kill tmp
}

/// -------template for path parameters style = label, explode = false
XData PathParameterLabel [ MimeType = plain/text ]
{
    Set ..Path = $Replace(..Path, "{.{{Name}}}", "."_..{{ModelProperty.Name}})
}

/// template for path parameters style = label, explode = true
XData PathParameterLabelExplode [ MimeType = plain/text ]
{
    Set ..Path = $Replace(..Path, "{.{{Name}}*}", "."_..{{ModelProperty.Name}})
}

/// template for path parameters style = matrix, explode = false
XData PathParameterMatrix [ MimeType = plain/text ]
{
    Set ..Path = $Replace(..Path, "{;{{Name}}}", ";{{Name}}="_..{{ModelProperty.Name}})
}

/// template for path parameters style = matrix, explode = true
XData PathParameterMatrixExplode [ MimeType = plain/text ]
{
    Set ..Path = $Replace(..Path, "{;{{Name}}*}", ";{{Name}}="_..{{ModelProperty.Name}})
}

/// template for path parameters array style = label, explode = false
XData PathParameterArrayLabel [ MimeType = plain/text ]
{
    Do ..{{ModelProperty.Name}}.%SerializeObject(.tmpList)
    Set ..Path = $Replace(..Path, "{.{{Name}}}", "."_$ListToString($List(tmpList)))
    Kill tmpList
}

/// template for path parameters array style = matrix, explode = false
XData PathParameterArrayMatrix [ MimeType = plain/text ]
{
    Do ..{{ModelProperty.Name}}.%SerializeObject(.tmpList)
    Set ..Path = $Replace(..Path, "{;{{Name}}}", ";{{Name}}="_$ListToString($List(tmpList)))
    Kill tmpList
}

}
