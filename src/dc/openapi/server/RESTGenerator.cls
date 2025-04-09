Class dc.openapi.server.RESTGenerator Extends (%RegisteredObject, dc.openapi.common.Generator)
{

Parameter ROUTETEMPLATE = "  <Route Url=""%1"" Method=""%2"" Call=""%3"" />";

Property superModel As %String [ InitialExpression = "%JSON.Adaptor,%RegisteredObject" ];

Property restClassName As %String;

Property implClassName As %String;

Property specClassName As %String;

Property routes As %Stream.GlobalCharacter [ Private ];

Property tmp As %String [ Private ];

Method %OnNew(specification As %DynamicObject, application) As %Status
{
    Set sc = $$$OK

    Set ..spec = specification
    Set ..application = application
    Set ..packageModel = ..application _ "." _ ..#PKGMODEL
    Set ..packageRequest = ..application _ "." _ ..#PKGREQUEST
    Set ..restClassName = ..application _ ".disp"
    Set ..implClassName = ..application _ ".impl"
    Set ..specClassName = ..application _ ".Spec"

    Do ##class(dc.openapi.common.Utils).SetTempData("model.package", ..packageModel)

    Quit sc
}

Method Generate(ByRef features As %Binary) As %Status
{
    Set sc = $$$OK

    Set sc = $$$ADDSC(sc, ..GenerateModels())

    If $Get(features("modelOnly")) = 1 Quit sc

    Set sc = $$$ADDSC(sc, ..IterateOnOperation("GenerateRequestClass"))

    Set sc = $$$ADDSC(sc, ..IterateOnOperation("GenerateLoadFromRequestMethod"))

    Set sc = $$$ADDSC(sc, ..IterateOnOperation("GenerateRequestValidate"))

    Set sc = $$$ADDSC(sc, ..GenerateREST())

    Set sc = $$$ADDSC(sc, ..GenerateImpl())

    Quit sc
}

Method CleanPreviousCodeGeneration() As %Status
{
    Do $SYSTEM.OBJ.DeletePackage(..packageModel)
    Do $SYSTEM.OBJ.DeletePackage(..packageRequest)
    Do $SYSTEM.OBJ.Delete(..restClassName)
    Do $SYSTEM.OBJ.Delete(..restClassName)
    Quit $$$OK
}

Method GenerateModels() As %Status
{
    $$$zlog("* Start model generation in package " _ ..packageModel)

    #dim modelGenerator As Grongier.OpenApi.DefinitionV3 = ##class(Grongier.OpenApi.DefinitionV3).%New(..spec, ..packageModel, , $$$NO)
    Set modelGenerator.super = ..superModel

    Set sc = modelGenerator.GenerateClasses()

    $$$zlog("= Models generation status : " _ $SYSTEM.Status.GetOneErrorText(sc))

    Quit sc
}

Method GenerateLoadFromRequestMethod(path As %String, pathItem As %DynamicObject, method As %String, operation As %DynamicObject) As %Status
{
    Set sc = $$$OK
    #dim propDef As %Dictionary.PropertyDefinition
    Set sc = $$$OK

    Do ..CheckAndGenerateOperationId(method, .operation, path)

    Set className = ..packageRequest _ "." _ operation.operationId

    Set classDef = ##class(%Dictionary.ClassDefinition).%OpenId(className,,.sc)

    If $$$ISERR(sc) {
        $$$zlog($Char(9) _"+ Can't add LoadFromRequest method to  " _ className _ "(class definition does not exist)")
        Quit sc
    }

    $$$zlog($Char(9) _"+ Add LoadFromRequest method to  " _ className)

    Set methodDef = ##class(%Dictionary.MethodDefinition).%New()
    Set methodDef.Name = "LoadFromRequest"
    Set methodDef.Description = "Load object properties from %CSP.Request object."
    Set methodDef.FormalSpec = "request:%CSP.Request=%request"
    Set methodDef.ClassMethod = $$$NO
    Set methodDef.ReturnType = "%Status"
    Do classDef.Methods.Insert(methodDef)
    Do methodDef.Implementation.WriteLine( $Char(9) _ "Set sc = $$$OK")

    Do methodDef.Implementation.WriteLine( $Char(9) _ "Set ..%ContentType = $Piece(request.ContentType, "";"", 1)")
    
    Set parameters = ..GetOperationParameters(pathItem, operation)

    Set parameterIterator = parameters.%GetIterator()
    While parameterIterator.%GetNext(.key, .parameter) {

        ; parameter is a parameter object https://swagger.io/specification/#parameter-object
        
        Set:parameter."$ref"'="" parameter = ##class(dc.openapi.common.Utils).GetObjectByRef(..spec, parameter."$ref", .name)
        
        Continue:'$IsObject(parameter)
        Continue:parameter.name=""
        Continue:parameter.in=""

        Set propDef = $$$FindPropertyName(classDef, $$$NormalizePropertyParamName(parameter.in_parameter.name))
        If '$IsObject(propDef) {
            Set errMsg = $$$FormatText("Property definition %1 not found in class %2", parameter.in_parameter.name, classDef.Name)
            $$$zlog($Char(9) _ "! " _ errMsg)
            Set sc = $$$ADDSC(sc, $$$ERROR(5001, errMsg))
            Continue
        }

        Set parameterPropertyName = $$$CodeNormalizeProperty($$$NormalizePropertyParamName(parameter.in_parameter.name))

        If parameter.in = "header" {
            Do methodDef.Implementation.WriteLine( $Char(9) _ "Set .." _ parameterPropertyName _ " = $Get(request.GetCgiEnv(""HTTP_" _ $ZCVT(parameter.name,"U") _ """))" )
        } ElseIf parameter.in = "path" {
            ; Must be managed out of this method.
            Do methodDef.Implementation.WriteLine( $Char(9) _ ";" _ parameterPropertyName _ " must be set out of this method")
        } ElseIf parameter.in = "query" {
            If propDef.Collection '= "" {
                Do methodDef.Implementation.WriteLine( $Char(9) _ "Set key = """"")
                Do methodDef.Implementation.WriteLine( $Char(9) _ "For  {")
                Do methodDef.Implementation.WriteLine( $Char(9,9) _ "Set key = $Order(request.Data(""" _ parameter.name _""", key), 1, tmpValue)")
                Do methodDef.Implementation.WriteLine( $Char(9,9) _ "Quit:key=""""")
                Do methodDef.Implementation.WriteLine( $Char(9,9) _ "Do .." _ parameterPropertyName _ ".Insert(tmpValue)")
                Do methodDef.Implementation.WriteLine( $Char(9) _ "}")
            } Else {
                Do methodDef.Implementation.WriteLine( $Char(9) _ "Set .." _ parameterPropertyName _ " = $Get(request.Data(""" _ parameter.name _""",1))" )
            }
        }

    }

    If $IsObject(operation.requestBody), operation.requestBody.%IsDefined("$ref") {
        Set refContent = ##class(dc.openapi.common.Utils).GetObjectByRef(..spec, operation.requestBody."$ref")
        Set:$IsObject(refContent) operation.requestBody.content = refContent.content
    }

    If '$ISOBJECT(operation.requestBody)||'$ISOBJECT(operation.requestBody.content) {
        Do methodDef.Implementation.WriteLine( $Char(9) _ "Quit sc")
        Quit $$$ADDSC(sc, classDef.%Save())
    }

    Set bodyHelper = ..RequestBodyHelper(operation.requestBody.content), bodyHelperIterator = bodyHelper.%GetIterator()

    While bodyHelperIterator.%GetNext(.propertyName, .propertyDetail) {
        
        Set propDef = $$$FindPropertyName(classDef, $$$NormalizePropertyParamName(propertyName))
        If '$IsObject(propDef) {
            Set errMsg = $$$FormatText("Property definition %1 not found in class %2", propertyName, classDef.Name)
            $$$zlog($Char(9) _ "! " _ errMsg)
            Set sc = $$$ADDSC(sc, $$$ERROR(5001, errMsg))
            Continue
        }

        Set ctIterator = propertyDetail.contentType.%GetIterator()
        While ctIterator.%GetNext(.key, .contentType) {

            Set condition = $$$FormatText("If ..%ContentType = ""%1""", $$$LOWER(contentType))
            If $$$LOWER(contentType) = "application/json" {
                If propDef.Collection '= "" {
                    Do methodDef.Implementation.WriteLine( $Char(9) _ condition _ "{")
                    Do methodDef.Implementation.WriteLine( "" )
                    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "Set key = """", array = [].%FromJSON(request.Content), iterator = array.%GetIterator()")
                    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "While iterator.%GetNext(.index, .item) {")
                    Do methodDef.Implementation.WriteLine( $Char(9,9,9) _ $$$FormatText("Set tmpObject = ##class(%1).%New()", propDef.Type ))
                    Do methodDef.Implementation.WriteLine( $Char(9,9,9) _ "Do tmpObject.%JSONImport(item)")
                    Do methodDef.Implementation.WriteLine( $Char(9,9,9) _ "Do .." _ $$$CodeNormalizeProperty(propDef.Name)_".Insert(tmpObject)")
                    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "}")
                    Do methodDef.Implementation.WriteLine( $Char(9) _ "}")
                } Else {
                    Do methodDef.Implementation.WriteLine( $Char(9) _ condition _ "{")
                    
                    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "Do .." _ $$$CodeNormalizeProperty(propDef.Name)_"NewObject().%JSONImport(request.Content)")
                    
                    Do methodDef.Implementation.WriteLine( $Char(9) _ "}" )
                }

            }ElseIf ($$$LOWER(contentType) [ "multipart/form-data") {
            
                Do methodDef.Implementation.WriteLine( $Char(9) _ condition _ "{")

                If propDef.Type = "%Stream.GlobalBinary" {
                    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "Set mime = request.GetMimeData(""" _ propertyName _ """)")
                    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "Do:$IsObject(mime) .." _ $$$CodeNormalizeProperty(propertyName) _ ".CopyFrom(mime)")
                } Else {
                    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "; To implement.  There is no code generation yet for this case.")
                    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "$$$ThrowStatus($$$ERROR($$$NotImplemented))")
                }

                Do methodDef.Implementation.WriteLine( $Char(9) _ "}")
            
            } ElseIf $$$LOWER(contentType) [ "application/octet-stream" {
                Do methodDef.Implementation.WriteLine( $Char(9) _ condition _ "{")

                If propDef.Type = "%Stream.GlobalBinary" {
                    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "Do .." _ $$$CodeNormalizeProperty(propDef.Name) _ ".CopyFrom(request.Content)" )
                } Else {
                    
                    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "; To implement.  There is no code generation for this case.")
                    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "$$$ThrowStatus($$$ERROR($$$NotImplemented))")
                }

                Do methodDef.Implementation.WriteLine( $Char(9) _ "}")

            } ElseIf $$$LOWER(contentType) [ "application/xml" {
                
                Do methodDef.Implementation.WriteLine( $Char(9) _ condition _ "{")

                Set xmlTagName = propDef.Parameters.GetAt("XMLNAME")
                Set xmlItemName = propDef.Parameters.GetAt("XMLITEMNAME")
                If xmlTagName = "" Set xmlTagName = propDef.Name
                If xmlItemName = "" Set xmlItemName = propDef.Name
                

                Do methodDef.Implementation.WriteLine( $Char(9,9) _ "Set reader = ##class(%XML.Reader).%New()" )
                Do methodDef.Implementation.WriteLine( $Char(9,9) _ "$$$QuitOnError(reader.OpenStream(request.Content))")

                If propDef.Collection = ""{
                    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "Do reader.Correlate(""" _ xmlTagName _ """,""" _ propDef.Type _""")" )
                    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "Do reader.Next(." _ $$$zNormalizeClassName(propDef.Name) _ ", .sc)" )
                    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "If $$$ISERR(sc) Quit sc" )
                    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "Set .." _ $$$zNormalizeClassName(propDef.Name) _ " = " _ $$$zNormalizeClassName(propDef.Name) )
                } Else {
                    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "Do reader.Correlate(""" _ xmlItemName _ """,""" _ propDef.Type _""")" )
                    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "While reader.Next(." _ $$$zNormalizeClassName(propDef.Name) _ ", .sc) {" )
                    Do methodDef.Implementation.WriteLine( $Char(9,9,9) _ "Return:$$$ISERR(sc) sc")
                    Do methodDef.Implementation.WriteLine( $Char(9,9,9) _ "Do ..ListOf" _ $$$zNormalizeClassName(propDef.Name) _ ".Insert(" _ $$$zNormalizeClassName(propDef.Name) _ ")" )
                    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "}" )
                }
                
                Do methodDef.Implementation.WriteLine( $Char(9,9) _ "Return sc")
                Do methodDef.Implementation.WriteLine( $Char(9) _ "}")

            } Else {
                Do methodDef.Implementation.WriteLine( $Char(9) _ condition _" {")
                Do methodDef.Implementation.WriteLine( $Char(9,9) _ "; To implement.  There is no code generation yet for this case.")
                Do methodDef.Implementation.WriteLine( $Char(9,9) _ "$$$ThrowStatus($$$ERROR($$$NotImplemented))")
                Do methodDef.Implementation.WriteLine( $Char(9) _ "}")
            }
        }

    }

    Do methodDef.Implementation.WriteLine( $Char(9) _ "Quit sc")

    Set sc = classDef.%Save()

    Quit sc
}

Method GenerateREST() As %Status
{
    Set sc = $$$OK

    Set className = ..restClassName
    $$$zlog($Char(9) _"Class name is " _ className)

    $$$zlog("* Generate class " _ className)

    #dim classDef As %Dictionary.ClassDefinition
    $$$QuitOnError(##class(dc.openapi.common.Utils).CreateClassDefInstance(className, .classDef))
    Set classDef.Super = "%CSP.REST"

    #dim parameter As %Dictionary.ParameterDefinition
    Set parameter = ##class(%Dictionary.ParameterDefinition).%New()
    Set parameter.Name = "SpecificationClass"
    Set parameter.Default = ..application _ ".Spec"
    Do classDef.Parameters.Insert(parameter)

    Set parameter = ##class(%Dictionary.ParameterDefinition).%New()
    Set parameter.Name = "IgnoreWrites"
    Set parameter.Default = "1"
    Do classDef.Parameters.Insert(parameter)

    Set parameter = ##class(%Dictionary.ParameterDefinition).%New()
    Set parameter.Name = "CONVERTINPUTSTREAM"
    Set parameter.Default = "1"
    Do classDef.Parameters.Insert(parameter)

    Set parameter = ##class(%Dictionary.ParameterDefinition).%New()
    Set parameter.Name = "CHARSET"
    Set parameter.Default = "utf-8"
    Do classDef.Parameters.Insert(parameter)

    Do ..routes.WriteLine("<Routes>")
    Set sc = $$$ADDSC(sc, ..IterateOnOperation("AddRoute"))
    Do ..routes.WriteLine($$$FormatText(..#ROUTETEMPLATE, "/_spec", "get", "SwaggerSpec"))
    Do ..routes.WriteLine("</Routes>")
    
    #dim xData As %Dictionary.XDataDefinition = ##class(%Dictionary.XDataDefinition).%New()
    Set xData.Name = "UrlMap", xData.XMLNamespace = "http://www.intersystems.com/urlmap"
    Do xData.Data.CopyFrom(..routes)
    Do classDef.XDatas.Insert(xData)

    Set sc = $$$ADDSC(sc, classDef.%Save())

    Set sc = $$$ADDSC(sc, ..IterateOnOperation("AddDispMethod"))
    
    Set sc = $$$ADDSC(sc, ..AddDispSwaggerSpec())

    Quit sc
}

Method GenerateImpl() As %Status
{
    Set sc = $$$OK

    Set className = ..implClassName
    $$$zlog($Char(9) _"Class name is " _ className)

    $$$zlog("* Generate class " _ className)

    #dim classDef As %Dictionary.ClassDefinition

    Set classDef = ##class(%Dictionary.ClassDefinition).%OpenId(className)  ; to avoid erase implementation class

    If '$IsObject(classDef) {
        $$$QuitOnError(##class(dc.openapi.common.Utils).CreateClassDefInstance(className, .classDef))
        Set classDef.Super = "%REST.Impl"

        #dim parameter As %Dictionary.ParameterDefinition
        Set parameter = ##class(%Dictionary.ParameterDefinition).%New()
        Set parameter.Name = "ExposeServerExceptions"
        Set parameter.Default = "1"
        Do classDef.Parameters.Insert(parameter)

    }

    

    Set sc = classDef.%Save()

    Set sc = $$$ADDSC(sc, ..AddImplSwaggerSpec())

    Set sc = $$$ADDSC(sc, ..IterateOnOperation("AddImplMethod"))
    
    Quit sc
}

Method AddImplMethod(path As %String, pathItem As %DynamicObject, method As %String, operation As %DynamicObject) As %Status
{
    Set sc = $$$OK
    Set className = ..implClassName, messageRequestClass = ..packageRequest _ "." _ operation.operationId

    If ##class(%Dictionary.MethodDefinition).%ExistsId(className_"||"_operation.operationId) Quit $$$OK    ; override protection

    Set classDef = ##class(%Dictionary.ClassDefinition).%OpenId(className,,.sc)

    If $$$ISERR(sc) {
        $$$zlog($Char(9) _"+ Can't add "_ operation.operationId _" method to  " _ className _ "(class definition does not exist)")
        Quit sc
    }

    $$$zlog($Char(9) _"+ Add "_ operation.operationId _ " method to " _ className)

    Set methodDef = ##class(%Dictionary.MethodDefinition).%New()
    Set methodDef.Name = operation.operationId
    Set methodDef.Description = "Service implemntation for " _ method _ " " _ path
    Set methodDef.ClassMethod = $$$YES
    Set methodDef.FormalSpec = "messageRequest:"_messageRequestClass
    Set methodDef.ReturnType = "%DynamicObject"
    Do classDef.Methods.Insert(methodDef)
    
    Do methodDef.Implementation.WriteLine( $Char(9) _ "; Implement your service here.")
    Do methodDef.Implementation.WriteLine( $Char(9) _ "; The return type should be %DynamicObject, %String or Stream object, adapt the method return type with you implementation.")
    Do methodDef.Implementation.WriteLine( $Char(9) _ "; Return {}")
    Do methodDef.Implementation.WriteLine( $Char(9) _ "$$$ThrowStatus($$$ERROR($$$NotImplemented))")
    
    Set sc = classDef.%Save()
    
    Quit sc
}

Method AddImplSwaggerSpec() As %Status
{

    Set className = ..implClassName, sc = $$$OK

    If ##class(%Dictionary.MethodDefinition).%ExistsId(className_"||SwaggerSpec") Quit $$$OK    ; override protection
    
    Set classDef = ##class(%Dictionary.ClassDefinition).%OpenId(className,,.sc)

    If $$$ISERR(sc) {
        $$$zlog($Char(9) _"+ Can't add SwaggerSpec method to  " _ className _ "(class definition does not exist)")
        Quit sc
    }

    $$$zlog($Char(9) _"+ Add SwaggerSpec method to " _ className)
    
    Set methodDef = ##class(%Dictionary.MethodDefinition).%New()
    Set methodDef.Name = "SwaggerSpec"
    Set methodDef.Description = "Process request " _ "SwaggerSpec" _ " " _ "/_spec"
    Set methodDef.ClassMethod = $$$YES
    Set methodDef.ReturnType = "%Status"
    Do classDef.Methods.Insert(methodDef)
    Do methodDef.Implementation.WriteLine( $Char(9) _ "Set spec = {}.%FromJSON(##class(%Dictionary.CompiledXData).%OpenId(""" _ ..specClassName _ "||OpenAPI"").Data)")
    Do methodDef.Implementation.WriteLine( $Char(9) _ "Set url = $Select(%request.Secure:""https"",1:""http"") _ ""://""_$Get(%request.CgiEnvs(""SERVER_NAME"")) _ "":"" _ $Get(%request.CgiEnvs(""SERVER_PORT"")) _ %request.Application")
    Do methodDef.Implementation.WriteLine( $Char(9) _ "Set spec.servers = [{""url"" : (url)}]")
    Do methodDef.Implementation.WriteLine( $Char(9) _ "Quit spec" )
    
    Set sc = classDef.%Save()

    Quit sc
}

Method AddRoute(path As %String, pathItem As %DynamicObject, method As %String, operation As %DynamicObject) As %Status
{
    Quit ..routes.WriteLine($$$FormatText(..#ROUTETEMPLATE, $Translate(path, "{}", ":"), $ZConvert(method, "U"), operation.operationId))
}

Method AddDispMethod(path As %String, pathItem As %DynamicObject, method As %String, operation As %DynamicObject) As %Status
{
    Set className = ..restClassName, messageRequestClass = ..packageRequest _ "." _ operation.operationId

    Set classDef = ##class(%Dictionary.ClassDefinition).%OpenId(className,,.sc)

    If $$$ISERR(sc) {
        $$$zlog($Char(9) _"+ Can't add "_ operation.operationId _" method to  " _ className _ "(class definition does not exist)")
        Quit sc
    }

    $$$zlog($Char(9) _"+ Add "_ operation.operationId _ " method to " _ className)

    Set methodDef = ##class(%Dictionary.MethodDefinition).%New()
    Set methodDef.Name = operation.operationId
    Set methodDef.Description = "Process request " _ method _ " " _ path
    Set methodDef.ClassMethod = $$$YES
    Set methodDef.ReturnType = "%Status"
    Do classDef.Methods.Insert(methodDef)
    Do ..AlimPathParamList(path, .pathParam)
    Set key = "", setPathParamLine = ""
    For  {
        Set key = $Order(pathParam(key), 1, pathParamName)
        Quit:key=""
        Set methodDef.FormalSpec = methodDef.FormalSpec _ "," _ pathParamName_":%String"
        Set setPathParamLine = $Select(setPathParamLine="": "Set requestMessage.path" _ pathParamName _" = "_pathParamName,1:setPathParamLine _ ", requestMessage.path" _ pathParamName _" = "_pathParamName)
    }
    Set methodDef.FormalSpec = $Extract(methodDef.FormalSpec, 2, *)

    Do methodDef.Implementation.WriteLine( $Char(9) _ "Set sc = $$$OK")
    
    Set listContentType = ""
    If $IsObject(operation.requestBody), $IsObject(operation.requestBody.content) {
        ; media type here.
        Set contentTypeIterator = operation.requestBody.content.%GetIterator()
        While contentTypeIterator.%GetNext(.contentType, .contentTypeItem) {
            Set $List(listContentType,*+1) = $$$LOWER(contentType)
        }
    }
   
    Set ..tmp = ""
    Do ..IterateOnResponses("AlimCheckAccept")
    Set accept = ..tmp, ..tmp = "" ; "application/json" ;
    
    Set implMethodName = operation.operationId ;

    Do methodDef.Implementation.WriteLine( $Char(9) _ "Try{")
    
    If $ListLength(listContentType) > 0 {
        Do methodDef.Implementation.WriteLine( $Char(9,9) _ $$$FormatText("Set acceptedMedia = $ListFromString(""%1"")", $ListToString(listContentType)))
        Do methodDef.Implementation.WriteLine( $Char(9,9) _ "If '$ListFind(acceptedMedia,$$$LOWER(%request.ContentType)) {")
        Do methodDef.Implementation.WriteLine( $Char(9,9,9) _ " Do ##class(%REST.Impl).%ReportRESTError(..#HTTP415UNSUPPORTEDMEDIATYPE,$$$ERROR($$$RESTContentType,%request.ContentType)) Quit")
        Do methodDef.Implementation.WriteLine( $Char(9,9) _ "}")
    }

    Do methodDef.Implementation.WriteLine( $Char(9,9) _ $$$FormatText("Do ##class(%REST.Impl).%SetContentType(%1)", "$Get(%request.CgiEnvs(""HTTP_ACCEPT""))" ))
    Do methodDef.Implementation.WriteLine( $Char(9,9) _ $$$FormatText("If '##class(%REST.Impl).%CheckAccepts(""%1"") Do ##class(%REST.Impl).%ReportRESTError(..#HTTP406NOTACCEPTABLE,$$$ERROR($$$RESTBadAccepts)) Quit", accept ))
    
    If operation.requestBody.required||(operation.requestBody.required="true") {
        Do methodDef.Implementation.WriteLine( $Char(9,9) _ "If '$isobject(%request.Content) Do ##class(%REST.Impl).%ReportRESTError(..#HTTP400BADREQUEST,$$$ERROR($$$RESTRequired,""body"")) Quit")
    }

    Do methodDef.Implementation.WriteLine( $Char(9,9) _ $$$FormatText("Set requestMessage = ##class(%1).%New()", messageRequestClass))
    Do:setPathParamLine'="" methodDef.Implementation.WriteLine( $Char(9,9) _ setPathParamLine)
    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "Do requestMessage.LoadFromRequest(%request)")
    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "Set scValidateRequest = requestMessage.RequestValidate()")
    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "If $$$ISERR(scValidateRequest) Do ##class(%REST.Impl).%ReportRESTError(..#HTTP400BADREQUEST,$$$ERROR(5001,""Invalid requestMessage object."")) Quit")
    Do methodDef.Implementation.WriteLine( $Char(9,9) _ $$$FormatText("Set response = ##class(%1).%2(requestMessage)", ..implClassName, implMethodName))
    Do methodDef.Implementation.WriteLine( $Char(9,9) _ $$$FormatText("Do ##class(%1).%WriteResponse(response)",..implClassName))
    
    Do methodDef.Implementation.WriteLine( $Char(9) _ "} Catch(ex) {")
    Do methodDef.Implementation.WriteLine( $Char(9,9) _ $$$FormatText("Do ##class(%REST.Impl).%ReportRESTError(..#HTTP500INTERNALSERVERERROR,ex.AsStatus(),$parameter(""%1"",""ExposeServerExceptions""))", ..implClassName))
    Do methodDef.Implementation.WriteLine( $Char(9) _ "}")
    Do methodDef.Implementation.WriteLine( $Char(9) _ "Quit sc")

    Set sc = classDef.%Save()

    Quit sc
}

Method GenerateRequestValidate(path As %String, pathItem As %DynamicObject, method As %String, operation As %DynamicObject) As %Status
{
    Set sc = $$$OK
    #dim propDef As %Dictionary.PropertyDefinition

    Do ..CheckAndGenerateOperationId(method, .operation, path)

    Set className = ..packageRequest _ "." _ operation.operationId

    Set classDef = ##class(%Dictionary.ClassDefinition).%OpenId(className,,.sc)

    If $$$ISERR(sc) {
        $$$zlog($Char(9) _"+ Can't add RequestValidate method to  " _ className _ "(class definition does not exist)")
        Quit sc
    }

    $$$zlog($Char(9) _"+ Add RequestValidate method to  " _ className)

    Set methodDef = ##class(%Dictionary.MethodDefinition).%New()
    Set methodDef.Name = "RequestValidate"
    Set methodDef.Description = "Load object properties from %CSP.Request object."
    Set methodDef.FormalSpec = ""
    Set methodDef.ClassMethod = $$$NO
    Set methodDef.ReturnType = "%Status"
    Do classDef.Methods.Insert(methodDef)
    Do methodDef.Implementation.WriteLine( $Char(9) _ "Set sc = $$$OK")
    Do methodDef.Implementation.WriteLine( $Char(9) _ "$$$QuitOnError(..%ValidateObject())")

    #dim property As %Dictionary.PropertyDefinition

    Set bodyRequired = $$$NO
    If $IsObject(operation.requestBody) Set bodyRequired = operation.requestBody.required||(operation.requestBody.required="true")

    Set key = ""
    For  {
        Set property = classDef.Properties.GetNext(.key)
        Quit:key=""

        
        If ..isBodyProperty(property.Name, operation), bodyRequired {

            Set contentTypeList = ..GetContentTypeListForProperty(property.Name, operation)

            Do methodDef.Implementation.WriteLine( $Char(9) _ $$$FormatText("If ''$ListFind($ListFromString(""%1""), ..%ContentType) {", contentTypeList) )
            
            If property.Type["%Stream." {
                Do methodDef.Implementation.WriteLine( $Char(9,9) _ $$$FormatText("Quit:..%1.Size=0 $$$ERROR(5659, ""%1"")", $$$CodeNormalizeProperty(property.Name)))
            } Else {
                Do methodDef.Implementation.WriteLine( $Char(9,9) _ $$$FormatText("Quit:..%1="""" $$$ERROR(5659, ""%1"")", $$$CodeNormalizeProperty(property.Name)))
            }

            Do methodDef.Implementation.WriteLine( $Char(9) _ "}" )
        }

        Do:property.Type[..packageModel methodDef.Implementation.WriteLine( $Char(9) _$$$FormatText("If $IsObject(..%1) $$$QuitOnError(..%1.%ValidateObject())", $$$CodeNormalizeProperty(property.Name)))
        
        
    }
    
    Do methodDef.Implementation.WriteLine( $Char(9) _ "Quit sc")

    Set sc = classDef.%Save()
    Quit sc
}

Method AddDispSwaggerSpec() As %Status
{
    Set className = ..restClassName, sc = $$$OK

    Set classDef = ##class(%Dictionary.ClassDefinition).%OpenId(className,,.sc)

    If $$$ISERR(sc) {
        $$$zlog($Char(9) _"+ Can't add SwaggerSpec method to  " _ className _ "(class definition does not exist)")
        Quit sc
    }

    $$$zlog($Char(9) _"+ Add SwaggerSpec method to " _ className)

    Set methodDef = ##class(%Dictionary.MethodDefinition).%New()
    Set methodDef.Name = "SwaggerSpec"
    Set methodDef.Description = "Process request " _ "SwaggerSpec" _ " " _ "/_spec"
    Set methodDef.ClassMethod = $$$YES
    Set methodDef.ReturnType = "%Status"
    Do classDef.Methods.Insert(methodDef)
    Do methodDef.Implementation.WriteLine( $Char(9) _ "Try {")
    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "Do ##class(%REST.Impl).%SetContentType(""application/json"")" )
    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "If '##class(%REST.Impl).%CheckAccepts(""application/json"") Do ##class(%REST.Impl).%ReportRESTError(..#HTTP406NOTACCEPTABLE,$$$ERROR($$$RESTBadAccepts)) Quit" )
    Do methodDef.Implementation.WriteLine( $Char(9,9) _ $$$FormatText("Set response=##class(%1).SwaggerSpec()", ..implClassName)  )
    Do methodDef.Implementation.WriteLine( $Char(9,9) _ $$$FormatText("Do ##class(%1).%WriteResponse(response)", ..implClassName)  )
    Do methodDef.Implementation.WriteLine( $Char(9) _ "} Catch(ex) {" )
    Do methodDef.Implementation.WriteLine( $Char(9,9) _ $$$FormatText(" Do ##class(%REST.Impl).%ReportRESTError(..#HTTP500INTERNALSERVERERROR,ex.AsStatus(),$parameter(""%1"",""ExposeServerExceptions""))", className) )
    Do methodDef.Implementation.WriteLine( $Char(9) _ "}" )
    
    Do methodDef.Implementation.WriteLine( $Char(9) _ "Quit $$$OK")

    Set sc = classDef.%Save()

    Quit sc
}

Method AlimCheckAccept(path As %String, pathItem As %DynamicObject, method As %String, operation As %DynamicObject, response As %String, responseItem As %DynamicObject) As %Status
{
    Set sc = $$$OK

    If $IsObject(responseItem.content) {
        Set contentTypeIterator = responseItem.content.%GetIterator()
        While contentTypeIterator.%GetNext(.contentType, .contentTypeItem) {
            Continue:..tmp[contentType
            Set ..tmp = $Select(..tmp="": $$$LOWER(contentType), 1: ..tmp _ "," _ $$$LOWER(contentType))
        }
    }

    Quit sc
}

ClassMethod AlimPathParamList(path As %String, Output paramList As %Binary) As %Status
{
    Set matcher = ##class(%Regex.Matcher).%New("\{([^{}]*)\}") 
    Set matcher.Text = path
    While matcher.Locate() {
        Set paramList($Increment(paramList)) = $$$zNormalizeClassName(matcher.Group(1))
    }
    Quit $$$OK
}

}
