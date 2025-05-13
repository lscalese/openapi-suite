Class dc.openapi.common.template.Code
{

ClassMethod GetTemplate(type As %String, style As %String, explode As %Boolean) As %String
{
    Return ..ByName(..Decision(type, style, explode))
}

ClassMethod ByName(XDataName As %String) As %String
{
    Set id = $classname() _ "||" _ XDataName
    If '##class(%Dictionary.CompiledXData).%ExistsId(id) {
        Return ""
    }
    Set template = ##class(%Dictionary.CompiledXData).%OpenId(id).Data.Read()
    Return template
}

ClassMethod Decision(type As %String, style As %String, explode As %Boolean) As %String
{
    ; to implemet in subclass
    Return ""
}

}
