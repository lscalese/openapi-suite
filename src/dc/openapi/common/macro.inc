ROUTINE dc.openapi.common.macro [Type=INC]

#def1arg zlog(%arg)                         Do ##class(dc.openapi.common.Utils).log(%arg)
#def1arg FindPropertyName(%arg)             ##class(dc.openapi.common.Utils).FindPropertyName(%arg)
 /*#def1arg NormalizePropertyParamName(%arg)   %arg
#def1arg CodeNormalizeProperty(%arg)        $Select(%arg?1.A.AN:%arg,1:""""_%arg_"""")*/
#def1arg NormalizePropertyParamName(%arg)   $zstrip(%arg, "*P")
#def1arg CodeNormalizeProperty(%arg)        $zstrip(%arg, "*P")
#def1arg GetObjectScriptType(%arg)          ##class(Grongier.OpenApi.DefinitionV3).GetObjectScriptType(%arg)
#define zNormalizeClassName(%arg)           $zstrip(%arg, "*P")