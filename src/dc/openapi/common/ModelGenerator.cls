Class dc.openapi.common.ModelGenerator Extends %RegisteredObject
{

Property AST As dc.openapi.common.ast.OAS;

Property AddSuperClass As %String;

Method Generate() As %Status
{
    Set tSc = $$$OK
    // Iterate over the models in the AST and generate code for each one
    #dim model As dc.openapi.common.ast.Model
    #dim models As %ListOfObjects

    Set models = ..AST.Models

    Set key = ""
    For  {
        Set model = models.GetNext(.key)
        Quit:key=""
        Set tSc = $$$ADDSC(tSc,..GenerateModel(model))
    }

    Return tSc
}

Method GenerateModel(model As dc.openapi.common.ast.Model) As %Status
{
    #define classDef As %Dictionary.ClassDefinition

    Set classDef = ##class(%Dictionary.ClassDefinition).%New()
    Set classDef.Name = model.Name
    Set classDef.Super = model.Super _ $Select(..AddSuperClass'="" : "," _ ..AddSuperClass, 1: "")
    Set classDef.Description = $REPLACE($ZSTRIP($ZSTRIP(model.Description, "*", $Char(13)), "<>CW"), $Char(10), $Char(10) _ "/// ")
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
    Set key = ""
    For  {
        Set prop = props.GetNext(.key)
        Quit:key=""

        Set propDef = ..GetPropertyDefinition(prop)
        Do classDef.Properties.Insert(propDef)
    }

    Return classDef.%Save()
}

ClassMethod GetPropertyDefinition(property As dc.openapi.common.ast.ModelProperty) As %Dictionary.PropertyDefinition
{
    Set propDef = ##class(%Dictionary.PropertyDefinition).%New()
    Set propDef.Name = property.Name
    Set propDef.Type = property.Type
    Set propDef.Description = $REPLACE($ZSTRIP($ZSTRIP(property.Description, "*", $Char(13)), "<>CW"), $Char(10), $Char(10) _ "/// ")
    Set:property.Collection'="" propDef.Collection = property.Collection

    Do:property.pMaxLength'="" propDef.Parameters.SetAt(property.pMaxLength,"MAXLEN")        
    Do:property.pMinLength'="" propDef.Parameters.SetAt(property.pMinLength,"MINLEN")        
    Do:property.pMinimum'="" propDef.Parameters.SetAt(property.pMinimum,"MINVAL")        
    Do:property.pMaximum'="" propDef.Parameters.SetAt(property.pMaximum,"MAXVAL")        
    Do:property.pDefault'="" propDef.Parameters.SetAt(property.pDefault,"INITIALEXPRESSION")        
    Do:property.pEnum'="" propDef.Parameters.SetAt(property.pEnum,"VALUELIST")        

    Return propDef
}

}
