Include dc.openapi.common.macro

Class dc.openapi.suite.apiv2.Implementation Extends %REST.Impl [ ProcedureBlock ]
{

ClassMethod Ping() As %Status
{
    Return {
        "status": "ok",
        "message": ("Ping successful "_$zdt($h,3,1))
    }
}

ClassMethod SwaggerSpec() As %DynamicObject
{
    Set spec = {}.%FromJSONFile("/home/irisowner/irisdev/src/dc/openapi/suite/apiv2/openapi-suite_v2.json")
	Set url = $Select(%request.Secure:"https",1:"http") _ "://"_$Get(%request.CgiEnvs("SERVER_NAME")) _ ":" _ $Get(%request.CgiEnvs("SERVER_PORT")) _ %request.Application
	Set spec.servers = [{"url" : (url)}]
	Quit spec
}

ClassMethod ValidateDocumentCollection() As %DynamicObject
{
    #dim %request As %CSP.Request
    Set response = {}
    Try {
        Set logLevel = $Get(%request.Data("logs",1))
        Do:logLevel'="" ##class(dc.openapi.common.TinyLogger).StartSession({"level":($$$LOGLEVEL(logLevel))})
        Set preparer = ..GetPreparer(.code, .response)
        If code '= "" {
            Set %response.Status = code
        }
        Else {
            Set documentCollection = preparer.GetDocumentCollection()
            Set validationResult =##class(dc.openapi.suite.services.Generator).DocumentCollectionValidation(documentCollection)
            Do validationResult.%JSONExportToString(.responseStr)
            Set response = {}.%FromJSON(responseStr)
        }
    }
    Catch ex {
        Set response.error = "Error processing request: "_ex.AsStatus()
        Set %response.Status = ##class(%CSP.REST).#HTTP500INTERNALSERVERERROR
    }
    Do ..AddLogsToResponse(.response)
    Return response
}

ClassMethod GetHttpClientGenConfig(Package As %String, ASTReference As dc.openapi.common.ASTReference) As dc.openapi.client.config.HttpClientGenConfig
{
    Set clientConfig = ##class(dc.openapi.suite.services.Generator).GetHttpClientGenConfig(Package, ASTReference)
    Set response = clientConfig.ToJSONWithArraysAsKeyValue()
    Return response
}

ClassMethod GenerateASTCollection() As %DynamicObject
{
    #dim %request As %CSP.Request
    Set response = {}
    Set tSc =$$$OK
    Try {
        Set logLevel = $Get(%request.Data("logs",1))
        Do:logLevel'="" ##class(dc.openapi.common.TinyLogger).StartSession({"level":($$$LOGLEVEL(logLevel))})
        Set preparer = ..GetPreparer(.code, .response)
        If code '= "" {
            Set %response.Status = code
        }
        Else {
            Set responseGCS = ##class(%Stream.GlobalCharacter).%New()
            Set documentCollection = preparer.GetDocumentCollection()
            $$$TOE(tSc, ##class(dc.openapi.suite.services.Generator).DocumentCollectionToAST(documentCollection, .ASTCollection))
            $$$TOE(tSc,ASTCollection.%JSONExportToStream(.responseGCS))
            Set response = {}.%FromJSON(responseGCS)
        }
    }
    Catch ex {
        Set response.error = "Error processing request: "_ex.AsStatus()
        Set %response.Status = ##class(%CSP.REST).#HTTP500INTERNALSERVERERROR
    }
    Do ..AddLogsToResponse(.response)
    Return response
}

ClassMethod GenerateModels() As %DynamicObject
{
    #dim %request As %CSP.Request
    Set response = {}
    Set tSc =$$$OK
    Set namespaceOrigin = $Namespace New $Namespace
    Try {
        Set mode = $Get(%request.Data("mode",1), "download")
        Do:$Data(%request.Data("logs",1),logLevel) ##class(dc.openapi.common.TinyLogger).StartSession({"level":($$$LOGLEVEL(logLevel))})
        Set ASTCollection = ##class(dc.openapi.common.ASTCollection).%New()
        $$$TOE(tSc,ASTCollection.%JSONImport(%request.Content))
        TSTART:mode="download"
        Set:$Data(%request.Data("namespace",1),namespace)&&(namespace'="") $Namespace = namespace
        $$$TOE(tSc,##class(dc.openapi.suite.services.Generator).GenerateModels(ASTCollection))
        Set generationResult = ##class(dc.openapi.suite.services.Generator).GetGenerationResult()
        Set response = ##class(%Stream.GlobalCharacter).%New()
        $$$TOE(tSc,generationResult.%JSONExportToStream(.response))
    }
    Catch ex {
        Set response.error = "Error processing request: "_ex.AsStatus()
        Set %response.Status = ##class(%CSP.REST).#HTTP500INTERNALSERVERERROR
    }
    TROLLBACK:$TLEVEL
    Set:$Namespace'=namespaceOrigin $Namespace = namespaceOrigin
    Return response
}

ClassMethod GetPreparer(Output code As %String = "", Output response As %DynamicObject) As dc.openapi.common.SwaggerDocumentPreparer
{
    #dim %response As %CSP.Response
    Set preparer = ##class(dc.openapi.common.SwaggerDocumentPreparer).%New()

    Set response = {}
    Set documentKeys = $Get(%request.Data("documentKeys", 1))
    
    Set index = "", documentCount = 0
    For  {
        Set index = $Order(%request.MimeData("documents", index), 1, currentDocument)
        Quit:index=""
        Do $Increment(documentCount)

        Set documentKey = $Piece(documentKeys, ",", index)

        If documentKey = "" {
            Set response.error = "Document key not found for document "_index
            Set code = ##class(%CSP.REST).#HTTP400BADREQUEST
            Quit
        }

        If documentKey = ##class(dc.openapi.common.SwaggerDocumentCollection).#MAINKEY {
            $$$TOE(sc, preparer.SetMainDocument(currentDocument) )
        }
        Else {
            $$$TOE(sc, preparer.AddDocument(currentDocument, documentKey) )
        }
    }

    If documentCount = 0 {
        Set response.error = "No documents found in the request"
        Set code = ##class(%CSP.REST).#HTTP400BADREQUEST
    }
    
    Return preparer
}

ClassMethod AddLogsToResponse(response As %DynamicObject) [ Private ]
{
    Set:'response.%IsDefined("logs") response.logs = []
    #dim logInstance As dc.openapi.common.TinyLogger
    Set logInstance = ##class(dc.openapi.common.TinyLogger).GetInstance()
    Set key = ""
    For  {
        Set log = logInstance.Logs.GetNext(.key)
        Quit:key=""
        Do response.logs.%Push(log)
    }
    Return
}

}
