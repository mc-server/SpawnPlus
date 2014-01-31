-- Copyright (c) 2012-2014 Alexander Harkness

-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:

-- The above copyright notice and this permission notice shall be included
-- in all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
-- OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


-- Configuration

-- Show messages upon entering and exiting spawn by default?
SPAWNMESSAGE = false
-- Allow players to toggle entry and exit messages?
ALLOWMESSAGETOGGLE = true
-- Default radius to protect in. Set to -1 to disable.
PROTECTIONRADIUS = 10

-- Globals

PLUGIN = {}
LOGPREFIX = ""
WORLDSPAWNPROTECTION = {}

-- Plugin Start

function Initialize( Plugin )

	PLUGIN = Plugin

	Plugin:SetName( "SpawnProtect" )
	Plugin:SetVersion( 1 )

	LOGPREFIX = "[" .. Plugin:GetName() .. "] "

	-- Hooks
	cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_BREAKING_BLOCK, OnPlayerBreakingBlock)
	cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_MOVING, OnPlayerMoving)
	cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_PLACING_BLOCK, OnPlayerPlacingBlock)

	-- Commands
	if ALLOWMESSAGETOGGLE then
		cPluginManager.BindCommand("/togglespawnmessage", "spawnplus.togglemessage", ToggleMessages, " - Toggle the message upon entering and leaving spawn.")
	end
	
	-- Load the world spawn protection values fron the INI file.
	cRoot:Get():ForEachWorld(
		function (world)
			local WorldIni = cIniFile()
			WorldIni:ReadFile(world:GetIniFileName())
			WORLDSPAWNPROTECTION[world:GetName()] = WorldIni:GetValueSetI("SpawnProtect", "ProtectRadius", PROTECTIONRADIUS)
			WorldIni:WriteFile(world:GetIniFileName())
		end
	)

	LOG( LOGPREFIX .. "Plugin v" .. Plugin:GetVersion() .. " Enabled!" )
	return true
		
end

function OnDisable()
	LOG( LOGPREFIX .. "Plugin Disabled!" )
end

function ToggleMessages(Split, Player)

	-- Load message preferences from file.
	local PlayersIni = IniFile()
	PlayersIni:ReadFile(PLUGIN:GetLocalFolder() .. "/players.ini")
	local SendMessages = PlayersIni:GetValueSetB("EntryMessages", Player:GetName(), SPAWNMESSAGE)
	PlayersIni:WriteFile(PLUGIN:GetLocalFolder() .. "/players.ini")

	if SendMessages == "true" then
		PlayersIni:SetValueB("EntryMessages", Player:GetName(), false)
		SendMessageSuccess(Player, "Spawn entry messages disabled!")
	else
		PlayersIni:SetValueB("EntryMessages", Player:GetName(), true)	
		SendMessageSuccess(Player, "Spawn entry messages enabled!")
	end
	PlayersIni:WriteFile(PLUGIN:GetLocalFolder() .. "/players.ini")

	return true

end

function IsInSpawn(x, y, z, worldName)
	
	-- Get Spawn Coordinates for the World
	local world = cRoot:Get():GetWorld(worldName)
	local spawnx = world:GetSpawnX()
	local spawny = world:GetSpawnY()
	local spawnz = world:GetSpawnZ()
	
	-- Get protection radius for the world.
	local protectRadius = GetSpawnProtection(worldName)
	
	if protectRadius == -1 then
		-- There is no spawn for this world, so the player can't be in it.
		return false
	end

	-- Check if the specified coords are in the spawn.
	if not ((x <= (spawnx + protectRadius)) and (x >= (spawnx - protectRadius))) then
		return false -- Not in spawn area.
	end
	if not ((y <= (spawny + protectRadius)) and (y >= (spawny - protectRadius))) then 
		return false -- Not in spawn area.
	end
	if not ((z <= (spawnz + protectRadius)) and (z >= (spawnz - protectRadius))) then 
		return false -- Not in spawn area.
	end
		
	-- If they're not not in spawn, they must be in spawn!
	return true

end

function GetSpawnProtection(WorldName)
	return WORLDSPAWNPROTECTION[WorldName]
end
