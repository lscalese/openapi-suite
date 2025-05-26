Include dc.openapi.common.macro

Class dc.openapi.common.GeneratorAbstract Extends %RegisteredObject
{

/// Default sub package name
/// Should be overridden in the subclass
Parameter SUBPKG;

/// Default name of the class without package
/// Should be overridden in the subclass
Parameter NAME;

Property ASTReference As dc.openapi.common.ASTReference;

Property AST As dc.openapi.common.ast.OAS [ Calculated, Private ];

Property Package As %String [ Calculated ];

Property ClassName As %String;

Property Super As %String [ InitialExpression = "%RegisteredObject" ];

Property OverrideClassIfExists As %Boolean [ InitialExpression = 0 ];

ClassMethod GetClassName(rootPackageName As %String, object As %RegisteredObject = "") As %String [ CodeMode = expression ]
{
rootPackageName _ $Select(..#SUBPKG'="":"."_..#SUBPKG,1:"") _ "." _ ..#NAME
}

Method GenerateAll() As %Status [ Abstract ]
{
}

Method Generate(object As %RegisteredObject) As %Dictionary.ClassDefinition [ Abstract ]
{
}

Method PackageGet() As %String
{
    Return $Piece(..ClassName, ".", 1, * -1)
}

Method DeleteIfExists() As %Status
{
    Return:'##class(%Dictionary.ClassDefinition).%ExistsId(..ClassName) $$$OK
    ; todo add security check to avoid deleting system classes
    $$$LOGDEBUG("Deleting existing class definition for "_..ClassName)
    Return $SYSTEM.OBJ.Delete(..ClassName)
}

Method ASTGet() As dc.openapi.common.ast.OAS [ CodeMode = expression ]
{
..ASTReference.AST
}

/// Check if the parameter OverrideClassIfExists is set.
/// If it is set, the method will check if the class definition already exists.
/// If it exists, it will delete the existing class definition.
/// If the parameter OverrideClassIfExists is not set, it will check if the class definition already exists.
/// If it exists, it will return the existing class definition.
/// 
/// The method returns $$$NO if the class definition already exists and OverrideClassIfExists is not set.
/// In this case, the output parameter classDefinition will contain the existing class definition.
Method HandleOverride(Output classDefinition As %Dictionary.ClassDefinition = "") As %Boolean
{
    If ..OverrideClassIfExists {
        If ##class(%Dictionary.CompiledClass).%ExistsId(..ClassName) {
            $$$LOGDEBUG("Class definition for "_..ClassName_" already exists and OverrideClassIfExists is set. Deleting it.")
            Set sc = ..DeleteIfExists()
            If $$$ISERR(sc) {
                $$$LOGERROR("Failed to delete existing class definition for "_..ClassName_": "_$System.Status.GetErrorText(sc))
            }
        }
    }
    ElseIf ##class(%Dictionary.ClassDefinition).%ExistsId(..ClassName) {
        $$$LOGDEBUG("Class definition for "_..ClassName_" already exists and OverrideClassIfExists is not set. Skipping generation.")
        Set classDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(..ClassName)
        Return $$$NO
    }
    
    Return $$$YES
}

}
