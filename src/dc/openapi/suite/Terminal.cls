/// Terminal application for OpenAPI Suite
Class dc.openapi.suite.Terminal Extends %RegisteredObject
{

Property DocumentPreparer As dc.openapi.common.SwaggerDocumentPreparer;

Property ASTCollection As dc.openapi.common.ASTCollection;

ClassMethod Run(args...) As %Status
{
    tro
    tstart
    Set terminalApplication = ..%New()
    Do terminalApplication.Start()
    Return $$$OK
}

Method Start() As %Status
{
    Do ..Reset()
    Do ..WriteTitleLines()
    If ' ..SetDocument() {
        Write !, ?3, "No document provided. Exiting..."
        Return $$$OK
    }

    If '..Validation() {
        Write !, ?3, "Document validation failed. Exiting..."
        Return $$$OK
    }

    Set tSc = ##class(dc.openapi.suite.services.Generator).DocumentCollectionToAST(..DocumentPreparer.DocumentCollection, .ASTCollection)
    If $$$ISERR(tSc) {
        Write !, ?3, "Error generating AST collection: ", $SYSTEM.Status.GetErrorText(tSc), !
        Return tSc
    }
    Set ..ASTCollection = ASTCollection
    Do ..ResolveASTPackage(.genModels)

    If $Data(genModels) {
        Do ..GenerateModels(.genModels)
    }
}

Method Validation() As %Boolean
{
    Set valid = $$$YES
    #dim validationResult As dc.openapi.common.ValidationResult

    Set validationResult = ##class(dc.openapi.suite.services.Generator).DocumentCollectionValidation(..DocumentPreparer.DocumentCollection)
    If validationResult.IsValid {
        Return $$$YES
    }

    If validationResult.MissingExternalDocuments.Count() > 0 {
        Do {
            Set valid = $$$NO
            Write !, ?3, "Validation failed. Missing external documents:", !
            Set index = ""
            For  {
                Set item = validationResult.MissingExternalDocuments.GetNext(.index)
                Quit:index=""
                Write ?5, item, !
            }

            Write !, ?3, "Please provide the missing documents.", !
            Set index = ""
            For  {
                Set item = validationResult.MissingExternalDocuments.GetNext(.index)
                Quit:index=""
                Set added = $$$NO
                Do {
                    Set added = ..SetDocument(item)
                } While 'added
            }
            Set validationResult = ##class(dc.openapi.suite.services.Generator).DocumentCollectionValidation(..DocumentPreparer.DocumentCollection)
        
        } While validationResult.MissingExternalDocuments.Count() > 0
    }

    If validationResult.IsValid {
        Return $$$YES
    }

    Write !, ?3, "Validation failed undefined references:", !
    Set index = ""
    For  {
        Set item = validationResult.UndefinedReferences.GetNext(.index)
        Quit:index=""
        Write ?5, item, !
    }

    Return $$$NO
}

Method ResolveASTPackage(ByRef genModels As %Binary) As %Boolean
{
    #dim astRef As dc.openapi.common.ASTReference
    
    Set index = ""
    For  {
        Set astRef = ..ASTCollection.ASTs.GetNext(.index)
        Quit:index=""
        Set modelCount = astRef.AST.Models.Count()
        if modelCount > 0 {
            Write !, ?3, modelCount, " models found in AST: ", astRef.Key, !
            Write !, ?3, "Insert package name: "
            Read packageName
            Set astRef.PackageModel = packageName
            Write !, ?3, "Would you like to generate models for this document? (Y/N): "
            Read generateModels
            Set generateModels = $$$LOWER($Extract(generateModels))="y"
            Set:generateModels genModels(astRef.Key) = packageName
        }
    }

    Do ..ASTCollection.ASTCollectionResolve()
}

Method GenerateModels(ByRef genModels As %Binary) As %Status
{
    Set tSc = $$$OK
    #dim astRef As dc.openapi.common.ASTReference

    Set index = ""
    For  {
        Set astRef = ..ASTCollection.ASTs.GetNext(.index)
        Quit:index=""
        If $Data(genModels(astRef.Key)) {
            Write !, ?3, "Generating models for AST: ", astRef.Key, " with package: ", genModels(astRef.Key), !
            Set modelGenerator = ##class(dc.openapi.common.generator.ModelGenerator).%New()
            Set modelGenerator.ASTReference = astRef
            Set tSc = $$$ADDSC(tSc, modelGenerator.GenerateAll())
        }
    }
    
    Return tSc
}

ClassMethod WriteTitleLines()
{
    Write #
    Do ..RepeatLine("=") Write !
    Write "+"
    Do ..WriteCenter("OpenAPI Suite Client Generator", 78) 
    Write ?79, "+",!
    Do ..RepeatLine("=") Write !
}

ClassMethod WriteCenter(text As %String, width As %Integer = 80)
{
    Set startPosition = (width - $Length(text)) \ 2
    Write ?startPosition, text
}

ClassMethod RepeatLine(char As %String, count As %Integer = 80)
{
    For i=1:1:count {
        Write char
    }
}

Method Reset() As %Status
{
    Do ##class(dc.openapi.common.GeneratedItemRegistry).Clear()
    Set ..DocumentPreparer = ##class(dc.openapi.common.SwaggerDocumentPreparer).%New()
    Set ..ASTCollection = ##class(dc.openapi.common.ASTCollection).%New()
    Return $$$OK
}

Method SetDocument(key As %String = {##class(dc.openapi.common.SwaggerDocumentCollection).#MAINKEY}) As %Boolean
{
    #define ISQUIT(%x) ($$$LOWER($Extract(%x))="q")

    Set repeat = $$$NO
    Do {
        Write !,!
        Write:##class(dc.openapi.common.SwaggerDocumentCollection).#MAINKEY'=key ?3, "Retrieving document with key: ", key, !
        Write ?3, "File (Q)uit : "
        Read specFile

        If $$$ISQUIT(specFile) {
            Write !, !, ?3, "Exiting..."
            Return $$$NO
        }
        Else {
            Write !, !, ?3, "Check if the file exists..."
            
            If ##class(%File).Exists(specFile) {
                
                Write !, !, ?3, "File exists. Loading ..."
                Set gcs = ##class(%Stream.GlobalCharacter).%New()
                Set oas = ##class(%Stream.FileCharacter).%New()
                Do oas.LinkToFile(specFile)
                Do gcs.CopyFrom(oas)
                Do ..DocumentPreparer.AddDocument(gcs,key)
                Write " Loaded."
                Hang 0.5
                Set repeat = $$$NO
                Return $$$YES
            }
            Else {
                Write !, !, ?3, "File does not exist. Retry..."
                Hang 1.25
                Set repeat = $$$YES
            }
        }

    } While repeat
    Return $$$NO
}

}
