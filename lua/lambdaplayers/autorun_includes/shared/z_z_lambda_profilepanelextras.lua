local table_insert = table.insert
LambdaPlayersProfileExternalpanels = {}


--[[ 
    You can add onto the profile panel to set specific variables to be saved/edited on the profiles

panelclass  | String |  The classname of the panel you want added to the profile panel. Current Value supported panels are below

DTextEntry
DCheckBox
DNumSlider
DColorMixer
DComboBox

variablename  | String |  The variable name that will be applied to the Lambda. For example, inputting "testvar" will add a variable on the Lambda with the name testvar which can accessed by .testvar on the Lambda Entity
category  | String |  The panel category to put your setting in. You can place settings in the same category and they will be added onto each other
callback( createdpanel, parentpanel )  | Function |  The function that will be called when the panel is created
 ]]
function LambdaCreateProfileSetting( panelclass, variablename, category, callback )
    table_insert( LambdaPlayersProfileExternalpanels, { panelclass, variablename, category, callback } )
end
