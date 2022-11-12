# Lambda-Players

A project to rewrite Zeta Players with the goal to be as clean and optimized as possible.

Currently the project will only be located here on Github and will be seen on the workshop when the addon is in a decent state


# Custom Content 

## Profile Pictures
Custom Profile Pictures can be added by putting .png and .jpg images in this folder, `DRIVE:\Program Files (x86)\Steam\steamapps\common\GarrysMod\garrysmod\materials\lambdaplayers\custom_profilepictures` or `DRIVE:\Program Files (x86)\Steam\steamapps\common\GarrysMod\sourceengine\materials\lambdaplayers\custom_profilepictures` Note that you can create sub folders in custom_profilepictures containing images to be able to organize your image files.

Addons that add profile pictures should have this file path: `ADDONNAME/materials/lambdaplayers/custom_profilepictures/( Any .png/.jpg image files)`
### Remember to Update Lambda Data after any changes!

## Names

Custom names can be added in the in game Name Panel found in the Spawnmenu at Lambda Players>Panels. The panel allows you to export your names to share with others. The panel is also capable of importing nameexport.json files full of names or txt files full of names formatted like
- Garry
- Sora
- Breen

Files you want to import should go in, `C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\garrysmod\data\lambdaplayers\nameimport`


![alt text](https://cdn.discordapp.com/attachments/696733081763315803/1041036572562296954/image.png)

Addons that add custom names should have this file path: `ADDONNAME/materials/lambdaplayers/data/customnames/( Any exported nameexport.json or .txt files here)`

### Remember to Update Lambda Data after any changes!

## Custom Voice lines

Custom Voice lines can be used by simply defining a directory relative to `GarrysMod/sourceengine/sound` folder in Directories in Voice Options as shown below.

For example, if I wanted to use voicelines from `C:/Program Files (x86)/Steam/steamapps/common/GarrysMod/sourceengine/sound/somefolder/vo/(Imagine sounds files here)` as idle lines, I would input `somefolder/vo` in Idle Directory. Any folders after the directory you inputted will be included so try it out for organization of your sound files.

![alt text](https://cdn.discordapp.com/attachments/696733081763315803/1040465456131231754/image.png)

Addons that add voice lines should have this file path: `ADDONNAME/sound/lambdaplayers/vo/custom/(possible folders are, death, taunt, idle, kill)/( Any sound files here. Preferably MP3 for storage reasons)`

See Voice Profiles to see a explanation of each voice line type

## Voice Profiles
Similar to Voice Packs for Zeta Players, Voice Profiles is a pack of voice lines that a individual Lambda can use. Think of it as a way of making specific voices instead of a massive mix of random voicelines. Unlike Custom Voice Lines, Voice Profiles will not be added to the list of Voice Lines. 

Voice Profiles can be added by creating folders here `C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\sourceengine\sound\lambdaplayers\voiceprofiles\( Names of the Voice Profiles )`

Inside your Custom Voice Profile, you can add the following folders relating to a Voice Type

- idle | Voice lines that are used randomly
- death | Voice lines that are used when the Lambda Player is killed
- kill | Voice lines that are used when the Lambda Player kills someone
- taunt | Voice lines that are used when a Lambda Player is about to attack someone

Example of a Voice Profile:
![image](https://user-images.githubusercontent.com/109770359/201493628-63bc45f0-492a-442c-b9f1-8217d45885c4.png)


To use Voice Profiles in-game, either turn up the VP Use Chance or manually select a Voice Profile. 

![image](https://user-images.githubusercontent.com/109770359/201493491-ee075918-1639-4308-a742-ca11a90011b8.png)
![image](https://user-images.githubusercontent.com/109770359/201493494-82f78fee-f0c7-41df-a7a7-91b2642fbf3e.png)

Addons that add Voice Profiles follow the same general process but will have this file path: `ADDONNAME/sound/lambdaplayers/voiceprofiles/( Voice Profiles )`

### Remember to Update Lambda Data after any changes!

# Hooks

### `LambdaOnConvarsCreated`

Called when all default convars have been created. Use this hook if you want use the `CreateLambdaConvar()` function to create custom convars for Lambda Players externally. See lambdaplayers/autorun_includes/shared/convars.lua


### `LambdaOnConCommandsCreated`

Called when all default console commands have been created. Use this hook if you want use the `CreateLambdaConsoleCommand()` function to create custom console commands for Lambda Players externally See lambdaplayers/autorun_includes/shared/d_consolecommands.lua


### `LambdaOnUAloaded`

Called when all default UActions (Universal Actions, functions that randomly get called. Example being weapon switching) have been made. Use this hook if you want add a function to the UActions with `AddUActionToLambdaUA()` See lambdaplayers/lambda/sv_x_universalactions.lua

### `LambdaOnToolsLoaded`

Called when all default tools are loaded. Use this hook if you want to add custom tools with `AddToolFunctionToLambdaTools()` See lambdaplayers/autorun_includes/shared/lambda_toolguntools.lua

### `LambdaOnEntLimitsCreated`

Called when all default Entity Limits have been created. Use this hook if you want to make custom entity limits with `CreateLambdaEntLimit()` See lambdaplayers/autorun_includes/shared/lambda_entitylimits

### `LambdaOnBuildFunctionsLoaded`

Called when all default Building Functions have been loaded. Use this hook if you want to add custom building functions with `AddBuildFunctionToLambdaBuildingFunctions()` See lambdaplayers/autorun_includes/shared/lambda_x_buildingfunctions.lua
