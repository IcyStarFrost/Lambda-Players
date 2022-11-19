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

Addons that add voice lines should have this file path: `ADDONNAME/sound/lambdaplayers/vo/custom/(possible folders are, death, taunt, idle, kill, laugh)/( Any sound files here. Preferably MP3 for storage reasons)`

See Voice Profiles to see a explanation of each voice line type

## Voice Profiles
Similar to Voice Packs for Zeta Players, Voice Profiles is a pack of voice lines that a individual Lambda can use. Think of it as a way of making specific voices instead of a massive mix of random voicelines. Unlike Custom Voice Lines, Voice Profiles will not be added to the list of Voice Lines. 

Voice Profiles can be added by creating folders here `C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\sourceengine\sound\lambdaplayers\voiceprofiles\( Names of the Voice Profiles )`

Inside your Custom Voice Profile, you can add the following folders relating to a Voice Type

- idle | Voice lines that are used randomly
- death | Voice lines that are used when the Lambda Player is killed
- kill | Voice lines that are used when the Lambda Player kills someone
- taunt | Voice lines that are used when a Lambda Player is about to attack someone
- laugh | Voice lines that are used when a Lambda Player laughs at someone

Example of a Voice Profile:
![image](https://user-images.githubusercontent.com/109770359/201493628-63bc45f0-492a-442c-b9f1-8217d45885c4.png)


To use Voice Profiles in-game, either turn up the VP Use Chance or manually select a Voice Profile. 

![image](https://user-images.githubusercontent.com/109770359/201493491-ee075918-1639-4308-a742-ca11a90011b8.png)
![image](https://user-images.githubusercontent.com/109770359/201493494-82f78fee-f0c7-41df-a7a7-91b2642fbf3e.png)

Addons that add Voice Profiles follow the same general process but will have this file path: `ADDONNAME/sound/lambdaplayers/voiceprofiles/( Voice Profiles )`


## Lambda Profiles

Specific Lambda Players can be made through the Profile Panel. For example, you create a Profile that will use the name Breen and have that Profile use the Breen model, have a certain personality, a certain voice, ect.

To start making a profile, go to Panels and press `Open Profile Panel`

![image](https://user-images.githubusercontent.com/109770359/202868464-4a377da5-4bb5-47bb-86af-7619112439a3.png)

You should see something like this 

![image](https://user-images.githubusercontent.com/109770359/202868604-e7baa9eb-cd86-416c-be1b-3919396a430e.png)


Let's start with navigating the panel before doing any profile creations. First, Put your cursor to the bottom right corner of the panel and resize if you want. Second, the panel will have arrows on each bottom corner which will scroll left or right.

![image](https://user-images.githubusercontent.com/109770359/202868705-c356e4c7-75ba-49c7-a8c7-cb96dee6c1f8.png)

Third, each pillar of settings will have a scroll bar as well that will scroll vertically. That's pretty much it for navigating this panel. Let's begin to create a Profile. For this guide I will make a Profile named Eve.


![image](https://user-images.githubusercontent.com/109770359/202868793-48971a92-51c3-4220-8af2-378d8877b12e.png)

Normally this is the name that a Lambda Player has to spawn with in order to use this profile but `Profile Use Chance` in `Lambda Server Settings` can force a Profile Lambda to spawn.

![image](https://user-images.githubusercontent.com/109770359/202868873-62d231b5-e855-4124-9ad0-1ea82198e39e.png)

For Eve, I think I will use the Female Metro Cop model by simply scrolling through the list of playermodels

![image](https://user-images.githubusercontent.com/109770359/202868941-e0cff2a1-bc1c-47f2-bce0-3d65f5ae6259.png)

Next I need to give "her" a profile picture. If you don't know how to add Profile Pictures, please scroll up to the Profile Picture section. I'm gonna look through the Profile Pictures and find one that I want to use 

![image](https://user-images.githubusercontent.com/109770359/202869021-11d43e65-506d-440b-8d73-be49b0a72e00.png)

![image](https://user-images.githubusercontent.com/109770359/202869045-8e5d2f63-94bd-47ad-859b-66abf7f0fc4b.png)

In my case, I already have a Profile Picture ready for use. Since Profile Pictures are relative to the `lambdaplayers/custom_profilepictures` folder, I can input this file path.

![image](https://user-images.githubusercontent.com/109770359/202869108-e8fb73cd-004c-444c-a671-7629fdacd5b1.png)

Notice that there is now a image under the text box. This means we inputted the path correctly

The rest in this pillar of settings is pretty much self explanatory

![image](https://user-images.githubusercontent.com/109770359/202869153-bbcb6614-3281-4758-9f90-d291be06c18d.png)

Next, let's tweak the personality settings. These are the default personality sliders

![image](https://user-images.githubusercontent.com/109770359/202869184-f32728f8-8101-47f0-8c15-257024a80efc.png)

Eve to me isn't the type that would really fight people so I'll make her favor building and stuff over combat

![image](https://user-images.githubusercontent.com/109770359/202869226-8c36765f-63d8-4149-b1cf-ed8c335e258d.png)

After that, let's move onto the colors. I want the colors to sorta match the colors in the Profile Picture so I'll choose them according to that

![image](https://user-images.githubusercontent.com/109770359/202869284-ac16e65d-764c-42a9-9c8b-f34977cd6ddc.png)

Notice the Playermodel Preview changes as you change the playermodel color

![image](https://user-images.githubusercontent.com/109770359/202869323-865b0f9e-aa1a-4388-95f9-842e155c7298.png)

And that's it! That's all you really have to do to make a profile. Now what's left is to save it. To the right of the panel, you will see a List Panel and 3 buttons.

The list will show all your saved profiles which you can load by double clicking them or remove them by right clicking them. The panel will ask you if you are sure you want to delete whatever profile as added security.
At the top of the list is a search bar where you can search for specific profiles.

![image](https://user-images.githubusercontent.com/109770359/202869374-92abdf57-70e7-42ec-bb00-34ec59037dde.png)

Anyway, there are two buttons we want to look at. `Save Profile` and `Save To Server`. What's the difference? For singleplayer, both buttons will save your profile to your computer, however, in multiplayer, the `Save To Server` will save the Profile to the Server's files only if you are the host or are a Super Admin. This would be your files if you are the host of the multiplayer server. `Save Profile` will always save the profile to your own Profiles. 

For the last button, `Request Server Profiles` will send a request to the Server to send its Profiles to you so you can edit it. This will only work for Super Admins that are not the host because the host already *has* the Server's Profiles

I will now press `Save Profile` and there it is! It is now saved

![image](https://user-images.githubusercontent.com/109770359/202869845-f0691422-129c-4a86-b15d-c05bf6ea043a.png)

###Now this is important! You must Update Lambda Data for any changes to take effect!

![image](https://user-images.githubusercontent.com/109770359/202869883-cb336e9e-64e5-4c0b-8fbb-238adb896af0.png)

My Profile Chance is to 100% so this means profiles will always spawn as long as they don't already exist. Here we can see Eve in game now. That's all you have to do. Happy Profile Making!

![image](https://user-images.githubusercontent.com/109770359/202869913-39279f39-fd5a-4e38-a1b5-b172ae1b88b5.png)


### Remember to Update Lambda Data after any changes!

# Hooks

### `LambdaOnConvarsCreated`
### Must be Shared!

Called when all default convars have been created. Use this hook if you want use the `CreateLambdaConvar()` function to create custom convars for Lambda Players externally. See lambdaplayers/autorun_includes/shared/convars.lua


### `LambdaOnConCommandsCreated`
### Must be Shared!

Called when all default console commands have been created. Use this hook if you want use the `CreateLambdaConsoleCommand()` function to create custom console commands for Lambda Players externally See lambdaplayers/autorun_includes/shared/d_consolecommands.lua



### `LambdaOnProfilePanelLoaded`
### Client-Side/Shared

Called when the Profile Panel has been loaded. Use this hook if you want to add more settings to the Profile Panel using `LambdaCreateProfileSetting()` See lambdaplayers/autorun_includes/shared/z_z_lambda_profilepanelextras.lua



### `LambdaCanTarget( Entity Lambda, Entity Target )`
### Server-Side

Called when a Lambda Player wants to know if they can attack someone. Return true to make them not attack the target


# Lambda Player Addon Hooks

*The hooks below can be used to add onto certain features of the lambdas*



### `LambdaOnUAloaded`
### Server-Side

*Universal Actions or UActions are functions that randomly get called during a Lambda's life. Example of a UAction being weapon switching.*

Called when all default UActions have been made. Use this hook if you want add a function to the UActions with `AddUActionToLambdaUA()` See lambdaplayers/lambda/sv_x_universalactions.lua



### `LambdaOnToolsLoaded`
### Must be Shared!

Called when all default tools are loaded. Use this hook if you want to add custom tools with `AddToolFunctionToLambdaTools()` See lambdaplayers/autorun_includes/shared/lambda_toolguntools.lua



### `LambdaOnEntLimitsCreated`
### Must be Shared!

*Entity limits can help limit a certain type of entity or range of entities. This should be used in conjunction with Tool gun tools that spawn entities or Build functions that spawn untracked entities*

Called when all default Entity Limits have been created. Use this hook if you want to make custom entity limits with `CreateLambdaEntLimit()` See lambdaplayers/autorun_includes/shared/lambda_entitylimits AND lambdaplayers/lambda/sv_entitylimits.lua



### `LambdaOnBuildFunctionsLoaded`
### Must be Shared!

*Build functions are functions that are called when a lambda player wants to build/spawn something. For example, prop spawning is used by this*

Called when all default Building Functions have been loaded. Use this hook if you want to add custom building functions with `AddBuildFunctionToLambdaBuildingFunctions()` See lambdaplayers/autorun_includes/shared/lambda_x_buildingfunctions.lua




### `LambdaOnPersonalitiesLoaded`
### Must be Shared!

*"Personalities" are functions that have chances ordered from highest to lowest applied to them. When a Lambda Player is in the idle state, each chance will be tested and if it succeeds, the function will run. Personalities are responsible for the decisions on building stuff or fighting*

Called when all default Personality types have been loaded. Use this hook if you want to create custom personality types with LambdaCreatePersonalityType() See lambdaplayers/autorun_includes/shared/lambda_personalityfuncs.lua




### `LambdaOnKilled( Entity lambda, CTakeDamageInfo info  )`
### Server-Side

Called when a Lambda Player is killed. This hook can be used to add onto the ENT:OnKilled() hook each Lambda Player has



### `LambdaOnInjured( Entity lambda, CTakeDamageInfo info )`
### Server-Side

Called when a Lambda Player takes damage. This hook can be used to add onto the ENT:OnInjured() hook each Lambda Player has



### `LambdaOnOtherKilled( Entity lambda, Entity victim, CTakeDamageInfo info )`
### Server-Side

Called when a someone that is not the Lambda Player dies. This hook can be used to add onto the ENT:OnOtherKilled() hook each Lambda Player has



### `LambdaOnThink( Entity lambda, Entity lambdaWeaponEntity )`
### Server and Client

Called when a Lambda's ENT:Think() hook runs. This hook can be used to add onto the ENT:Think() hook each Lambda Player has



### `LambdaOnInitialize( Entity lambda, Entity lambdaWeaponEntity )`
### Server and Client

Called when a Lambda Player initializes. This hook can be used to add onto the ENT:Initialize() hook each Lambda Player has



### `LambdaOnStuck( Entity lambda, Number stucktimes )`
### Server-Side

*stucktimes is a variable that holds how many times the Lambda Player got stuck within the last 10 seconds + now*

Called when a Lambda Player gets stuck. This hook can be used to make a custom unstuck function. Return "stop" to make the Lambda Player give up in their path or return "continue" to make the Lambda Player continue down their path
