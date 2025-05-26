Include dc.openapi.common.macro

/// To simplify the process of converting OpenAPI documents to AST structure
/// This class processes OpenAPI documents according to the following rules:
/// 
/// Prerequisites:
/// - Document must be a valid OpenAPI document
/// - All $ref references must be defined within the document
/// - External document references must be defined in the DocumentCollection
/// 
/// Simplification Process:
/// 1. Resolves all external documents that are not full specifications
/// 2. Flattens documents using the web validator for normalization
/// 3. Resolves all non-object components in /components/schemas (string, number, integer, boolean, array)
///    leaving only object definitions in components
/// 4. Resolves all common parameters in the paths section
/// 5. Consolidates schema references to improve processing efficiency
Class dc.openapi.common.SwaggerSpecProcessor Extends %RegisteredObject
{

Property DocumentCollection As dc.openapi.common.SwaggerDocumentCollection;

Property ExpectedExternalSwagger As list Of %String;

Property ValidationResult As dc.openapi.common.ValidationResult [ InitialExpression = {##class(dc.openapi.common.ValidationResult).%New()} ];

Method %OnNew(DocumentCollection As dc.openapi.common.SwaggerDocumentCollection) As %Status
{
    Set ..DocumentCollection = DocumentCollection
    Return $$$OK
}

Method PreProcess() As %Status
{
    Set tSc = $$$OK
    
    Try{
        Set isValid = ..Validate()

        If 'isValid {
            $$$ThrowStatus($$$ERROR($$$GeneralError, "Validation failed, check logs for details."))
        }
        
        ; Resolve external documents that are not full specifications
        #dim documentReference As dc.openapi.common.SwaggerDocumentReference
        Set key = ""
        For  {
            Set documentReference = ..DocumentCollection.Items.GetNext(.key)
            Quit:key=""
            If documentReference.IsAFullSpecification Continue
            Do ..ResolveExternalDocument(documentReference.Document, key)
        }

        ; flatten the documents
        ; firstly use validator.swagger.io
        Set key = ""
        For  {
            Set documentReference = ..DocumentCollection.Items.GetNext(.key)
            Quit:key=""
            If 'documentReference.IsAFullSpecification Continue
            $$$LOGINFO("Starting to flatten  document: "_key _" using the web validator tools.")
            Set webValidator = ##class(dc.swaggervalidatorcli.WebSwaggerValidator).%New()
            Set queryParameters("flatten") = "true"
            Set tSc = webValidator.Parse(.queryParameters, .outSpec, documentReference.Document)
            If $$$ISERR(tSc) {
                $$$LOGERROR("Failed to flatten document: "_key_" using the web validator tools.")
                $$$ThrowStatus(tSc)
            }
            Set documentReference.Document = outSpec
            Kill outSpec
        }

        Set tSc = ..ResolveNonObjectComponents()
        If $$$ISERR(tSc) {
            $$$ThrowStatus(tSc)
        }

        Set flattener = ##class(dc.openapi.common.Flattener).%New()
        Set flattener.DocumentCollection = ..DocumentCollection
        Set tSc = flattener.Lift()

        If $$$ISERR(tSc) {
            $$$LOGERROR("Failed to flatten document "_$SYSTEM.Status.GetErrorText(tSc))
            $$$ThrowStatus(tSc)
        }

        Set tSc = ..ResolveAllCommonParameters()
        If $$$ISERR(tSc) {
            $$$ThrowStatus(tSc)
        }

        If $$$LOGTRACEENABLED {
            Set key = ""
            For  {
                Set documentReference = ..DocumentCollection.Items.GetNext(.key)
                Quit:key=""
                If 'documentReference.IsAFullSpecification Continue
                Do ##class(%JSON.Formatter).%New().FormatToString(documentReference.Document, .docString)
                $$$LOGTRACE($$$FormatText("Document %1 after preprocessing: "_$$$NL_"%2", key, docString))
            }
        }

        $$$LOGINFO("Preprocessing completed successfully.")
    } 
    Catch ex {
        Set tSc = ex.AsStatus()
        $$$LOGERROR("Error during preprocessing: "_$SYSTEM.Status.GetErrorText(tSc))
        $$$LOGERROR("SwaggerSpecProcessor Errors: "_ $$$NL _ jsonErrors)
        Return tSc
    }

    Return tSc
}

Method Validate() As %Boolean
{
    Set isValid = $$$YES, getInternal = $$$YES, getExternal = $$$YES
    
    ; Check if the references are defined
    Set key = ""
    For  {
        Set item = ..DocumentCollection.Items.GetNext(.key)
        Quit:key=""
        
        $$$LOGINFO("Starting validation for document: "_key)


        Set document = item.Document
        Set references = ##class(dc.openapi.common.ReferenceAnalyzer).GetListOfRefs(document, getInternal, getExternal)

        $$$LOGINFO("Check used $ref are defined, Number of references: "_$ListLength(references))

        Set ptr = 0
        While $ListNext(references, ptr, ref) {
            Set isDefined = ..ReferenceIsDefined(document, ref)
            If 'isDefined {
                $$$LOGERROR("Undefined reference in document: "_ref)
                Do ..ValidationResult.UndefinedReferences.Insert("Undefined Reference in document "_key _" : "_ref)
                Set:isValid isValid = $$$NO
            }
            Else {
                $$$LOGINFO("Valid reference found in document: "_ref)
            }
            Do alimUniqueExternal
        }
    }

    ; Check if expected external document are defined
    Set key = ""
    For  {
        Set key = $Order(uniqueExternal(key))
        Quit:key=""

        If '..DocumentCollection.ItemExists(key) {
            $$$LOGERROR("Missing external document: "_key)
            Do ..ValidationResult.MissingExternalDocuments.Insert(key)
            Set:isValid isValid = $$$NO
        }
    }

    Set ..ValidationResult.IsValid = isValid

    Return isValid

alimUniqueExternal
    kill part
    Do ##class(dc.openapi.common.ReferenceAnalyzer).DecomposeRef(ref, .part)
    Set externalPart = part("external")
    If externalPart '= "" && '$Data(uniqueExternal(externalPart)) {
        Set uniqueExternal(externalPart) = ""
        Do ..ExpectedExternalSwagger.Insert(externalPart)
        Do ..ValidationResult.ExpectedExternalDocuments.Insert(externalPart)
    }
    Quit 1
}

