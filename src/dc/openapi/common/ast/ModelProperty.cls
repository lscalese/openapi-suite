Class dc.openapi.common.ast.ModelProperty Extends (%JSON.Adaptor, %RegisteredObject)
{

/// Represents the property name in the ObjectScript model class
Property Name As %String;

/// JSOIN Field name
Property pJSONFieldName As %String;

/// Represents the ObjectScript type of this property
Property Type As %String;

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
Property pEnum As %String;

/// Collection type
Property Collection As %String;

Property OASReference As %String;

Property Description As %String;

}
