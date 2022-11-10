# Lambda-Players

A project to rewrite Zeta Players with the goal to be as clean and optimized as possible.

Currently the project will only be located here on Github and will be seen on the workshop when the addon is in a decent state


# Custom Content 

### Profile Pictures
Custom Profile Pictures can be added by putting .png and .jpg images in this folder, `DRIVE:\Program Files (x86)\Steam\steamapps\common\GarrysMod\garrysmod\materials\lambdaplayers\custom_profilepictures` or `DRIVE:\Program Files (x86)\Steam\steamapps\common\GarrysMod\sourceengine\materials\lambdaplayers\custom_profilepictures` Note that you can create sub folders in custom_profilepictures containing images to be able to organize your image files. Recent update changes directory so profile pictures can be added by addon and be sent to a server's clients

# Hooks

### `LambdaOnConvarsCreated`

Called when all default convars have been created. Use this hook if you want use the `CreateLambdaConvar()` function to create custom convars for Lambda Players externally


### `LambdaOnConCommandsCreated`

Called when all default console commands have been created. Use this hook if you want use the `CreateLambdaConsoleCommand()` function to create custom console commands for Lambda Players externally


### `LambdaOnUAloaded( UActionTable )`

Called when all default UActions (Universal Actions, functions that randomly get called. Example being weapon switching) have been made. Use this hook if you want add a function to the UActions. Use table.insert to add functions to the UActionTable.

### `LambdaOnToolsLoaded`

Called when all default tools are loaded. Use this hook if you want to add custom tools with `AddToolFunctionToLambdaTools()` See lambda/sh_b_toolguntools.lua for tool examples
