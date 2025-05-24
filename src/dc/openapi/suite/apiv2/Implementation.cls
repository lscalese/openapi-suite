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
        Set preparer = ..GetPreparerForValidation(.code, .response)
        If code '= "" {
            Set %response.Status = code
            Return response
        }
        Else {
            Set documentCollection = preparer.GetDocumentCollection()
            Set validationResult =##class(dc.openapi.suite.services.Generator).DocumentCollectionValidation(documentCollection)
            Do validationResult.%JSONExportToString(.responseStr)
            Set response = responseStr
        }
    }
    Catch ex {
        Set response.error = "Error processing request: "_ex.AsStatus()
        Set %response.Status = ##class(%CSP.REST).#HTTP500INTERNALSERVERERROR
    }
    Return response
}

ClassMethod GenerateASTCollection() As %DynamicObject
{
    #dim %request As %CSP.Request
    Set response = {}
    Set tSc =$$$OK
    Try {
        Set preparer = ..GetPreparerForValidation(.code, .response)
        If code '= "" {
            Set %response.Status = code
            Return response
        }
        Else {
            Set response = ##class(%Stream.GlobalCharacter).%New()
            Set documentCollection = preparer.GetDocumentCollection()
            $$$TOE(tSc, ##class(dc.openapi.suite.services.Generator).DocumentCollectionToAST(documentCollection, .ASTCollection))
            $$$TOE(tSc,ASTCollection.%JSONExportToStream(.response))
        }
    }
    Catch ex {
        Set response.error = "Error processing request: "_ex.AsStatus()
        Set %response.Status = ##class(%CSP.REST).#HTTP500INTERNALSERVERERROR
    }
    Return response
}

ClassMethod GetPreparerForValidation(Output code As %String = "", Output response As %DynamicObject) As dc.openapi.common.SwaggerDocumentPreparer
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

/// complex and common code to create a SwaggerDocumentPreparer object
/// from %request.
ClassMethod GetPreparer(Output code As %String = "", Output response As %DynamicObject) As dc.openapi.common.SwaggerDocumentPreparer
{
    #dim %response As %CSP.Response
    Set preparer = ##class(dc.openapi.common.SwaggerDocumentPreparer).%New()

    Set response = {}
    
    Set documentKeys = $Get(%request.Data("documentKeys", 1))
    Set documentSettings = {}.%FromJSON("[" _ $g(%request.Data("documentSettings",1)) _ "]")
    
    Set iterator = documentSettings.%GetIterator()
    While iterator.%GetNext(.key, .value) {
        Set arrayDocumentSettings(value.key) = value
    }
    
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

        Set settings = $Get(arrayDocumentSettings(documentKey))
        If '$IsObject(settings) || (settings.modelPackage = ""){
            Set response.error = "DocumentSettings not found for document key "_documentKey_" (modelPackage is mandatory) "
            Set code = ##class(%CSP.REST).#HTTP400BADREQUEST
            Quit
        }

        If documentKey = ##class(dc.openapi.common.SwaggerDocumentCollection).#MAINKEY {
            $$$TOE(sc, preparer.SetMainDocument(currentDocument, settings) )
        }
        Else {
            $$$TOE(sc, preparer.AddDocument(currentDocument, documentKey, settings) )
        }
    }

    If documentCount = 0 {
        Set response.error = "No documents found in the request"
        Set code = ##class(%CSP.REST).#HTTP400BADREQUEST
    }
    

    Return preparer
}

}
