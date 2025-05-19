Class dc.openapi.client.template.Parameters Extends dc.openapi.common.template.Code
{

ClassMethod Decision(parameter As dc.openapi.common.ast.Parameter) As %String
{
    ; to implemet in subclass
    Return ""
}

ClassMethod DetermineSubClass(parameter As dc.openapi.common.ast.Parameter) As %String
{
    Set subClass = ""

    If parameter.In = "path" {
        Set subClass = "dc.openapi.client.template.PathParameters"
    }
    ElseIf parameter.In = "query" {
        Set subClass = "dc.openapi.client.template.QueryParameters"
    }
    ElseIf parameter.In = "header" {
        Set subClass = "dc.openapi.client.template.HeaderParameters"
    }
    ElseIf parameter.In = "cookie" {
        Set subClass = "dc.openapi.client.template.CookieParameters"
    }

    Return subClass
}

}
