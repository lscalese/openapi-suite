Include dc.openapi.common.macro

Class dc.openapi.client.ProductionGenerator Extends (%RegisteredObject, dc.openapi.common.Generator)
{

Parameter PKGSERVICES = "bs";

Parameter PKGOPERATION = "bo";

Parameter PKGPROCESS = "bp";

Property genericResponseClassName As %String [ Private ];

Property productionClassName As %String [ InitialExpression = "Production" ];

Property tmp As %Binary [ MultiDimensional ];

Method %OnNew(specification As %DynamicObject, application As %String) As %Status
{
    Set ..spec = specification
    Set ..application = application
    Set ..packageModel = ..application _ "." _ ..#PKGMODEL
    Set ..packageRequest = ..application _ "." _..#PKGREQUEST
    Set ..superRequest = "Ens.Request"

    Do ##class(dc.openapi.common.Utils).SetTempData("model.package", ..packageModel)
    
    Quit $$$OK
}

Method Generate(ByRef features) As %Status
{
    Set sc = $$$OK
    
    Set httpClientGenerator = ##class(dc.openapi.client.HttpClientGenerator).%New(..spec, ..application, .features)
    Set httpClientGenerator.superRequest = ..superRequest
    Set httpClientGenerator.superModel = "%SerialObject,%JSON.Adaptor,%XML.Adaptor"
    Set httpClientGenerator.superGenericResponse = "Ens.Response"
    Set ..genericResponseClassName = httpClientGenerator.genericResponseClassName

    Set sc = $$$ADDSC(sc, httpClientGenerator.GenerateClient(.features))

    If $Get(features("noBP")) '= 1 {
        ; Generate Business process
        Set sc = $$$ADDSC(sc, ..GenerateBusinessProcess())
    }

    If $Get(features("noBS")) '= 1 {
        ; Generate Business services
        Set sc = $$$ADDSC(sc, ..IterateOnOperation("GenerateBusinessService"))

        ; Generate Proxy service
        Set sc = $$$ADDSC(sc, ..GenerateProxyService())
    }

    ; Generate Business Operation
    Set sc = $$$ADDSC(sc, ..GenerateBusinessOperation())


    If $Get(features("noUtils")) '= 1 {
        Set utilsClass =..application_".Utils"

        If '$$$defClassDefined(utilsClass) {    ;copy utils class to the target package
        
            Set clsUtils = ##class(%Dictionary.ClassDefinition).%OpenId("dc.openapi.client.Utils").%ConstructClone()
            Set clsUtils.Name = utilsClass
            
            Set sc = $$$ADDSC(sc, clsUtils.%Save())
            ; class copy, explicit compile is required
            Set sc = $$$ADDSC(sc, $SYSTEM.OBJ.Compile(utilsClass, "ck-d"))
        }
    }

    ; Generate Production
    Set sc = $$$ADDSC(sc, ..GenerateProduction())
    
    Set sc = $$$ADDSC(sc, ..GenerateMessageMap())

    Quit sc
}

