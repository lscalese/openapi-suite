/// Class for processing templates with variables between double accolades
Class dc.openapi.common.TemplateProcessor
{

/// Replace variables in a template with their corresponding values from a map
/// @param template The template string containing variables in {{variable}} format
/// @param variables Reference to an array of variable values indexed by variable name
/// @param nbPass Number of passes to process nested replacements
/// @return The processed template with all variables replaced
ClassMethod ResolveTemplate(template As %String, ByRef variables As %Binary, nbPass As %Integer = 2) As %String
{
    For i = 1 : 1 : nbPass {
        // Extract all strings between {{ and }} from the template
        Set regex = "\{\{([^}]*)\}\}"
        Set pattern = ##class(%Regex.Matcher).%New(regex, template)
        
        While pattern.Locate() {
            Set placeholder = pattern.Group
            Continue:pattern.Group(1)=""
            Set value = $Get(variables(pattern.Group(1)))
            Set template = $Replace(template, pattern.Group, $zstrip(value, "<W"))
        }
    }
    
    Return template
}

/// Replace variables in a template with values extracted from an object's properties
/// @param template The template string containing variables in {{property}} or {{prefix.property}} format
/// @param inputObject The object containing the property values to use for replacement
/// @param prefix Optional prefix for nested properties
/// @return The processed template with all properties replaced
ClassMethod ReplaceVariableInTemplate(template As %String, inputObject As %RegisteredObject, prefix As %String = "") As %String
{
    // If not an object or is a collection, return template unchanged
    If '$IsObject(inputObject) || (inputObject.%IsA("%Collection.AbstractIterator")) {
        Return template
    }
    
    Set sourceClass = $classname(inputObject), propertyName = ""
    For  {
        Set propertyName = $Order(^oddCOM(sourceClass, $$$cCLASSproperty, propertyName))
        Quit:propertyName=""
        
        Try {
            Set propertyValue = $Property(inputObject, propertyName)
            
            If $IsObject(propertyValue) {
                // Recursively process nested objects
                Set template = ..ReplaceVariableInTemplate(template, propertyValue, prefix _ propertyName _ ".")
            }
            Else {
                // Replace the variable placeholder with its value
                Set template = $Replace(template, "{{"_prefix_propertyName_"}}", propertyValue)
            }
        } Catch {}
    }
    
    Return template
}

/// Process a template with variable replacements from both a map and an object
/// @param template The template string with variables in {{name}} format
/// @param variables Reference to an array of variable values for direct replacement
/// @param inputObject Optional object whose properties should be used for replacements
/// @param nbPass Number of passes for processing nested replacements
/// @return The fully processed template
ClassMethod ProcessTemplate(template As %String, ByRef variables As %Binary = "", inputObject As %RegisteredObject = "", nbPass As %Integer = 2) As %String
{
    // First replace variables from the object if provided
    If $IsObject(inputObject) {
        Set template = ..ReplaceVariableInTemplate(template, inputObject)
    }
    
    // Then replace variables from the map if provided
    If $Data(variables) {
        Set template = ..ResolveTemplate(template, .variables, nbPass)
    }
    
    Return template
}

/// Get a template from an XData block in a class
/// @param className The name of the class containing the XData
/// @param xdataName The name of the XData block
/// @return The template content or empty string if not found
ClassMethod GetTemplateFromXData(className As %String, xdataName As %String) As %String
{
    Set id = className _ "||" _ xdataName
    If '##class(%Dictionary.CompiledXData).%ExistsId(id) {
        Return ""
    }
    Set template = ##class(%Dictionary.CompiledXData).%OpenId(id).Data.Read()
    Return template
}

}
