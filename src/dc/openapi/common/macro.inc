ROUTINE dc.openapi.common.macro [Type=INC]

#def1arg zlog(%arg)                         Do ##class(dc.openapi.common.Utils).log(%arg)
#def1arg FindPropertyName(%arg)             ##class(dc.openapi.common.Utils).FindPropertyName(%arg)
 /*#def1arg NormalizePropertyParamName(%arg)   %arg
#def1arg CodeNormalizeProperty(%arg)        $Select(%arg?1.A.AN:%arg,1:""""_%arg_"""")*/
#def1arg NormalizePropertyParamName(%arg)   $zstrip(%arg, "*P")
#def1arg CodeNormalizeProperty(%arg)        $zstrip(%arg, "*P")
#def1arg GetObjectScriptType(%arg)          ##class(Grongier.OpenApi.DefinitionV3).GetObjectScriptType(%arg)
#define zNormalizeClassName(%arg)           $zstrip(%arg, "*P")

#define LEVELFATAL                          0
#define LEVELERROR                          1
#define LEVELWARNING                        2
#define LEVELINFO                           3
#define LEVELDEBUG                          4
#define LEVELTRACE                          5

#Def1Arg LOGFATAL(%arg)                     Do ##class(dc.openapi.common.TinyLogger).AddLog(%arg,$$$LEVELFATAL)
#Def1Arg LOGERROR(%arg)                     Do ##class(dc.openapi.common.TinyLogger).AddLog(%arg,$$$LEVELERROR)
#Def1Arg LOGWARNING(%arg)                   Do ##class(dc.openapi.common.TinyLogger).AddLog(%arg,$$$LEVELWARNING)
#Def1Arg LOGINFO(%arg)                      Do ##class(dc.openapi.common.TinyLogger).AddLog(%arg,$$$LEVELINFO)
#Def1Arg LOGDEBUG(%arg)                     Do ##class(dc.openapi.common.TinyLogger).AddLog(%arg,$$$LEVELDEBUG)
#Def1Arg LOGTRACE(%arg)                     Do ##class(dc.openapi.common.TinyLogger).AddLog(%arg,$$$LEVELTRACE)

#Def1Arg LOGTAG(%level)                     $Case(%level, $$$LEVELFATAL: "[FATAL]", $$$LEVELERROR: "[ERROR]", $$$LEVELWARNING: "[WARNING]", $$$LEVELINFO: "[INFO]", $$$LEVELDEBUG: "[DEBUG]", $$$LEVELTRACE: "[TRACE]",:"")

#define LOGTRACEENABLED                     (##class(dc.openapi.common.TinyLogger).GetInstance().Level>=$$$LEVELTRACE)
#define LOGDEBUGENABLED                     (##class(dc.openapi.common.TinyLogger).GetInstance().Level>=$$$LEVELDEBUG)

#define LOGSTATUS(%log,%status)             If $$$ISERR(%status) { $$$LOGERROR(%log) } Else { $$$LOGINFO(%log) }