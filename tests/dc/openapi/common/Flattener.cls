Class tests.dc.openapi.common.Flattener Extends %UnitTest.TestCase
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
    Do ##class(%UnitTest.Manager).RunTest(":tests.dc.openapi.common.Flattener","/nodelete")
    Return
}

Method TestSimpleSchema()
{
    Set swagger = {}.%FromJSON(##class(%Dictionary.XDataDefinition).%OpenId($CLASSNAME()_"||SimpleSchemas").Data)
    
    Set clone = swagger.%ToJSON()

    Set flattener = ##class(dc.openapi.common.Flattener).%New()
    Set flattener.OAS = swagger

    Set sc = flattener.Lift()

    Do $$$AssertStatusOK(sc, "Lift should be OK")

    ; there is no nested schema
    ; so the result should be the same
    Set result = swagger.%ToJSON()

    Do $$$AssertEquals(result, clone, "Flattening a simple schema should not change the original")

    Return
}

Method TestNestedSchema()
{
    Set swagger = {}.%FromJSON(##class(%Dictionary.XDataDefinition).%OpenId($CLASSNAME()_"||NestedSchemas").Data)
    Set flattener = ##class(dc.openapi.common.Flattener).%New()
    Set flattener.OAS = swagger
    Set sc = flattener.Lift()

    Do $$$AssertStatusOK(sc, "Lift should be OK")

    ; Check if we don't lost the "MainObject" schema

    Set sc = $$$OK

    If '$ISOBJECT(swagger.components.schemas.MainObject) {
        Set sc = $$$ERROR($$$GeneralError, "MainObject schema not found")
    }

    Do $$$AssertStatusOK(sc, "MainObject schema should be found")


    ; following the current rules, the lifted schema name should be:
    ; - auto_MainObject_firstNestedObject_deepNestedObject_metadata
    ; - auto_MainObject_firstNestedObject_deepNestedObject
    ; - auto_MainObject_firstNestedObject
    ; - auto_MainObject_secondNestedObject_nestedConfiguration_settings
    ; - auto_MainObject_secondNestedObject_nestedConfiguration
    ; - auto_MainObject_secondNestedObject
    ; ! If the rules change, adapt the test !

    Set schemaNames("0") = $LISTBUILD("MainObject")
    Set schemaNames("1") = $LISTBUILD("auto_MainObject_firstNestedObject_deepNestedObject_metadata", "2", "metadata")
    Set schemaNames("2") = $LISTBUILD("auto_MainObject_firstNestedObject_deepNestedObject", "3", "deepNestedObject")
    Set schemaNames("3") = $LISTBUILD("auto_MainObject_firstNestedObject", "0", "firstNestedObject")
    Set schemaNames("4") = $LISTBUILD("auto_MainObject_secondNestedObject_nestedConfiguration_settings", "5", "settings")
    Set schemaNames("5") = $LISTBUILD("auto_MainObject_secondNestedObject_nestedConfiguration", "6", "nestedConfiguration")
    Set schemaNames("6") = $LISTBUILD("auto_MainObject_secondNestedObject", "0", "secondNestedObject")

    Set key = "0"
    For  {
        Set key = $ORDER(schemaNames(key), 1, data)
        Quit:key=""

        Set liftedName = $LISTGET(data, 1)

        Set sc = $$$OK
        If '$ISOBJECT(swagger.components.schemas.%Get(liftedName)) {
            Set sc = $$$ERROR($$$GeneralError, liftedName _ " schema not found")
        }

        Do $$$AssertStatusOK(sc, liftedName _ " schema should be found")

        If $$$ISERR(sc) {
            ; if the previous test failed, other tests will fail too...
            Continue
        }

        If $LISTGET(data, 2) '= "" {
            ; check if the lifted schema has been referenced
            Set referencedFrom = $LISTGET(schemaNames($LISTGET(data, 2)), 1)
            Set property = $LISTGET(data, 3)

            Set isCorrectlyReferenced = $$$OK

            Try {
                Set referenceFound = swagger.components.schemas.%Get(referencedFrom).properties.%Get(property)."$ref"
            } Catch ex {
                Set referenceFound = ""
            }

            Set expectedReference = "#/components/schemas/" _ liftedName

            If referenceFound '= expectedReference {
                Set isCorrectlyReferenced = $$$ERROR($$$GeneralError, "Schema " _ liftedName _ " should be referenced from " _ referencedFrom _ " as " _ property _ " but found " _ referenceFound _" expected " _ expectedReference )
            }
            Do $$$AssertStatusOK(isCorrectlyReferenced, "Check if the lifted schema " _ liftedName _ " is correctly referenced")
        }
    }

    Return
}

