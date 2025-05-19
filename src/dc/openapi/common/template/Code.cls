Class dc.openapi.common.template.Code
{

ClassMethod GetTemplate(object As %RegisteredObject) As %String
{
    Set subClass = ..DetermineSubClass(object)
    
    If subClass = "" {
        Return ..ByName(..Decision(object))
    }

    Set name = $CLASSMETHOD(subClass, "Decision", object)
    Set template = $CLASSMETHOD(subClass, "ByName", name)
    Return template
}

ClassMethod GetResolvedTemplate(object As %RegisteredObject, variables As %Binary) As %String
{
    Set template = ..GetTemplate(object)
    If template '= "" {
        Set template = ##class(dc.openapi.common.TemplateProcessor).ProcessTemplate(template, .variables, object)
    }
    Return template
}

ClassMethod Decision(object As %RegisteredObject) As %String
{
    ; to implemet in subclass
    Return ""
}

ClassMethod DetermineSubClass(parameter As dc.openapi.common.ast.Parameter)
{
    Return ""
}

ClassMethod ByName(XDataName As %String) As %String
{
    Return ##class(dc.openapi.common.TemplateProcessor).GetTemplateFromXData($classname(), XDataName)
}

ClassMethod ReplaceVariableInTemplate(template As %String, inputObject As %RegisteredObject, prefix As %String = "") As %String
{
    Set sourceClass = $classname(inputObject), propertyName = ""
    if sourceClass [ "%Collection." Return template
    For  {
        Set propertyName = $Order(^oddCOM(sourceClass, $$$cCLASSproperty, propertyName))
        Quit:propertyName=""
        Set propertyValue = $Property(inputObject, propertyName)
        If $IsObject(propertyValue) {
            Set template = ..ReplaceVariableInTemplate(template, propertyValue, propertyName _ ".")
        }
        Else {
            Set template = $Replace(template, "{{"_prefix_propertyName_"}}", propertyValue)
        }
    }
    Return template
}

}
