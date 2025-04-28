/// This class represents the OpenAPI Specification (OAS) AST
/// It's a intermediate representation of the OpenAPI Specification
/// It can be modified before generating ObjectScript code
Class dc.openapi.common.ast.OAS Extends (%JSON.Adaptor, %RegisteredObject)
{

/// The OpenAPI Specification (OAS) version
Property openapi As %String;

/// The OpenAPI Specification (OAS) info object
/// This object contains metadata about the API
/// It includes the title, version, and description of the API
Property info As dc.openapi.common.ast.Info;

/// The OpenAPI Specification (OAS) servers object
Property servers As list Of dc.openapi.common.ast.Server;

/// The OpenAPI Specification (OAS) paths object
Property paths As list Of dc.openapi.common.ast.Path;

/// The OpenAPI Specification (OAS) responses object
Property responses As list Of dc.openapi.common.ast.Response;

/// Common parameters for all paths
Property commonParameters As list Of dc.openapi.common.ast.Parameter;

Property models As list Of dc.openapi.common.ast.Model;

}