Method TestAllOfSchema()
{
    Set swagger = {}.%FromJSON(##class(%Dictionary.XDataDefinition).%OpenId($CLASSNAME()_"||AllOfSchemas").Data)
    Set flattener = ##class(dc.openapi.common.Flattener).%New()
    Set flattener.OAS = swagger
    Set sc = flattener.Lift()

    Do $$$AssertStatusOK(sc, "Lift should be OK")

    ; Check if we don't lost the "MainObject" schema

    Set sc = $$$OK

    For schemaName = "BaseEntity", "Address", "Person", "Employee" {
        Set sc = $$$OK
        If '$ISOBJECT(swagger.components.schemas.%Get(schemaName)) {
            Set sc = $$$ERROR($$$GeneralError, schemaName _ " schema not found")
        }

        Do $$$AssertStatusOK(sc, schemaName _ " schema should be found")
    }

    For liftedName = "auto_PersonallOf1", "auto_EmployeeallOf2" {
        Set sc = $$$OK
        If '$ISOBJECT(swagger.components.schemas.%Get(liftedName)) {
            Set sc = $$$ERROR($$$GeneralError, liftedName _ " schema not found")
        }
        Do $$$AssertStatusOK(sc, liftedName _ " schema should be found")
    }

    Set expected = "#/components/schemas/auto_PersonallOf1"
    Set found = "", liftedName = $Piece(expected, "/", *)
    Try {
        Set found = swagger.components.schemas.Person.allOf.%Get(1)."$ref"
    } Catch ex {
        Set found = ""
    }

    Set sc = $$$OK

    If found '= expected {
        Set sc = $$$ERROR($$$GeneralError, "Lifted Schema "_liftedName_" should be referenced in Person " _ found _" expected " _ expected )
    }

    Do $$$AssertStatusOK(sc, "Check if the lifted schema " _ liftedName _ " is correctly referenced")

    Set expected = "#/components/schemas/auto_EmployeeallOf2"
    Set found = "", liftedName = $Piece(expected, "/", *)
    Try {
        Set found = swagger.components.schemas.Employee.allOf.%Get(2)."$ref"
    } Catch ex {
        Set found = ""
    }
    Set sc = $$$OK
    If found '= expected {
        Set sc = $$$ERROR($$$GeneralError, "Lifted Schema "_liftedName_" should be referenced in Employee " _ found _" expected " _ expected )
    }
    Do $$$AssertStatusOK(sc, "Check if the lifted schema " _ liftedName _ " is correctly referenced")

    Return
}