Method ReferenceIsDefined(document As %DynamicObject, ref As %String) As %Boolean
{
    Do ##class(dc.openapi.common.ReferenceAnalyzer).DecomposeRef(ref, .part)

    If part("external") = "" {
        ; It's an internal reference
        Return ##class(dc.openapi.common.ReferenceAnalyzer).ReferenceIsDefined(document, ref)
    }

    ; It's an external reference
    ; Check if the external reference is already in the list
    Set key = part("external")
    Set document = ..DocumentCollection.GetDocument(key, .found)
    If 'found Return $$$NO

    Return ##class(dc.openapi.common.ReferenceAnalyzer).ReferenceIsDefined(document, ref)
}

/// This method allows to resolve the given document and his $ref (externalReference) to the DoucumentCollection.
/// document represents a part of a OpenAPI specification that is referenced in the main document using $ref.
/// These kind of documents are not "full specifications", (flag SwaggerDocumentReference.IsAFullSpecification).
Method ResolveExternalDocument(document As %DynamicObject, externalReference As %String) As %Status
{
    $$$LOGINFO("Starting to resolve external document partial OpenAPI Document: "_externalReference)
    #dim documentReference As dc.openapi.common.SwaggerDocumentReference
    Set key = ""
    For  {
        Set documentReference = ..DocumentCollection.Items.GetNext(.key)
        Quit:key=""
        If 'documentReference.IsAFullSpecification Continue
        Set currentDocument = documentReference.Document
        Do ResolveDoc
    }
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
            $$$LOGINFO("Resolved external document: "_externalReference _" into the document "_key_" ("_line_")")
        }
    }
    Kill out

    Quit 1
}

