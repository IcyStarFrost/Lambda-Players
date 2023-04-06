local table_insert = table.insert

LambdaValidVoiceTypes = {}

-- This allows the creation of new voice types

-- voicetypename    | String |  The name of the voice type. Should be lowercare letters only
-- defaultpath  | String |  The default directory for this voice type
-- voicetypedescription     | String |  The description of when this voice type is typically used
function LambdaRegisterVoiceType( voicetypename, defaultpath, voicetypedescription )
    CreateLambdaConvar( "lambdaplayers_voice_" .. voicetypename .. "dir", defaultpath, true, false, false, "The directory to get " .. voicetypename .. " voice lines from. " .. voicetypedescription .. " Make sure you update Lambda Data after you change this!", nil, nil, { type = "Text", name = voicetypename .. " Directory", category = "Voice Options" } )
    table_insert( LambdaValidVoiceTypes, { voicetypename, "lambdaplayers_voice_" .. voicetypename .. "dir" } )
end

LambdaRegisterVoiceType( "idle", "lambdaplayers/vo/idle", "These are voice lines that play randomly. Input randomengine to randomly use sounds loaded in game. randomengine can work on any voice type" )
LambdaRegisterVoiceType( "taunt", "lambdaplayers/vo/taunt", "These are voice lines that play when a Lambda Player is about to attack something." )
LambdaRegisterVoiceType( "death", "lambdaplayers/vo/death", "These are voice lines that play when a Lambda Player dies." )
LambdaRegisterVoiceType( "kill", "lambdaplayers/vo/kill", "These are voice lines that play when a Lambda Player kills their enemy." )
LambdaRegisterVoiceType( "laugh", "lambdaplayers/vo/laugh", "These are voice lines that play when a Lambda Player laughs at someone." )
LambdaRegisterVoiceType( "fall", "lambdaplayers/vo/fall", "These are voice lines that play when a Lambda Player starts falling from deadly distance." )
LambdaRegisterVoiceType( "assist", "lambdaplayers/vo/assist", "These are voice lines that play when someone else kills Lambda Player's current enemy." )
LambdaRegisterVoiceType( "witness", "lambdaplayers/vo/witness", "These are voice lines that play when a Lambda Player sees someone get killed." )
LambdaRegisterVoiceType( "panic", "lambdaplayers/vo/panic", "These are voice lines that play when a Lambda Player is low on health and starts retreating." )