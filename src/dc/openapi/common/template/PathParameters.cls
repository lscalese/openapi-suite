Class dc.openapi.common.template.PathParameters Extends dc.openapi.common.template.Code
{

/// --- simple
/// template for path parameters style = simple, (explode = false or explode = true)
XData DatatypeSimple [ MimeType = plain/text ]
{
    Set ..%Path = $Replace(..%Path, "{{{Name}}}", ..{{ModelProperty.Name}})
}

/// template for path parameters array style = simple, (explode = false or explode = true)
XData ArraySimple [ MimeType = plain/text ]
{
    // Serialize the list parameter {{{Name}}}, ex path = /path/{{{Name}}} to /path/1,2,3
    Do ..{{ModelProperty.Name}}.%SerializeObject(.tmpList)
    Set tmpList = $List(tmpList)
    Set ..%Path = $Replace(..%Path, "{{{Name}}}", $ListToString(tmpList))
    Kill tmpList
}

///  template for path parameters object style = simple, explode = false
XData ObjectSimple [ MimeType = plain/text ]
{
    Do ..{{ModelProperty.Name}}.%JSONExportToString(.tmp)
    Set tmp = $tr($e(tmp,2,*-1),":""",",")
    Set ..%Path = $Replace(..%Path, "{{{Name}}}", tmp)
    Kill tmp
}

///  template for path parameters object style = simple, explode = true
XData ObjectSimpleExplode [ MimeType = plain/text ]
{
    Do ..{{ModelProperty.Name}}.%JSONExportToString(.tmp)
    Set tmp = $tr($e(tmp,2,*-1),":""","=")
    Set ..%Path = $Replace(..%Path, "{{{Name}}}", tmp)
    Kill tmp
}

/// --- label
/// template for path parameters style = label, explode = false
XData DatatypeLabel [ MimeType = plain/text ]
{
    // Serialize the parameter {{{Name}}}, ex path = /path/{{{Name}}} to /path/.5
    Set ..%Path = $Replace(..%Path, "{{{Name}}}", "."_..{{ModelProperty.Name}})
}

/// template for path parameters array style = label, explode = false
XData ArrayLabel [ MimeType = plain/text ]
{
    // Serialize the list parameter {{{Name}}}, ex path = /path/{{{Name}}} to /path/.1,2,3
    Do ..{{ModelProperty.Name}}.%SerializeObject(.tmpList)
    Set tmpList = $List(tmpList)
    Set ..%Path = $Replace(..%Path, "{{{Name}}}", "."_$ListToString(tmpList))
    Kill tmpList
}

/// template for path parameters array style = label, explode = false
XData ArrayLabelExplode [ MimeType = plain/text ]
{
    // Serialize the list parameter {{{Name}}}, ex path = /path/{{{Name}}} to /path/.1.2.3
    Do ..{{ModelProperty.Name}}.%SerializeObject(.tmpList)
    Set tmpList = $List(tmpList)
    Set ..%Path = $Replace(..%Path, "{{{Name}}}", "."_$ListToString(tmpList,"."))
    Kill tmpList
}

///  template for path parameters object style = label, explode = false
XData ObjectLabel [ MimeType = plain/text ]
{
    Do ..{{ModelProperty.Name}}.%JSONExportToString(.tmp)
    Set tmp = $tr($e(tmp,2,*-1),":""",",")
    Set ..%Path = $Replace(..%Path, "{{{Name}}}", "."_tmp)
    Kill tmp
}

///  template for path parameters object style = label, explode = true
XData ObjectLabelExplode [ MimeType = plain/text ]
{
    Do ..{{ModelProperty.Name}}.%JSONExportToString(.tmp)
    Set tmp = $tr($e(tmp,2,*-1),":""","=")
    Set ..%Path = $Replace(..%Path, "{{{Name}}}", "."_tmp)
    Kill tmp
}

/// --- matrix
/// template for path parameters style = matrix, (explode = false or explode=true)
XData DatatypeMatrix [ MimeType = plain/text ]
{
    // Serialize the parameter {{{Name}}}, ex path = /path/{{{Name}}} to /path/;{{Name}}=1
    Set ..%Path = $Replace(..%Path, "{{{Name}}}", ";{{Name}}="_..{{ModelProperty.Name}})
}

/// template for path parameters array style = matrix, explode = false
XData ArrayMatrix [ MimeType = plain/text ]
{
    // Serialize the list parameter {{{Name}}}, ex path = /path/{{{Name}}} to /path/;{{Name}}=1,2,3
    Do ..{{ModelProperty.Name}}.%SerializeObject(.tmpList)
    Set tmpList = $List(tmpList)
    Set ..%Path = $Replace(..%Path, "{{{Name}}}", ";{{Name}}="_$ListToString(tmpList))
    Kill tmpList
}

/// template for path parameters array style = simple, explode = false
XData ArrayMatrixExplode [ MimeType = plain/text ]
{
    // Serialize the list parameter {{{Name}}}, ex path = /path/{{{Name}}} to /path/;{{Name}}=1;{{Name}}=2;{{Name}}=3
    Do ..{{ModelProperty.Name}}.%SerializeObject(.tmpList)
    Set tmpList = $List(tmpList)
    Set ..%Path = $Replace(..%Path, "{{{Name}}}", ";{{Name}}="_$ListToString(tmpList,";{{Name}}="))
    Kill tmpList
}

///  template for path parameters object style = simple, explode = false
XData ObjectMatrix [ MimeType = plain/text ]
{
    Do ..{{ModelProperty.Name}}.%JSONExportToString(.tmp)
    Set tmp = $tr($e(tmp,2,*-1),":""",",")
    Set ..%Path = $Replace(..%Path, "{{{Name}}}", ";{{Name}}="_tmp)
    Kill tmp
}

///  template for path parameters object style = simple, explode = true
XData ObjectMatrixExplode [ MimeType = plain/text ]
{
    Do ..{{ModelProperty.Name}}.%JSONExportToString(.tmp)
    Set tmp = $tr($e(tmp,2,*-1),":""","=")
    Set ..%Path = $Replace(..%Path, "{{{Name}}}", ";"_tmp)
    Kill tmp
}

ClassMethod Decision(type As %String, style As %String, explode As %Boolean) As %String
{
    Set type = $$$LOWER(type), style = $$$LOWER(style), explode = $Select(explode:"explode=true",1:"explode=false")

    Set decision("datatype", "simple", "explode=false") = "DatatypeSimple"
    Set decision("datatype", "simple", "explode=true") = "DatatypeSimple"
    Set decision("array", "simple", "explode=false") = "ArraySimple"
    Set decision("array", "simple", "explode=true") = "ArraySimple"
    Set decision("object", "simple", "explode=false") = "ObjectSimple"
    Set decision("object", "simple", "explode=true") = "ObjectSimpleExplode"

    Set decision("datatype", "label", "explode=false") = "DatatypeLabel"
    Set decision("datatype", "label", "explode=true") = "DatatypeLabel"
    Set decision("array", "label", "explode=false") = "ArrayLabel"
    Set decision("array", "label", "explode=true") = "ArrayLabelExplode"
    Set decision("object", "label", "explode=false") = "ObjectLabel"
    Set decision("object", "label", "explode=true") = "ObjectLabelExplode"
    
    Set decision("datatype", "matrix", "explode=false") = "DatatypeMatrix"
    Set decision("datatype", "matrix", "explode=true") = "DatatypeMatrix"
    Set decision("array", "matrix", "explode=false") = "ArrayMatrix"
    Set decision("array", "matrix", "explode=true") = "ArrayMatrixExplode"
    Set decision("object", "matrix", "explode=false") = "ObjectMatrix"
    Set decision("object", "matrix", "explode=true") = "ObjectMatrixExplode"

    Return $Get(decision(type, style, explode))
}

}
