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

    #dim ASTReference As dc.openapi.common.ASTReference
    Set ASTReference = ..Config.ASTReference
    

    $$$LOGINFO("Generating HTTP Client classes...")

    If ..Config.GenerateModels {
        $$$LOGINFO("Generating models...")
        Set tSc = ..GenerateModels()
        Set sc = $$$ADDSC(sc,tSc)
        $$$LOGSTATUS("Models generation " _ $Select($$$ISOK(tSc):"completed successfully", 1:"failed with error: " _ $SYSTEM.Status.GetErrorText(tSc)),tSc)
    } 
    Else {
        $$$LOGINFO("Models generation skipped based on configuration")
    }

    Set httpClientClass = ""
    If ..Config.GenerateClientClass {
        $$$LOGINFO("Generating HTTP client class: " _ ..Config.HttpClientClassName)
        Set clientClassGenerator = ##class(dc.openapi.client.generator.ClientClassGenerator).%New()
        Set clientClassGenerator.ClassName = ..Config.HttpClientClassName
        Set clientClassGenerator.OverrideClassIfExists = ..Config.OverrideClientClass
        Set clientClassGenerator.ASTReference = ASTReference
        Set httpClientClass = clientClassGenerator.Generate()
        $$$LOGDEBUG("HTTP client class structure generated")
    }
    Else { ; open the class definition if exists
        $$$LOGINFO("HTTP client class generation skipped based on configuration")
        Set httpClientClass = ##class(%Dictionary.ClassDefinition).%OpenId(..Config.HttpClientClassName)
        If httpClientClass = "" {
            $$$LOGWARNING("HTTP client class '" _ ..Config.HttpClientClassName _ "' not found")
        }
    }

    If ..Config.GenerateAbstractResponseClass {
        $$$LOGINFO("Generating abstract response class: " _ ..Config.AbstractResponseClassName)
        Set abstractResponseClassGenerator = ##class(dc.openapi.client.generator.AbstractResponseClassGenerator).%New()
        Set abstractResponseClassGenerator.ClassName = ..Config.AbstractResponseClassName
        Set abstractResponseClassGenerator.OverrideClassIfExists = ..Config.OverrideAbstractResponseClass
        Set abstractResponseClass = abstractResponseClassGenerator.Generate()
        Set tSc = abstractResponseClass.%Save()
        Set sc = $$$ADDSC(sc,tSc)
        $$$LOGSTATUS("Abstract response class saved with " _ $Select($$$ISOK(tSc):"success", 1:"error: " _ $SYSTEM.Status.GetErrorText(tSc)),tSc)
    }

    Set responseModelGenerator = ##class(dc.openapi.client.generator.ResponseModelGenerator).%New()
    Set responseModelGenerator.Super = ..Config.AbstractResponseClassName
    Set requestModelGenerator = ##class(dc.openapi.client.generator.RequestModelGenerator).%New()
    
    $$$LOGINFO("Processing API paths...")
    Set key = ""
    Set pathCount = 0
    For  {
        Set path = ASTReference.AST.Paths.GetNext(.key)
        Quit:key=""

        If '..Config.ProcessOperationId.GetAt(path.OperationId) {
            $$$LOGDEBUG("Skipping path: " _ path.OperationId)
            Continue
        }
        
        Set pathCount = pathCount + 1
        $$$LOGDEBUG("Processing path #" _ pathCount _ ": operation=" _ path.OperationId)

        Set requestModelClassName = ..Config.GenerateOperationRequestClassNames.GetAt(path.OperationId)
        If ..Config.GenerateOperationRequestClasses.GetAt(path.OperationId) {
            $$$LOGDEBUG("Generating request model class: " _ requestModelClassName)
            Set requestModelGenerator.ClassName = requestModelClassName
            Set requestModelGenerator.OverrideClassIfExists = ''..Config.OverrideOperationRequestClassNames.GetAt(path.OperationId)
            Set requestClassModel = requestModelGenerator.Generate(path)
            Set tSc = requestClassModel.%Save()
            Set sc = $$$ADDSC(sc,tSc)
            $$$LOGSTATUS("Request class '" _ requestModelClassName _ "' saved with " _ $Select($$$ISOK(tSc):"success", 1:"error: " _ $SYSTEM.Status.GetErrorText(tSc)),tSc)
        } 
        Else {
            $$$LOGDEBUG("Skipping request model generation for operation: " _ path.OperationId)
        }

        Set responseModelClassName = ..Config.GenerateOperationResponseClassNames.GetAt(path.OperationId)
        If ..Config.GenerateOperationResponseClasses.GetAt(path.OperationId) {
            $$$LOGDEBUG("Generating response model class: " _ responseModelClassName)
            Set responseModelGenerator.ClassName = responseModelClassName
            Set responseModelGenerator.OverrideClassIfExists = ''..Config.OverrideOperationResponseClassNames.GetAt(path.OperationId)
            Set responseClassModel = responseModelGenerator.Generate(path)
            Set tSc = responseClassModel.%Save()
            Set sc = $$$ADDSC(sc,tSc)
            $$$LOGSTATUS("Response class '" _ responseModelClassName _ "' saved with " _ $Select($$$ISOK(tSc):"success", 1:"error: " _ $SYSTEM.Status.GetErrorText(tSc)),tSc)
        } 
        Else {
            $$$LOGDEBUG("Skipping response model generation for operation: " _ path.OperationId)
        }

        If $IsObject(httpClientClass), '##class(%Dictionary.MethodDefinition).%ExistsId(httpClientClass_"||"_path.OperationId) {
            $$$LOGDEBUG("Adding operation method for: " _ path.OperationId)
            Set operationMethod = clientClassGenerator.GetOperationMethod(path, requestModelClassName, responseModelClassName)
            Do httpClientClass.Methods.Insert(operationMethod)
        }
        Else {
            $$$LOGDEBUG("Skipping adding operation method generation for: " _ path.OperationId _ "(httpClientClass not found or method already exists)")
        }
    }
    $$$LOGINFO("Processed " _ pathCount _ " API paths")

    If $IsObject(httpClientClass) {
        $$$LOGINFO("Saving HTTP client class...")
        Set tSc = httpClientClass.%Save()
        Set sc = $$$ADDSC(sc,tSc)
        $$$LOGSTATUS("HTTP client class saved with " _ $Select($$$ISOK(tSc):"success", 1:"error: " _ $SYSTEM.Status.GetErrorText(tSc)),tSc)
    }

    $$$LOGSTATUS("HTTP Client generation " _ $Select($$$ISOK(sc):"completed successfully", 1:"completed with issues: " _ $SYSTEM.Status.GetErrorText(sc)),sc)
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
        
        $$$LOGSTATUS("Model '" _ model.Name _ "' saved with " _ $Select($$$ISOK(tScLocal):"success", 1:"error: " _ $SYSTEM.Status.GetErrorText(tScLocal)),tScLocal)
    }
    
    $$$LOGSTATUS("Generated " _ modelCount _ " model classes with " _ $Select($$$ISOK(tSc):"success", 1:"errors: " _ $SYSTEM.Status.GetErrorText(tSc)),tSc)
    Return tSc
}

}
