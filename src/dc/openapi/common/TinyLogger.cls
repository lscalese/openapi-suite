Class dc.openapi.common.TinyLogger Extends %RegisteredObject
{

Property Logs As list Of %String(MAXLEN = 1024);

Property Verbose As %Boolean [ InitialExpression = 0 ];

Property SessionStarted As %Boolean [ InitialExpression = 0 ];

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

ClassMethod AddLog(log As %String, level As %String = "INFO")
{
    Set session = ..GetInstance()
    If 'session.SessionStarted {
        Return $$$OK
    }

    Set level = $$$UPPER(level)

    if level = "ERROR" {
        Do session.Error(log)
    }
    ElseIf level = "WARNING" {
        Do session.Warning(log)
    }
    ElseIf level = "INFO" {
        Do session.Info(log)
    }
    ElseIf level = "DEBUG" {
        Do session.Debug(log)
    }
    ElseIf level = "TRACE" {
        Do session.Trace(log)
    }
    ElseIf level = "LOG" {
        Do session.Log(log)
    }
    Else {
        Do session.Add($zdt($h,3,1)_" "_log)
    }

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

Method Error(log As %String)
{
    Set logDT = $zdt($h,3,1)_" [ERROR] "_log
    Do ..Add(logDT)
}

Method Warning(log As %String)
{
    Set logDT = $zdt($h,3,1)_" [WARNING] "_log
    Do ..Add(logDT)
}

Method Info(log As %String)
{
    Set logDT = $zdt($h,3,1)_" [INFO] "_log
    Do ..Add(logDT)
}

Method Debug(log As %String)
{
    Set logDT = $zdt($h,3,1)_" [DEBUG] "_log
    Do ..Add(logDT)
}

Method Trace(log As %String)
{
    Set logDT = $zdt($h,3,1)_" [TRACE] "_log
    Do ..Add(logDT)
}

Method Log(log As %String)
{
    Set logDT = $zdt($h,3,1)_" [LOG] "_log
    Do ..Add(logDT)
}

Method Add(log As %String)
{
    Quit:'..SessionStarted
    Do ..Logs.Insert(log)
    Write:..Verbose !, log
}

}
