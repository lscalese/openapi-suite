
```
Set oas = {}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/allOf1.json") Do ##class(dc.openapi.common.Flattener).Flatten(.oas),##class(%JSON.Formatter).%New().Format(oas)
```


SwaggerDocumentProcessor
SwaggerPreprocessor
SwaggerFormatHandler
SwaggerDocumentPreparer
SwaggerContentNormalizer


/home/irisowner/irisdev/debug/ast.json

d $SYSTEM.OBJ.DeletePackage("myapplication")
d ##class(dc.openapi.suite.services.Test).PetStoreClient()
d $SYSTEM.OBJ.CompilePackage("myapplication")
Set request = ##class(myapplication.httpclient.request.FindPetsByStatus).%New()
Set request.Status = "available"
Set client = ##class(myapplication.httpclient.HttpClient).%New()
Set client.SSLConfiguration = "DefaultSSL"
Set client.Server = client.#SERVER1
Do client.%Prepare()
Set sc = client.FindPetsByStatus(request,.response)
if 'sc Do $SYSTEM.Status.DisplayError(sc)



Set request = ##class(myapplication.httpclient.request.FindPetsByTags).%New()
Do request.Tags.Insert("tag2")
Set client = ##class(myapplication.httpclient.HttpClient).%New()
Set client.SSLConfiguration = "DefaultSSL"
Set client.Server = client.#SERVER1
Do client.%Prepare()
Set sc = client.FindPetsByTags(request,.response)
if 'sc Do $SYSTEM.Status.DisplayError(sc)