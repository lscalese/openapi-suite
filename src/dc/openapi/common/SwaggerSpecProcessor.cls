Class dc.openapi.common.SwaggerSpecProcessor Extends %RegisteredObject
{

Property DocumentCollection As dc.openapi.common.SwaggerDocumentCollection;

Property Errors As %DynamicObject [ InitialExpression = {{}} ];

Property ExpectedExternalSwagger As list Of %String;

Method PreProcess() As %Status
{
    Set tSc = $$$OK
    
    Set isValid = ..Validate()

    If 'isValid {
        Set tSc = $$$ERROR($$$GeneralError, "Validation failed, check the Errors property")
        Return tSc
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
        Set webValidator = ##class(dc.swaggervalidatorcli.WebSwaggerValidator).%New()
        Set queryParameters("flatten") = "true"
        Set tSc = webValidator.Parse(.queryParameters, .outSpec, documentReference.Document)
        If $$$ISERR(tSc) Return tSc
        Set documentReference.Document = outSpec
        Kill outSpec
    }

    Set tSc = ..ResolveNonObjectComponents()
    If $$$ISERR(tSc) {
        Return tSc
    }

    Set flattener = ##class(dc.openapi.common.Flattener).%New()
    Set flattener.DocumentCollection = ..DocumentCollection
    Set tSc = flattener.Lift()

    If $$$ISERR(tSc) {
        Return tSc
    }

    Set tSc = ..ResolveAllCommonParameters()
    If $$$ISERR(tSc) {
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
        ;Continue:key=##class(dc.openapi.common.SwaggerDocumentCollection).#MAINKEY
        ;w !,"item   : ", key
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

        If '..DocumentCollection.ItemExists(key) {
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
    Set document = ..DocumentCollection.GetDocument(key, .found)
    If 'found Return $$$NO

    Return ##class(dc.openapi.common.ReferenceAnalyzer).ReferenceIsDefined(document, ref)
}

/// This method allows to resolve the given document and his $ref (externalReference) to the DoucumentCollection.
/// document represents a part of a OpenAPI specification that is referenced in the main document using $ref.
/// These kind of documents are not "full specifications", (flag SwaggerDocumentReference.IsAFullSpecification).
Method ResolveExternalDocument(document As %DynamicObject, externalReference As %String) As %Status
{
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
        Set tSc = ..ResolveCommonParameters(document)
        If $$$ISERR(tSc) {
            Return tSc
        }
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
                    Continue
                }
                Do operation.parameters.%Push({}.%FromJSON(commonParameter.%ToJSON()))
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
