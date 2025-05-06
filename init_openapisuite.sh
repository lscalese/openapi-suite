#!/bin/bash

openapi_suite() {
iris session $ISC_PACKAGE_INSTANCENAME -U IRISAPP <<- END
Set ^swaggerconverter("ConverterURL") = "${CONVERTER_URL:-converter.swagger.io}"
Set ^swaggerconverter("Port") = "${CONVERTER_PORT:-80}"
Set ^swaggervalidator("ValidatorURL") = "${VALIDATOR_URL:-validator.swagger.io}"
Set ^swaggervalidator("Port") = "${VALIDATOR_PORT:-80}"
Set ^openapisuite("settings", "AI", "provider") = "ollama"
Halt
END
}

openapi_suite

exit 0