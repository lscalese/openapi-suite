Include dc.openapi.common.macro

Class dc.openapi.suite.services.Test
{

ClassMethod PetStoreClient() As %Status
{
 
    Set tSc = $$$OK
    Do ##class(dc.openapi.common.GeneratedItemRegistry).Clear()
    Do ##class(dc.openapi.common.TinyLogger).StartSession({"verbose":1,"level":($$$LEVELINFO)})
    Try {
        Set mainKey = ##class(dc.openapi.common.SwaggerDocumentCollection).#MAINKEY
        Set documentCollection = ##class(dc.openapi.common.SwaggerDocumentPreparer).PrepareFiles(.tSc,mainKey,"/home/irisowner/irisdev/temp-dev-specs/petstorev3.yaml")
        Set validationResult = ##class(dc.openapi.suite.services.Generator).DocumentCollectionValidation(documentCollection)
        If 'validationResult.IsValid {
            $$$LOGERROR("Validation failed")
            Set tSc = $$$ERROR($$$GeneralError, "Validation failed")
        }
        Set pp = ##class(dc.openapi.common.SwaggerSpecProcessor).%New(documentCollection)
        Set tSc = pp.PreProcess()
        If $$$ISERR(tSc) {
            $$$ThrowStatus(tSc)
        }
        Set astCollection = ##class(dc.openapi.common.SwaggerToASTConverter).ToASTCollection(documentCollection)
        Set astCollection.GetByKey(mainKey).PackageModel = "myapplication.models.common"
        Do astCollection.ASTCollectionResolve()
        Set httpClientGenConfig = ##class(dc.openapi.client.config.HttpClientGenConfig).%New("myapplication.httpclient",astCollection.ASTs.GetAt(1))
        Set httpClientGenerator = ##class(dc.openapi.client.HttpClientGeneratorV2).%New(httpClientGenConfig)
        Set tsc = httpClientGenerator.Generate()
        If $$$ISERR(tsc) {
            $$$ThrowStatus(tsc)
        }
    } 
    Catch ex {
        Set tSc = ex.AsStatus()
        Do $SYSTEM.Status.DisplayError(tSc)
    }
    Return tSc
}

ClassMethod Test() As %Status
{
    Set tSc = $$$OK
    Do ##class(dc.openapi.common.GeneratedItemRegistry).Clear()
    Do ##class(dc.openapi.common.TinyLogger).StartSession({"verbose":1,"level":($$$LEVELINFO)})
    Try{
        tro 
        ts

        Set oasFile = ##class(%Stream.FileCharacter).%New()
        Do oasFile.LinkToFile("/home/irisowner/irisdev/temp-dev-specs/v1.yaml")
        Set oasStream = ##class(%Stream.GlobalCharacter).%New()
        Do oasStream.CopyFrom(oasFile)
        
        Set ssiFile = ##class(%Stream.FileCharacter).%New()
        Do ssiFile.LinkToFile("/home/irisowner/irisdev/temp-dev-specs/ssi_types.yaml")
        Set ssiStream = ##class(%Stream.GlobalCharacter).%New()
        Do ssiStream.CopyFrom(ssiFile)
        
        Set errFile = ##class(%Stream.FileCharacter).%New()
        Do errFile.LinkToFile("/home/irisowner/irisdev/temp-dev-specs/error_response.yaml")
        Set errStream = ##class(%Stream.GlobalCharacter).%New()
        Do errStream.CopyFrom(errFile)

        
        Set preparer = ##class(dc.openapi.common.SwaggerDocumentPreparer).%New()
        Do preparer.SetMainDocument(oasStream)
        Do preparer.AddDocument(ssiStream, "../common/ssi_types.yaml")
        Do preparer.AddDocument(errStream, "../common/error_response.yaml")
        
        Set documentCollection = preparer.GetDocumentCollection()

        Set validationResult = ##class(dc.openapi.suite.services.Generator).DocumentCollectionValidation(documentCollection)
        if 'validationResult.IsValid {
            $$$LOGERROR("Validation failed")
        }
        Set pp = ##class(dc.openapi.common.SwaggerSpecProcessor).%New(documentCollection)
        
        Set tSc = pp.PreProcess()
        If $$$ISERR(tSc) {
            $$$ThrowStatus(tSc)
        }

        #dim astCollection As dc.openapi.common.ASTCollection
        Set astCollection = ##class(dc.openapi.common.SwaggerToASTConverter).ToASTCollection(documentCollection)
        Set astCollection.GetByKey(##class(dc.openapi.common.SwaggerDocumentCollection).#MAINKEY).PackageModel = "myapplication.models.common"
        Set astCollection.GetByKey("../common/ssi_types.yaml").PackageModel = "myapplication.models.ssi"
        Set astCollection.GetByKey("../common/error_response.yaml").PackageModel = "myapplication.models.err"
        Do astCollection.ASTCollectionResolve()
        
        Do ##class(dc.openapi.common.Utils).DumpToFile(astCollection, "/home/irisowner/irisdev/debug/ast-collection.json", $$$YES)
       
        Set httpClientGenConfig = ##class(dc.openapi.client.config.HttpClientGenConfig).%New("myapplication.httpclient", astCollection.ASTs.GetAt(1))        
        Set httpClientGenerator = ##class(dc.openapi.client.HttpClientGeneratorV2).%New(httpClientGenConfig)
        Set tsc = httpClientGenerator.Generate()
        If $$$ISERR(tsc) {
            $$$ThrowStatus(tsc)
        }
       
    } Catch ex {
        Set tSc = ex.AsStatus()
        Do $SYSTEM.Status.DisplayError(tSc)
    }

    Do ##class(dc.openapi.common.TinyLogger).StopSession()
    Return tSc
}

