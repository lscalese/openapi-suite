Class dc.openapi.suite.client.model.spec Extends %RegisteredObject [ ProcedureBlock ]
{

XData OpenAPI [ MimeType = application/json ]
{
{
  "openapi":"3.0.3",
  "info":{
    "title":"Swagger Generator for Objectscript",
    "description":"This an api to generate ObjectScript code from a OpenAPI specification.  It allows to generate interoperability client, simple HTTP client or the server-side REST application.",
    "termsOfService":"http://swagger.io/terms/",
    "contact":{
      "email":"lorenzo.scalese@gmail.com"
    },
    "license":{
      "name":"MIT License",
      "url":"https://github.com/lscalese/openapi-server-gen/blob/master/LICENSE"
    },
    "version":"1"
  },
  "externalDocs":{
    "description":"Find out OpenAPI suite on Intersystems developer community",
    "url":"https://community.intersystems.com/"
  },
  "servers":[
    {
      "url":"https://openapisuite.demo.community.intersystems.comhttp://openapisuite.demo.community.intersystems.com:80/openapisuite/"
    }
  ],
  "paths":{
    "/generate":{
      "post":{
        "summary":"Generate code for download purpose.",
        "operationId":"generateCode",
        "parameters":[
          {
            "name":"packageName",
            "in":"query",
            "description":"package name of the generated classes.",
            "required":true,
            "style":"form",
            "explode":true,
            "schema":{
              "type":"string"
            }
          },
          {
            "name":"type",
            "in":"query",
            "description":"Type of generation possible value are : client, production or rest.",
            "required":true,
            "style":"form",
            "explode":true,
            "schema":{
              "type":"string"
            }
          }
        ],
        "requestBody":{
          "content":{
            "text/plain":{
              "schema":{
                "type":"string",
                "example":"https://petstore3.swagger.io/api/v3/openapi.json"
              }
            },
            "application/json":{
            }
          },
          "required":true
        },
        "responses":{
          "200":{
            "description":"Successful operation.  The generated code is returned in XML format.",
            "content":{
              "application/xml":{
              }
            }
          },
          "400":{
            "description":"Bad Request"
          },
          "405":{
            "description":"Validation exception"
          }
        }
      }
    },
    "/install":{
      "post":{
        "summary":"Generate code and compile on the server.",
        "operationId":"generateAndInstall",
        "parameters":[
          {
            "name":"packageName",
            "in":"query",
            "description":"package name of the generated classes.",
            "required":true,
            "style":"form",
            "explode":true,
            "schema":{
              "type":"string"
            }
          },
          {
            "name":"type",
            "in":"query",
            "description":"Type of generation possible value are : client, production or rest.",
            "required":true,
            "style":"form",
            "explode":true,
            "schema":{
              "type":"string"
            }
          },
          {
            "name":"namespace",
            "in":"query",
            "description":"Namespace to install the generated code.",
            "required":true,
            "style":"form",
            "explode":true,
            "schema":{
              "type":"string"
            }
          },
          {
            "name":"webApplicationName",
            "in":"query",
            "description":"WebApplication name to create, if empty web application won't be created.",
            "required":false,
            "style":"form",
            "explode":true,
            "schema":{
              "type":"string"
            }
          }
        ],
        "requestBody":{
          "content":{
            "text/plain":{
              "schema":{
                "type":"string",
                "example":"https://petstore3.swagger.io/api/v3/openapi.json"
              }
            },
            "application/json":{
            }
          },
          "required":true
        },
        "responses":{
          "200":{
            "description":"Check the import status object for more information about the generation and compile process.",
            "content":{
              "application/json":{
                "schema":{
                  "$ref":"#/components/schemas/ImportStatus"
                }
              }
            }
          },
          "400":{
            "description":"Bad Request"
          },
          "405":{
            "description":"Validation exception"
          }
        }
      }
    }
  },
  "components":{
    "schemas":{
      "ImportStatus":{
        "type":"object",
        "properties":{
          "generateStatus":{
            "type":"string"
          },
          "compileStatus":{
            "type":"string"
          },
          "logs":{
            "type":"string"
          }
        }
      }
    }
  }
}
}

}
