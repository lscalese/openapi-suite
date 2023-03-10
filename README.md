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


```
zpm "install openapi-suite"
; optional
zpm "install swagger-ui"
```

## Installation docker

```
git clone git@github.com:lscalese/openapi-suite.git
cd openapi-suite
# in case of permission issue with iris-main.log
# touch iris-main.log && chmod 777 iris-main.log
docker-compose up -d
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

```
Set packageName = "petstoreclient"
Set features("simpleHttpClientOnly") = 1
Set sc = ##class(dc.openapi.client.Spec).generateApp(packageName, "https://petstore3.swagger.io/api/v3/openapi.json", .features)
```

### Production client

```
Set packageName = "petstoreproduction"
Set sc = ##class(dc.openapi.client.Spec).generateApp(packageName, "https://petstore3.swagger.io/api/v3/openapi.json")
```

### Rest server-side classes

```
Set packageName = "petstoreserver", webApplication = "/petstore/api"
Set sc = ##class(dc.openapi.server.ServerAppGenerator).Generate("petstoreserver", "https://petstore3.swagger.io/api/v3/openapi.json", webApplication)
```

## Developer community article

More information about OpenAPI-suite are available on this [developer community article](https://community.intersystems.com/post/openapi-suite).  