ClassMethod Debug()
{
    Set data = [
        {
            "id": 4,
            "category": {
            "id": 1,
            "name": "Dogs"
            },
            "name": "Dog 1",
            "photoUrls": [
            "url1",
            "url2"
            ],
            "tags": [
            {
                "id": 1,
                "name": "tag1"
            },
            {
                "id": 2,
                "name": "tag2"
            }
            ],
            "status": "available"
        },
        {
            "id": 8,
            "category": {
            "id": 4,
            "name": "Lions"
            },
            "name": "Lion 2",
            "photoUrls": [
            "url1",
            "url2"
            ],
            "tags": [
            {
                "id": 1,
                "name": "tag2"
            },
            {
                "id": 2,
                "name": "tag3"
            }
            ],
            "status": "available"
        },
        {
            "id": 12345,
            "category": {
            "id": 1,
            "name": "dogs"
            },
            "name": "fluffy",
            "photoUrls": [],
            "tags": [
            {
                "id": 0,
                "name": "tag1"
            },
            {
                "id": 1,
                "name": "tag2"
            }
            ],
            "status": "available"
        },
        {
            "id": 7,
            "category": {
            "id": 4,
            "name": "Lions"
            },
            "name": "Lion 1",
            "photoUrls": [
            "url1",
            "url2",
            "/tmp/inflector10743913034772246052.tmp"
            ],
            "tags": [
            {
                "id": 1,
                "name": "tag1"
            },
            {
                "id": 2,
                "name": "tag2"
            }
            ],
            "status": "available"
        },
        {
            "id": 2,
            "category": {
            "id": 0,
            "name": "Cats"
            },
            "name": "Updated Kitty",
            "photoUrls": [
            "string"
            ],
            "tags": [
            {
                "id": 0,
                "name": "string"
            }
            ],
            "status": "available"
        },
        {
            "id": 999,
            "name": "test",
            "photoUrls": [],
            "tags": [],
            "status": "available"
        },
        {
            "id": 1110,
            "category": {
            "id": 1,
            "name": "Dogs"
            },
            "name": "doggie",
            "photoUrls": [
            "string"
            ],
            "tags": [
            {
                "id": 0,
                "name": "string"
            }
            ],
            "status": "available"
        },
        {
            "id": 1287138758235,
            "name": "Woofy Mc Woofer",
            "photoUrls": [],
            "tags": [],
            "status": "available"
        },
        {
            "id": 100,
            "category": {
            "id": 1,
            "name": "Dogs"
            },
            "name": "doggie",
            "photoUrls": [
            "string"
            ],
            "tags": [
            {
                "id": 0,
                "name": "string"
            }
            ],
            "status": "available"
        },
        {
            "id": 130,
            "category": {
            "id": 131,
            "name": "Boa"
            },
            "name": "Kaa",
            "photoUrls": [
            "https://commons.wikimedia.org/wiki/File:Boa_constrictor_(2).jpg?uselang=ru"
            ],
            "tags": [
            {
                "id": 0,
                "name": "string"
            }
            ],
            "status": "available"
        }
    ]

    #dim pet As %ListOfObjects
    ;Pet As list Of myapplication.models.common.Pet
    Set array = [].%FromJSON(data.%ToJSON())
    s pet = ##class(%ListOfObjects).%New()
    Set iterator = array.%GetIterator()
    While iterator.%GetNext(.key, .value) {
        Set currentObject = ##class(myapplication.models.common.Pet).%New()
        Do currentObject.%JSONImport(value)
        Do pet.Insert(currentObject)
        zw currentObject
        w !
    }
    w !,pet.Count()
}

}
