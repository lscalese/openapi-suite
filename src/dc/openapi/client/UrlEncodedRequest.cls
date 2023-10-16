Include Ensemble

/// Util-class to create a Request body for Content-Type = "application/x-www-form-urlencoded"
Class dc.openapi.client.UrlEncodedRequest
{

/// Convert json enabled object to "application/x-www-form-urlencoded" formatted stream
ClassMethod ConvertJson2Stream(object As %JSON.Adaptor, ByRef export As %Stream.Object) As %Status
{
	set sc = ..ConvertJson2String(object, .output)

	#; $$$TRACE("URLENCODED body = " _ output)

	if $$$ISERR(sc)
	{
		return sc
	}

	return export.Write(output)
}

/// Convert json enabled object to "application/x-www-form-urlencoded" formatted string
ClassMethod ConvertJson2String(object As %JSON.Adaptor, Output export As %String) As %Status
{
	#dim sc As %Status = $$$OK

	try
	{
		$$$ThrowOnError(object.%JSONExportToString(.jsonstring))
		set json = ##class(%DynamicObject).%FromJSON(jsonstring)

		set iterator = json.%GetIterator()
		set export = ""
		set count = 0

		while iterator.%GetNext(.name, .value) 
		{
			#; $$$TRACE("Found " _ name _ "=" _ value)
			if count > 0
			{
				set export = export _ "&"
			}
			
			set export = export _ name _ "=" _ $$$URLENCODE(value)
			set count = count + 1
		}
	}
	catch ex
	{
		set sc = ex.AsStatus()

		$$$LOGERROR("Fout tijdens uitvoeren van ConvertToUrlEncoded: " _ $System.Status.GetErrorText(sc))
	}

	return sc
}

}
