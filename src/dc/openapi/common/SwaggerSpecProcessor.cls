Class dc.openapi.common.SwaggerSpecProcessor Extends %RegisteredObject
{

Property OAS As %DynamicObject;

Property ExternalRefs As dc.openapi.common.SwaggerDocumentCollection;

Property Errors As %DynamicObject [ InitialExpression = {{}} ];

Property ExpectedExternalSwagger As list Of %String;

ClassMethod Test(show = 0) As %Status
{
    Set tSc = $$$OK
    
    Set oas = {}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/v1.json")
    Set ssi = {}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/ssi_types.json")
    Set err = {}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/error_response.json")
    
    Set pp = ##class(dc.openapi.common.SwaggerSpecProcessor).%New()
    Set pp.OAS = oas
    Set pp.ExternalRefs = ##class(dc.openapi.common.SwaggerDocumentCollection).%New()
    Do pp.ExternalRefs.AddItem(ssi, "../common/ssi_types.yaml", 1)
    Do pp.ExternalRefs.AddItem(err, "../common/error_response.yaml", 0)
    
    ;w pp.ExternalRefs.GetDocument("../common/ssi_types.yaml", .found)

    Set tSc = pp.PreProcess()
    w !
    zw tSc
    
    W !
    ;zw pp.ExpectedExternalSwagger.GetAt(1)
    zw pp.Errors
    w !

    Do:show ##class(%JSON.Formatter).%New().Format(pp.OAS)
    Quit tSc
}

Method PreProcess() As %Status
{
    Set tSc = $$$OK
    
    Set isValid = ..Validate()

    If 'isValid {
        Set tSc = $$$ERROR($$$GeneralError, "Validation failed, check the Errors property")
        Return tSc
    }

    ; Resolve external documents that are not full specifications
    #dim externalSwaggerItem As dc.openapi.common.SwaggerDocumentReference
    Set key = ""
    For  {
        Set externalSwaggerItem = ..ExternalRefs.Items.GetNext(.key)
        Quit:key=""
        If externalSwaggerItem.IsAFullSpecification {
            Continue
        }
        Do ..ResolveExternalDocument(externalSwaggerItem.Document, key)
    }

    ; flatten the document
    ; firstly use validator.swagger.io

    Set webValidator = ##class(dc.swaggervalidatorcli.WebSwaggerValidator).%New()
    Set queryParameters("flatten")="true"
    Set tSc = webValidator.Parse(.queryParameters, .outSpec, ..OAS)

    If $$$ISERR(tSc) {
        Return tSc
    }
    
    Set flattener = ##class(dc.openapi.common.Flattener).%New()
    Set flattener.OAS = outSpec
    Set tSc = flattener.Lift()

    If $$$ISERR(tSc) {
        Return tSc
    }

    Set transformer = ##class(dc.openapi.common.SwaggerToASTConverter).%New()
    Set transformer.OAS = flattener.OAS
    Set transformer.PackageModel = "myapp.models"

    Set tSc = transformer.Transform()
    If $$$ISERR(tSc) {
        Write "Error: ", $SYSTEM.Status.GetErrorText(tSc), !
        Return tSc
    }
    
    Do transformer.AST.%JSONExportToString(.tempString)
    Do ##class(%JSON.Formatter).%New().FormatToString(tempString, .string)
    Write !, string
    ;Do ##class(%JSON.Formatter).%New().Format(outSpec)

    Return tSc
}

Method ResolveExternalDocument(document As %DynamicObject, externalReference As %String) As %Status
{
    #dim externalSwaggerItem As dc.openapi.common.SwaggerDocumentReference
    Set key = ""
    For  {
        Set externalSwaggerItem = ..ExternalRefs.Items.GetNext(.key)
        Quit:key=""
        If 'externalSwaggerItem.IsAFullSpecification Continue
        Set currentDocument = externalSwaggerItem.Document
        Do ResolveDoc
    }
    Set currentDocument = ..OAS
    Do ResolveDoc
    Return $$$OK

ResolveDoc
    Do ##class(dc.openapi.common.ReferenceAnalyzer).CollectOASReferences(currentDocument, .out)
    Set n = ""
    For  {
        Set n = $Order(out(n), 1, line)
        Quit:n=""
        If $Extract(line, *-3, *) '= "$ref" Continue
        Set reference = ##class(dc.openapi.common.ReferenceAnalyzer).GetValue(currentDocument, line)
        If reference = externalReference {
            Set parent = $Piece(line, ##class(dc.openapi.common.ReferenceAnalyzer).#SEPARATOR, 1, * - 2)
            Set name = $Piece(line, ##class(dc.openapi.common.ReferenceAnalyzer).#SEPARATOR,* - 1)
            Set parentObject = ##class(dc.openapi.common.ReferenceAnalyzer).GetValue(.currentDocument, parent)
            Do parentObject.%Set(name, {}.%FromJSON(document.%ToJSON()))
        }
    }
    Kill out

    Quit 1
}

Method Validate() As %Boolean
{
    Set isValid = $$$YES
    Set document = ..OAS ; specification to process ...

    
    Set getInternal = $$$YES, getExternal = $$$YES
    Set references = ##class(dc.openapi.common.ReferenceAnalyzer).GetListOfRefs(document, getInternal, getExternal)
    
    Set uniqueExternal = ""

    Set ptr = 0
    While $ListNext(references, ptr, ref) {
        Set isDefined = ..ReferenceIsDefined(document, ref)
        If 'isDefined {
            Write !,"Reference not defined: ", ref
            Set:isValid isValid = $$$NO
        }

        Do alimUniqueExternal
    }

    ; Check if the external references are defined
    Set key = ""
    For  {
        Set item = ..ExternalRefs.Items.GetNext(.key)
        Quit:key=""
        w !,"item   : ", key
        Set document = item.Document
        Set references = ##class(dc.openapi.common.ReferenceAnalyzer).GetListOfRefs(document, getInternal, getExternal)
        Set ptr = 0
        While $ListNext(references, ptr, ref) {
            Set isDefined = ..ReferenceIsDefined(document, ref)
            If 'isDefined {
                Write !,"External reference not defined: ", ref, !
                Set:isValid isValid = $$$NO
            }
            Do alimUniqueExternal
        }
    }

    ; Check if expected external document are defined
    Set ..Errors.MissingExternalSwagger = []
    Set key = ""
    For  {
        Set key = $Order(uniqueExternal(key))
        Quit:key=""

        If '..ExternalRefs.ItemExists(key) {
            Write !,"Missing external document: ", key, !
            Do ..Errors.MissingExternalSwagger.%Push(key)
            Set:isValid isValid = $$$NO
        }
    }

    Return isValid

alimUniqueExternal
    Set externalPart = $Piece(ref, "#", 1)
    If externalPart '= "" && '$Data(uniqueExternal(externalPart)) {
        Set uniqueExternal(externalPart) = ""
        Do ..ExpectedExternalSwagger.Insert(externalPart)
    }
    Quit 1
}

Method ReferenceIsDefined(document As %DynamicObject, ref As %String) As %Boolean
{
    If $Extract(ref) = "#" {
        ; It's an internal reference
        Return ##class(dc.openapi.common.ReferenceAnalyzer).ReferenceIsDefined(document, ref)
    }

    ; It's an external reference
    ; Check if the external reference is already in the list
    Set key = $Piece(ref, "#", 1)
    Set document = ..ExternalRefs.GetDocument(key, .found)
    If 'found Return $$$NO

    Return ##class(dc.openapi.common.ReferenceAnalyzer).ReferenceIsDefined(document, ref)
}

}
