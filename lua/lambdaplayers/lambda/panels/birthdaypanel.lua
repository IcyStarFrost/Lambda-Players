local round = math.Round
local months = {
    [ "January" ] = "January",
    [ "February"] =  "February",
    [ "March" ] = "March",
    [ "April" ] = "April",
    [ "May" ] = "May",
    [ "June" ] = "June",
    [ "July" ] = "July",
    [ "August" ] = "August",
    [ "September" ] = "September",
    [ "October" ] = "October",
    [ "November" ] = "November",
    [ "December" ] = "December"
}

local function OpenBirthdaypanel( ply )

    local frame = LAMBDAPANELS:CreateFrame( "Birthday Editor", 300, 100 )

    LAMBDAPANELS:CreateLabel( "Changes are saved when you close the panel", frame, TOP )

    local box = LAMBDAPANELS:CreateComboBox( frame, LEFT, months )
    box:SetSize( 100, 5 )
    box:Dock( LEFT )
    box:SetValue( "Select a Month" )

    local day = LAMBDAPANELS:CreateNumSlider( frame, LEFT, 0, "Week day", 1, 31, 0 )
    day:SetSize( 200, 5 )
    day:Dock( LEFT )

    local birthdaydata = LAMBDAFS:ReadFile( "lambdaplayers/playerbirthday.json", "json" )

    if birthdaydata then
        box:SelectOptionByKey( birthdaydata.month )
        day:SetValue( birthdaydata.day )
    end

    function frame:OnClose() 
        local _, month = box:GetSelected()
        if !month or month == "" then return end
        LAMBDAFS:UpdateKeyValueFile(  "lambdaplayers/playerbirthday.json", { month = month, day = round( day:GetValue(), 0 ) }, "json" ) 

        net.Start( "lambdaplayers_onclosebirthdaypanel" )
        net.WriteString( month )
        net.WriteUInt( round( day:GetValue(), 0 ), 5 ) 
        net.SendToServer()
    end
end
RegisterLambdaPanel( "Birthday", "Opens a panel that allows you to set your birthday so the Lambdas know when to mention your birthday", OpenBirthdaypanel )