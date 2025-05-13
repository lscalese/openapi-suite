/// Class for standardizing naming conventions across generated code
Class dc.openapi.common.NamingConvention
{

/// Normalize a class name to follow project conventions
/// @param name Raw name from OpenAPI spec
/// @param namespace Optional namespace to prepend
/// @return Normalized class name
ClassMethod NormalizeClassName(name As %String, namespace As %String = "") As %String
{
    // Remove special characters
    Set name = ..RemoveSpecialChars(name)
    
    // Apply PascalCase
    Set name = ..ToPascalCase(name)
    
    // Prepend namespace if provided
    If namespace '= "" {
        Set name = namespace _ "." _ name
    }
    
    Return name
}

/// Normalize a property name
/// @param name Raw property name from OpenAPI spec
/// @return Normalized property name
ClassMethod NormalizePropertyName(name As %String) As %String
{
    // Remove special characters
    Set name = ..RemoveSpecialChars(name)
    
    // Apply PascalCase for IRIS convention
    Set name = ..ToPascalCase(name)
    
    Return name
}

/// Normalize a method name
/// @param name Raw method name from OpenAPI spec (often operationId)
/// @return Normalized method name
ClassMethod NormalizeMethodName(name As %String) As %String
{
    // Remove special characters
    Set name = ..RemoveSpecialChars(name)
    
     // Apply PascalCase for IRIS convention
    Set name = ..ToPascalCase(name)
    
    Return name
}

/// Generate a consistent operationId for paths missing one
/// @param path Path string from OpenAPI
/// @param verb HTTP verb (GET, POST, etc.)
/// @param resource Optional resource name to incorporate
/// @return Generated operationId
ClassMethod GenerateOperationId(path As %String, verb As %String, resource As %String = "") As %String
{
    // If resource not provided, extract from path
    If resource = "" {
        // Extract last meaningful segment from path
        Set segments = $LISTFROMSTRING(path, "/")
        For i=$LISTLENGTH(segments):-1:1 {
            Set segment = $LISTGET(segments, i)
            // Skip parameter segments like {id}
            Continue:$EXTRACT(segment, 1)="{"
            Set resource = segment
            Quit
        }
    }
    
    Set operationId = ..NormalizeMethodName(verb _" "_ resource)
    
    Return operationId
}

/// Remove special characters from a name
ClassMethod RemoveSpecialChars(name As %String) As %String
{
    // Replace non-alphanumeric with spaces
    Set name = $Replace($Translate(name, "-_.%@","     "), "  ", " ")
    
    // Remove any remaining invalid characters
    Set validChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 "
    Set result = ""
    For i=1:1:$LENGTH(name) {
        Set char = $EXTRACT(name, i)
        If $FIND(validChars, char) > 0 {
            Set result = result _ char
        }
    }
    
    Return result
}

/// Convert string to PascalCase (first letter of each word capitalized)
ClassMethod ToPascalCase(str As %String) As %String
{
    Set result = "", ptr = 0
    Set words = $LISTFROMSTRING($ZSTRIP(str, "<>W"), " ")
    
    // Process each word
    While $ListNext(words, ptr, word) {
        Continue:word=""
        
        // Check if already in PascalCase format
        If $Match(word, "^[A-Z][a-z0-9]*([A-Z][a-z0-9]*)*$") {
            // do nothing
        }
        // Check if word already has internal capitalization (camelCase portion)
        ElseIf $Match(word, "[a-z]+[A-Z].*") {
            // Word has internal capitalization - preserve it and just capitalize first letter
            Set word = $ZCVT($EXTRACT(word, 1), "U") _ $EXTRACT(word, 2, *)
        } 
        Else {
            // Standard case - capitalize first letter, lowercase rest
            Set word = $ZCVT($EXTRACT(word, 1), "U") _ $ZCVT($EXTRACT(word, 2, *), "L")
        }
        
        Set result = result _ word
    }
    
    Return result
}

/// Convert string to camelCase (first word lowercase, rest words capitalized)
ClassMethod ToCamelCase(str As %String) As %String
{
    Set pascalCase = ..ToPascalCase(str)
    
    // Convert first character to lowercase
    If $LENGTH(pascalCase) > 0 {
        Set pascalCase = $ZCVT($EXTRACT(pascalCase, 1), "L") _ $EXTRACT(pascalCase, 2, *)
    }
    
    Return pascalCase
}

}
