Class dc.openapi.common.template.Utils Extends %RegisteredObject
{

ClassMethod ObjectToMultipart(InputObject As %RegisteredObject) As %Status
{
    Set sc = $$$OK

    Set sourceClass = $classname(InputObject)
    Set property = ""
    For  {
        Set property = $Order(^oddCOM(sourceClass, $$$cCLASSproperty, property))
        Quit:property=""

        If $Extract(property) = "%" {
            Continue
        }

        Set propertyClass = $$$comMemberKeyGet(sourceClass,$$$cCLASSproperty,prop,$$$cPROPtype)
        //  Use global lookup instead of %Dictionary.Class query so users don't need privileges on that table
        w !,"Property: " _ prop _ " Class: " _ propertyClass
        
        
    }

    Return sc
}

}