Method TestArraySchema()
{
    Set swagger = {}.%FromJSON(##class(%Dictionary.XDataDefinition).%OpenId($CLASSNAME()_"||ArraySchemas").Data)
    Set flattener = ##class(dc.openapi.common.Flattener).%New()
    Set flattener.OAS = swagger
    Set sc = flattener.Lift()

    Do $$$AssertStatusOK(sc, "Lift should be OK")

    ; Check if we don't lost the "MainObject" schema

    Set sc = $$$OK

    If '$ISOBJECT(swagger.components.schemas.Person) {
        Set sc = $$$ERROR($$$GeneralError, "Person schema not found")
    }

    Do $$$AssertStatusOK(sc, "Person schema should be found")

    ; Check if we don't lost the lifted schemas

    For liftedName = "auto_Person_addressesItem", "auto_Person_phoneNumbersItem" {
        Set sc = $$$OK
        If '$ISOBJECT(swagger.components.schemas.%Get(liftedName)) {
            Set sc = $$$ERROR($$$GeneralError, liftedName _ " schema not found")
        }
        Do $$$AssertStatusOK(sc, liftedName _ " schema should be found")
    }

    Set expected = "#/components/schemas/auto_Person_addressesItem"
    Set found = "", liftedName = $Piece(expected, "/", *)
    Try {
        Set found = swagger.components.schemas.Person.properties.addresses.items."$ref"
    } Catch ex {
        Set found = ""
    }
    Set sc = $$$OK
    If found '= expected {
        Set sc = $$$ERROR($$$GeneralError, "Schema "_liftedName_" should be referenced in Person.addresses " _ found _" expected " _ expected )
    }
    Do $$$AssertStatusOK(sc, "Check if the lifted schema " _ liftedName _ " is correctly referenced")

    Set expected = "#/components/schemas/auto_Person_phoneNumbersItem"
    Set found = "", liftedName = $Piece(expected, "/", *)
    Try {
        Set found = swagger.components.schemas.Person.properties.phoneNumbers.items."$ref"
    } Catch ex {
        Set found = ""
    }
    Set sc = $$$OK
    If found '= expected {
        Set sc = $$$ERROR($$$GeneralError, "Schema "_liftedName_" should be referenced in Person.phoneNumbers " _ found _" expected " _ expected )
    }
    Do $$$AssertStatusOK(sc, "Check if the lifted schema " _ liftedName _ " is correctly referenced")


    Return
}

Method TestRequestBodies()
{
    Set swagger = {}.%FromJSON(##class(%Dictionary.XDataDefinition).%OpenId($CLASSNAME()_"||RequestBodies").Data)

    Set flattener = ##class(dc.openapi.common.Flattener).%New()
    Set flattener.OAS = swagger
    Set sc = flattener.Lift()
    Do $$$AssertStatusOK(sc, "Lift should be OK")

    For liftedName = "auto_requestbody_CreateUserRequest_schema", "auto_requestbody_ProductSubmission_schema" {
        Set sc = $$$OK
        If '$ISOBJECT(swagger.components.schemas.%Get(liftedName)) {
            Set sc = $$$ERROR($$$GeneralError, liftedName _ " schema not found")
        }
        Do $$$AssertStatusOK(sc, liftedName _ " schema should be found")
    }

    ; check reference in requestBodies

    Set expected = "#/components/schemas/auto_requestbody_CreateUserRequest_schema"
    Set found = "", liftedName = $Piece(expected, "/", *)
    Try {
        Set found = swagger.components.requestBodies.CreateUserRequest.content."application/json".schema."$ref"
    } Catch ex {
        Set found = ""
    }
    Set sc = $$$OK
    If found '= expected {
        Set sc = $$$ERROR($$$GeneralError, "Schema " _ liftedName _ " should be referenced in CreateuserRequest requestBodies " _ found _" expected " _ expected )
    }
    Do $$$AssertStatusOK(sc, "Check if the lifted schema " _ liftedName _ " is correctly referenced")


    Set expected = "#/components/schemas/auto_requestbody_ProductSubmission_schema"
    Set found = "", liftedName = $Piece(expected, "/", *)
    Try {
        Set found = swagger.components.requestBodies.ProductSubmission.content."application/json".schema."$ref"
    } Catch ex {
        Set found = ""
    }
    Set sc = $$$OK
    If found '= expected {
        Set sc = $$$ERROR($$$GeneralError, "Schema " _ liftedName _ " should be referenced in ProductSubmission requestBodies " _ found _" expected " _ expected )
    }
    Do $$$AssertStatusOK(sc, "Check if the lifted schema " _ liftedName _ " is correctly referenced")

    Quit
}

