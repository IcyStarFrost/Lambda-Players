_LambdaAddonVersion = "V1.0"
_LambdaAddonNotes = [[


-- Changed external personality chances for Builder preset to be limited to 0-10 instead of 0-100. This helps make the builders focus on building

-- Validity checks

-- Fixed the Toolgun not actually firing

-- Added an option to see a lambda's profile picture along with their name display. Option located at Lambda Players > Misc > Display Profile Picture on Hover
/e
---- (Pyri) Pull Request #125 ----

-- Added Profiles don't repeat. Lambda Players > Lambda Server Settings > Profiles Don't Repeat

-- Added Melee only. Lambda Players > Weapons > Melee Only

-- Added the ability insert commas between model paths in Force Playermodel to randomly choose between set model paths

-- For weapon fire data, on LambdaRNG(), the third parameter is set to false, this will would allow integer values for random fire rate chances instead of float values. This will make fire rate on weapons more "realistic", rather than robotic fire rates.

-- Default LambdaPlayer weapons now have a min and max fire rate.

-- Changed the Golf Club a bit.

-- Added Bully (PS2) SFX's to the fists.
/e
Command Changes:

    The ConVar lambdaplayers_cmd_cacheplayermodels has been renamed to lambdaplayers_cmd_cacheassets. It will now precache player models and lambda weapon models, for now.

Some changes to lambdaplayers_cmd_forcespawnlambda:

    Added Height Spawn Level (Lambdas will only spawn on the same height as the player that triggered it)
    Lambdaplayers will attempt to spawn somewhere that won't get them stuck (They won't spawn on walls, or smaller navmeshes that could get them stuck)
        will apply this to MWS later.

]]

-- Note: Remember to add /e to seperate the change notes to seperate Dlabels in the spawn menu. Apparently one Dlabel has a character limit until the text is cut off.