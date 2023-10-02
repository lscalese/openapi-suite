 [![Gitter](https://img.shields.io/badge/Available%20on-Intersystems%20Open%20Exchange-00b2a9.svg)](https://openexchange.intersystems.com/package/openapi-suite)
 [![Quality Gate Status](https://community.objectscriptquality.com/api/project_badges/measure?project=intersystems_iris_community%2Fopenapi-suite&metric=alert_status)](https://community.objectscriptquality.com/dashboard?id=intersystems_iris_community%2Fopenapi-suite)
 [![Reliability Rating](https://community.objectscriptquality.com/api/project_badges/measure?project=intersystems_iris_community%2Fopenapi-suite&metric=reliability_rating)](https://community.objectscriptquality.com/dashboard?id=intersystems_iris_community%2Fopenapi-suite)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat&logo=AdGuard)](LICENSE)

# openapi-suite

This package gather a set of tools for ObjectScript code generation from Swagger specification 3.0.  

It includes : 

* openapi-server-gen [OEX link](https://openexchange.intersystems.com/package/openapi-server-gen)
* openapi-client-gen [OEX link](https://openexchange.intersystems.com/package/Open-API-Client-Gen)
* openapi-common-lib [OEX link](https://openexchange.intersystems.com/package/openapi-common-lib)


The following features are available : 

* Web interface to generate the code.  
* REST services to expose code generation.  
* Automatic conversion of Swagger specification 1.x or 2.x to version 3.x before processing (using [swagger-converter-cli](https://openexchange.intersystems.com/package/swagger-converter-cli) ).

OpenAPI-suite can generate code : 

* Simple HTTP client
* Production client (with business services, processes and operation)
* Server-side REST classes.


## Installation ZPM


```objectscript
zpm "install openapi-suite"
; optional
zpm "install swagger-ui"
```

## Installation docker

```bash
git clone git@github.com:lscalese/openapi-suite.git
cd openapi-suite
# in case of permission issue with iris-main.log
# touch iris-main.log && chmod 777 iris-main.log
docker-compose up -d
```

**Important** : If you use url to a specification accessible only from your network \ organization use the docker-compose that include  
validator and converter tools instead of the default docker-compose.yml:

```bash
docker-compose --file docker-compose-with-swagger.yml up -d
```

**Note**: 
It seems a problem could be occurs with BuildKit on Ubuntu.  
In this case, you should use the compose plugin with the command `docker compose up -d` plugin instead of `docker-compose up -d`.  
See the official documentation to instal compose plugin : [Install the Compose plugin | Docker Documentation](https://docs.docker.com/compose/install/linux/)  



## Usage

### Web interface

The UI is available at this address(*)  [http://localhost:52796/openapisuite/ui/index.csp](http://localhost:52796/openapisuite/ui/index.csp)  

<img width="1123" src="https://raw.githubusercontent.com/lscalese/openapi-suite/master/asset/ui.png">

By default the feature `Install On Server` is disabled.  
To enable, just : 

```ObjectScript
Set ^openapisuite.config("web","enable-install-onserver") = 1
```

(*) Adapt the port number if needed  

### Swagger-ui

If you install swagger-ui, you can open [http://localhost:52796/swagger-ui/index.html](http://localhost:52796/swagger-ui/index.html) and explore 
[http://localhost:52796/openapisuite/_spec](http://localhost:52796/openapisuite/_spec) to test REST services.  
  
<img width="1123" src="https://raw.githubusercontent.com/lscalese/openapi-suite/master/asset/swagger.png">

## Generate by programming

All code snipets are available in the class [dc.openapi.suite.samples.PetStore](https://github.com/lscalese/openapi-suite/blob/master/src/dc/openapi/suite/samples/PetStore.cls)  

### Simple HTTP client

```objectscript
Set sc = ##class(dc.openapi.suite.Generate).Client("petstore.client", "https://petstore3.swagger.io/api/v3/openapi.json")
```

### Production client

```objectscript
Set sc = ##class(dc.openapi.suite.Generate).ProductionClient("petstore.production","https://petstore3.swagger.io/api/v3/openapi.json")
```

### Rest server-side classes

```objectscript
Set sc = ##class(dc.openapi.suite.Generate).Server("petstore.server", "https://petstore3.swagger.io/api/v3/openapi.json")
```

### Code generation with a specification contains external references

If the input of your specification is a URL, the parser will resolve automatically external references like: 

```json
{
    "didDocument":{
        "$ref":"../common/ssi_types.yaml#/components/schemas/DIDDocument"
    }
}
```

Howewer, the name of the model is auto generated and there is way to have a better result.  
Start to generate models from the referenced specification, then map the "$ref" with the `model` package before generate your app, example:  

```objectscript
; Generate models from referenced specification
Set sc = ##class(dc.openapi.suite.Generate).Models("Nuts.Api.Common", "https://nuts-node.readthedocs.io/en/stable/_static/common/ssi_types.yaml")

; Set a mapping specifcation - models
Set externals =  {"../common/ssi_types.yaml": "Nuts.Api.Common.model"}

; Generate your application with a mapping model for external references.
Set sc = ##class(dc.openapi.suite.Generate).Server("Nuts.ApiServer.DidManager", "https://nuts-node.readthedocs.io/en/stable/_static/didman/v1.yaml", , externals)

```

**Note:** *If you use a filepath instead of a URL, the solution above is the only way.*

### The `features` argument

The code generation methods described above can take 3rd argument `features`, this is an array with the following supported key-value:

```objectscript
Set features("noExtRef") = 1    ; avoid resolving external references by the parser.

; The following key\value make sense for ProductionClient generator:
;
Set features("noBS") = 1        ; no business service class generation
Set features("noBP") = 1        ; no business process class generation
Set features("noUtils") = 1     ; no utils class generation

; Example:
;
Set sc = ##class(dc.openapi.suite.Generate).ProductionClient("petstore.production","https://petstore3.swagger.io/api/v3/openapi.json", .features)
```

## Developer community article

More information about OpenAPI-suite are available on this [developer community article](https://community.intersystems.com/post/openapi-suite).  

## Troubleshoot

Due to many change, recently you could experienced issue with your environment (zpm install error, problem to generate from an URL).  
Before creating an issue please try this procedure to have a clean install and try again:  

```objectscript
zpm "uninstall objectscript-openapi-definition"
zpm "uninstall openapi-common-lib"
zpm "uninstall openapi-client-gen"
zpm "uninstall openapi-server-gen"
zpm "uninstall swagger-validator-cli"
zpm "uninstall swagger-converter-cli"

zpm "install openapi-suite"
```