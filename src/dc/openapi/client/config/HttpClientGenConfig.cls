Class dc.openapi.client.config.HttpClientGenConfig Extends (%JSON.Adaptor, dc.openapi.common.JSONArrayKeyValueHandler)
{

Property ASTReference As dc.openapi.common.ASTReference;

Property AST As dc.openapi.common.ast.OAS [ Calculated, Private ];

/// Package de base pour générer les classes
Property Package As %String;

Property GenerateModels As %Boolean [ InitialExpression = 1 ];

Property GenerateClientClass As %Boolean [ InitialExpression = 1 ];

Property OverrideClientClass As %Boolean [ InitialExpression = 0 ];

Property GenerateAbstractResponseClass As %Boolean [ InitialExpression = 1 ];

Property OverrideAbstractResponseClass As %Boolean [ InitialExpression = 0 ];

Property GenerateRequestClasses As %Boolean [ InitialExpression = 1 ];

Property GenerateResponseClasses As %Boolean [ InitialExpression = 1 ];

/// The key is the operationId
Property GenerateOperationRequestClasses As array Of %Boolean;

Property GenerateOperationRequestClassNames As array Of %String;

Property OverrideOperationRequestClassNames As array Of %Boolean;

/// The key is the operationId
Property GenerateOperationResponseClasses As array Of %Boolean;

Property GenerateOperationResponseClassNames As array Of %String;

Property OverrideOperationResponseClassNames As array Of %Boolean;

Property HttpClientClassName As %String;

Property AbstractResponseClassName As %String;

Property ProcessOperationId As array Of %String;

Method %OnNew(pPackage As %String = "", ASTReference As dc.openapi.common.ASTReference = "") As %Status
{
    Set ..ASTReference = ASTReference
    Set ..Package = pPackage
    Return:'$IsObject(ASTReference) $$$OK
    Set ..HttpClientClassName = ##class(dc.openapi.client.generator.ClientClassGenerator).GetClassName(..Package)
    Set ..AbstractResponseClassName = ##class(dc.openapi.client.generator.AbstractResponseClassGenerator).GetClassName(..Package)
    Set AST = ASTReference.AST
    
    If $IsObject(AST), $IsObject(AST.Paths) {
        Set key = ""
        For  {
            Set path = AST.Paths.GetNext(.key)
            Quit:key=""
            Do ..ProcessOperationId.SetAt($$$YES, path.OperationId)
            Do ..GenerateOperationRequestClasses.SetAt($$$YES, path.OperationId)
            Do ..GenerateOperationResponseClasses.SetAt($$$YES, path.OperationId)
            Do ..OverrideOperationRequestClassNames.SetAt($$$NO, path.OperationId)
            Do ..OverrideOperationResponseClassNames.SetAt($$$NO, path.OperationId)
            Set requestClassName = ##class(dc.openapi.client.generator.RequestModelGenerator).GetClassName(..Package, path)
            Set responseClassName = ##class(dc.openapi.client.generator.ResponseModelGenerator).GetClassName(..Package, path)
            Do ..GenerateOperationRequestClassNames.SetAt(requestClassName, path.OperationId)
            Do ..GenerateOperationResponseClassNames.SetAt(responseClassName, path.OperationId)
        }
    }

    Return $$$OK
}

Method ASTGet() As dc.openapi.common.ast.OAS [ CodeMode = expression ]
{
$Select($IsObject(..ASTReference):..ASTReference.AST,1:"")
}

}
