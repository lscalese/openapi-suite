Include dc.openapi.common.macro

Class dc.openapi.client.generator.ClientClassGenerator Extends dc.openapi.common.GeneratorAbstract
{

Parameter NAME = "HttpClient";

Method Generate() As %Dictionary.ClassDefinition
{
    Return:'..HandleOverride(.classDef) classDef
    
    Set httpClientClass = ##class(%Dictionary.ClassDefinition).%New()
    Set httpClientClass.ProcedureBlock = $$$YES
    Set httpClientClass.Inheritance = "left"
    Set httpClientClass.Super = "%RegisteredObject"
    Set httpClientClass.Name = ..ClassName
    Do ##class(dc.openapi.common.GeneratedItemRegistry).RegisterClass(..ClassName)
    

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
    Set code = ##class(dc.openapi.client.template.HttpClient).ByName("%PrepareMethod")
    Do PrepareMethod.Implementation.Write(code)
    Do httpClientClass.Methods.Insert(PrepareMethod)

    Return httpClientClass
}

Method GetOperationMethod(path As dc.openapi.common.ast.Path, requestObject As %String = "", responseObject As %String) As %Dictionary.MethodDefinition
{
    Set methodDefinition = ##class(%Dictionary.MethodDefinition).%New()
    Set methodDefinition.Name = path.OperationId
    Set methodDefinition.Description = "Build the HTTP request for the operation"
    Set methodDefinition.ReturnType = "%Status"

    Set requestModel = $Piece(requestObject, ".", *) _ "Request"
    Set responseModel = $Piece(responseObject, ".", *) _ "Response"
    Set methodDefinition.FormalSpec= requestModel_":" _ requestObject_",*"_responseModel_":" _ responseObject

    Set variables("requestModel") = requestModel
    Set variables("responseObject") = responseObject
    Set variables("responseModel") = responseModel
    Set variables("HttpRequestObject") = ##class(dc.openapi.client.HttpClientGeneratorV2).#HTTPREQUESTOBJECT

    Set template = ##class(dc.openapi.client.template.Operation).GetResolvedTemplate(path, .variables)
    Do methodDefinition.Implementation.Write(template)

    Return methodDefinition
}

}