Method TestResponses()
{
    Set swagger = {}.%FromJSON(##class(%Dictionary.XDataDefinition).%OpenId($CLASSNAME()_"||Responses").Data)

    Set flattener = ##class(dc.openapi.common.Flattener).%New()
    Set flattener.OAS = swagger
    Set sc = flattener.Lift()
    Do $$$AssertStatusOK(sc, "Lift should be OK")

    For liftedName = "auto_response_StandardResponse_schema", "auto_response_ErrorResponse_schema" {
        Set sc = $$$OK
        If '$ISOBJECT(swagger.components.schemas.%Get(liftedName)) {
            Set sc = $$$ERROR($$$GeneralError, liftedName _ " schema not found")
        }
        Do $$$AssertStatusOK(sc, liftedName _ " schema should be found")
    }

    ; check reference in responses

    Set expected = "#/components/schemas/auto_response_StandardResponse_schema"
    Set found = "", liftedName = $Piece(expected, "/", *)
    Try {
        Set found = swagger.components.responses.StandardResponse.content."application/json".schema."$ref"
    } Catch ex {
        Set found = ""
    }
    Set sc = $$$OK
    If found '= expected {
        Set sc = $$$ERROR($$$GeneralError, "Schema " _ liftedName _ " should be referenced in StandardResponse responses " _ found _" expected " _ expected )
    }
    Do $$$AssertStatusOK(sc, "Check if the lifted schema " _ liftedName _ " is correctly referenced")

    Set expected = "#/components/schemas/auto_response_ErrorResponse_schema"
    Set found = "", liftedName = $Piece(expected, "/", *)
    Try {
        Set found = swagger.components.responses.ErrorResponse.content."application/json".schema."$ref"
    } Catch ex {
        Set found = ""
    }
    Set sc = $$$OK
    If found '= expected {
        Set sc = $$$ERROR($$$GeneralError, "Schema " _ liftedName _ " should be referenced in ErrorResponse responses " _ found _" expected " _ expected )
    }
    Do $$$AssertStatusOK(sc, "Check if the lifted schema " _ liftedName _ " is correctly referenced")

    Return
}

Method TestParameters()
{
    Set swagger = {}.%FromJSON(##class(%Dictionary.XDataDefinition).%OpenId($CLASSNAME()_"||Parameters").Data)
    Set flattener = ##class(dc.openapi.common.Flattener).%New()
    Set flattener.OAS = swagger
    Set sc = flattener.Lift()
    Do $$$AssertStatusOK(sc, "Lift should be OK")
    ; Check if we don't lost the "MainObject" schema
    Set sc = $$$OK
    If '$ISOBJECT(swagger.components.parameters.filterParameter) {
        Set sc = $$$ERROR($$$GeneralError, "filterParameter schema not found")
    }
    Do $$$AssertStatusOK(sc, "filterParameter schema should be found")

    ; Check if we don't lost the lifted schemas
    For liftedName = "auto_param_filterParameter_schema", "auto_param_complexParameter_schema" {
        Set sc = $$$OK
        If '$ISOBJECT(swagger.components.schemas.%Get(liftedName)) {
            Set sc = $$$ERROR($$$GeneralError, liftedName _ " schema not found")
        }
        Do $$$AssertStatusOK(sc, liftedName _ " schema should be found")
    }

    ; check reference in parameters
    Set expected = "#/components/schemas/auto_param_filterParameter_schema"
    Set found = "", liftedName = $Piece(expected, "/", *)
    Try {
        Set found = swagger.components.parameters.filterParameter.schema."$ref"
    } Catch ex {
        Set found = ""
    }
    Set sc = $$$OK
    If found '= expected {
        Set sc = $$$ERROR($$$GeneralError, "Schema " _ liftedName _ " should be referenced in filterParameter parameters " _ found _" expected " _ expected )
    }
    Do $$$AssertStatusOK(sc, "Check if the lifted schema " _ liftedName _ " is correctly referenced")

    Set expected = "#/components/schemas/auto_param_complexParameter_schema"
    Set found = "", liftedName = $Piece(expected, "/", *)
    Try {
        Set found = swagger.components.parameters.complexParameter.schema."$ref"
    } Catch ex {
        Set found = ""
    }
    Set sc = $$$OK
    If found '= expected {
        Set sc = $$$ERROR($$$GeneralError, "Schema " _ liftedName _ " should be referenced in complexParameter parameters " _ found _" expected " _ expected )
    }
    Do $$$AssertStatusOK(sc, "Check if the lifted schema " _ liftedName _ " is correctly referenced")
    Return
}