/// This method resolve all non object components in all documents.
Method ResolveNonObjectComponents() As %Status
{
    Set tSc = $$$OK
    Set dataTypes = $ListBuild("string","number","integer","boolean","array")

    $$$LOGINFO("Starting to resolve non object components in all documents ("_$ListToString(dataTypes)_")...")

    Set key = ""
    For  {
        Set documentReference = ..DocumentCollection.Items.GetNext(.key)
        Quit:key=""
        
        Set document = documentReference.Document
        Do ##class(dc.openapi.common.ReferenceAnalyzer).CollectOASReferences(document, .lines)

        Set n = ""
        For  {
            Set n = $Order(lines(n), 1, line)
            Quit:n=""
            If $Extract(line, *-3, *) '= "$ref" Continue
            Set ref = ##class(dc.openapi.common.ReferenceAnalyzer).GetValue(document, line) ; retrieve the $ref property value
            Set value = ##class(dc.openapi.common.ReferenceAnalyzer).GetObjectByRef(document, ref, ..DocumentCollection)
            If '$IsObject(value) Continue
            If '$ListFind(dataTypes,value.type) Continue
            ; it's not an object we resolve it
            Set parent = $Piece(line, ##class(dc.openapi.common.ReferenceAnalyzer).#SEPARATOR, 1, * - 2)
            Set name = $Piece(line, ##class(dc.openapi.common.ReferenceAnalyzer).#SEPARATOR,* - 1)
            Set parentObject = ##class(dc.openapi.common.ReferenceAnalyzer).GetValue(document, parent)
            Do parentObject.%Set(name, {}.%FromJSON(value.%ToJSON()))
            $$$LOGINFO("Resolved non object component: "_ref _" into the document "_key_" ("_line_")")
        }
        Kill lines
    }
    Return tSc
}

Method ResolveAllCommonParameters() As %Status
{
    Set tSc = $$$OK
    Set key = ""
    For  {
        Set documentReference = ..DocumentCollection.Items.GetNext(.key)
        Quit:key=""
        If 'documentReference.IsAFullSpecification Continue
        Set document = documentReference.Document

        $$$LOGINFO("Starting to resolve common parameters in document: "_key)
        
        Set tSc = ..ResolveCommonParameters(document)
        
        If $$$ISERR(tSc) {
            $$$LOGERROR("Failed to resolve common parameters in document: "_key)
            Return tSc
        }

        $$$LOGINFO("Resolving common parameters in document: "_key_" completed.")
    }
    Return tSc
}

Method ResolveCommonParameters(document As %DynamicObject) As %Status
{
    Set tSc = $$$OK

    If '$IsObject(document.paths) Return tSc

    Set iterator = document.paths.%GetIterator()

    While iterator.%GetNext(.path, .pathItem, .type) { ; iterate over the paths
        If '$IsObject(pathItem.parameters) Continue

        For verb = "get", "put", "post", "delete", "options", "head", "patch", "trace" { ; iterate over the verbs
            Set operation = pathItem.%Get(verb)
            If '$IsObject(operation) Continue

            Set commonParametersIterator = pathItem.parameters.%GetIterator()
            While commonParametersIterator.%GetNext(.pIdx, .commonParameter, .type) { ; iterate over the common parameters
                If ..CommonParameterIsDefinedInOperation(operation, pathItem.parameters) {
                    $$$LOGTRACE("Skipping common parameter "_commonParameter.name_" in operation "_verb_" for path "_path _" because it is already defined in the operation.")
                    Continue
                }
                Do operation.parameters.%Push({}.%FromJSON(commonParameter.%ToJSON()))
                $$$LOGTRACE("Resolved common parameter "_commonParameter.name_" in operation "_verb_" for path "_path)
            }
        }
        Do pathItem.remove("parameters") ; remove the common parameters from the pathItem after resolving
    }

    Return tSc
}

ClassMethod CommonParameterIsDefinedInOperation(operation As %DynamicObject, commonParameter As %DynamicArray) As %Boolean
{
    Set isDefined = $$$NO
    If '$IsObject(operation.parameters) {
        Set operation.parameters = []
        Return isDefined
    }

    Set iterator = operation.parameters.%GetIterator()
    While iterator.%GetNext(.name, .item, .type) {
        If commonParameter.%IsDefined("$ref") && item.%IsDefined("$ref") {
            If commonParameter."$ref" = item."$ref" {
                Set isDefined = $$$YES
                Quit
            }
            ElseIf (commonParameter.name = item.name) && (commonParameter.in = item.in) {
                Set isDefined = $$$YES
                Quit
            }
        }
    }

    Return isDefined
}

}
