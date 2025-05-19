Class dc.JDBC Extends %RegisteredObject
{

Property gatewayName As %String;

Property sqlGateway As %Library.ObjectHandle;

Method %OnNew(DSN As %String = "") As %Status [ Private, ServerOnly = 1 ]
{
    Set ..gatewayName=DSN
    Return $$$OK
}

Method connect() As %Status
{
    Set ..sqlGateway=$$GetJConnection^%apiGTW(..gatewayName)
    Return:(..sqlGateway="") $$$ERROR($$$GTWCConnectionError)
    Return $$$OK
}

Method disconnect() As %Status
{
    Do %JDBCGateway.removeConnection(..sqlGateway)
    Set ..sqlGateway=""
    Return $$$OK
}

/// todo
ClassMethod testConnection(DSN As %String = "") As %Status
{
    Return $$$OK
}

/// Attention au memory leaks
/// Toujours faire ceci après:
///  %JDBCGateway.removeResultSet(##this.sqlGateway)
///  %JDBCGateway.removeStatement(sc)
Method prepareAndExecuteQry(Output stat, qryStr As %String = "") As %Status
{
    Set stat=%JDBCGateway.prepareStatement(..sqlGateway,qryStr)
    Return:(stat<0) $$$ERROR($$$GeneralError,%JDBCGateway.getErrorText())
    Set rs=%JDBCGateway.execQuery(stat)
    Return:(rs<0) $$$ERROR($$$GeneralError,%JDBCGateway.getErrorText())
    Return $$$OK
}

Method describeColumns(stat, neededColumns As %List = {$LISTBUILD("*")}, Output columnTab As %Binary) As %Status
{
    For colCpt=1:1:%JDBCGateway.getColumnCount(stat) {
        Set colName=%JDBCGateway.getColumnName(stat,colCpt)
        Set colName=$ZCONVERT(colName,"U")
        Set:(($LISTGET(neededColumns,1)="*") || ($LISTFIND(neededColumns,colName)>0)) columnTab(colName)=colCpt
    }
    Return $$$OK
}

Method reverseDescribeColumns(ByRef columnTab As %Binary, Output revColumnTab As %Binary) As %Status
{
    Set k1=$ORDER(columnTab(""))
    While (k1'="") {
        Set revColumnTab($GET(columnTab(k1)))=k1
        Set k1=$ORDER(columnTab(k1))
    }
    Return $$$OK
}

ClassMethod t()
{

    Set jdbc = ##class(dc.JDBC).%New()
    Set sc = jdbc.connect()
    Return:$$$ISERR(sc)
    Set sql = "SELECT * FROM ..."
    Set sc = jdbc.prepareAndExecuteQry(.stat,sql)
    Return:$$$ISERR(sc)
    Do jdbc.describeColumns(stat,,.columnTab)
    Do jdbc.reverseDescribeColumns(.columnTab,.revColumnTab)
    While %JDBCGateway.next(stat){
        Set orderTab="", key=""
        For  {
            Set key=$ORDER(revColumnTab(key))
            Quit:key=""
            Set orderTab($GET(revColumnTab(key)))=%JDBCGateway.getString(stat,key)    
        }
        Set lb = $LISTBUILD($GET(orderTab("<field_name_1>")), $GET(orderTab("<field_name_2>")))
        Set ^||qHandle.Results($INCREMENT(^||qHandle.Results)) = lb
        Kill orderTab
    }
    Do %JDBCGateway.removeResultSet(jdbc.sqlGateway)
    Do %JDBCGateway.removeStatement(stat)

    ;
}

}