/// Simple swagger schemas
XData SimpleSchemas [ MimeType = application/json ]
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

/// Test the flattening with nested schemas
XData NestedSchemas [ MimeType = application/json ]
{
{
  "openapi": "3.0.0",
  "info": {
    "title": "Nested Schema Example",
    "version": "1.0.0",
    "description": "A simple API with nested schema objects"
  },
  "paths": {},
  "components": {
    "schemas": {
      "MainObject": {
        "type": "object",
        "properties": {
          "id": {
            "type": "string",
            "description": "Unique identifier of the main object"
          },
          "name": {
            "type": "string",
            "description": "Name of the main object"
          },
          "firstNestedObject": {
            "type": "object",
            "properties": {
              "id": {
                "type": "integer",
                "description": "ID of the first nested object"
              },
              "title": {
                "type": "string",
                "description": "Title of the first nested object"
              },
              "active": {
                "type": "boolean",
                "default": true
              },
              "deepNestedObject": {
                "type": "object",
                "properties": {
                  "deepId": {
                    "type": "string",
                    "description": "ID of the deep nested object"
                  },
                  "metadata": {
                    "type": "object",
                    "properties": {
                      "created": {
                        "type": "string",
                        "format": "date-time"
                      },
                      "author": {
                        "type": "string"
                      }
                    }
                  }
                }
              }
            },
            "required": ["id", "title"]
          },
          "secondNestedObject": {
            "type": "object",
            "properties": {
              "code": {
                "type": "string",
                "description": "Code of the second nested object"
              },
              "value": {
                "type": "number",
                "description": "Value of the second nested object"
              },
              "createdAt": {
                "type": "string",
                "format": "date-time"
              },
              "nestedConfiguration": {
                "type": "object",
                "properties": {
                  "enabled": {
                    "type": "boolean",
                    "default": false
                  },
                  "settings": {
                    "type": "object",
                    "properties": {
                      "timeout": {
                        "type": "integer",
                        "minimum": 0,
                        "default": 30
                      },
                      "retryCount": {
                        "type": "integer",
                        "default": 3
                      }
                    }
                  }
                }
              }
            },
            "required": ["code"]
          }
        },
        "required": ["id", "name"]
      }
    }
  }
}
}

/// Test the flattening with allOf
XData AllOfSchemas [ MimeType = application/json ]
{
{
  "openapi": "3.0.0",
  "info": {
    "title": "AllOf Example API",
    "version": "1.0.0",
    "description": "Une API simple démontrant l'utilisation de allOf"
  },
  "paths": {},
  "components": {
    "schemas": {
      "BaseEntity": {
        "type": "object",
        "properties": {
          "id": {
            "type": "integer",
            "format": "int64"
          },
          "createdAt": {
            "type": "string",
            "format": "date-time"
          },
          "updatedAt": {
            "type": "string",
            "format": "date-time"
          }
        },
        "required": ["id"]
      },
      "Address": {
        "type": "object",
        "properties": {
          "street": {
            "type": "string"
          },
          "city": {
            "type": "string"
          },
          "postalCode": {
            "type": "string"
          },
          "country": {
            "type": "string"
          }
        },
        "required": ["street", "city", "country"]
      },
      "Person": {
        "allOf": [
          {
            "$ref": "#/components/schemas/BaseEntity"
          },
          {
            "type": "object",
            "properties": {
              "firstName": {
                "type": "string"
              },
              "lastName": {
                "type": "string"
              },
              "email": {
                "type": "string",
                "format": "email"
              },
              "age": {
                "type": "integer",
                "minimum": 0
              }
            },
            "required": ["firstName", "lastName", "email"]
          }
        ]
      },
      "Employee": {
        "allOf": [
          {
            "$ref": "#/components/schemas/Person"
          },
          {
            "$ref": "#/components/schemas/Address"
          },
          {
            "type": "object",
            "properties": {
              "position": {
                "type": "string"
              },
              "department": {
                "type": "string"
              },
              "salary": {
                "type": "number",
                "format": "float"
              }
            },
            "required": ["position", "department"]
          }
        ]
      }
    }
  }
}
}

