local table_insert = table.insert

LambdaValidVoiceTypes = {}

-- This allows the creation of new voice types

-- voicetypename    | String |  The name of the voice type. Should be lowercare letters only
-- defaultpath  | String |  The default directory for this voice type
-- voicetypedescription     | String |  The description of when this voice type is typically used
function LambdaRegisterVoiceType( voicetypename, defaultpath, voicetypedescription )
    local convar = CreateLambdaConvar( "lambdaplayers_voice_" .. voicetypename .. "dir", defaultpath, true, false, false, "The directory to get " .. voicetypename .. " voice lines from. " .. voicetypedescription .. " Make sure you update Lambda Data after you change this!", nil, nil, { type = "Text", name = voicetypename .. " Directory", category = "Voice Options" } )
    table_insert( LambdaValidVoiceTypes, { voicetypename, "lambdaplayers_voice_" .. voicetypename .. "dir" } )
end

LambdaRegisterVoiceType( "idle", "randomengine", "These are voice lines that play randomly." )
LambdaRegisterVoiceType( "taunt", "lambdaplayers/vo/taunt", "These are voice lines that play when a Lambda Player is about to attack something." )
LambdaRegisterVoiceType( "death", "lambdaplayers/vo/death", "These are voice lines that play when a Lambda Player dies." )
LambdaRegisterVoiceType( "kill", "lambdaplayers/vo/kill", "These are voice lines that play when a Lambda Player kills their enemy." )
LambdaRegisterVoiceType( "laugh", "lambdaplayers/vo/laugh", "These are voice lines that play when a Lambda Player laughs at someone." )

-- Called when all default voice types have been registered and before the file system has loaded the voice types

-- This hook allows the usage of LambdaRegisterVoiceType() 
if !LambdaFilesReloaded then -- This is so when the game is loading, the hook is created and if we are already in-game and reload the lua files, the hook will be forced to run
    hook.Add( "PreGamemodeLoaded", "lambdavoicetypesinit", function()
        hook.Run( "LambdaOnVoiceTypesRegistered" )
        LambdaVoiceLinesTable = LAMBDAFS:GetVoiceLinesTable()
    end )
else
    hook.Run( "LambdaOnVoiceTypesRegistered" )
    LambdaVoiceLinesTable = LAMBDAFS:GetVoiceLinesTable()
end
