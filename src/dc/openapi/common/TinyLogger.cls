Include dc.openapi.common.macro

Class dc.openapi.common.TinyLogger Extends %RegisteredObject
{

Property Logs As list Of %String(MAXLEN = 1024);

Property Verbose As %Boolean [ InitialExpression = 0 ];

Property SessionStarted As %Boolean [ InitialExpression = 0 ];

Property Level As %Integer [ InitialExpression = {$$$LEVELTRACE} ];

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

    if level = $$$LEVELERROR {
        Do session.Error(log)
    }
    ElseIf level = $$$LEVELWARNING {
        Do session.Warning(log)
    }
    ElseIf level = $$$LEVELINFO {
        Do session.Info(log)
    }
    ElseIf level = $$$LEVELDEBUG {
        Do session.Debug(log)
    }
    ElseIf level = $$$LEVELTRACE {
        Do session.Trace(log)
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