Method GenerateBusinessService(path As %String, pathItem As %DynamicObject, method As %String, operation As %DynamicObject) As %Status
{
    Set sc = $$$OK
    
    $$$zlog("* Generate Request class for " _path _ " "_ method _ "...")

    Do ##class(dc.openapi.client.HttpClientGenerator).CheckAndGenerateOperationId(method, .operation, path)
    Set className = ..application _"." _ ..#PKGSERVICES _ "." _ $$$zNormalizeClassName(operation.operationId)
    $$$zlog($Char(9) _"Class name is " _ className)


    #dim classDef As %Dictionary.ClassDefinition
    $$$QuitOnError(##class(Grongier.OpenApi.DefinitionV3).CreateClassDefInstance(className, .classDef))
    Set classDef.Super = "Ens.BusinessService"


    #dim property As %Dictionary.PropertyDefinition = ##class(%Dictionary.PropertyDefinition).%New()

    Set property.Name = "Adapter"
    Set property.Type = "Ens.Adapter"
    Set property.Description = "Auto generated : Change by your Adapter type."
    Do classDef.Properties.Insert(property)

    #dim classParameter As %Dictionary.ParameterDefinition = ##class(%Dictionary.ParameterDefinition).%New()
    Set classParameter.Name = "ADAPTER"
    Set classParameter.Default = "Ens.Adapter"
    Set classParameter.Description = "Auto generated : Change by your Adapter type."
    Do classDef.Parameters.Insert(classParameter)

    #dim mDef As %Dictionary.MethodDefinition = ##class(%Dictionary.MethodDefinition).%New()

    Set mDef.Name = "OnProcessInput"
    Set mDef.Description = "Auto generated method"
    Set mDef.FormalSpec = "pInput:%RegisteredObject,pOutput:%RegisteredObject"
    Set mDef.ReturnType = "%Status"

    Set msgRequestClass = ..application _"." _..PackageRequest() _ "." _ $$$zNormalizeClassName(operation.operationId)
    
    Do mDef.Implementation.WriteLine($Char(9) _ "Set sc = $$$OK" )
    Do mDef.Implementation.WriteLine($Char(9) _ "Set msg = ##class(" _ msgRequestClass _ ").%New()")
    Do mDef.Implementation.WriteLine($Char(9) _ "; Auto generated, put your own code...")
    Do mDef.Implementation.WriteLine($Char(9) _ "Return ..SendRequestAsync("""_ ..application _"." _..#PKGPROCESS_".Process" _ """, msg)")
    
    Do classDef.Methods.Insert(mDef)

    Set sc = classDef.%Save()
    Quit sc
}

ClassMethod PackageModel() As %String [ CodeMode = expression ]
{
..#PKGMODEL
}

ClassMethod PackageRequest() As %String [ CodeMode = expression ]
{
..#PKGREQUEST
}

ClassMethod PackageResponse() As %String [ CodeMode = expression ]
{
##class(dc.openapi.client.HttpClientGenerator).%GetParameter("PKGRESPONSE")
}

/// Generate Generic Business Process classes<br/>
Method GenerateBusinessProcess() As %Status
{
    #dim sc As %Status = $$$OK
    
    Set ensOperationClassName = ..application _"." _ ..#PKGOPERATION _ ".Operation"

    Set className = ..application _"." _ ..#PKGPROCESS _ ".Process"
    #dim cDef As %Dictionary.ClassDefinition
    $$$QuitOnError(##class(Grongier.OpenApi.DefinitionV3).CreateClassDefInstance(className, .cDef))
    Set cDef.Super = "Ens.BusinessProcess"
    $$$zlog("* Generate BusinessProcess class " _ className _" ...")

    Set mDef = ##class(%Dictionary.MethodDefinition).%New()
    Set mDef.Name = "OnRequest"
    Set mDef.FormalSpec = $$$FormatText("pRequest:%1,pResponse:%2", "Ens.Request", "Ens.Response")
    Set mDef.ReturnType = "%Status"
    Do mDef.Implementation.WriteLine($Char(9) _$$$FormatText("Return ..SendRequestAsync(""%1"", pRequest, 1, pRequest.%ClassName(1))", ensOperationClassName))
    Do cDef.Methods.Insert(mDef)

    Set mDef = ##class(%Dictionary.MethodDefinition).%New()
    Set mDef.Name = "OnResponse"
    Set mDef.FormalSpec = "request:%Library.Persistent,response:%Library.Persistent,callrequest:%Library.Persistent,callresponse:%Library.Persistent,pCompletionKey:%String"
    Set mDef.ReturnType = "%Status"
    Do mDef.Implementation.WriteLine($Char(9) _"Return $$$OK")
    Do cDef.Methods.Insert(mDef)

    Set sc = $$$ADDSC(sc, cDef.%Save())
    /// Sync process ...
   
    Set className = ..application _"." _ ..#PKGPROCESS _ ".SyncProcess"
    $$$QuitOnError(##class(Grongier.OpenApi.DefinitionV3).CreateClassDefInstance(className, .cDef))
    Set cDef.Super = "Ens.BusinessProcess"
    $$$zlog("* Generate BusinessProcess class " _ className _" ...")

    Set mDef = ##class(%Dictionary.MethodDefinition).%New()
    Set mDef.Name = "OnRequest"
    Set mDef.FormalSpec = $$$FormatText("pRequest:%1,pResponse:%2", "Ens.Request", "Ens.Response")
    Set mDef.ReturnType = "%Status"
    Do mDef.Implementation.WriteLine($Char(9) _$$$FormatText("Return ..SendRequestSync(""%1"", pRequest, .pResponse, ,pRequest.%ClassName(1))", ensOperationClassName))
    Do cDef.Methods.Insert(mDef)

    Set mDef = ##class(%Dictionary.MethodDefinition).%New()
    Set mDef.Name = "OnResponse"
    Set mDef.FormalSpec = "request:%Library.Persistent,response:%Library.Persistent,callrequest:%Library.Persistent,callresponse:%Library.Persistent,pCompletionKey:%String"
    Set mDef.ReturnType = "%Status"
    Do mDef.Implementation.WriteLine($Char(9) _"Return $$$OK")
    Do cDef.Methods.Insert(mDef)

    Set sc = $$$ADDSC(sc, cDef.%Save())

    Return sc
}

Method GenerateBusinessOperation() As %Status
{
    #dim sc As %Status = $$$OK
    
    Set ensOperationClassName = ..application _"." _ ..#PKGOPERATION _ ".Operation"    

    Set className = ensOperationClassName
    #dim cDef As %Dictionary.ClassDefinition
    $$$QuitOnError(##class(Grongier.OpenApi.DefinitionV3).CreateClassDefInstance(className, .cDef))
    Set cDef.Super = "Ens.BusinessOperation"
    Set cDef.Description = "Generated Business Operation"
    $$$zlog("* Generate BusinessOperation class " _ className _" ...")

    #dim property As %Dictionary.PropertyDefinition = ##class(%Dictionary.PropertyDefinition).%New()
    Set property.Name = "Adapter"
    Set property.Type = "EnsLib.HTTP.OutboundAdapter"
    Do cDef.Properties.Insert(property)

    #dim classParameter As %Dictionary.ParameterDefinition = ##class(%Dictionary.ParameterDefinition).%New()
    Set classParameter.Name = "ADAPTER"
    Set classParameter.Default = "EnsLib.HTTP.OutboundAdapter"
    Do cDef.Parameters.Insert(classParameter)

    Set sc = cDef.%Save()

    Set sc = $$$ADDSC(sc, ..IterateOnOperation("GenerateMethodExecutor"))

	Return ..GenerateHandleRequestMethod()
}

/// Generate a method for handling a single operation
Method GenerateMethodExecutor(path As %String, pathItem As %DynamicObject, method As %String, operation As %DynamicObject) As %Status
{
    Set sc = $$$OK

    Set ensOperationClassName = ..application _"." _ ..#PKGOPERATION _ ".Operation"    
    Set requestClass = ..application _"." _ ..PackageRequest() _ "." _ $$$zNormalizeClassName(operation.operationId)
    Set responseClass = ..application _"." _ ..PackageResponse()_ "."  _ $$$zNormalizeClassName(operation.operationId)

    Set ..tmp("MessageMap","MessageType", requestClass) = $$$zNormalizeClassName(operation.operationId)

    Set classDef = ##class(%Dictionary.ClassDefinition).%OpenId(ensOperationClassName,, .sc)

    If $$$ISERR(sc) {
        $$$zlog("!cannot add executor method " _ ensOperationClassName _ " does not exist.")
        Return sc
    }

    $$$zlog("+ Add method " _ operation.operationId _ " to " _ ensOperationClassName)

    Set methodDef = ##class(%Dictionary.MethodDefinition).%New()
    Set methodDef.Description = "Implement operationId : " _ operation.operationId
        _ $Char(13,10) _ method _ " " _path
    Set methodDef.Name = $$$zNormalizeClassName(operation.operationId)
    Set methodDef.FormalSpec = "requestMessage:" _ requestClass _ ",*responseMessage:" 
        _ responseClass

    Set methodDef.ReturnType = "%Status"
    Do methodDef.Implementation.WriteLine( $Char(9) _ "set responseMessage = ##class(" _ responseClass _ ").%New()")
    Do methodDef.Implementation.WriteLine( $Char(9) _ "return ..zzHandleRequest(requestMessage, """ _ operation.operationId _ """, """_ method _""", responseMessage)" )
    Do classDef.Methods.Insert(methodDef)

    Return classDef.%Save()
}

/// Generate HandleRequest method
Method GenerateHandleRequestMethod() As %Status
{
    Set sc = $$$OK

    Set ensOperationClassName = ..application _"." _ ..#PKGOPERATION _ ".Operation"    

    Set classDef = ##class(%Dictionary.ClassDefinition).%OpenId(ensOperationClassName,, .sc)

    If $$$ISERR(sc) {
        $$$zlog("!cannot add HandleRequest method; " _ ensOperationClassName _ " does not exist.")
        Return sc
    }

    $$$zlog("+ Add method HandleRequest to " _ ensOperationClassName)

    Set methodDef = ##class(%Dictionary.MethodDefinition).%New()
    Set methodDef.Description = "Common request handler"
    Set methodDef.Name = "zzHandleRequest"
    Set methodDef.FormalSpec = "requestMessage:Ens.Request,name:%String,method:%String,responseMessage:" _ ..genericResponseClassName
    Set methodDef.ReturnType = "%Status"
	Do methodDef.Implementation.WriteLine( $Char(9) _ "set sc = $$$OK, pHttpRequestIn = ##class(%Net.HttpRequest).%New()")
	Do methodDef.Implementation.WriteLine( $Char(9) _ "$$$QuitOnError(requestMessage.LoadHttpRequestObject(pHttpRequestIn))")
	Do methodDef.Implementation.WriteLine( $Char(9) _ "set sc = ..Adapter.SendFormDataArray(.pHttpResponse, method, pHttpRequestIn, , , ..Adapter.URL _ requestMessage.%URL)")
    Do methodDef.Implementation.WriteLine( )
	Do methodDef.Implementation.WriteLine( $Char(9) _ "if $$$ISERR(sc) && ($SYSTEM.Status.GetErrorCodes(sc) '= $$$EnsErrHTTPStatus) {")
    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "return sc")
    Do methodDef.Implementation.WriteLine( $Char(9) _ "}")
    Do methodDef.Implementation.WriteLine( )
	Do methodDef.Implementation.WriteLine( $Char(9) _ "if $ISOBJECT(pHttpResponse) {")
    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "$$$TRACE(name _"" returned "" _ pHttpResponse.StatusCode)")
    Do methodDef.Implementation.WriteLine( $Char(9,9) _ "$$$QuitOnError(responseMessage.LoadFromResponse(pHttpResponse, name))")
    Do methodDef.Implementation.WriteLine( $Char(9) _ "}")
    Do methodDef.Implementation.WriteLine( )
    Do methodDef.Implementation.WriteLine( $Char(9) _ "return sc")

    Do classDef.Methods.Insert(methodDef)

    Return classDef.%Save()
}

Method GenerateProxyService() As %Status
{
    #dim className As %String = ..application _ "." _ ..#PKGSERVICES _ ".ProxyService"
    #dim classDef As %Dictionary.ClassDefinition
    $$$QuitOnError(##class(Grongier.OpenApi.DefinitionV3).CreateClassDefInstance(className, .classDef))
    Set classDef.Super = "Ens.BusinessService"
    Set classDef.ProcedureBlock = $$$YES
    Quit classDef.%Save()
}

Method GenerateProduction() As %Status
{
    Set sc = $$$OK
    Set productionClassName = ..application_".Production"

    #dim classDef As %Dictionary.ClassDefinition
    $$$QuitOnError(##class(Grongier.OpenApi.DefinitionV3).CreateClassDefInstance(productionClassName, .classDef))
    Set classDef.Super = "Ens.BusinessService"

    Set strServiceTemplate = "<Item Name=""{className}"" Category="""" ClassName=""{className}"" PoolSize=""1"" Enabled=""{enabled}"" Foreground=""false"" Comment="""" LogTraceEvents=""false"" Schedule=""""></Item>"

    Set (startKey, className, ensProxyServiceClassName) = ..application _ "." _ ..#PKGSERVICES _ ".", 
        ensProxyServiceClassName = ensProxyServiceClassName _"ProxyService"
    
    For  {
        Set className = $Order(^oddDEF(className))
        Quit:$Extract(className, 1, $LENGTH(startKey))'=startKey

        Set enabled = $Select(className = ensProxyServiceClassName: "true", 1: "false")
        Set service($Increment(service)) = $Replace($Replace(strServiceTemplate, "{className}", className), "{enabled}", enabled)
    }
    
    Set xData=##class(%Dictionary.XDataDefinition).%New()
    Set xData.Name = "ProductionDefinition"
    
    Set xDataTemplate = ##class(%Dictionary.XDataDefinition).%OpenId(..%ClassName(1)_"||ProductionDefinitionTemplate",,.sc)
    Return:$$$ISERR(sc) sc

    Set ensOperationClassName = ..application _"." _ ..#PKGOPERATION _ ".Operation"
    Set ensProcessClassName = ..application _"." _ ..#PKGPROCESS _ ".Process"
    Set ensProcessSyncClassName = ..application _"." _ ..#PKGPROCESS _ ".SyncProcess"

    Set server = $Select(..spec.%IsDefined("servers")&&$IsObject(..spec.servers.%Get(0)): ..spec.servers.%Get(0).url, 1:"")
    If server '= "" {
        Do ##class(%Net.URLParser).Decompose(server, .components)
    }

    While 'xDataTemplate.Data.AtEnd {
        Set line = xDataTemplate.Data.ReadLine()
        If line [ "{services}" {
            Set key = ""
            For  {
                Set key = $Order(service(key), 1, serviceStr)
                Quit:key=""
                Do xData.Data.WriteLine("  "_serviceStr)
            }
        } Else {
            Set line = $Replace(line, "{application}", ..application)
            Set line = $Replace(line, "{ensOperationClassName}", ensOperationClassName)
            Set line = $Replace(line, "{ensProcessClassName}", ensProcessClassName)
            Set line = $Replace(line, "{ensProcessSyncClassName}", ensProcessSyncClassName)
            Set line = $Replace(line, "{server}", $Get(components("host")))
            Set line = $Replace(line, "{port}", $Get(components("port")))
            Set line = $Replace(line, "{SSLConfig}", "DefaultSSL")
            Set line = $Replace(line, "{URL}", $Get(components("path")))
            
            Do xData.Data.WriteLine(line)
        }
    }

    Set cDef = ##class(%Dictionary.ClassDefinition).%New(productionClassName)
    Set cDef.ProcedureBlock = $$$YES
    Set cDef.Super = "Ens.Production"
    Do cDef.XDatas.Insert(xData)

    $$$QuitOnError(cDef.%Save())

    Return sc
}

/// Generate Message Map XDATA for Business Operation class<br/>
Method GenerateMessageMap() As %Status [ Private ]
{

    Set ensOperationClassName = ..application _"." _ ..#PKGOPERATION _ ".Operation"

    #dim cDef As %Dictionary.ClassDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(ensOperationClassName,,.sc)

    Quit:$$$ISERR(sc) sc
    
    Do ##class(dc.openapi.client.Spec).%RemoveXDataBlock(cDef, "MessageMap")

    Set xData=##class(%Dictionary.XDataDefinition).%New()
    Set xData.Name="MessageMap"

    Do xData.Data.WriteLine("<MapItems>")
    
    Set key = ""
    For  {

        Set key = $Order(..tmp("MessageMap", "MessageType", key),1 , methodName)
        Quit:key=""

        Do xData.Data.WriteLine($Char(9)_$$$FormatText("<MapItem MessageType=""%1"">", key))
        Do xData.Data.WriteLine($Char(9,9)_$$$FormatText("<Method>%1</Method>", methodName))
        Do xData.Data.WriteLine($Char(9)_"</MapItem>")

    }

    Do xData.Data.WriteLine("</MapItems>")

    Do cDef.XDatas.Insert(xData)
    Return cDef.%Save()
}

XData ProductionDefinitionTemplate
{
<Production Name="{application}" LogGeneralTraceEvents="false">
  <Description></Description>
  <ActorPoolSize>2</ActorPoolSize>
  {services}
  <Item Name="{ensOperationClassName}" Category="" ClassName="{ensOperationClassName}" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="HTTPServer">{server}</Setting>
    <Setting Target="Adapter" Name="SSLConfig">{SSLConfig}</Setting>
    <Setting Target="Adapter" Name="HTTPPort">{port}</Setting>
    <Setting Target="Adapter" Name="URL">{URL}</Setting>
  </Item>
  <Item Name="{ensProcessClassName}" Category="" ClassName="{ensProcessClassName}" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="{ensProcessSyncClassName}" Category="" ClassName="{ensProcessSyncClassName}" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
</Production>
}

}
