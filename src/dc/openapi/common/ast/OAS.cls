/// This class represents the OpenAPI Specification (OAS) AST
/// It's a intermediate representation of the OpenAPI Specification
/// It can be modified before generating ObjectScript code
Class dc.openapi.common.ast.OAS Extends (%JSON.Adaptor, %RegisteredObject)
{

/// The OpenAPI Specification (OAS) version
Property OpenAPI As %String;

/// The OpenAPI Specification (OAS) info object
/// This object contains metadata about the API
/// It includes the title, version, and description of the API
Property Info As dc.openapi.common.ast.Info;

/// The OpenAPI Specification (OAS) servers object
Property Servers As list Of dc.openapi.common.ast.Server;

/// The OpenAPI Specification (OAS) paths object
Property Paths As list Of dc.openapi.common.ast.Path;

/// The OpenAPI Specification (OAS) responses object
Property Responses As list Of dc.openapi.common.ast.Response;

/// Common parameters for all paths
Property CommonParameters As list Of dc.openapi.common.ast.Parameter;

Property Models As list Of dc.openapi.common.ast.Model;

/// external reference used by other OpenAPI Specification that refers to this OAS
/// ex: $ref: 'http://example.com/common.json#/components/schemas/Pet'
/// The ExternalReference property must be set with the value before "#"
Property ExternalReference As %String;

}
