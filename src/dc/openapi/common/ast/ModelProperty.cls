Class dc.openapi.common.ast.ModelProperty Extends (%JSON.Adaptor, %RegisteredObject)
{

/// Represents the property name in the ObjectScript model class
Property Name As %String(MAXLEN = 256);

/// JSOIN Field name
Property pJSONFieldName As %String(MAXLEN = 256);

/// Represents the ObjectScript type of this property
Property Type As %String(MAXLEN = 256);

/// used to define MINVAL parameter
Property pMinimum As %String;

/// used to define MAXVAL parameter
Property pMaximum As %String;

/// used to define MINLEN parameter
Property pMinLength As %String;

/// used to define MAXLEN parameter
Property pMaxLength As %String;

/// used to define INITIALEXPRESSION parameter
Property pDefault As %String;

/// used to define VALUELIST parameter
Property pEnum As %String(MAXLEN = 32000);

/// Collection type
Property Collection As %String;

Property OASReference As %String(MAXLEN = 32000);

Property Description As %String(MAXLEN = 32000);

/// Helper for the code generation
/// stream, object, datatype
Property TypeHelper As %String(MAXLEN = 128) [ InitialExpression = "datatype" ];

}
