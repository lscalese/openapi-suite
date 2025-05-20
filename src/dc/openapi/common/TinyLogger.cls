Include dc.openapi.common.macro

Class dc.openapi.common.TinyLogger Extends %RegisteredObject
{

Property Logs As list Of %String(MAXLEN = 1024);

Property Verbose As %Boolean [ InitialExpression = 0 ];

Property SessionStarted As %Boolean [ InitialExpression = 0 ];

Property Level As %Integer [ InitialExpression = {$$$LEVELINFO} ];

ClassMethod GetInstance() As dc.openapi.common.TinyLogger
{
    If '$IsObject($Get(%zTinyLogger)) {
        Set %zTinyLogger = ##class(dc.openapi.common.TinyLogger).%New()
    }
    Return %zTinyLogger
}

ClassMethod StartSession(config As %DynamicObject = {{}})
{
    Set session = ..GetInstance()
    Set session.SessionStarted = $$$YES
    Set session.Verbose = ''config.verbose
}

ClassMethod StopSession()
{
    Set session = ..GetInstance()
    Set session.SessionStarted = $$$NO
}

ClassMethod AddLog(log As %String, level As %Integer = 3)
{
    Set session = ..GetInstance()
    If 'session.SessionStarted {
        Return $$$OK
    }

    If level > session.Level {
        Return $$$OK
    }
    Set tag = $$$LOGTAG(level)
    Set logDT = $zdt($h,3,1) _ " " _ tag _ " " _ log
    Do session.Add(logDT)
    
    Return $$$OK
}

ClassMethod ShowLogs() As %Status
{
    Set session = ..GetInstance()
    Set key = ""
    For  {
        Set log = %session.Logs.GetNext(.key)
        Quit:key=""
        Write !, log
    }
    Return $$$OK
}

ClassMethod ClearLogs()
{
    Set session = ..GetInstance()
    Do session.Logs.Clear()
}

Method Add(log As %String)
{
    Quit:'..SessionStarted
    Do ..Logs.Insert(log)
    Write:..Verbose !, log
}

}
