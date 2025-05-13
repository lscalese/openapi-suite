Class dc.openapi.client.HttpRequestGenerator Extends %RegisteredObject
{

Parameter HTTPREQUESTOBJECT = "httpRequest";

Parameter REQUESTSUBPKG = "request";

Parameter RESPONSESUBPKG = "response";

Property AST As dc.openapi.common.ast.OAS;

Property Package As %String [ InitialExpression = "testclient" ];

Property httpClientClass As %Dictionary.ClassDefinition [ Private ];

ClassMethod Test() As %Status
{
    TRollback
    TStart

    Set sc = $$$OK
    
    Try {
        ;Set dir = "/home/irisowner/irisdev/temp-dev-specs/ast-parameter/"
        ;Set file = "ast-path-parameter-array-matrix-explode.json"
        Set dir = "/home/irisowner/irisdev/temp-dev-specs/"
        Set file = "AST-1.json"
        
        
        Set jsonObject = {}.%FromJSONFile(dir _ file)

        Set generator = ..%New()
        Set generator.Package = "testclient"
        Set generator.AST = ##class(dc.openapi.common.ast.OAS).%New()
        $$$TOE(sc,generator.AST.%JSONImport(jsonObject))
        $$$TOE(sc,generator.Generate())
    } 
    Catch ex {
        Set sc = ex.AsStatus()
        If $$$ISERR(sc) {
            Write !
            Do $SYSTEM.Status.DisplayError(sc)
        }
    }
    
    Return sc
}

Method Generate() As %Status
{
    Set sc = ..GenerateHttpClientRequest()

    Set key = ""
    For  {
        Set path = ..AST.Paths.GetNext(.key)
        Quit:key=""
        Set sc = $$$ADDSC(sc, ..GenerateRequestClassModel(path))

        Set operationMethod = ..GetOperationMethod(path)
        Do ..httpClientClass.Methods.Insert(operationMethod)
    }
    Set sc = ..httpClientClass.%Save()
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
    Set requestClassModel.Name = ..GetRequestObjectClassName(path)

    Set pathParameter = ##class(%Dictionary.ParameterDefinition).%New()
    Set pathParameter.Name = "PATH"
    Set pathParameter.Default = path.Path
    Set pathParameter.Description = "Path for the operation, ex: /user/{userId}"
    Do requestClassModel.Parameters.Insert(pathParameter)

    Set pathProperty = ##class(%Dictionary.PropertyDefinition).%New()
    Set pathProperty.Name = "%Path"
    Set pathProperty.Type = "%String"
    Set pathProperty.InitialExpression = "..#PATH"
    Set pathProperty.Description = "The resolved path for the operation, ex: /user/{userId} --> /user/1"
    Do requestClassModel.Properties.Insert(pathProperty)

    Set acceptList = ..GetAcceptList(path.Responses)
    Set acceptProperty = ##class(%Dictionary.PropertyDefinition).%New()
    Set acceptProperty.Name = "%Accept"
    Set acceptProperty.Type = "%String"
    Set acceptProperty.InitialExpression = """"_$ListGet(acceptList,1)_""""
    Set acceptProperty.Description = "The Accept header for the operation. " _ $ListToString(acceptList,", ")
    Do requestClassModel.Properties.Insert(acceptProperty)

    Set contentTypeList = ..GetContentTypeList(path.RequestBodies)
    Set contentTypeProperty = ##class(%Dictionary.PropertyDefinition).%New()
    Set contentTypeProperty.Name = "%ContentType"
    Set contentTypeProperty.Type = "%String"
    Set contentTypeProperty.InitialExpression = """"_$ListGet(contentTypeList,1)_""""
    Set contentTypeProperty.Description = "The Content-Type header for the operation.  "_ $ListToString(contentTypeList,", ")
    Do requestClassModel.Properties.Insert(contentTypeProperty)

    #dim parameter As dc.openapi.common.ast.Parameter
    Set key = ""
    For  {
        Set parameter = path.Parameters.GetNext(.key)
        Quit:key=""

        Set propertyDef = ##class(dc.openapi.common.ModelGenerator).GetPropertyDefinition(parameter.ModelProperty)
        Do requestClassModel.Properties.Insert(propertyDef)
    }

    Set key = ""
    For  {
        Set requestBody = path.RequestBodies.GetNext(.key)
        Quit:key=""

        Set requestBodyPropDef = ##class(dc.openapi.common.ModelGenerator).GetPropertyDefinition(requestBody.ModelProperty)
        If '$Data(createdRequestBody(" "_requestBodyPropDef.Type)) { ; avoid duplicate request body objects if it's the same type
            Set createdRequestBody(" "_requestBodyPropDef.Type) = requestBodyPropDef
            Do requestClassModel.Properties.Insert(requestBodyPropDef) 
        }
    }

    Do requestClassModel.Methods.Insert(..GetBuildRequestMethod(path))

    Return requestClassModel.%Save()
}

