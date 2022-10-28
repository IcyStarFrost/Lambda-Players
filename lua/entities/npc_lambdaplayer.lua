AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.Spawnable = true
ENT.PrintName = "Lambda Player"
ENT.Author = "StarFrost"

--- Include files based on sv_ sh_ or cl_
local ENTFiles = file.Find( "lambdaplayers/lambda/*", "LUA", "nameasc" )

for k, luafile in ipairs( ENTFiles ) do

    if string.StartWith( luafile, "sv_" ) then -- Server Side Files
        include( "lambdaplayers/lambda/" .. luafile )
        print( "Lambda Players: Included Server Side ENT Lua File [" .. luafile .. "]" )
    elseif string.StartWith( luafile, "sh_" ) then -- Shared Files
        if SERVER then
            AddCSLuaFile( "lambdaplayers/lambda/" .. luafile )
        end
        include( "lambdaplayers/lambda/" .. luafile )
        print( "Lambda Players: Included Shared ENT Lua File [" .. luafile .. "]" )
    elseif string.StartWith( luafile, "cl_" ) then -- Client Side Files
        if SERVER then
            AddCSLuaFile( "lambdaplayers/lambda/" .. luafile )
        else
            include( "lambdaplayers/lambda/" .. luafile )
            print( "Lambda Players: Included Client Side ENT Lua File [" .. luafile .. "]" )
        end
    end
end
---

-- Localization

    local random = math.random

--

if CLIENT then

    language.Add( "npc_lambdaplayer", "Lambda Player" )

end


function ENT:Initialize()

    if SERVER then

        self:SetModel( _LAMBDAPLAYERSDEFAULTMDLS[ random( #_LAMBDAPLAYERSDEFAULTMDLS ) ] )

    elseif CLIENT then



    end

end


function ENT:SetupDataTables()



end


function ENT:Think()

end

function ENT:BodyUpdate()
    if self.IsMoving then
        self:BodyMoveXY()
        return
    end
    
    self:FrameAdvance()
end


function ENT:RunBehaviour()

end




list.Set( "NPC", "npc_lambdaplayer", {
	Name = "Lambda Player",
	Class = "npc_lambdaplayer",
	Category = "Lambda Players"
})