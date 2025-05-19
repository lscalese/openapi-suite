Class dc.openapi.common.GeneratorAbstract Extends %RegisteredObject
{

/// Default sub package name
/// Should be overridden in the subclass
Parameter SUBPKG;

/// Default name of the class without package
/// Should be overridden in the subclass
Parameter NAME;

Property AST As dc.openapi.common.ast.OAS;

Property Package As %String [ Calculated ];

Property ClassName As %String;

Property Super As %String [ InitialExpression = "%RegisteredObject" ];

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

}
