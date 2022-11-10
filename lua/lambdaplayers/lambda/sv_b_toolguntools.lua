local IsValid = IsValid
local table_insert = table.insert
local table_Merge = table.Merge

-- Toolgun tools are made in autorun_includes/shared/lambda_toolguntools.lua
-- It has to be this way because the spawnmenu is made before entities

ENT.l_ToolgunTools = {}

table_Merge( ENT.l_ToolgunTools, LambdaToolGunTools )