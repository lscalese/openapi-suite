Class dc.openapi.common.JSONArrayKeyValueHandler Extends %RegisteredObject
{

Method ToJSONWithArraysAsKeyValue() As %DynamicObject [ CodeMode = objectgenerator ]
{
    If %class.Name = "dc.openapi.common.JSONArrayKeyValueHandler" { ; Generate code only on subclass
        Do %code.WriteLine($Char(9)_"Return {}")
        Return $$$OK
    }
    Do %code.WriteLine($Char(9)_"Do ..%JSONExportToString(.jsonStr)")
    Do %code.WriteLine($Char(9)_"Set json = {}.%FromJSON(jsonStr)")
    #dim property As %Dictionary.CompiledProperty
    Set index = ""
    For  {
        Set property = %class.Properties.GetNext(.index)
        Quit:index=""
        Continue:property.Collection'="array"
        Continue:$Extract(property.Name)="%"

        Set jsonFieldName = property.Parameters.GetAt("%JSONFIELDNAME")
        Set:jsonFieldName="" jsonFieldName = property.Name
        Do %code.WriteLine($Char(9)_"Do json.%Set("""_jsonFieldName_""", [])")
        Do %code.WriteLine($Char(9)_"Set idx = """" For  { Set value = .."_property.Name_".GetNext(.idx) Quit:idx=""""  Do json."""_jsonFieldName_""".%Push({""key"":(idx),""value"":(value)}) }")
    }
    Do %code.WriteLine($Char(9)_"Return json")
    Return $$$OK
}

ClassMethod FromJSONKeyValueAsArray(json As %DynamicObject) As dc.openapi.client.config.HttpClientGenConfig [ CodeMode = objectgenerator ]
{
    If %class.Name = "dc.openapi.common.JSONArrayKeyValueHandler" { ; Generate code only on subclass
        Do %code.WriteLine($Char(9)_"Return ..%New()")
        Return $$$OK
    }
    Do %code.WriteLine($char(9)_"Set instance = ..%New()")
    Set template = $char(9)_"Set out = {}"
                        _ $$$NL _$char(9)_"Set tempList = json.%Get(""{{jsonFieldName}}"")"
                        _ $$$NL _$char(9)_"If $IsObject(tempList) {"
                        _ $$$NL _$char(9)_"    Set iterator = tempList.%GetIterator()"
                        _ $$$NL _$char(9)_"    While iterator.%GetNext(.index, .item) {"
                        _ $$$NL _$char(9)_"        Do out.%Set(item.key, item.value)"
                        _ $$$NL _$char(9)_"    }"
                        _ $$$NL _$char(9)_"}"
                        _ $$$NL _$char(9)_"Do json.%Set(""{{jsonFieldName}}"", out)"
                        _ $$$NL
   
    #dim property As %Dictionary.CompiledProperty
    Set index = ""
    For  {
        Set property = %class.Properties.GetNext(.index)
        Quit:index=""
        Continue:property.Collection'="array"
        Continue:$Extract(property.Name)="%"

        Set jsonFieldName = property.Parameters.GetAt("%JSONFIELDNAME")
        Set:jsonFieldName="" jsonFieldName = property.Name
        Do %code.Write($Replace(template, "{{jsonFieldName}}", jsonFieldName))
    }
    Do %code.WriteLine($char(9)_"Do instance.%JSONImport(json)")
    Do %code.WriteLine($char(9)_"Return instance")
    Return $$$OK
}

}
