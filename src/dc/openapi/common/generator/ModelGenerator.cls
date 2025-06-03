Include dc.openapi.common.macro

Class dc.openapi.common.generator.ModelGenerator Extends dc.openapi.common.GeneratorAbstract
{

Parameter SUBPKG = "model";

Method GenerateAll() As %Status
{
    $$$LOGINFO("Starting model generation process")
    Set tSc = $$$OK
    // Iterate over the models in the AST and generate code for each one
    #dim model As dc.openapi.common.ast.Model
    #dim models As %ListOfObjects

    Set models = ..AST.Models
    Set modelCount = models.Count()
    $$$LOGINFO("Found "_modelCount_" models to generate")
    
    Set key = ""
    Set processedCount = 0
    For  {
        Set model = models.GetNext(.key)
        Quit:key=""
        
        Set processedCount = processedCount + 1
        $$$LOGDEBUG("Processing model ["_processedCount_"/"_modelCount_"]: "_model.Name)
        
        Set ..ClassName = model.Name
        Set ..Super = model.Super _ $Select(..Super'="" : "," _ ..Super, 1: "")
        Set classDef = ..Generate(model)
        Set saveStatus = classDef.%Save()
        If $$$ISERR(saveStatus) {
            $$$LOGERROR("Failed to save class definition for "_model.Name_": "_$System.Status.GetErrorText(saveStatus))
        } Else {
            $$$LOGDEBUG("Successfully saved class definition for "_model.Name)
        }
        Set tSc = $$$ADDSC(tSc, saveStatus)
    }

    $$$LOGSTATUS("Model generation completed with "_processedCount_" models", tSc)
    Return tSc
}

Method Generate(model As dc.openapi.common.ast.Model) As %Dictionary.ClassDefinition
{
    $$$LOGDEBUG("Generating class definition for model: "_model.Name)
    #define classDef As %Dictionary.ClassDefinition

    Return:'..HandleOverride(.classDef) classDef

    Set classDef = ##class(%Dictionary.ClassDefinition).%New()
    Set classDef.Name = ..ClassName
    Do ##class(dc.openapi.common.GeneratedItemRegistry).RegisterClass(..ClassName)
    Set classDef.Super = ..Super
    Set classDef.Description = ##class(dc.openapi.common.Utils).FormatDescription(model.Description)
    Set classDef.Inheritance = "left"
    Set classDef.ProcedureBlock = $$$YES

    Set parameterDef = ##class(%Dictionary.ParameterDefinition).%New()
    Set parameterDef.Name = "SCHEMAREF"
    Set parameterDef.Default = model.SchemaRef
    Do classDef.Parameters.Insert(parameterDef)
    
    // iterate over the properties and add them to the class definition
    #dim prop As dc.openapi.common.ast.ModelProperty
    #dim props As %ListOfObjects
    
    Set props = model.Properties
    Set propCount = props.Count()
    $$$LOGDEBUG("Found "_propCount_" properties for model "_model.Name)
    
    Set key = ""
    Set processedProps = 0
    For  {
        Set prop = props.GetNext(.key)
        Quit:key=""
        
        Set processedProps = processedProps + 1
        If $$$LOGTRACEENABLED {
            $$$LOGTRACE("Processing property ["_processedProps_"/"_propCount_"]: "_prop.Name_" (Type: "_prop.Type_")")
        }

        Set propDef = ..GetPropertyDefinition(prop)
        Do classDef.Properties.Insert(propDef)
    }
    
    $$$LOGDEBUG("Completed generation for model "_model.Name_" with "_processedProps_" properties")
    Return classDef
}

ClassMethod GetPropertyDefinition(property As dc.openapi.common.ast.ModelProperty, isINJSONAdaptorClass As %Boolean = {$$$YES}) As %Dictionary.PropertyDefinition
{
    If $$$LOGTRACEENABLED {
        $$$LOGTRACE("Creating property definition for "_property.Name)
    }
    
    Set propDef = ##class(%Dictionary.PropertyDefinition).%New()
    Set propDef.Name = property.Name
    Set propDef.Type = property.Type
    Set propDef.Description = ##class(dc.openapi.common.Utils).FormatDescription(property.Description)
    Set:property.Collection'="" propDef.Collection = property.Collection

    Do:property.pMaxLength'="" propDef.Parameters.SetAt(property.pMaxLength,"MAXLEN")        
    Do:property.pMinLength'="" propDef.Parameters.SetAt(property.pMinLength,"MINLEN")        
    Do:property.pMinimum'="" propDef.Parameters.SetAt(property.pMinimum,"MINVAL")        
    Do:property.pMaximum'="" propDef.Parameters.SetAt(property.pMaximum,"MAXVAL")        
    Do:property.pDefault'="" propDef.Parameters.SetAt(property.pDefault,"INITIALEXPRESSION")        
    Do:property.pEnum'="" propDef.Parameters.SetAt(property.pEnum,"VALUELIST")
    Do:isINJSONAdaptorClass&&(property.pJSONFieldName'="") propDef.Parameters.SetAt(property.pJSONFieldName,"%JSONFIELDNAME")

    Return propDef
}

ClassMethod GetClassName(rootPackageName As %String, object As dc.openapi.common.ast.Model) As %String [ CodeMode = expression ]
{
rootPackageName _ $Select(..#SUBPKG'="":"."_..#SUBPKG,1:"") _ "." _ object.Name
}

}