ClassMethod GetBuildRequestMethod(path As dc.openapi.common.ast.Path) As %String
{
    Set methodDefinition = ##class(%Dictionary.MethodDefinition).%New()
    Set methodDefinition.Name = "%BuildRequest"
    Set methodDefinition.Description = "Build the HTTP request for the operation"
    Set methodDefinition.ReturnType = "%Status"
    Set methodDefinition.FormalSpec= "&"_..#HTTPREQUESTOBJECT_":%Net.HttpRequest"

    #dim parameter As dc.openapi.common.ast.Parameter
    Set PathParameterCode = "", QueryParameterCode = "", HeaderParameterCode = "", CookieParameterCode = "", RequestBodiesCode = ""
    
    Set key = ""
    For  {
        Set parameter = path.Parameters.GetNext(.key)
        Quit:key=""
        
        Set type = $Select(parameter.ModelProperty.Collection="list":"array",1:parameter.ModelProperty.TypeHelper)
            
        If parameter.In = "path" {
            Set style = $s(parameter.Style="":"simple",1:parameter.Style)   ; default is simple
            Set explode = parameter.Explode = 1                             ; default is false
            Set PathParameterTemplate = ##class(dc.openapi.common.template.PathParameters).GetTemplate(type, style, explode)
            Set PathParameterTemplate = $Replace(PathParameterTemplate, "{{Name}}", parameter.Name)
            Set PathParameterTemplate = $Replace(PathParameterTemplate, "{{ModelProperty.Name}}", parameter.ModelProperty.Name)
            Set PathParameterCode = PathParameterCode _ PathParameterTemplate
        }
        ElseIf parameter.In = "query" {
            Set style = $s(parameter.Style="":"form", 1:parameter.Style)    ; default is form
            Set explode = $s(parameter.Explode="": 1, 1:parameter.Explode)  ; default is true
            Set QueryParameterTemplate = ##class(dc.openapi.common.template.QueryParameters).GetTemplate(type, style, explode)
            Set QueryParameterTemplate = $Replace(QueryParameterTemplate, "{{Name}}", parameter.Name)
            Set QueryParameterTemplate = $Replace(QueryParameterTemplate, "{{ModelProperty.Name}}", parameter.ModelProperty.Name)
            Set QueryParameterCode = QueryParameterCode _ QueryParameterTemplate
        }
        ElseIf parameter.In = "header" {
            Set style = $s(parameter.Style="":"simple", 1:parameter.Style)  ; default is simple
            Set explode = parameter.Explode = 1                             ; default is false
            Set HeaderParameterTemplate = ##class(dc.openapi.common.template.HeaderParameters).GetTemplate(type, style, explode)
            Set HeaderParameterTemplate = $Replace(HeaderParameterTemplate, "{{Name}}", parameter.Name)
            Set HeaderParameterTemplate = $Replace(HeaderParameterTemplate, "{{ModelProperty.Name}}", parameter.ModelProperty.Name)
            Set HeaderParameterCode = HeaderParameterCode _ HeaderParameterTemplate
        }
        ElseIf parameter.In = "cookie" {
            Set style = $s(parameter.Style="":"form", 1:parameter.Style)    ; default is form
            Set explode = $s(parameter.Explode="": 1, 1:parameter.Explode)  ; default is true
            Set CookieParameterTemplate = ##class(dc.openapi.common.template.CookieParameters).GetTemplate(type, style, explode)
            Set CookieParameterTemplate = $Replace(CookieParameterTemplate, "{{Name}}", parameter.Name)
            Set CookieParameterTemplate = $Replace(CookieParameterTemplate, "{{ModelProperty.Name}}", parameter.ModelProperty.Name)
            Set CookieParameterCode = CookieParameterCode _ CookieParameterTemplate
        }
    }

    #dim requestBody As dc.openapi.common.ast.RequestBody
    Set key = ""
    For  {
        Set requestBody = path.RequestBodies.GetNext(.key)
        Quit:key=""

        If ##class(dc.openapi.common.Utils).isJsonMimeType(requestBody.ContentType) {
            Set RequestBodiesTemplate = ##class(dc.openapi.common.template.RequestBody).ByName("JSON")
            Set RequestBodiesTemplate = $Replace(RequestBodiesTemplate, "{{ContentType}}", requestBody.ContentType)
            Set RequestBodiesTemplate = $Replace(RequestBodiesTemplate, "{{ModelProperty.Name}}", requestBody.ModelProperty.Name)
            Set RequestBodiesCode = RequestBodiesCode _ RequestBodiesTemplate
        } 
    }

    Set buildRequestTemplate = ..GetTemplateByName("BuildRequest")
    Set buildRequestTemplate = $Replace(buildRequestTemplate, "{{PathParameterCode}}", $zstrip(PathParameterCode,"<W"))
    Set buildRequestTemplate = $Replace(buildRequestTemplate, "{{QueryParameterCode}}", $zstrip(QueryParameterCode,"<W"))
    Set buildRequestTemplate = $Replace(buildRequestTemplate, "{{HeaderParameterCode}}", $zstrip(HeaderParameterCode,"<W"))
    Set buildRequestTemplate = $Replace(buildRequestTemplate, "{{CookieParameterCode}}", $zstrip(CookieParameterCode,"<W"))
    Set buildRequestTemplate = $Replace(buildRequestTemplate, "{{RequestBodies}}", $zstrip(RequestBodiesCode,"<W"))

    
    Set buildRequestTemplate = $Replace(buildRequestTemplate, "{{httpRequestObject}}", $zstrip(..#HTTPREQUESTOBJECT,"<W"))
    
    Do methodDefinition.Implementation.Write(buildRequestTemplate)

    Return methodDefinition
}

Method GetOperationMethod(path As dc.openapi.common.ast.Path) As %Dictionary.MethodDefinition
{
    Set methodDefinition = ##class(%Dictionary.MethodDefinition).%New()
    Set methodDefinition.Name = path.OperationId
    Set methodDefinition.Description = "Build the HTTP request for the operation"
    Set methodDefinition.ReturnType = "%Status"

    Set requestObject = ..GetRequestObjectClassName(path)
    Set requestModel = $Piece(requestObject, ".", *)
    Set methodDefinition.FormalSpec= requestModel_":" _ requestObject

    Set template = ..GetTemplateByName("OperationMethod")
    Set template = $Replace(template, "{{requestModel}}", requestModel)
    Set template = $Replace(template, "{{httpRequestObject}}", ..#HTTPREQUESTOBJECT)

    Do methodDefinition.Implementation.Write(template)

    Return methodDefinition
}

Method GetRequestObjectClassName(path As dc.openapi.common.ast.Path) As %String [ CodeMode = expression ]
{
..Package _ "." _ ..#REQUESTSUBPKG _ "." _ path.OperationId
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

XData OperationMethod [ MimeType = plain/text ]
{
    Set sc = $$$OK
    Try {
        $$$TOE(sc,{{requestModel}}.%BuildRequest(..HttpRequest))
    }
    Catch ex {
        Set sc = ex.AsStatus()
    }
    Return sc
}

ClassMethod GetTemplateByName(XDataName As %String) As %String
{
    Set id = $classname() _ "||" _ XDataName
    If '##class(%Dictionary.CompiledXData).%ExistsId(id) {
        Return ""
    }
    Set template = ##class(%Dictionary.CompiledXData).%OpenId(id).Data.Read()
    Return template
}

ClassMethod GetContentTypeList(requestBodies As %ListOfObjects) As %String
{
    Set contentTypeList = ""
    #dim requestBody As dc.openapi.common.ast.RequestBody
    Set key = ""
    For  {
        Set requestBody = requestBodies.GetNext(.key)
        Quit:key=""
        If requestBody.ContentType'="" {
            Set $List(contentTypeList, *+1) = requestBody.ContentType
        }
    }
    Return contentTypeList
}

ClassMethod GetAcceptList(responses As %ListOfObjects) As %String
{
    Set contentTypeList = ""
    #dim response As dc.openapi.common.ast.Response
    Set key = ""
    For  {
        Set response = responses.GetNext(.key)
        Quit:key=""
        If response.ContentType'="" {
            Set $List(contentTypeList, *+1) = response.ContentType
        }
    }
    Return contentTypeList
}

XData BuildRequest [ MimeType = plain/text ]
{
    Set sc = $$$OK
    Set ..%Path = ..#PATH

    /// Set http header
    {{HeaderParameterCode}}
    /// Set path parameters
    {{PathParameterCode}}
    /// Set query parameters
    {{QueryParameterCode}}
    /// Set cookie parameters
    {{CookieParameterCode}}
    /// Set request body
    {{RequestBodies}}

    Return sc
}

}
