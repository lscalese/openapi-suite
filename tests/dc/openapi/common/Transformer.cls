Class tests.dc.openapi.common.Transformer Extends %UnitTest.TestCase
{

Method OnBeforeAllTests() As %Status
{
    Return $$$OK
}

Method OnAfterAllTests() As %Status
{
    Return $$$OK
}

ClassMethod Go()
{
    Set ^UnitTestRoot = "/home/irisowner/irisdev/tests/dc/openapi/common"
    Do ##class(%UnitTest.Manager).RunTest(":tests.dc.openapi.common.Transformer","/nodelete")
    Return
}

Method TestSimpleSchemas()
{
    Set sc = $$$OK

    Set swagger = {}.%FromJSON(##class(%Dictionary.XDataDefinition).%OpenId($ClassName()_"||ComponentsSchema").Data)
    
    Set transformer = ##class(dc.openapi.common.Tranformer).%New()
    Set transformer.OAS = swagger

    Set sc = transformer.Transform()

    Do $$$AssertStatusOK(sc, "Transform() must return a status OK")

    Do transformer.ast.%JSONExportToString(.tempString)
    Do ##class(%JSON.Formatter).%New().FormatToString(tempString, .formattedString)
    Write !, formattedString,!

    Quit
}

/// Test the OpenAPI 3.0.3 specification with only component schemas
XData ComponentsSchema [ MimeType = application/json ]
{
{
  "openapi": "3.0.3",
  "info": {
    "title": "Sample API with Schemas",
    "description": "A simple API specification with only component schemas",
    "version": "1.0.0"
  },
  "paths": {},
  "components": {
    "schemas": {
      "User": {
        "type": "object",
        "properties": {
          "id": {
            "type": "integer",
            "format": "int64",
            "description": "The unique identifier for a user"
          },
          "username": {
            "type": "string",
            "description": "The user's login name"
          },
          "email": {
            "type": "string",
            "format": "email",
            "description": "The user's email address"
          },
          "createdAt": {
            "type": "string",
            "format": "date-time",
            "description": "The date and time when the user was created"
          },
          "active": {
            "type": "boolean",
            "default": true,
            "description": "Whether the user is active or not"
          }
        },
        "required": ["id", "username", "email"]
      },
      "Product": {
        "type": "object",
        "properties": {
          "id": {
            "type": "string",
            "format": "uuid",
            "description": "The unique identifier for a product"
          },
          "name": {
            "type": "string",
            "description": "The name of the product"
          },
          "price": {
            "type": "number",
            "format": "float",
            "description": "The price of the product"
          },
          "category": {
            "$ref": "#/components/schemas/Category"
          },
          "tags": {
            "type": "array",
            "items": {
              "type": "string"
            },
            "description": "Tags associated with the product"
          }
        },
        "required": ["id", "name", "price"]
      },
      "Category": {
        "type": "object",
        "properties": {
          "id": {
            "type": "integer",
            "description": "The unique identifier for a category"
          },
          "name": {
            "type": "string",
            "description": "The name of the category"
          },
          "description": {
            "type": "string",
            "description": "A description of the category"
          }
        },
        "required": ["id", "name"]
      },
      "Error": {
        "type": "object",
        "properties": {
          "code": {
            "type": "integer",
            "format": "int32",
            "description": "Error code"
          },
          "message": {
            "type": "string",
            "description": "Error message"
          },
          "details": {
            "type": "array",
            "items": {
              "type": "string"
            },
            "description": "Additional error details"
          }
        },
        "required": ["code", "message"]
      }
    }
  }
}
}

}
