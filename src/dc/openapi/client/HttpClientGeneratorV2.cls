Include dc.openapi.common.macro

Class dc.openapi.client.HttpClientGeneratorV2 Extends %RegisteredObject
{

Parameter HTTPREQUESTOBJECT = "httpRequest";

/// Configuration pour contrôler le processus de génération
Property Config As dc.openapi.client.config.HttpClientGenConfig;

Method %OnNew(config As dc.openapi.client.config.HttpClientGenConfig = "") As %Status
{
    Set:$IsObject(config) ..Config = config
    $$$LOGDEBUG("HttpClientGeneratorV2 initialized with config: "_$Select($IsObject(config):"provided", 1:"default"))
    Return $$$OK
}

Method Generate() As %Status
{
    Set sc = $$$OK

    Set AST = ..Config.AST

    $$$LOGINFO("Generating HTTP Client classes...")

    If ..Config.GenerateModels {
        $$$LOGINFO("Generating models...")
        Set tSc = ..GenerateModels()
        Set sc = $$$ADDSC(sc,tSc)
        $$$LOGINFO("Models generation " _ $Select($$$ISOK(tSc):"completed successfully", 1:"failed with error: " _ $SYSTEM.Status.GetErrorText(tSc)))
    } 
    Else {
        $$$LOGINFO("Models generation skipped based on configuration")
    }

    If ..Config.GenerateClientClass {
        $$$LOGINFO("Generating HTTP client class: " _ ..Config.HttpClientClassName)
        Set clientClassGenerator = ##class(dc.openapi.client.generator.ClientClassGenerator).%New()
        Set clientClassGenerator.ClassName = ..Config.HttpClientClassName
        Set clientClassGenerator.AST = AST
        Set httpClientClass = clientClassGenerator.Generate()
        $$$LOGDEBUG("HTTP client class structure generated")
    }

    If ..Config.GenerateAbstractResponseClass {
        $$$LOGINFO("Generating abstract response class: " _ ..Config.AbstractResponseClassName)
        Set abstractResponseClassGenerator = ##class(dc.openapi.client.generator.AbstractResponseClassGenerator).%New()
        Set abstractResponseClassGenerator.ClassName = ..Config.AbstractResponseClassName
        Set abstractResponseClass = abstractResponseClassGenerator.Generate()
        Set tSc = abstractResponseClass.%Save()
        Set sc = $$$ADDSC(sc,tSc)
        $$$LOGDEBUG("Abstract response class saved with status: " _ $Select($$$ISOK(tSc):"OK", 1:$SYSTEM.Status.GetErrorText(tSc)))
    }

    Set responseModelGenerator = ##class(dc.openapi.client.generator.ResponseModelGenerator).%New()
    Set responseModelGenerator.Super = ..Config.AbstractResponseClassName
    Set requestModelGenerator = ##class(dc.openapi.client.generator.RequestModelGenerator).%New()
    
    $$$LOGINFO("Processing API paths...")
    Set key = ""
    Set pathCount = 0
    For  {
        Set path = AST.Paths.GetNext(.key)
        Quit:key=""
        
        Set pathCount = pathCount + 1
        $$$LOGDEBUG("Processing path #" _ pathCount _ ": operation=" _ path.OperationId)

        Set requestModelClassName = ..Config.GenerateOperationRequestClassNames.GetAt(path.OperationId)
        If ..Config.GenerateOperationRequestClasses.GetAt(path.OperationId) {
            $$$LOGDEBUG("Generating request model class: " _ requestModelClassName)
            Set requestModelGenerator.ClassName = requestModelClassName
            Set requestClassModel = requestModelGenerator.Generate(path)
            Set tSc = requestClassModel.%Save()
            Set sc = $$$ADDSC(sc,tSc)
            $$$LOGDEBUG("Request class saved with status: " _ $Select($$$ISOK(tSc):"OK", 1:$SYSTEM.Status.GetErrorText(tSc)))
        } Else {
            $$$LOGDEBUG("Skipping request model generation for operation: " _ path.OperationId)
        }

        Set responseModelClassName = ..Config.GenerateOperationResponseClassNames.GetAt(path.OperationId)
        If ..Config.GenerateOperationResponseClasses.GetAt(path.OperationId) {
            $$$LOGDEBUG("Generating response model class: " _ responseModelClassName)
            Set responseModelGenerator.ClassName = responseModelClassName
            Set responseClassModel = responseModelGenerator.Generate(path)
            Set tSc = responseClassModel.%Save()
            Set sc = $$$ADDSC(sc,tSc)
            $$$LOGDEBUG("Response class saved with status: " _ $Select($$$ISOK(tSc):"OK", 1:$SYSTEM.Status.GetErrorText(tSc)))
        } Else {
            $$$LOGDEBUG("Skipping response model generation for operation: " _ path.OperationId)
        }

        If ..Config.GenerateClientClass {
            $$$LOGDEBUG("Adding operation method for: " _ path.OperationId)
            Set operationMethod = clientClassGenerator.GetOperationMethod(path, requestModelClassName, responseModelClassName)
            Do httpClientClass.Methods.Insert(operationMethod)
        }
    }
    $$$LOGINFO("Processed " _ pathCount _ " API paths")

    If ..Config.GenerateClientClass {
        $$$LOGINFO("Saving HTTP client class...")
        Set tSc = httpClientClass.%Save()
        Set sc = $$$ADDSC(sc,tSc)
        $$$LOGINFO("HTTP client class saved with status: " _ $Select($$$ISOK(tSc):"OK", 1:$SYSTEM.Status.GetErrorText(tSc)))
    }

    $$$LOGINFO("HTTP Client generation " _ $Select($$$ISOK(sc):"completed successfully", 1:"completed with issues: " _ $SYSTEM.Status.GetErrorText(sc)))
    Return sc
}

Method GenerateModels() As %Status
{
    Set tSc = $$$OK
    #dim model As dc.openapi.common.ast.Model
    #dim models As %ListOfObjects

    Set models = ..Config.AST.Models
    Set key = ""
    Set modelCount = 0
    
    $$$LOGINFO("Starting model generation")
    For  {
        Set model = models.GetNext(.key)
        Quit:key=""
        
        Set modelCount = modelCount + 1
        $$$LOGDEBUG("Generating model #" _ modelCount _ ": " _ model.Name)
        
        Set modelGenerator = ##class(dc.openapi.common.generator.ModelGenerator).%New()
        Set modelGenerator.ClassName = model.Name
        Set modelGenerator.Super = model.Super
        Set classDef = modelGenerator.Generate(model)
        Set tScLocal = classDef.%Save()
        Set:$$$ISERR(tScLocal) tSc = $$$ADDSC(tSc,tScLocal)
        
        $$$LOGDEBUG("Model " _ model.Name _ " saved with status: " _ $Select($$$ISOK(tScLocal):"OK", 1:$SYSTEM.Status.GetErrorText(tScLocal)))
    }
    
    $$$LOGINFO("Generated " _ modelCount _ " model classes with final status: " _ $Select($$$ISOK(tSc):"OK", 1:$SYSTEM.Status.GetErrorText(tSc)))
    Return tSc
}

}
