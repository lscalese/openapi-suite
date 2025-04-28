
```
Set oas = {}.%FromJSONFile("/home/irisowner/irisdev/temp-dev-specs/allOf1.json") Do ##class(dc.openapi.common.SwaggerSchemaFlattener).Flatten(.oas),##class(%JSON.Formatter).%New().Format(oas)
```