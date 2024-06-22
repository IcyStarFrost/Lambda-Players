_LambdaAddonVersion = "V1.0.7"
_LambdaAddonNotes = [[

Color( 179, 107, 0)
-- Changed external personality chances for Builder preset to be limited to 0-10 instead of 0-100. This helps make the builders focus on building

-- Validity checks

-- Fixed the Toolgun not actually firing

-- Added an option to see a lambda's profile picture along with their name display. Option located at Lambda Players > Misc > Display Profile Picture on Hover

-- Redesigned Text Line Panel

-- Markov chain generator no longer is biased toward links

-- Bypass getting server data in panels if the local player is the local host of the server

-- Fixed major performance problems when looking at the default scoreboard

-- Added Experimental Asset Downloading to network voice lines, PFPs, and sprays to players. Option located at Lambda Players > Utilities > Allow Sharing Files
/e
Color( 179, 107, 0)
-- Considerable performance improvement by the removal of several constantly networked variables

-- Fixed a issue where profile chance at 100% would have a 1% chance to fail

-- Fixed errors relating to Ultrakill Base

-- Fixed Lambdas not pathfinding up stairs

-- Fixed an issue where presets would no longer show up when joining a new session after creating one.

-- Updated the default size of the Profile Panel

/e
Color( 0, 140, 255)
---- (Pyri) Pull Request #125 ----

-- Added Profiles don't repeat. Lambda Players > Lambda Server Settings > Profiles Don't Repeat

-- Added Melee only. Lambda Players > Weapons > Melee Only

-- Added the ability insert commas between model paths in Force Playermodel to randomly choose between set model paths

-- For weapon fire data, on LambdaRNG(), the third parameter is set to false, this will would allow integer values for random fire rate chances instead of float values. This will make fire rate on weapons more "realistic", rather than robotic fire rates.

-- Default LambdaPlayer weapons now have a min and max fire rate.

-- Changed the Golf Club a bit.

-- Added Bully (PS2) SFX's to the fists.
/e
Color( 0, 97, 177)
Command Changes:

    The ConVar lambdaplayers_cmd_cacheplayermodels has been renamed to lambdaplayers_cmd_cacheassets. It will now precache player models and lambda weapon models, for now.

Some changes to lambdaplayers_cmd_forcespawnlambda:

    Added Height Spawn Level (Lambdas will only spawn on the same height as the player that triggered it)
    Lambdaplayers will attempt to spawn somewhere that won't get them stuck (They won't spawn on walls, or smaller navmeshes that could get them stuck)
        will apply this to MWS later.

]]

-- Color Note: "Color( r, g, b )" functions can be added within the change notes. ONLY one Color() function can exists within a /e block.
-- Note: Remember to add /e to seperate the change notes to seperate Dlabels in the spawn menu. Apparently one Dlabel has a character limit until the text is cut off.