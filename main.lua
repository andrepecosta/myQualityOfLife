-- myQualityOfLife generation router.
-- Keep both implementations isolated: Gold never loads Gen 1 internals and
-- the stable Gen 1 path never loads experimental Gold code.
local mod = ...
local GameVersion = require("src.core.GameVersion")
local file = GameVersion.generation() == 2 and "gen2.lua" or "gen1.lua"
local source = assert(mod:read(file), file .. " is missing")
local chunk = assert(load(source, "@" .. mod.path .. "/" .. file))
return chunk()
