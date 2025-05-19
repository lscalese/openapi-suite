
```
Set oas = {}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/allOf1.json") Do ##class(dc.openapi.common.Flattener).Flatten(.oas),##class(%JSON.Formatter).%New().Format(oas)
```


SwaggerDocumentProcessor
SwaggerPreprocessor
SwaggerFormatHandler
SwaggerDocumentPreparer
SwaggerContentNormalizer


/home/irisowner/irisdev/debug/ast.json