/// Test the flattening with array
XData ArraySchemas [ MimeType = application/json ]
{
{
  "openapi": "3.0.0",
  "info": {
    "title": "Test Schema for Flattening",
    "description": "API avec schemas contenant des propriétés array avec définition d'objets en ligne",
    "version": "1.0.0"
  },
  "components": {
    "schemas": {
      "Person": {
        "type": "object",
        "properties": {
          "id": {
            "type": "integer",
            "format": "int64"
          },
          "name": {
            "type": "string"
          },
          "addresses": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "street": {
                  "type": "string"
                },
                "city": {
                  "type": "string"
                },
                "zipCode": {
                  "type": "string"
                },
                "isDefault": {
                  "type": "boolean"
                }
              }
            }
          },
          "phoneNumbers": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "number": {
                  "type": "string"
                },
                "type": {
                  "type": "string",
                  "enum": ["home", "work", "mobile"]
                }
              }
            }
          }
        },
        "required": ["id", "name"]
      }
    }
  }
}
}

/// Test the flattening requestBodies
XData RequestBodies [ MimeType = application/json ]
{
{
  "openapi": "3.0.3",
  "info": {
    "title": "Nested RequestBody Example",
    "description": "Example API with nested request bodies for flattening tests",
    "version": "1.0.0"
  },
  "paths": {},
  "components": {
    "requestBodies": {
      "CreateUserRequest": {
        "description": "Request body for creating a new user with nested objects",
        "required": true,
        "content": {
          "application/json": {
            "schema": {
              "type": "object",
              "required": ["username", "email", "profile"],
              "properties": {
                "username": {
                  "type": "string",
                  "minLength": 3,
                  "maxLength": 50
                },
                "email": {
                  "type": "string",
                  "format": "email"
                },
                "profile": {
                  "type": "object",
                  "required": ["firstName", "lastName"],
                  "properties": {
                    "firstName": {
                      "type": "string"
                    },
                    "lastName": {
                      "type": "string"
                    },
                    "age": {
                      "type": "integer",
                      "minimum": 18
                    },
                    "address": {
                      "type": "object",
                      "properties": {
                        "street": {
                          "type": "string"
                        },
                        "city": {
                          "type": "string"
                        },
                        "zipCode": {
                          "type": "string",
                          "pattern": "^[0-9]{5}(?:-[0-9]{4})?$"
                        },
                        "geolocation": {
                          "type": "object",
                          "properties": {
                            "latitude": {
                              "type": "number",
                              "format": "float"
                            },
                            "longitude": {
                              "type": "number",
                              "format": "float"
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "preferences": {
                  "type": "object",
                  "properties": {
                    "theme": {
                      "type": "string",
                      "enum": ["light", "dark", "system"]
                    },
                    "notifications": {
                      "type": "object",
                      "properties": {
                        "email": {
                          "type": "boolean",
                          "default": true
                        },
                        "sms": {
                          "type": "boolean",
                          "default": false
                        },
                        "frequency": {
                          "type": "string",
                          "enum": ["daily", "weekly", "monthly"]
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      },
      "ProductSubmission": {
        "description": "Request body for submitting a product with nested categories and variants",
        "required": true,
        "content": {
          "application/json": {
            "schema": {
              "type": "object",
              "required": ["name", "price", "category"],
              "properties": {
                "name": {
                  "type": "string"
                },
                "description": {
                  "type": "string"
                },
                "price": {
                  "type": "number",
                  "format": "float",
                  "minimum": 0
                },
                "category": {
                  "type": "object",
                  "required": ["id", "name"],
                  "properties": {
                    "id": {
                      "type": "integer"
                    },
                    "name": {
                      "type": "string"
                    },
                    "subCategory": {
                      "type": "object",
                      "properties": {
                        "id": {
                          "type": "integer"
                        },
                        "name": {
                          "type": "string"
                        }
                      }
                    }
                  }
                },
                "variants": {
                  "type": "array",
                  "items": {
                    "type": "object",
                    "properties": {
                      "sku": {
                        "type": "string"
                      },
                      "attributes": {
                        "type": "object",
                        "additionalProperties": {
                          "type": "string"
                        }
                      },
                      "stock": {
                        "type": "object",
                        "properties": {
                          "quantity": {
                            "type": "integer",
                            "minimum": 0
                          },
                          "warehouse": {
                            "type": "object",
                            "properties": {
                              "id": {
                                "type": "string"
                              },
                              "location": {
                                "type": "string"
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
}

/// Test the flattening reponses
XData Responses [ MimeType = application/json ]
{
{
  "openapi": "3.0.0",
  "info": {
    "title": "Components Responses Test",
    "description": "API specification with components responses for testing a flattener script",
    "version": "1.0.0"
  },
  "paths": {},
  "components": {
    "responses": {
      "StandardResponse": {
        "description": "A standard response with inline object definition",
        "content": {
          "application/json": {
            "schema": {
              "type": "object",
              "properties": {
                "status": {
                  "type": "string",
                  "enum": ["success", "error"]
                },
                "data": {
                  "type": "object",
                  "properties": {
                    "id": {
                      "type": "integer",
                      "format": "int64"
                    },
                    "name": {
                      "type": "string"
                    },
                    "metadata": {
                      "type": "object",
                      "additionalProperties": true
                    }
                  },
                  "required": ["id", "name"]
                },
                "message": {
                  "type": "string"
                }
              },
              "required": ["status"]
            }
          }
        }
      },
      "ErrorResponse": {
        "description": "Error response with inline error object",
        "content": {
          "application/json": {
            "schema": {
              "type": "object",
              "properties": {
                "error": {
                  "type": "object",
                  "properties": {
                    "code": {
                      "type": "integer"
                    },
                    "message": {
                      "type": "string"
                    },
                    "details": {
                      "type": "array",
                      "items": {
                        "type": "object",
                        "properties": {
                          "field": {
                            "type": "string"
                          },
                          "issue": {
                            "type": "string"
                          }
                        }
                      }
                    }
                  },
                  "required": ["code", "message"]
                }
              },
              "required": ["error"]
            }
          }
        }
      }
    }
  }
}
}

/// Test the flattening  parameters
XData Parameters [ MimeType = application/json ]
{
{
  "openapi": "3.0.0",
  "info": {
    "title": "Parameters Test API",
    "description": "API with components.parameters containing inline objects for flattener testing",
    "version": "1.0.0"
  },
  "components": {
    "parameters": {
      "filterParameter": {
        "name": "filter",
        "in": "query",
        "description": "Filter criteria with inline object definition",
        "required": false,
        "schema": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string",
              "description": "Filter by name"
            },
            "status": {
              "type": "string",
              "enum": ["active", "pending", "inactive"],
              "description": "Filter by status"
            },
            "criteria": {
              "type": "object",
              "properties": {
                "minValue": {
                  "type": "integer",
                  "description": "Minimum value"
                },
                "maxValue": {
                  "type": "integer",
                  "description": "Maximum value"
                },
                "tags": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          }
        }
      },
      "complexParameter": {
        "name": "options",
        "in": "header",
        "description": "Complex options with nested inline objects",
        "required": true,
        "schema": {
          "type": "object",
          "properties": {
            "sorting": {
              "type": "object",
              "properties": {
                "field": {
                  "type": "string"
                },
                "direction": {
                  "type": "string",
                  "enum": ["asc", "desc"]
                }
              }
            },
            "pagination": {
              "type": "object",
              "properties": {
                "page": {
                  "type": "integer",
                  "minimum": 1
                },
                "pageSize": {
                  "type": "integer",
                  "minimum": 1,
                  "maximum": 100
                }
              }
            }
          }
        }
      }
    }
  }
}
}

}
