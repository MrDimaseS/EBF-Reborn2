	--[[
Holdout Example

	Underscore prefix such as "_function()" denotes a local function and is used to improve readability

	Variable Prefix Examples
		"fl"	Float
		"n"		Int
		"v"		Table
		"b"		Boolean
]]


DAMAGE_TYPES = {
	    [0] = "DAMAGE_TYPE_NONE",
	    [1] = "DAMAGE_TYPE_PHYSICAL",
	    [2] = "DAMAGE_TYPE_MAGICAL",
	    [4] = "DAMAGE_TYPE_PURE",
	    [7] = "DAMAGE_TYPE_ALL",
	    [8] = "DAMAGE_TYPE_HP_REMOVAL",
}

require("lua_item/simple_item")
require("lua_boss/boss_32_meteor")
require( "epic_boss_fight_game_round" )
require( "epic_boss_fight_game_spawner" )
require('lib.optionsmodule')
require( "libraries/Timers" )
require( "libraries/vector_targeting" )
require("libraries/disable_help")

require( "panoramaBridge")
require( "bossManager")

require("libraries/utility")
require( "ai/ai_core" )




if CHoldoutGameMode == nil then
	CHoldoutGameMode = class({})
end

-- Precache resources
function Precache( context )

    --Precache particle
	--PrecacheResource( "particle", "particles/generic_gameplay/winter_effects_hero.vpcf", context )
	PrecacheResource( "particle", "particles/items2_fx/veil_of_discord.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_ursa/ursa_claw_left.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_ursa/ursa_claw_right.vpcf", context )
	
	PrecacheResource( "particle", "particles/ui_mouseactions/range_finder_cone.vpcf", context )
		

	PrecacheResource( "particle", "particles/units/heroes/hero_treant/treant_foot_step.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_skeletonking/skeleton_king_weapon_blur.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_skeletonking/skeleton_king_weapon_blur_reverse.vpcf", context )


	PrecacheResource( "particle_folder", "particles/frostivus_gameplay", context )

	
	--Precache sounds
	PrecacheResource( "soundfile", "soundevents/game_sounds_items.vsndevts", context)
	PrecacheResource( "soundfile", "soundevents/game_sounds_custom.vsndevts", context)

	PrecacheItemByNameSync( "item_tombstone", context )
	PrecacheItemByNameSync( "item_bag_of_gold", context )
	
	--Precache models
	PrecacheResource( "model", "models/heroes/nerubian_assassin/nerubian_assassin.vmdl", context )
	PrecacheResource( "model", "models/heroes/drow/drow_base.vmdl", context )
	PrecacheResource( "model", "models/heroes/tiny/tiny_01/tiny_01.vmdl", context )
	PrecacheResource( "model", "models/heroes/tiny/tiny_02/tiny_02.vmdl", context )
	PrecacheResource( "model", "models/heroes/tiny/tiny_03/tiny_03.vmdl", context )
	PrecacheResource( "model", "models/heroes/tiny/tiny_04/tiny_04.vmdl", context )

	--Precache bosses
	PrecacheUnitByNameSync("npc_dota_boss32_vh", context)
	PrecacheUnitByNameSync("npc_dota_boss32_h", context)
	PrecacheUnitByNameSync("npc_dota_boss32", context)
	PrecacheUnitByNameSync("npc_dota_boss31_vh", context)
	PrecacheUnitByNameSync("npc_dota_boss31_h", context)
	PrecacheUnitByNameSync("npc_dota_boss31", context)
	PrecacheUnitByNameSync("npc_dota_boss30_vh", context)
	PrecacheUnitByNameSync("npc_dota_boss30_h", context)
	PrecacheUnitByNameSync("npc_dota_boss30", context)
	PrecacheUnitByNameSync("npc_dota_boss_naga_illusionist", context)
	PrecacheUnitByNameSync("npc_dota_boss_troll_warlord", context)
	PrecacheUnitByNameSync("npc_dota_boss_clockwerk_mecha", context)
	
	PrecacheUnitByNameSync("npc_dota_boss_zombie_minion", context)
	PrecacheUnitByNameSync("npc_dota_boss_treant", context)
	PrecacheUnitByNameSync("npc_dota_boss_greater_treant", context)
	PrecacheUnitByNameSync("npc_dota_troll_warlord_axe", context)
	
    PrecacheUnitByNameSync("npc_dota_boss32_trueform", context)
    PrecacheUnitByNameSync("npc_dota_boss32_trueform_h", context)
    PrecacheUnitByNameSync("npc_dota_boss32_trueform_vh", context)
	
	
	PrecacheUnitByNameSync("npc_dota_boss_ogre_magi", context)
	PrecacheUnitByNameSync("npc_dota_visage_familiar1", context)
end

-- Actually make the game mode when we activate
function Activate()
	GameRules.holdOut = CHoldoutGameMode()
	GameRules.holdOut:InitGameMode()

end

function CHoldoutGameMode:InitGameMode()
	print ("Epic Boss Fight Reborn version 0.1")
	print ("Made By DimaseS")
	GameRules._finish = false
	GameRules.vote_Yes = 0
	GameRules.vote_No = 0
	GameRules.voteRound_Yes = 0;
	GameRules.voteRound_No = 0;
	self._nRoundNumber = 1
	GameRules._roundnumber = 1
	self._NewGamePlus = false
	self.Last_Target_HB = nil
	self.Shield = false
	self.Last_HP_Display = -1
	self._currentRound = nil

	self._roundsRegened = {}
	self._regenNG = false
	self._check_check_dead = false
	self._flLastThinkGameTime = nil
	self._check_dead = false
	self._timetocheck = 0
	self._freshstart = true
	self.boss_master_id = -1
	Life = class({})


	-- if GetMapName() == "epic_boss_fight_boss_master" then Life._life = 9
		-- GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 1 )
		-- GameRules:SetHeroSelectionTime( 45.0 )
		-- Life._MaxLife = 9
	-- else
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 0 )
	-- end
	
	GameRules:SetPreGameTime( 30 )
	GameRules:SetShowcaseTime( 0 )
	GameRules:SetStrategyTime( 5 )
	GameRules:SetPostGameTime( 15 )
	GameRules:SetCustomGameEndDelay( 15.0 )
	GameRules:SetHeroSelectionTime( 60.0 )
	GameRules:SetHeroSelectPenaltyTime( 5.0 )
	GameRules:SetCustomGameSetupAutoLaunchDelay( 0 )
	
	if IsInToolsMode() or GameRules:IsCheatMode() then
		GameRules:SetPreGameTime( 99999 )
		GameRules:SetHeroSelectionTime( 99999 )
	end
	
	-- defining lifes
	if GetMapName() == "epic_boss_fight_normal" then
		Life._life = 4
		Life._MaxLife = 4
		GameRules._bonusLifeRoundDivider = 5
		GameRules.gameDifficulty = 1
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 5)
	elseif GetMapName() == "epic_boss_fight_hard" then 
		Life._life = 2
		Life._MaxLife = 2
		GameRules._bonusLifeRoundDivider = 10
		GameRules.gameDifficulty = 2
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 7)
	elseif GetMapName() == "epic_boss_fight_impossible" then
		Life._life = 2
		Life._MaxLife = 2
		GameRules._bonusLifeRoundDivider = 15
		GameRules.gameDifficulty = 3
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 7)
	elseif GetMapName() == "epic_boss_fight_challenger" then
		Life._life = 1
		Life._MaxLife = 1
		GameRules._bonusLifeRoundDivider = 99
		GameRules.gameDifficulty = 3
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 7)
	elseif GetMapName() == "epic_boss_fight_nightmare" then
		Life._life = 1
		Life._MaxLife = 1
		GameRules._bonusLifeRoundDivider = 99
		GameRules.gameDifficulty = 3
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 10)
	end

	GameRules._live = Life._life
	GameRules._used_live = 0

	self:_ReadGameConfiguration()
	GameRules:SetHeroRespawnEnabled( false )
	GameRules:SetUseUniversalShopMode( true )
	GameRules:SetTreeRegrowTime( 15.0 )
	GameRules:SetCreepMinimapIconScale( 4 )
	GameRules:SetRuneMinimapIconScale( 1.5 )
	GameRules:SetGoldTickTime( 0.6 )
    GameRules:SetGoldPerTick( 1 )
	GameRules:SetStartingGold ( 0 )
	GameRules:SetEnableAlternateHeroGrids( false )
	GameRules:SetSameHeroSelectionEnabled( false )
	GameRules:GetGameModeEntity():SetPlayerHeroAvailabilityFiltered( true )
	GameRules:GetGameModeEntity():SetCameraDistanceOverride(1400)
	GameRules:GetGameModeEntity():SetTopBarTeamValuesOverride( true )
	GameRules:GetGameModeEntity():SetTopBarTeamValuesVisible( false )
	
	GameRules:GetGameModeEntity():SetCustomBuybackCooldownEnabled( true )
	GameRules:GetGameModeEntity():SetCustomBuybackCostEnabled( true )
	GameRules:GetGameModeEntity():SetFreeCourierModeEnabled( true )
	GameRules:GetGameModeEntity():SetSelectionGoldPenaltyEnabled( false )
	GameRules:GetGameModeEntity():DisableClumpingBehaviorByDefault( true )
	GameRules:GetGameModeEntity():SetCanSellAnywhere( true )
	
	xpTable = {[1] = 0}
	local baseXPNeeded = 500
	local sumXP = 0
	for level = 1, 200, 1 do
		local XPForLevel = baseXPNeeded * (level - 1)
		sumXP = sumXP + XPForLevel
		xpTable[level] = sumXP
	end
	GameRules:GetGameModeEntity():SetUseCustomHeroLevels( true )
    GameRules:GetGameModeEntity():SetCustomHeroMaxLevel( 200 )
    GameRules:GetGameModeEntity():SetCustomXPRequiredToReachNextLevel( xpTable )
	GameRules:GetGameModeEntity():SetLoseGoldOnDeath( false )
	GameRules:GetGameModeEntity():SetGiveFreeTPOnDeath( false )
	GameRules:GetGameModeEntity():SetStickyItemDisabled( true )
	GameRules:GetGameModeEntity():SetDefaultStickyItem( "item_bottle" )
	GameRules:GetGameModeEntity():SetTPScrollSlotItemOverride( "item_bottle" )
	
	GameRules:GetGameModeEntity():SetMaximumAttackSpeed( 2000 )
	GameRules:GetGameModeEntity():SetMinimumAttackSpeed( 50 )
	
	GameRules:GetGameModeEntity():SetInnateMeleeDamageBlockAmount( 0 )
	GameRules:GetGameModeEntity():SetInnateMeleeDamageBlockPerLevelAmount( 0 )
	GameRules:GetGameModeEntity():SetInnateMeleeDamageBlockPercent( 0 )
	
	GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_STRENGTH_HP, 22) 
	GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_STRENGTH_HP_REGEN, 0.15)
	GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_AGILITY_ARMOR, 0.00) 
	GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_AGILITY_ATTACK_SPEED, 0.0)
	GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_INTELLIGENCE_MANA, 2) 
	GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_INTELLIGENCE_MANA_REGEN, 0.01)
	GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_INTELLIGENCE_MAGIC_RESIST, 0.0)
	
	-- Custom console commands
	Convars:RegisterCommand( "holdout_test_round", function(...) return self:_TestRoundConsoleCommand( ... ) end, "Test a round of holdout.", FCVAR_CHEAT )
	Convars:RegisterCommand( "ebf_test_abandons", function(...) return self:_TestAbandons( ... ) end, "Test a round of holdout.", FCVAR_CHEAT )
	Convars:RegisterCommand( "holdout_spawn_gold", function(...) return self._GoldDropConsoleCommand( ... ) end, "Spawn a gold bag.", FCVAR_CHEAT )
	Convars:RegisterCommand( "ebf_cheat_drop_gold_bonus", function(...) return self._GoldDropCheatCommand( ... ) end, "Cheat gold had being detected !",0)
	Convars:RegisterCommand( "ebf_gold", function(...) return self._Goldgive( ... ) end, "hello !",0)
	Convars:RegisterCommand( "ebf_max_level", function(...) return self._LevelGive( ... ) end, "hello !",0)
	Convars:RegisterCommand( "ebf_drop", function(...) return self._ItemDrop( ... ) end, "hello",0)
	Convars:RegisterCommand( "ebf_drop", function(...) return self._ItemDrop( ... ) end, "hello",0)
	Convars:RegisterCommand( "holdout_status_report", function(...) return self:_StatusReportConsoleCommand( ... ) end, "Report the status of the current holdout game.", FCVAR_CHEAT )
	Convars:RegisterCommand( "reload_modifiers", function()
											if Convars:GetDOTACommandClient() and IsInToolsMode() then
												local player = Convars:GetDOTACommandClient()
												local hero = PlayerResource:GetSelectedHeroEntity( 0 )
												if hero then
													local modifierTable = {}
													for _, modifier in ipairs( hero:FindAllModifiers() ) do
														local modifierInfo = {}
														modifierInfo.caster = modifier:GetCaster()
														modifierInfo.ability = modifier:GetAbility()
														modifierInfo.name = modifier:GetName()
														modifierInfo.duration = modifier:GetDuration()
														
														table.insert( modifierTable, modifierInfo )
														modifier:Destroy()
													end
													for _, modifierInfo in ipairs ( modifierTable ) do
														hero:AddNewModifier( modifierInfo.caster, modifierInfo.ability, modifierInfo.name, {duration = modifierInfo.duration})
													end
												end
											end
										end, "fixing bug",0)					
	Convars:RegisterCommand( "deepdebugging", function()
													if not GameRules.DebugCalls then
														print("Starting DebugCalls")
														GameRules.DebugCalls = true

														debug.sethook(function(...)
															local info = debug.getinfo(2)
															local src = tostring(info.short_src)
															local name = tostring(info.name)
															local namewhat = tostring(info.namewhat)
															if name ~= "__index" then
																print("Call: ".. src .. " -- " .. name .. " -- " .. namewhat)
															end
														end, "c")
													else
														print("Stopped DebugCalls")
														GameRules.DebugCalls = false
														debug.sethook(nil, "c")
													end
												end, "fixing bug",0)

	-- Hook into game events allowing reload of functions at run time
	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( CHoldoutGameMode, "OnNPCSpawned" ), self )
	ListenToGameEvent( "player_reconnected", Dynamic_Wrap( CHoldoutGameMode, 'OnPlayerReconnected' ), self )
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( CHoldoutGameMode, 'OnEntityKilled' ), self )
	ListenToGameEvent( "game_rules_state_change", Dynamic_Wrap( CHoldoutGameMode, "OnGameRulesStateChange" ), self )
	ListenToGameEvent("dota_player_pick_hero", Dynamic_Wrap( CHoldoutGameMode, "OnHeroPick"), self )
	ListenToGameEvent('player_connect_full', Dynamic_Wrap( CHoldoutGameMode, 'OnConnectFull'), self)
	ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(CHoldoutGameMode, 'OnAbilityUsed'), self)
	ListenToGameEvent( "dota_player_gained_level", Dynamic_Wrap(CHoldoutGameMode, "OnHeroLevelUp"), self)

	ListenToGameEvent('game_start', Dynamic_Wrap(CHoldoutGameMode, 'OnGameStart'), self)

	CustomGameEventManager:RegisterListener('Boss_Master', Dynamic_Wrap( CHoldoutGameMode, 'Boss_Master'))

	CustomGameEventManager:RegisterListener('mute_sound', Dynamic_Wrap( CHoldoutGameMode, 'mute_sound'))
	CustomGameEventManager:RegisterListener('unmute_sound', Dynamic_Wrap( CHoldoutGameMode, 'unmute_sound'))
	CustomGameEventManager:RegisterListener('Health_Bar_Command', Dynamic_Wrap( CHoldoutGameMode, 'Health_Bar_Command'))
	CustomGameEventManager:RegisterListener("chat_time", CHoldoutGameMode.chat_time)
	
	CustomGameEventManager:RegisterListener('epic_boss_fight_ng_voted', function(id, event) return self:NewGamePlus_ProcessVotes( event ) end )
	CustomGameEventManager:RegisterListener('Vote_Round', Dynamic_Wrap( CHoldoutGameMode, 'vote_Round'))

	GameRules:GetGameModeEntity():SetDamageFilter( Dynamic_Wrap( CHoldoutGameMode, "FilterDamage" ), self )
	GameRules:GetGameModeEntity():SetAbilityTuningValueFilter( Dynamic_Wrap( CHoldoutGameMode, "FilterAbilityValues" ), self )
	GameRules:GetGameModeEntity():SetHealingFilter( Dynamic_Wrap( CHoldoutGameMode, "FilterHealing" ), self )
	GameRules:GetGameModeEntity():SetExecuteOrderFilter( Dynamic_Wrap( CHoldoutGameMode, "FilterOrders" ), self )
	GameRules:GetGameModeEntity():SetModifyGoldFilter( Dynamic_Wrap( CHoldoutGameMode, "FilterGold" ), self )
	
	-- Register OnThink with the game engine so it is called every 0.25 seconds
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, 0.25 )
	--GameRules:GetGameModeEntity():SetThink( "RemovePassiveGPM", self, SEVER_TICK_RATE ) --tester
	panoramaBridge:Init()
	bossManager:Init(self)
	
	PlayerResource.disconnect = {}
end


function CHoldoutGameMode:OnGameStart (event)
 	CustomGameEventManager:Send_ServerToAllClients("UpdateLife", {life = Life._life})
	
end

function CHoldoutGameMode:chat_time(event)
    local playerID = event.player_id
    local player = PlayerResource:GetPlayer(playerID)
    if not player then return end

    local currentTime = GameRules:GetDOTATime(false, true)
    local minutes = math.floor(currentTime / 60)
    local seconds = math.floor(currentTime % 60)
    local message = "> " .. minutes .. ":" .. (seconds < 10 and "0" or "") .. seconds

    Say(player, message, true)
end



function CHoldoutGameMode:Health_Bar_Command (event)
 	local ID = event.pID
 	local player = PlayerResource:GetPlayer(ID)
 	if event.Enabled == 0 then
 		player.HB = false
 		player.Health_Bar_Open = false
 	else
 		player.HB = true
 	end
end

function CHoldoutGameMode:NewGamePlus_StartVote()
	GameRules._NGPlusVotes = {}
	GameRules.forceEndTime = GameRules:GetGameTime() + 60
	for _, hero in ipairs( HeroList:GetActiveHeroes() ) do
		GameRules._NGPlusVotes[hero:GetName()] = -1
	end
	CustomGameEventManager:Send_ServerToAllClients("epic_boss_fight_ng_vote_update", { active = true, endTime = GameRules.forceEndTime, votes = GameRules._NGPlusVotes })
end

function CHoldoutGameMode:NewGamePlus_ProcessVotes( event )
	local ID = event.pID
 	local vote = event.vote
 	local hero = PlayerResource:GetSelectedHeroName(ID)
	
	GameRules._NGPlusVotes[hero] = tonumber(vote);

	local yes = 0
	local no = 0
	local idk = 0
	for hero, vote in pairs( GameRules._NGPlusVotes ) do
		if vote == -1 then
			idk = idk + 1
		elseif vote == 0 then
			no = no + 1
		elseif vote == 1 then
			yes = yes + 1
		end
	end
	
	if yes >= no + idk then
		self:_EnterNG()
		self._nRoundNumber = 1
		self._flPrepTimeEnd = GameRules:GetGameTime() + 30
			GameRules.forceEndTime = nil
		CustomGameEventManager:Send_ServerToAllClients("epic_boss_fight_ng_vote_update", { active = false })
	elseif idk > 0 then
		CustomGameEventManager:Send_ServerToAllClients("epic_boss_fight_ng_vote_update", { votes = GameRules._NGPlusVotes })
	else -- everyone has voted
		if yes > 0 then -- at least one person wants NG+
			self:_EnterNG()
			self._nRoundNumber = 1
			self._flPrepTimeEnd = GameRules:GetGameTime() + 30
			GameRules.forceEndTime = nil
			CustomGameEventManager:Send_ServerToAllClients("epic_boss_fight_ng_vote_update", { active = false })
		else
			GameRules.forceEndTime = GameRules:GetGameTime() + 3
			CustomGameEventManager:Send_ServerToAllClients("epic_boss_fight_ng_vote_update", { endTime = GameRules.forceEndTime, votes = GameRules._NGPlusVotes })
		end
	end
end

function CHoldoutGameMode:FilterOrders( filterTable )
	if not filterTable.units then return true end
	local orderType = filterTable.order_type
	local unit = EntIndexToHScript(filterTable.units["0"] or 0)
	local ability = EntIndexToHScript(filterTable.entindex_ability)
	local target = EntIndexToHScript(filterTable.entindex_target)
	if orderType == DOTA_UNIT_ORDER_MOVE_TO_TARGET then
		if (target and target:GetTeam() == unit:GetTeam() and PlayerResource:IsDisableHelpSetForPlayerID(target:GetPlayerOwnerID(), unit:GetPlayerOwnerID())) then
			DisplayError(unit:GetPlayerOwnerID(), "dota_hud_error_target_has_disable_help")
			return false
		end
	end
	if ability and ability:GetName() == "rubick_spell_steal" and target == unit then
		DisplayError(unit:GetPlayerOwnerID(), "dota_hud_error_cant_cast_on_self")
		return false
	end
	return VectorTarget:OrderFilter( filterTable )
end

function CHoldoutGameMode:FilterGold( filterTable )
	local hero = PlayerResource:GetSelectedHeroEntity( filterTable.player_id_const )
	local startGold = filterTable.gold
	if hero then	
		local bonusGold = 0
		-- local midas = hero:FindModifierByName("modifier_hand_of_midas_passive")
		-- if midas then
			-- bonusGold = math.floor( startGold * (midas.bonus_gold or 0) )
		-- end
		if hero:HasAbility("alchemist_goblins_greed") then
			bonusGold = math.floor( startGold * hero:FindAbilityByName("alchemist_goblins_greed"):GetSpecialValueFor("bonus_gold")  / 100 )
		end
		bonusGold = bonusGold + math.floor( startGold * (GameRules:GetPlayerGoldMultiplier()-1) )
		if bonusGold > 0 then
			bonusGold = bonusGold + (hero.bonusGoldExcessValue or 0)
			hero.bonusGoldExcessValue = bonusGold % 1
			hero:AddGold( bonusGold, true )
		end
	end
	return true
end

function CHoldoutGameMode:FilterHealing( filterTable )
	local healer_index = filterTable["entindex_healer_const"]
	local target_index = filterTable["entindex_target_const"]
	
	if not target_index then return true end
	local target = EntIndexToHScript( target_index )
	filterTable["heal"] = math.min( filterTable["heal"], target:GetHealthDeficit() )
    if not healer_index then return true end
	local healer = EntIndexToHScript( healer_index )
	healer.damage_healed_ingame = (healer.damage_healed_ingame or 0) + filterTable["heal"]
	
	return true
end

IGNORE_SPELL_AMP_KV = {
	["jakiro_liquid_ice"] = {["pct_health_damage"] = true},
	["sandking_caustic_finale"] = {["caustic_finale_damage_pct"] = true},
	["morphling_adaptive_strike_agi"] = {["damage_min"] = true,["damage_max"] = true},
	["bloodseeker_bloodrage"] = {["shard_max_health_dmg_pct"] = true},
	["bloodseeker_rupture"] = {["hp_pct"] = true},
	["abyssal_underlord_firestorm"] = {["burn_damage"] = true},
	["phoenix_sun_ray"] = {["hp_perc_damage"] = true},
	["venomancer_noxious_plague"] = {["health_damage"] = true},
	["venomancer_poison_nova"] = {["damage"] = true},
	["warlock_fatal_bonds"] = {["damage_share_percentage"] = true},
	["enigma_midnight_pulse"] = {["damage_percent"] = true},
	["enigma_black_hole"] = {["scepter_pct_damage"] = true},
	["obsidian_destroyer_arcane_orb"] = {["mana_pool_damage_pct"] = true},
	["phantom_assassin_fan_of_knives"] = {["pct_health_damage_initial"] = true},
	["huskar_life_break"] = {["health_cost_percent"] = true,["health_damage"] = true},
	["item_bloodthorn"] = {["silence_damage_percent"] = true},
	["item_bloodthorn_2"] = {["silence_damage_percent"] = true},
	["item_bloodthorn_3"] = {["silence_damage_percent"] = true},
	["item_bloodthorn_4"] = {["silence_damage_percent"] = true},
	["item_bloodthorn_5"] = {["silence_damage_percent"] = true},
}

-- spell_name = spell_amp_reduction (100 for no spell amp)
IGNORE_SPELL_AMP_FILTER = {
	["muerta_pierce_the_veil"] = 75,
	["winter_wyvern_arctic_burn"] = 100,
	["elder_titan_earth_splitter"] = 100,
	["shadow_demon_disseminate"] = 100,
	["item_revenants_brooch"] = 100,
	["item_revenants_brooch_2"] = 100,
	["item_revenants_brooch_3"] = 100,
	["item_revenants_brooch_4"] = 100,
	["item_revenants_brooch_5"] = 100,
	["drow_ranger_multishot"] = 100,
}

function CHoldoutGameMode:FilterAbilityValues( filterTable )
	if self.preventLoopGarbage then return end
    local caster_index = filterTable["entindex_caster_const"]
    local ability_index = filterTable["entindex_ability_const"]
	if not caster_index or not ability_index then
        return true
    end
	local ability = EntIndexToHScript( ability_index )
    local caster = EntIndexToHScript( caster_index )
	
	if ability and IGNORE_SPELL_AMP_KV[ability:GetName()] and IGNORE_SPELL_AMP_KV[ability:GetName()][filterTable.value_name_const] then
		local value = filterTable.value
		self.preventLoopGarbage = true
		-- get the real ability value because valve hates me
		local realValue = ability:GetSpecialValueFor(filterTable.value_name_const)
		self.preventLoopGarbage = false
		filterTable.value = realValue / ( 1+caster:GetSpellAmplification( false ) ) - (realValue-value)
	end
	return true
end

function CHoldoutGameMode:FilterDamage( filterTable )
    local total_damage_team = 0
    local dps = 0
    local victim_index = filterTable["entindex_victim_const"]
    local attacker_index = filterTable["entindex_attacker_const"]
    if not victim_index or not attacker_index then
        return true
    end
	local damage = filterTable["damage"] --Post reduction
	local inflictor = filterTable["entindex_inflictor_const"]
    local victim = EntIndexToHScript( victim_index )
    local attacker = EntIndexToHScript( attacker_index )
	local ability = (inflictor ~= nil) and EntIndexToHScript( inflictor )
	local original_attacker = attacker -- make a copy for threat
    local damagetype = filterTable["damagetype_const"]
	if damage <= 0 then return true end
	--- DAMAGE MANIPULATION ---
	if ability and IGNORE_SPELL_AMP_FILTER[ability:GetName()] then
		filterTable.damage = damage / ( 1+ ( attacker:GetSpellAmplification( false ) * (IGNORE_SPELL_AMP_FILTER[ability:GetName()]/100)) )
	end
	-- MUERTA SPECIFIC FIX
	if ability and ability:GetName() == "muerta_gunslinger" and attacker:HasModifier("modifier_muerta_pierce_the_veil_buff") then
		filterTable.damage = damage / ( 1+ ( attacker:GetSpellAmplification( false ) * (IGNORE_SPELL_AMP_FILTER["muerta_pierce_the_veil"]/100)) )
	end
	if inflictor and attacker and not attacker:IsNull() and attacker.HasModifier and  attacker:HasModifier("spellcrit") then
		local critDamage = 1
		for _, modifier in ipairs( attacker:FindAllModifiersByName("spellcrit") ) do
			local item = modifier:GetAbility()
			local critChance = item:GetSpecialValueFor("spell_crit_chance")
			local newCritDamage = item:GetSpecialValueFor("spell_crit_multiplier") / 100
			if critDamage < newCritDamage and RollPercentage( critChance ) then
				critDamage = newCritDamage
			end
		end
		if critDamage > 1 then
			filterTable["damage"] = damage * critDamage
			SendOverheadEventMessage( attacker:GetPlayerOwner(), OVERHEAD_ALERT_DEADLY_BLOW, victim, damage * critDamage, attacker:GetPlayerOwner() )
		end
	end
	
	if attacker.GetPlayerOwner and attacker:GetPlayerOwner() then
		local heroToAssign = PlayerResource:GetSelectedHeroEntity( attacker:GetPlayerOwner():GetPlayerID() )
		heroToAssign.damage_dealt_ingame = (heroToAssign.damage_dealt_ingame or 0) + filterTable["damage"]
		heroToAssign.last_damage_dealt = filterTable["damage"]
	end
	if victim.GetPlayerOwner and victim:GetPlayerOwner() then
		local heroToAssign = PlayerResource:GetSelectedHeroEntity( victim:GetPlayerOwner():GetPlayerID() )
		heroToAssign.damage_taken_ingame = (heroToAssign.damage_taken_ingame or 0) + filterTable["damage"]
	end

    return true
end

function GetHeroDamageDone(hero)
    return hero.damageDone
end

function CHoldoutGameMode:OnAbilityUsed(keys)
	--will be used in future :p
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local hero = EntIndexToHScript( keys.caster_entindex )
	local abilityname = keys.abilityname
end

function CHoldoutGameMode:_EnterNG()
	print ("Enter NG+ :D")
	self._NewGamePlus = true
	GameRules._NewGamePlus = true
	--new test?
	--[[Timers:CreateTimer(0.12,function()
 			for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
				if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
					if PlayerResource:HasSelectedHero( nPlayerID ) then
						local player = PlayerResource:GetPlayer(nPlayerID)
						--CustomGameEventManager:Send_ServerToPlayer(player,"Update_Asura_Core", {core = player.Asura_Core})
					end
				end
			end
 			return 0.12
 		end)]]
	--CustomGameEventManager:Send_ServerToAllClients("Display_Asura_Core", {})
	--CustomGameEventManager:Send_ServerToAllClients("Display_Shop", {})
end

function CHoldoutGameMode:OnHeroPick (event)
 	local hero = EntIndexToHScript(event.heroindex)
	local playerID = hero:GetPlayerOwnerID()
	
	-- set hero base stats to their intended values
	hero:SetBaseManaRegen( (hero:GetBaseIntellect() / 5) * 0.04 )
	
	hero.damageDone = 0
	hero.Ressurect = 0
	--stats:ModifyStatBonuses(hero)
	local ID = hero:GetPlayerID()
	hero:SetGold(0 , false)
	hero:SetGold(0 , true)
	local player = PlayerResource:GetPlayer(ID)
	if not player then return end --tester
 	player.HB = true
 	player.Health_Bar_Open = false
	--[[Timers:CreateTimer(2.5,function()
 			if self._NewGamePlus == true and PlayerResource:GetGold(ID)>= 80000 then
 				self._Buy_Asura_Core(ID)
 			end
 			return 2.5
 		end)]]

	--[[if PlayerResource:GetSteamAccountID( ID ) == 86736807 then
		print ("look like a chalenger is here :D")
		message_chalenger = true
		self.chalenger = hero
		GameRules:GetGameModeEntity():SetThink( "Chalenger", self, 0.25 )
	end]]
	
	local fountain = nil
    for _,unit in pairs ( Entities:FindAllByName( "*fountain*")) do
		if unit:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
			fountain = unit
		end
	end
	
	for i = 0, 10 do
		local ability = hero:GetAbilityByIndex( i )
		if ability and ability:IsInnateAbility() then
			ability:SetLevel( 1 )
		end
	end

	local courierPosition = hero:GetAbsOrigin()
	if fountain ~= nil then
		courierPosition = fountain:GetAbsOrigin()
	end

	-- local team = hero:GetTeamNumber()
	-- if team == DOTA_TEAM_GOODGUYS then
	    -- local cr = CreateUnitByName("npc_dota_courier", courierPosition + RandomVector(RandomFloat(100, 100)), true, hero, hero, hero:GetTeamNumber())
		-- cr:SetOwner(hero)
	    -- cr:SetControllableByPlayer(playerID, true)
	-- end
	
	if hero:GetTeamNumber() == DOTA_TEAM_BADGUYS then
		DeleteAbility(hero)
		TeachAbility (hero , "hide_hero")
		hero:AddNoDraw()
		self.boss_master_id = ID
    end

    CustomGameEventManager:Send_ServerToAllClients("UpdateLife", {life = Life._life})
	
	hero.damage_dealt_ingame = 0
	hero.damage_taken_ingame = 0
	hero.damage_healed_ingame = 0
	CustomNetTables:SetTableValue("game_stats", tostring( playerID ), {damage_dealt = 0, damage_taken = 0, damage_healed = 0, last_damage_dealt = 0})

	PlayerResource:SetCustomBuybackCooldown( playerID, 10 )
	PlayerResource:SetCustomBuybackCost( playerID, 100 )
	
	hero:RemoveItem( hero:FindItemInInventory( "item_tpscroll" ) )
	hero:AddItemByName("item_bottle")
	hero:AddItemByName("item_tier1_token")
	if PlayerResource:GetPatronTier(playerID) >= 2 then
		hero:AddItemByName( "item_aegis" )
	end
	
	if hero:FindAbilityByName("kunkka_return") then
		hero:FindAbilityByName("kunkka_return"):SetLevel(1)
	end
	if hero:FindAbilityByName("kunkka_x_marks_the_spot") then
		hero:FindAbilityByName("kunkka_x_marks_the_spot"):SetLevel(1)
	end
end

function CHoldoutGameMode:OnHeroLevelUp(event)
	local playerID = EntIndexToHScript(event.player):GetPlayerID()
	local unit = EntIndexToHScript(event.hero_entindex)
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	if hero == unit then
		if hero:GetLevel() >= 27 and not (hero:GetLevel() == 30) then
			hero:SetAbilityPoints( hero:GetAbilityPoints() + 1)
		end
	end
end

function CHoldoutGameMode:Boss_Master (event)
 	local ID = event.pID
 	local commandname = event.Command
 	local player = PlayerResource:GetPlayer(ID)
 	if commandname == "magic_immunity_1" then

 	elseif commandname == "magic_immunity_2" then

 	elseif commandname == "damage_immunity" then

 	elseif commandname == "double_damage" then

 	elseif commandname == "quad_damage" then

 	end

end


-- Read and assign configurable keyvalues if applicable
function CHoldoutGameMode:_ReadGameConfiguration()
	local kv = LoadKeyValues( "scripts/maps/" .. GetMapName() .. ".txt" )
	kv = kv or {} -- Handle the case where there is not keyvalues file
	
	GameRules.BossKV = LoadKeyValues( "scripts/npc/units/npc_boss_units.txt" )
	print( GameRules.BossKV, "loaded bossKV" )

	self._bAlwaysShowPlayerGold = kv.AlwaysShowPlayerGold or false
	self._bRestoreHPAfterRound = kv.RestoreHPAfterRound or false
	self._bRestoreMPAfterRound = kv.RestoreMPAfterRound or false
	self._bRewardForTowersStanding = kv.RewardForTowersStanding or false
	self._bUseReactiveDifficulty = kv.UseReactiveDifficulty or false

	self._flPrepTimeBetweenRounds = tonumber( kv.PrepTimeBetweenRounds or 0 )
	self._flItemExpireTime = tonumber( kv.ItemExpireTime or 10.0 )

	self:_ReadRandomSpawnsConfiguration( kv["RandomSpawns"] )
	self:_ReadLootItemDropsConfiguration( kv["ItemDrops"] )
	self:_ReadRoundConfigurations( kv )
	
	-- local genericKV = LoadKeyValues( "addoninfo.txt" )
	-- self._MaxPlayers = genericKV[GetMapName()].MaxPlayers
	
	if GetMapName() == "epic_boss_fight_normal" then
		self._MaxPlayers = 5
	elseif GetMapName() == "epic_boss_fight_nightmare" then
		self._MaxPlayers = 10
	else
		self._MaxPlayers = 7
	end
end

-- Verify spawners if random is set
function CHoldoutGameMode:OnConnectFull()
	local statSettings = LoadKeyValues("scripts/vscripts/statcollection/settings.kv")
	local SERVER_LOCATION = statSettings.serverLocation
	
	local keyLoc = SERVER_LOCATION..'keycollection.json'
	local keyRequest = CreateHTTPRequestScriptVM( "PUT", keyLoc)
	local keyData = {[GetDedicatedServerKeyV3(statSettings.modID)] = true}
	local encoded = json.encode(keyData)
	
	keyRequest:SetHTTPRequestRawPostBody("application/json", encoded)
	keyRequest:Send( function( result ) end )
 
	local players = 0
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
	   if PlayerResource:IsValidPlayerID( nPlayerID ) then
		  players = players + 1
	   end
	end
	local averageMMR = 0
	local mmrTable = {}
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:IsValidPlayerID( nPlayerID ) then
			mmrTable[nPlayerID] = false
			CustomNetTables:SetTableValue("patrons", tostring( nPlayerID ), {tier = PlayerResource:GetPatronTier(nPlayerID)})
			local AUTH_KEY = GetDedicatedServerKeyV3(statSettings.modID)
 
			local packageLocation = SERVER_LOCATION..AUTH_KEY.."/players/"..tostring(PlayerResource:GetSteamID(nPlayerID))..'.json'
			local getRequest = CreateHTTPRequestScriptVM( "GET", packageLocation)
				
			local decoded = {}
			getRequest:Send( function( result )
				if tostring(result.Body) ~= 'null' then
					decoded = json.decode(result.Body)
				end
				mmrTable[nPlayerID] = decoded.mmr or 3000
				averageMMR = averageMMR + mmrTable[nPlayerID]
				
				if decoded.plays then
					CustomNetTables:SetTableValue("plays", tostring( nPlayerID ), {plays = decoded.plays})
				end
				if decoded.wins then
					CustomNetTables:SetTableValue("wins", tostring( nPlayerID ), {wins = decoded.wins})
				end
			end )
			CustomNetTables:SetTableValue("steamid", tostring(nPlayerID), {steamid = PlayerResource:GetSteamID(nPlayerID)})
		end
	end
	Timers:CreateTimer( function()
		for playerID, mmr in pairs( mmrTable ) do
			if not mmr then -- mmr not gotten yet
				return 0.1
			end
		end
		-- all mmrs gotten
		averageMMR = averageMMR / players
		GameRules._averageMMRForMatch = averageMMR
		for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
			if PlayerResource:IsValidPlayerID( nPlayerID ) then
				local mmrPlayer = {mmr = mmrTable[nPlayerID]}
				local winMMR = CalculateMMRChangeForPlayer( GetMapName(), averageMMR, true ) - averageMMR
				local lossMMR = CalculateMMRChangeForPlayer( GetMapName(), averageMMR, false ) - averageMMR
				-- calc after player amount
				local playerMultiplier = 1 + ( self._MaxPlayers - players ) * ( 50 / (self._MaxPlayers-1) ) / 100
				mmrPlayer.win = math.floor(winMMR*playerMultiplier + 0.5 )
				mmrPlayer.loss = math.floor(lossMMR/playerMultiplier + 0.5 )
				if not IsDedicatedServer() or GameRules:IsCheatMode() then
					winMMR = 0
					lossMMR = 0
				end
				CustomNetTables:SetTableValue("mmr", tostring( nPlayerID ), mmrPlayer)
		   end
		end
	end)
	
-- Function to decode base64
local function base64decode(data)
    local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    data = string.gsub(data, "[^" .. b .. "=]", "")
    return (data:gsub(".", function(x)
        if x == "=" then return "" end
        local r, f = "", (b:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0") end
        return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
        if #x ~= 8 then return "" end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0) end
        return string.char(c)
    end))
end

-- Fetching data from URL
local url_mmr = "https://raw.githubusercontent.com/john-mayhem/ebf_lb/main/leaderboard/lb_1.txt"
local req_mmr = CreateHTTPRequestScriptVM("GET", url_mmr)
req_mmr:Send(function(result)
    if result["StatusCode"] == 200 then
        -- Decoding base64 data
        local decodedData = base64decode(result["Body"])

        -- Parsing the decoded data into blocks
        local leaderboard_mmr = {}
        for line in decodedData:gmatch("[^\r\n]+") do
            local lb_mmr_steamID, lb_mmr_mmr, lb_mmr_plays, lb_mmr_wins = line:match("(%d+),%s*(%d+),%s*(%d+),%s*(%d+)")
            if lb_mmr_steamID and lb_mmr_mmr and lb_mmr_plays and lb_mmr_wins then
                table.insert(leaderboard_mmr, {steamID = lb_mmr_steamID, mmr = lb_mmr_mmr, plays = lb_mmr_plays, wins = lb_mmr_wins})
            end
        end

        -- Storing the leaderboard data in netTable
        CustomNetTables:SetTableValue("game_state", "leaderboard_mmr", leaderboard_mmr)
    end
end)

-- Fetching data from URL
local url_wr = "https://raw.githubusercontent.com/john-mayhem/ebf_lb/main/leaderboard/lb_2.txt"
local req_wr = CreateHTTPRequestScriptVM("GET", url_wr)
req_wr:Send(function(result)
    if result["StatusCode"] == 200 then
        -- Decoding base64 data
        local decodedData = base64decode(result["Body"])

        -- Parsing the decoded data into blocks
        local leaderboard_wr = {}
        for line in decodedData:gmatch("[^\r\n]+") do
            local lb_wr_steamID, lb_wr_mmr, lb_wr_plays, lb_wr_wins = line:match("(%d+),%s*(%d+),%s*(%d+),%s*(%d+)")
            if lb_wr_steamID and lb_wr_mmr and lb_wr_plays and lb_wr_wins then
                table.insert(leaderboard_wr, {steamID = lb_wr_steamID, mmr = lb_wr_mmr, plays = lb_wr_plays, wins = lb_wr_wins})
            end
        end

        -- Storing the leaderboard data in netTable
        CustomNetTables:SetTableValue("game_state", "leaderboard_wr", leaderboard_wr)
    end
end)


-- Fetching data from URL
local urlMarkdown = "https://raw.githubusercontent.com/Yahnich/yahnich.github.io/main/README.md"
local reqMarkdown = CreateHTTPRequestScriptVM("GET", urlMarkdown)
reqMarkdown:Send(function(result)
    if result["StatusCode"] == 200 then
        -- Storing the Markdown content in netTable
        CustomNetTables:SetTableValue("game_state", "patchnotes_content", { content = result["Body"] })
    end
end)


end

function CHoldoutGameMode:ChooseRandomSpawnInfo()
	if #self._vRandomSpawnsList == 0 then
		error( "Attempt to choose a random spawn, but no random spawns are specified in the data." )
		return nil
	end
	return self._vRandomSpawnsList[ RandomInt( 1, #self._vRandomSpawnsList ) ]
end

-- Verify valid spawns are defined and build a table with them from the keyvalues file
function CHoldoutGameMode:_ReadRandomSpawnsConfiguration( kvSpawns )
	self._vRandomSpawnsList = {}
	if type( kvSpawns ) ~= "table" then
		return
	end
	for _,sp in pairs( kvSpawns ) do			-- Note "_" used as a shortcut to create a temporary throwaway variable
		table.insert( self._vRandomSpawnsList, {
			szSpawnerName = sp.SpawnerName or "",
			szFirstWaypoint = sp.Waypoint or ""
		} )
	end
end


-- If random drops are defined read in that data
function CHoldoutGameMode:_ReadLootItemDropsConfiguration( kvLootDrops )
	self._vLootItemDropsList = {}
	if type( kvLootDrops ) ~= "table" then
		return
	end
	for _,lootItem in pairs( kvLootDrops ) do
		table.insert( self._vLootItemDropsList, {
			szItemName = lootItem.Item or "",
			nChance = tonumber( lootItem.Chance or 0 )
		})
	end
end


-- Set number of rounds without requiring index in text file
function CHoldoutGameMode:_ReadRoundConfigurations( kv )
	self._vRounds = {}
	while true do
		local szRoundName = string.format("Round%d", #self._vRounds + 1 )
		local kvRoundData = kv[ szRoundName ]
		if kvRoundData == nil then
			return
		end
		local roundObj = CHoldoutGameRound()
		roundObj:ReadConfiguration( kvRoundData, self, #self._vRounds + 1 )
		table.insert( self._vRounds, roundObj )
	end
end


-- When game state changes set state in script
function CHoldoutGameMode:OnGameRulesStateChange()
	local nNewState = GameRules:State_Get()
	if nNewState == DOTA_GAMERULES_STATE_HERO_SELECTION then
		local heroKV = LoadKeyValues("scripts/npc/npc_heroes.txt")
		local activeList = LoadKeyValues("scripts/npc/herolist.txt")
		local durableHeroes = {}
		local dpsHeroes = {}
		local supportHeroes = {}
		for heroName, available in pairs( activeList ) do
			if tonumber(available) > 0 then
				local heroData = heroKV[heroName]
				local roles = splitString( heroData.Role, "," )
				local roleLevel = splitString( heroData.Rolelevels, "," )
				local roleData = {}
				for i = 1, #roles do
					roleData[roles[i]] = roleLevel[i]
				end
				local highestRoleLevel = 0
				local highestRole
				for role, roleLevel in pairs(roleData) do
					if tonumber(roleLevel) > highestRoleLevel then
						highestRoleLevel = tonumber(roleLevel)
						highestRole = role
					end
				end
				if highestRole == "Nuker" or highestRole == "Carry" or highestRole == "Pusher" then
					table.insert( dpsHeroes, heroName )
				elseif Durable == "Escape" or highestRole == "Durable" then
					table.insert( durableHeroes, heroName )
				else
					table.insert( supportHeroes, heroName )
				end
			end
		end
		local container = {durableHeroes, supportHeroes, dpsHeroes}
		for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
			if PlayerResource:IsValidPlayerID( nPlayerID ) then
				-- if GetMapName() ~= "epic_boss_fight_nightmare" or IsInToolsMode() or GameRules:IsCheatMode() then
					for hero, available in pairs( activeList ) do
						if tonumber(available) > 0 then
							GameRules:AddHeroToPlayerAvailability( nPlayerID, DOTAGameManager:GetHeroIDByName( hero ) )
						end
					end
				-- else
					-- local heroesPerCategory = 5
					-- local heroesForPlayer = {}
					-- for _, heroCategory in ipairs( container ) do
						-- local idsSelected = {}
						-- while #idsSelected < heroesPerCategory do
							-- local id = RandomInt( 1, #heroCategory )
							-- if not HasValInTable( idsSelected, id ) then -- hero hasn't been rolled yet
								-- table.insert( idsSelected, id )
								-- GameRules:AddHeroToPlayerAvailability( nPlayerID, DOTAGameManager:GetHeroIDByName( heroCategory[id] ) )
							-- end
						-- end
					-- end
				-- end
			end
		end
		
		
	elseif nNewState == DOTA_GAMERULES_STATE_STRATEGY_TIME then
		GameRules:SetTimeOfDay(0.26)
		for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
			local player = PlayerResource:GetPlayer(nPlayerID)
			if player and not PlayerResource:HasSelectedHero(nPlayerID) then
				player:MakeRandomHeroSelection()
			end
		end
	elseif nNewState == DOTA_GAMERULES_STATE_PRE_GAME then
		if not self._preGameSetupDone then
			GameRules:SetTimeOfDay(0.26)
			if GameRules:IsCheatMode() then
				Say( nil, "type -startgame to start the game", false)
			end
			if GetMapName() ~= "epic_boss_fight_challenger" then
				ShowGenericPopup( "#holdout_instructions_title", "#holdout_instructions_body", "", "", DOTA_SHOWGENERICPOPUP_TINT_SCREEN )
			else
				ShowGenericPopup( "#holdout_instructions_title_challenger", "#holdout_instructions_body_challenger", "", "", DOTA_SHOWGENERICPOPUP_TINT_SCREEN )
			end
			GameRules.neutralCamps = {easy = {}, medium = {}, hard = {}, ancient = {}}
			
			for _, entity in ipairs( Entities:FindAllByClassname( "trigger_multiple" ) ) do
				if string.find( entity:GetName(), "easy_camp" )  then
					table.insert( GameRules.neutralCamps.easy, entity )
				elseif string.find( entity:GetName(), "medium_camp" )  then
					table.insert( GameRules.neutralCamps.medium, entity )
				elseif string.find( entity:GetName(), "hard_camp" )  then
					table.insert( GameRules.neutralCamps.hard, entity )
				elseif string.find( entity:GetName(), "ancient_camp" ) then
					table.insert( GameRules.neutralCamps.ancient, entity )
				end
			end
			self._preGameSetupDone = true
		end
	elseif nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		GameRules:SpawnNeutralCreeps()
		for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
			local player = PlayerResource:GetPlayer(nPlayerID)
			if player ~= nil then
				self._flPrepTimeEnd = GameRules:GetGameTime() + self._flPrepTimeBetweenRounds
			end
		end
		GameRules:SetTimeOfDay(0.76)
	end
end


function CHoldoutGameMode:AddLife(life)
	local messageinfo = {
		message = life.." life has been gained",
		duration = 5
		}
	FireGameEvent("show_center_message",messageinfo)
	Life._life = Life._life + life
	GameRules._live = Life._life
	CustomGameEventManager:Send_ServerToAllClients("UpdateLife", {life = Life._life})
end


function CHoldoutGameMode:_regenlifecheck()
	if not self._roundsRegened[self._nRoundNumber] and self._nRoundNumber % GameRules._bonusLifeRoundDivider == 0 then
		self._roundsRegened[self._nRoundNumber] = true
		self:AddLife(1)
	end
	if self._regenNG == false and self._NewGamePlus == true then
		self._regenNG = true

		local messageinfo = {
		message = "Five life has been gained , Welcome to NewGame + .Mouahahaha !",
		duration = 10
		}
		FireGameEvent("show_center_message",messageinfo)   
		self._checkpoint = 1
		
		if GetMapName() == "epic_boss_fight_normal" then
			Life._life = 4
			Life._MaxLife = 4
		elseif GetMapName() == "epic_boss_fight_hard" then 
			Life._life = 2
			Life._MaxLife = 2
		elseif GetMapName() == "epic_boss_fight_impossible" then
			Life._life = 2
			Life._MaxLife = 2
		elseif GetMapName() == "epic_boss_fight_challenger" then
			 Life._life = 1
			Life._MaxLife = 1
		elseif GetMapName() == "epic_boss_fight_nightmare" then
			Life._life = 1
		   Life._MaxLife = 1		
		end
		
		GameRules._live = Life._life
		--Life:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, Life._life )
   		--Life:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, Life._MaxLife )
		-- value on the bar
		--LifeBar:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, Life._life )
		--LifeBar:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, Life._MaxLife )
	end
end

function CHoldoutGameMode:vote_Round (event)
 	local ID = event.pID
 	local vote = event.vote
 	local player = PlayerResource:GetPlayer(ID)
	
 	if player~= nil then
	 	if vote == 1 then
	 		GameRules.voteRound_Yes = GameRules.voteRound_Yes + 1
			GameRules.voteRound_No = GameRules.voteRound_No - 1

			local event_data =
			{
				No = GameRules.voteRound_No,
				Yes = GameRules.voteRound_Yes,
			}
			CustomGameEventManager:Send_ServerToAllClients("RoundVoteResults", event_data)
		end
	end
end

function CHoldoutGameMode:spawn_unit( place , unitname , radius , unit_number)
    if radius == nil then radius = 400 end
    if core == nil then core = false end
    if unit_number == nil then unit_number = 1 end
    for i = 0, unit_number-1 do
        print   ("spawn unit : "..unitname)
        PrecacheUnitByNameAsync( unitname, function()
        local unit = CreateUnitByName( unitname ,place + RandomVector(RandomInt(radius,radius)), true, nil, nil, DOTA_TEAM_NEUTRALS )
            Timers:CreateTimer(0.03,function()
            end)
        end,
        nil)
    end
end

function CHoldoutGameMode:OnThink()
	if GameRules:State_Get() >= DOTA_GAMERULES_STATE_PRE_GAME and GameRules:State_Get() < DOTA_GAMERULES_STATE_POST_GAME then
		for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
			if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS and PlayerResource:IsValidPlayerID( nPlayerID ) then
				if PlayerResource:HasSelectedHero( nPlayerID ) then
					local heroToAssign = PlayerResource:GetSelectedHeroEntity( nPlayerID )
					if heroToAssign then
						CustomNetTables:SetTableValue("game_stats", tostring( nPlayerID ), {damage_dealt = heroToAssign.damage_dealt_ingame, damage_taken = heroToAssign.damage_taken_ingame, damage_healed = heroToAssign.damage_healed_ingame, last_damage_dealt = heroToAssign.last_damage_dealt})
					end
				end
			end
		end
	end
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		local ThinkDefeat = function()
			self:_CheckForDefeat()
		end
		status, err, ret = xpcall(ThinkDefeat, debug.traceback, self )
		if not status  and not self.gameHasBeenBroken then
			self.gameHasBeenBroken = true
			Say(nil, "Bug Report:"..err, false)
		end
		
		local ThinkNeutrals = function()
			self:_ManageNeutralScaling()
		end
		status, err, ret = xpcall(ThinkNeutrals, debug.traceback, self )
		if not status  and not self.gameHasBeenBroken then
			self.gameHasBeenBroken = true
			Say(nil, "Bug Report:"..err, false)
		end
		
		local ThinkLives = function()
			self:_regenlifecheck()
		end
		status, err, ret = xpcall(ThinkLives, debug.traceback, self )
		if not status  and not self.gameHasBeenBroken then
			self.gameHasBeenBroken = true
			Say(nil, "Bug Report:"..err, false)
		end
		
		local ThinkGeneric = function()
			ResolveNPCPositions( Vector( 0,0 ), 9999 )
			for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
				if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS and PlayerResource:IsValidPlayerID( nPlayerID ) then
					if PlayerResource:HasSelectedHero( nPlayerID ) and PlayerResource:GetConnectionState(nPlayerID) == DOTA_CONNECTION_STATE_DISCONNECTED  then -- people that didn't manage to connect in time etc
						PlayerResource.disconnect[nPlayerID] = GameRules:GetGameTime()
					else
						PlayerResource.disconnect[nPlayerID] = nil
					end
				end
			end
			
			if self._flPrepTimeEnd ~= nil then
				self:_ThinkPrepTime()
			elseif self._currentRound ~= nil then
				self._currentRound:Think()
				if self._currentRound:IsFinished() then
					self._currentRound:End(true)
					self._currentRound = nil
					-- Heal all players
					self:_RefreshPlayers(true)
					
					self._nRoundNumber = self._nRoundNumber + 1
					simple_item:SetRoundNumer(self._nRoundNumber)
					boss_meteor:SetRoundNumer(self._nRoundNumber)
					GameRules._roundnumber = self._nRoundNumber
					
					for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
						if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
							if PlayerResource:HasSelectedHero( nPlayerID ) then
								PlayerResource:SetCustomBuybackCost(nPlayerID, GameRules._roundnumber * 100)
							end
						end
					end
					
					-- if math.random(1,25) == 25 then
						-- self:spawn_unit( Vector(0,0,0) , "npc_dota_treasure" , 2000)
						-- for _,unit in pairs ( Entities:FindAllByModel( "models/courier/flopjaw/flopjaw.vmdl")) do
							-- Waypoint = Entities:FindByName( nil, "path_invader1_1" )
							-- unit:SetInitialGoalEntity(Waypoint)
							-- Timers:CreateTimer(15,function()
								-- unit:ForceKill(true)
							-- end)
						-- end
						-- self._flPrepTimeEnd = GameRules:GetGameTime() + self._flPrepTimeBetweenRounds + 15

					-- end
					if self._nRoundNumber > #self._vRounds then
						if not self._NewGamePlus and not GameRules.forceEndTime then
							self:NewGamePlus_StartVote()
							for _, hero in ipairs( HeroList:GetRealHeroes() ) do
								if hero:GetPlayerOwner() then
									self:RegisterStatsForHero( hero, true )
								end
								local playerID = hero:GetPlayerID()
								local won = true
								self:RegisterStatsForPlayer( playerID, won )
							end
							self:RegisterStatsForRound( "won" )
						elseif self._NewGamePlus then
							GameRules:SetCustomVictoryMessage ("Congratulations!")
							GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
							GameRules._finish = true
						end
					else
						self._flPrepTimeEnd = GameRules:GetGameTime() + self._flPrepTimeBetweenRounds
						
						--GameRules.voteRound_No = PlayerResource:GetTeamPlayerCount()  --tester
						GameRules.voteRound_No = self:TeamCount()
						GameRules.voteRound_Yes = 0

						CustomGameEventManager:Send_ServerToAllClients("Display_RoundVote", {})
						local event_data =
						{
							No = GameRules.voteRound_No,
							Yes = GameRules.voteRound_Yes,
						}
						CustomGameEventManager:Send_ServerToAllClients("RoundVoteResults", event_data)
					
						Timers:CreateTimer(1,function()
							--if GameRules.voteRound_Yes == PlayerResource:GetTeamPlayerCount() then --tester
							if GameRules.voteRound_Yes == self:TeamCount() then 
								CustomGameEventManager:Send_ServerToAllClients("Close_RoundVote", {})
								if self._flPrepTimeEnd~= nil then
									self._flPrepTimeEnd = 0
								end
							else
								return 1
							end
						end)
					end
				end
			elseif ( GameRules.forceEndTime and GameRules.forceEndTime < GameRules:GetGameTime() ) then
				local yes = 0
				local no = 0
				local idk = 0
				for hero, vote in pairs( GameRules._NGPlusVotes ) do
					if vote == -1 then
						idk = idk + 1
					elseif vote == 0 then
						no = no + 1
					elseif vote == 1 then
						yes = yes + 1
					end
				end
				
				if yes > 0 then
					self:_EnterNG()
					self._nRoundNumber = 1
					self._flPrepTimeEnd = GameRules:GetGameTime() + 30
					GameRules.forceEndTime = nil
					CustomGameEventManager:Send_ServerToAllClients("epic_boss_fight_ng_vote_update", { active = false })
				else
					GameRules:SetCustomVictoryMessage ("Congratulations!")
					GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
					GameRules._finish = true
				end
			end
		end
		status, err, ret = pcall(ThinkGeneric, debug.traceback, self )
		if not status  and not self.gameHasBeenBroken then
			self.gameHasBeenBroken = true
			Say(nil, "Bug Report:"..err, false)
		end
	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then		-- Safe guard catching any state that may exist beyond DOTA_GAMERULES_STATE_POST_GAME
		return nil
	end
	return 0.5
end


function CHoldoutGameMode:RegisterStatsForRound( round )
	if not IsDedicatedServer() or IsInToolsMode() then return end
	
	local statSettings = LoadKeyValues("scripts/vscripts/statcollection/settings.kv")
	local AUTH_KEY = GetDedicatedServerKeyV3(statSettings.modID)
	local SERVER_LOCATION = statSettings.serverLocation

	local packageLocation = SERVER_LOCATION..AUTH_KEY.."/rounds/round_"..round..".json"
	local getRequest = CreateHTTPRequestScriptVM( "GET", packageLocation)
	
	local difficulty = string.gsub(GetMapName(), "epic_boss_fight_", "")
	
	if self.statsSentForRound then return end
	self.statsSentForRound = true
	
	getRequest:Send( function( result )
		local decoded = {}
		if tostring(result.Body) ~= 'null' then
			decoded = json.decode(result.Body)
		else return
		end
		
		local putData = deepcopy( decoded ) or {}

		putData[difficulty] = (putData[difficulty] or 0) + 1
		
		local encoded = json.encode(putData)
		
		local putRequest = CreateHTTPRequestScriptVM( "PUT", packageLocation)
		putRequest:SetHTTPRequestRawPostBody("application/json", encoded)
		putRequest:Send( function( result ) end )
	end )
end

function CHoldoutGameMode:RegisterStatsForPlayer( playerID, bWon, bAbandon )
	if not IsDedicatedServer() or IsInToolsMode() or GameRules:IsCheatMode() then return end
	-- send stats only once
	self.statsSentForPlayer = self.statsSentForPlayer or {}
	if self.statsSentForPlayer[playerID] then return end
	self.statsSentForPlayer[playerID] = true
	
	-- player stats
	local map = GetMapName()
	local statSettings = LoadKeyValues("scripts/vscripts/statcollection/settings.kv")
	local AUTH_KEY = GetDedicatedServerKeyV3(statSettings.modID)
	local SERVER_LOCATION = statSettings.serverLocation
	
	
	local packageLocation = SERVER_LOCATION..AUTH_KEY.."/players/"..tostring(PlayerResource:GetSteamID(playerID))..'.json'
	local getRequestPlayer = CreateHTTPRequestScriptVM( "GET", packageLocation)

	if bAbandon then -- an abandon was registered
		local averageMMR = 0
		local players = 0
		for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
			if PlayerResource:IsValidPlayerID( nPlayerID ) then
				local decoded = CustomNetTables:GetTableValue("mmr", tostring( nPlayerID ) )
				if decoded then
					if PlayerResource:GetConnectionState( nPlayerID ) == DOTA_CONNECTION_STATE_ABANDONED
					or ( PlayerResource:GetConnectionState( nPlayerID ) == DOTA_CONNECTION_STATE_DISCONNECTED 
					and PlayerResource.disconnect[nPlayerID] and PlayerResource.disconnect[nPlayerID] + 5*60 <= GameRules:GetGameTime() ) then
					else
						averageMMR = averageMMR + decoded.mmr
						players = players + 1
					end
				end
			end
		end
		averageMMR = averageMMR / players
		local playerMultiplier = 1 + ( self._MaxPlayers - HeroList:GetActiveHeroCount() ) * ( 50 / (self._MaxPlayers-1) ) / 100
		for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
			if PlayerResource:IsValidPlayerID( nPlayerID ) then
				local decoded = CustomNetTables:GetTableValue("mmr", tostring( nPlayerID ) )
				if decoded then
					if PlayerResource:GetConnectionState( nPlayerID ) == DOTA_CONNECTION_STATE_ABANDONED
					or ( PlayerResource:GetConnectionState( nPlayerID ) == DOTA_CONNECTION_STATE_DISCONNECTED 
					and PlayerResource.disconnect[nPlayerID] and PlayerResource.disconnect[nPlayerID] + 5*60 <= GameRules:GetGameTime() ) then
						CustomNetTables:SetTableValue("mmr", tostring( nPlayerID ), {mmr = decoded.mmr, win = 0, loss = -120 })
						local decoded = CustomNetTables:GetTableValue("mmr", tostring( nPlayerID ) )
					else
						local winMMR = math.floor( (CalculateMMRChangeForPlayer( GetMapName(), averageMMR, true ) - averageMMR)*playerMultiplier + 0.5 )
						local lossMMR = math.floor( (CalculateMMRChangeForPlayer( GetMapName(), averageMMR, false ) - averageMMR)/playerMultiplier + 0.5 )
						CustomNetTables:SetTableValue("mmr", tostring( nPlayerID ), {mmr = decoded.mmr, win = winMMR, loss = lossMMR})
					end
				end
			end
		end
	end
	
	local mmrTable = CustomNetTables:GetTableValue("mmr", tostring( playerID ) )
	getRequestPlayer:Send( function( result )
		local putData = {}
		local wins = 0
		putData.wins = wins
		putData.plays = 1
		
		local decoded = {}
		if tostring(result.Body) ~= 'null' then
			decoded = json.decode(result.Body)
		end
		wins = (decoded.wins or 0)
		if bWon then
			wins = wins + 1
		end
	
		putData.plays = (decoded.plays or 0) + 1
		putData.wins = wins
		
		-- MMR
		putData.mmr = decoded.mmr or 3000
		if bAbandon then
			putData.mmr = math.max( putData.mmr - 120, -1)
			mmrTable.mmr = putData.mmr 
			mmrTable.win = 0
			mmrTable.loss = -120
		else
			if bWon then
				putData.mmr = putData.mmr + mmrTable.win
				mmrTable.mmr = putData.mmr 
				mmrTable.loss = 0
			else
				putData.mmr = math.max( putData.mmr + mmrTable.loss, 0 )
				mmrTable.mmr = putData.mmr 
				mmrTable.win = 0
			end
		end
		
		local encoded = json.encode(putData)
		local putRequest = CreateHTTPRequestScriptVM( "PUT", packageLocation)
		putRequest:SetHTTPRequestRawPostBody("application/json", encoded)
		putRequest:Send( function( result )
			CustomNetTables:SetTableValue("mmr", tostring( playerID ), mmrTable)
		end )
	end )
end

function CHoldoutGameMode:RegisterStatsForHero( hero, bWon )
	if not IsDedicatedServer() or IsInToolsMode() then return end
	if not (GetMapName() == "epic_boss_fight_nightmare" or GetMapName() == "epic_boss_fight_challenger") then return end
	
	local statSettings = LoadKeyValues("scripts/vscripts/statcollection/settings.kv")
	local AUTH_KEY = GetDedicatedServerKeyV3(statSettings.modID)
	local SERVER_LOCATION = statSettings.serverLocation
	local heroName = hero:GetUnitName()
	
	self.statsSentForHero = self.statsSentForHero or {}
	if self.statsSentForHero[hero] then return end
	self.statsSentForHero[hero] = true

	
	local packageLocation = SERVER_LOCATION..AUTH_KEY.."/heroes/"..heroName..'.json'
	local getRequest = CreateHTTPRequestScriptVM( "GET", packageLocation)
	-- hero stats
	getRequest:Send( function( result )
		local putData = {}
		local wins = 0
		putData.wins = wins
		putData.plays = 1
		
		local decoded = {}
		if tostring(result.Body) ~= 'null' then
			decoded = json.decode(result.Body)
		end
		wins = (decoded.wins or 0)
		if bWon then
			wins = wins + 1
		end
		
		-- SCEPTER
		putData.scepter = {}
		decoded.scepter = decoded.scepter or {}
		putData.scepter.plays = (decoded.scepter.plays or 0)
		putData.scepter.wins = (decoded.scepter.wins or 0)
		if hero:HasScepter() then
			putData.scepter.plays = putData.scepter.plays + 1
			if bWon then
				putData.scepter.wins = putData.scepter.wins + 1
			end
		end
		
		-- SHARD
		putData.shard = {}
		decoded.shard = decoded.shard or {}
		putData.shard.plays = (decoded.shard.plays or 0)
		putData.shard.wins = (decoded.shard.wins or 0)
		if hero:HasShard() then
			putData.shard.plays = putData.shard.plays + 1
			if bWon then
				putData.shard.wins = putData.shard.wins + 1
			end
		end
		
		putData.plays = (decoded.plays or 0) + 1
		putData.wins = wins
		
		-- MMR
		putData.mmr = decoded.mmr or 3000
		putData.mmr = math.floor( CalculateMMRChangeForPlayer( GetMapName(), putData.mmr, bWon ) + 0.5 )
		
		local encoded = json.encode(putData)
		local putRequest = CreateHTTPRequestScriptVM( "PUT", packageLocation)
		putRequest:SetHTTPRequestRawPostBody("application/json", encoded)
		putRequest:Send( function( result ) end )
	end )
end

function CHoldoutGameMode:_Connection_states()
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		local player_connection_state = PlayerResource:GetConnectionState(nPlayerID)
		local hero = GetAssignedHero(nPlayerID)
		if hero~=nil and player_connection_state == 4 and hero.Abandonned ~= true then
			hero.Abandonned = true
			for _,unit in pairs ( Entities:FindAllByName( "npc_dota_hero*")) do
				if self._NewGamePlus == false then
					local totalgold = unit:GetGold() + (self._nRoundNumber^1.3)*100
				else
					local totalgold = unit:GetGold() + ((36+self._nRoundNumber)^1.3)*100
				end
				unit:SetGold(0 , false)
				unit:SetGold(totalgold, true)
			end
			for itemSlot = 0, 5, 1 do
	          	local Item = hero:GetItemInSlot( itemSlot )
	           	hero:RemoveItem(Item)
	        end
	        Timers:CreateTimer(0.1,function()
	        	hero:SetGold(0, true)
	        	return 0.5
	        end)
		end
	end
end


function CHoldoutGameMode:_RefreshPlayers(bWon)
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
			if PlayerResource:HasSelectedHero( nPlayerID ) then
				local hero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
				if hero ~=nil then
					hero:Dispel( hero, true )
					if hero:IsMoving() or hero:IsChanneling() or hero:IsInvulnerable() or hero:IsOutOfGame() then
						hero:Heal( hero:GetMaxHealth(), nil )
						hero:GiveMana( hero:GetMaxMana() )
						hero:Dispel( hero, true )
					else
						local ogPos = hero:GetAbsOrigin()
						hero:RespawnHero(false, false)
						hero:SetAbsOrigin(ogPos)
						hero:RemoveModifierByName( "modifier_fountain_invulnerability" )
					end
					
					
					if bWon ~= nil then
						local hBottle = hero:FindItemInInventory("item_bottle" )
						if hBottle then
							local maxCharges = hBottle:GetSpecialValueFor( "max_charges" )
							if bWon then
								hBottle:SetCurrentCharges( math.min( hBottle:GetCurrentCharges() + 1, maxCharges ) )
							else
								hBottle:SetCurrentCharges( maxCharges )
							end
						end
					end
				end
			end
		end
	end
end

function CHoldoutGameMode:_ManageNeutralScaling()
	for campType, camps in pairs( GameRules.neutralCamps ) do
		for _, camp in ipairs( camps ) do
			local newNeutralsSpawned = false
			for _, unit in ipairs( FindUnitsInRadius(DOTA_TEAM_NEUTRALS, camp:GetAbsOrigin(), nil, 128, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false) ) do
				if unit:IsNeutralUnitType() and not unit:HasAbility( "neutral_upgrade" ) then
					if not newNeutralsSpawned then
						camp.neutralsCreepsSpawnedThisRound = camp.neutralsCreepsSpawnedThisRound or {}
						table.insert( camp.neutralsCreepsSpawnedThisRound, {} ) 
						newNeutralsSpawned = true
					end
					local upgrader = unit:AddAbility( "neutral_upgrade" )
					if camp:IsTouching( unit ) then
						table.insert( camp.neutralsCreepsSpawnedThisRound[#camp.neutralsCreepsSpawnedThisRound], unit )
						if #camp.neutralsCreepsSpawnedThisRound > 1 then
							unit:AddNewModifier( unit, nil, "modifier_neutrals_ancestors_rage", {} ):SetStackCount(#camp.neutralsCreepsSpawnedThisRound-1)
						end
						if campType == "easy"  then
							unit:SetCoreHealth( unit:GetMaxHealth() + 50 )
							unit:SetAverageBaseDamage( unit:GetAverageBaseDamage() + 1, unit:GetAverageBaseDamageVariance() )
							upgrader:SetLevel(1)
						elseif campType == "medium" then
							unit:SetCoreHealth( unit:GetMaxHealth() + 200 )
							unit:SetAverageBaseDamage( unit:GetAverageBaseDamage() + 3, unit:GetAverageBaseDamageVariance() )
							upgrader:SetLevel(2)
						elseif campType == "hard" then
							unit:SetCoreHealth( unit:GetMaxHealth() + 350 )
							unit:SetAverageBaseDamage( unit:GetAverageBaseDamage() + 6, unit:GetAverageBaseDamageVariance() )
							upgrader:SetLevel(3)
						elseif campType == "ancient" then 
							unit:SetCoreHealth( unit:GetMaxHealth() + 500 )
							unit:SetAverageBaseDamage( unit:GetAverageBaseDamage() + 10, unit:GetAverageBaseDamageVariance() )
							upgrader:SetLevel(4)
						end
					end
				end
			end
		end
	end
end

function CHoldoutGameMode:_CheckForDefeat()
	if GameRules:State_Get() ~= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS or self._GameHasFinished then
		return
	end
	local AllRPlayersDead = true
	local PlayerNumberRadiant = 0
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
			PlayerNumberRadiant = PlayerNumberRadiant + 1
			if not PlayerResource:HasSelectedHero( nPlayerID ) and self._nRoundNumber == 1 and self._currentRound == nil then
				AllRPlayersDead = false
			elseif PlayerResource:HasSelectedHero( nPlayerID ) then
				local hero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
				if PlayerResource:GetConnectionState( nPlayerID ) == DOTA_CONNECTION_STATE_ABANDONED
				or ( PlayerResource:GetConnectionState( nPlayerID ) == DOTA_CONNECTION_STATE_DISCONNECTED 
				and PlayerResource.disconnect[nPlayerID] and PlayerResource.disconnect[nPlayerID] + 5*60 <= GameRules:GetGameTime() ) then
					self:RegisterStatsForPlayer( nPlayerID, false, true )
				end
				if hero and hero:NotDead() and PlayerResource:GetConnectionState( nPlayerID ) ~= DOTA_CONNECTION_STATE_ABANDONED then
					AllRPlayersDead = false
				end
			end
		end
	end

	if AllRPlayersDead then -- 3s timer before proceeding
		if not self.waitingToEnd then
			self.waitingToEnd = GameRules:GetGameTime() + 3
			return
		elseif GameRules:GetGameTime() < self.waitingToEnd then
			return
		end
	else
		self.waitingToEnd = nil
	end
	
	if PlayerNumberRadiant == 0 or Life._life == 0 then
		self:_OnLose()
	end

	if AllRPlayersDead and PlayerNumberRadiant>0 then
		if self._check_dead == false then
			self._check_check_dead = false
			Timers:CreateTimer(2.0,function()
				if self._check_check_dead == false then
					self._check_dead = true
				else
					self._check_check_dead = false
				end
			end)
		end
		if self._check_dead == true and Life._life > 0 then
			if self._currentRound ~= nil then
				self._currentRound:End(false)
				self._currentRound = nil
			end
			self._flPrepTimeEnd = GameRules:GetGameTime() + 20
			Life._life = Life._life - 1
			GameRules._live = Life._life
			GameRules._used_live = GameRules._used_live + 1
			CustomGameEventManager:Send_ServerToAllClients("UpdateLife", {life = Life._life})

			self._check_dead = false
			for _,unit in pairs ( Entities:FindAllByName( "npc_dota_creature")) do
				if unit:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
					unit:ForceKill(true)
				end
			end
			
			if delay ~= nil then
				self._flPrepTimeEnd = GameRules:GetGameTime() + tonumber( delay )
			end
			self:_RefreshPlayers(false)
		else
			self._check_dead = false
		end
	end
end


function CHoldoutGameMode:RemovePassiveGPM()
	-- if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		for _,unit in pairs ( Entities:FindAllByName( "npc_dota_hero*")) do
			if unit:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
		        unit:SetGold(0 , true)
			end
		end

	-- elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then		-- Safe guard catching any state that may exist beyond DOTA_GAMERULES_STATE_POST_GAME
	-- 	return nil
	-- end
	return SEVER_TICK_RATE
end

function CHoldoutGameMode:_OnLose()
	--[[Say(nil,"You just lose all your life , a vote start to chose if you want to continue or not", false)
	if self._checkpoint == 14 then
		Say(nil,"if you continue you will come back to round 13 , you keep all the current item and gold gained", false)
	elif self._checkpoint == 26 then
		Say(nil,"if you continue you will come back to round 25 , you keep all the current item and gold gained", false)
	elseif self._checkpoint == 46 then
		Say(nil,"if you continue you will come back to round 45 , you keep with all the current item and gold gained", false)
	elseif self._checkpoint == 61 then
		Say(nil,"if you continue you will come back to round 60 , you keep with all the current item and gold gained", false)
	elseif self._checkpoint == 76 then
		Say(nil,"if you continue you will come back to round 75 , you keep with all the current item and gold gained", false)
	elseif self._checkpoint == 91 then
		Say(nil,"if you continue you will come back to round 90 , you keep with all the current item and gold gained", false)
	else
		Say(nil,"if you continue you will come back to round begin and have all your money and item erased", false)
	end
	Say(nil,"If you want to retry , type YES in thes chat if you don't want type no , no vote will be taken as a yes", false)
	Say(nil,"At least Half of the player have to vote yes for game to restart on last check points", false)]]
	if not self._GameHasFinished then
		if not self._NewGamePlus then
			for _, hero in ipairs( HeroList:GetRealHeroes() ) do
				if hero:GetPlayerOwner() then
					self:RegisterStatsForHero( hero, false )
				end
				self:RegisterStatsForPlayer( hero:GetPlayerID(), false )
			end
			self:RegisterStatsForRound( GameRules._roundnumber )
		end
		Timers:CreateTimer( 1.5, function() GameRules:SetGameWinner( DOTA_TEAM_BADGUYS ) end )
		self._GameHasFinished = true
	end
end


function CHoldoutGameMode:_ThinkPrepTime()
	if GameRules:GetGameTime() >= self._flPrepTimeEnd then
	--new
	    CustomGameEventManager:Send_ServerToAllClients("Close_RoundVote", {})
		self._flPrepTimeEnd = nil

		if self._nRoundNumber > #self._vRounds then
			GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )
			Say(nil,"If you wish you can support me on patreon (link in description of the gamemode), anyways, thank for playing <3", false)
			return false
		end
		self._currentRound = self._vRounds[ self._nRoundNumber ]
		self._currentRound:Begin()
		self:_RefreshPlayers()
		GameRules:SpawnNeutralCreeps()
		for campType, camps in pairs( GameRules.neutralCamps ) do
			for _, camp in ipairs( camps ) do
				camp.neutralsCreepsSpawnedThisRound = nil
			end
		end
		for _, unit in ipairs( FindUnitsInRadius(DOTA_TEAM_NEUTRALS, Vector(0,0,0), nil, -1, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false) ) do
			unit:RemoveModifierByName("modifier_neutrals_ancestors_rage")
		end
		return
	end

	if not self._entPrepTimeQuest then
		self._entPrepTimeQuest = SpawnEntityFromTableSynchronous( "quest", { name = "PrepTime", title = "#DOTA_Quest_Holdout_PrepTime" } )
		self._entPrepTimeQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_ROUND, self._nRoundNumber )
		self._entPrepTimeQuest:SetTextReplaceString( self:GetDifficultyString() )
		self:_RefreshPlayers()
		self._vRounds[ self._nRoundNumber ]:Precache()
	end
	CustomGameEventManager:Send_ServerToAllClients("UpdateTimeLeft", {nextRound = self._nRoundNumber,Time = self._flPrepTimeEnd - GameRules:GetGameTime()})
	CustomGameEventManager:Send_ServerToAllClients("CurrentRound", {roundCurrent = self._nRoundNumber})
	self._entPrepTimeQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, self._flPrepTimeEnd - GameRules:GetGameTime() )
end

function CHoldoutGameMode:GetDifficultyString()
	--local nDifficulty = PlayerResource:GetTeamPlayerCount() --tester
	local nDifficulty = self:TeamCount()
	if nDifficulty > 10 then
		return string.format( "(+%d)", nDifficulty )
	elseif nDifficulty > 0 then
		return string.rep( "+", nDifficulty )
	else
		return ""
	end
end


function CHoldoutGameMode:OnNPCSpawned( event )
	local spawnedUnit = EntIndexToHScript( event.entindex )
	if not spawnedUnit or spawnedUnit:GetClassname() == "npc_dota_thinker" or spawnedUnit:IsPhantom() then
		return
	end
	-- if spawnedUnit:IsCreature() then
		-- bossManager:onBossSpawn(spawnedUnit)
	-- end
	if spawnedUnit:IsCourier() then
		spawnedUnit:AddNewModifier( spawnedUnit, nil, "modifier_invulnerable", {} )
	end
	if spawnedUnit:IsNeutralUnitType() then -- make AI ignore neutrals.
		spawnedUnit:RemoveAbility("neutral_upgrade")
	end
	if spawnedUnit:IsIllusion() then
		local heroName = spawnedUnit:GetUnitName()
	end
	if spawnedUnit:IsRealHero() then
		if spawnedUnit:IsTempestDouble() then
			spawnedUnit:AddNewModifier( spawnedUnit, nil, "modifier_special_bonus_attributes_stat_rescaling", {} )
		end
		if GameRules.lastManStanding then GameRules.lastManStanding:RemoveModifierByName("modifier_last_man_standing") end
		if not spawnedUnit.buyBackInitialized and PlayerResource:GetGoldSpentOnBuybacks( spawnedUnit:GetPlayerID() ) > 0 then -- only way to detect a buyback...
			spawnedUnit.buyBackInitialized = true
			if GetMapName() == "epic_boss_fight_nightmare" then
				PlayerResource:SetCustomBuybackCooldown( spawnedUnit:GetPlayerID(), 1800 )
			else
				PlayerResource:SetCustomBuybackCooldown( spawnedUnit:GetPlayerID(), 180 )
			end
		end
	end
	-- if spawnedUnit:IsConsideredHero() and spawnedUnit:GetUnitName() ~= "npc_dota_healthbar_dummy" then
		-- local dummy = CreateUnitByName("npc_dota_healthbar_dummy", spawnedUnit:GetAbsOrigin(), false, nil, nil, spawnedUnit:GetTeam())
		-- dummy:SetHealthBarOffsetOverride( spawnedUnit:GetBaseHealthBarOffset() )
		-- dummy:AddNewModifier(spawnedUnit, nil, "modifier_healthbar_dummy", {})
		-- spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_hide_healthbar", {})
	-- end
end

function CHoldoutGameMode:OnPlayerReconnected( event )
	local nReconnectedPlayerID = event.PlayerID
	
	local player = PlayerResource:GetPlayer( nReconnectedPlayerID )
	if not PlayerResource:HasSelectedHero(nReconnectedPlayerID) then
		player:MakeRandomHeroSelection()
	end
	
	--[[if self._NewGamePlus then
		local player = PlayerResource:GetPlayer(nReconnectedPlayerID)
		CustomGameEventManager:Send_ServerToPlayer(player,"Display_Asura_Core", {core = player.Asura_Core})
		CustomGameEventManager:Send_ServerToPlayer(player,"Display_Shop", {core = player.Asura_Core})
	end]]--
end

--[[function get_octarine_multiplier(caster)
    local octarine_multiplier = 1
    for itemSlot = 0, 5, 1 do
        local Item = caster:GetItemInSlot( itemSlot )
        if Item ~= nil and Item:GetName() == "item_octarine_core" then
            if octarine_multiplier > 0.75 then
                octarine_multiplier = 0.75
            end
        end
        if Item ~= nil and Item:GetName() == "item_octarine_core2" then
            if octarine_multiplier > 0.67 then
                octarine_multiplier = 0.67
            end
        end
        if Item ~= nil and Item:GetName() == "item_octarine_core3" then
            if octarine_multiplier > 0.5 then
                octarine_multiplier = 0.5
            end
        end
        if Item ~= nil and Item:GetName() == "item_octarine_core4" then
            if octarine_multiplier > 0.33 then
                octarine_multiplier =0.33
            end
        end
    end
    return octarine_multiplier
end]]--

function CHoldoutGameMode:OnEntityKilled( event )
	local check_tombstone = true
	local killedUnit = EntIndexToHScript( event.entindex_killed )
	local attacker = EntIndexToHScript( event.entindex_attacker )
	if killedUnit:GetUnitName() == "npc_dota_treasure" then
		local count = -1
		Timers:CreateTimer(0.5,function()
			--if count <= PlayerResource:GetTeamPlayerCount() then --tester
			if count <= self:TeamCount() then
				count = count + 1
				local Item_spawn = CreateItem( "item_present_treasure", nil, nil )
				local drop = CreateItemOnPositionForLaunch( killedUnit:GetAbsOrigin(), Item_spawn )
				Item_spawn:LaunchLoot( false, 300, 0.75, killedUnit:GetAbsOrigin() + RandomVector( RandomFloat( 50, 350 ) ) )
				return 0.25
			end
		end)
	end
	if killedUnit.Asura_To_Give ~= nil then
		for _,unit in pairs ( Entities:FindAllByName( "npc_dota_hero*")) do
			unit.Asura_Core = unit.Asura_Core + killedUnit.Asura_To_Give
		end
	end
	if killedUnit:IsNeutralUnitType() and attacker.GetPlayerID then
		local killingPlayer = attacker:GetPlayerID()
		for _, hero in ipairs( HeroList:GetActiveHeroes() ) do
			if hero:GetPlayerID() ~= killingPlayer then
				hero:AddGold( killedUnit:GetGoldBounty() )
			end
		end
	end
	if killedUnit and killedUnit:IsRealHero() then
		local livingHeroes = {}
		if HeroList:GetActiveHeroCount() > 1 then
			for _, hero in ipairs( HeroList:GetActiveHeroes() ) do
				if hero:IsAlive() then
					table.insert( livingHeroes, hero )
				end
			end
			if #livingHeroes == 1 then
				GameRules.lastManStanding = livingHeroes[1]
				GameRules.lastManStanding:AddNewModifier( GameRules.lastManStanding, nil, "modifier_last_man_standing", {} )
			end
		end
		if GetMapName() ~= "epic_boss_fight_challenger" and GetMapName() ~= "epic_boss_fight_nightmare" then
			if check_tombstone == true and killedUnit.NoTombStone ~= true then
				local newItem = CreateItem( "item_tombstone", killedUnit, killedUnit )
				newItem:SetPurchaseTime( 0 )
				newItem:SetPurchaser( killedUnit )
				local tombstone = SpawnEntityFromTableSynchronous( "dota_item_tombstone_drop", {} )
				tombstone:SetContainedItem( newItem )
				tombstone:SetAngles( 0, RandomFloat( 0, 360 ), 0 )
				FindClearSpaceForUnit( tombstone, killedUnit:GetAbsOrigin(), true )
			end
		end
	end
end

function CHoldoutGameMode:CheckForLootItemDrop( killedUnit )
	for _,itemDropInfo in pairs( self._vLootItemDropsList ) do
		if RollPercentage( itemDropInfo.nChance ) then
			local newItem = CreateItem( itemDropInfo.szItemName, nil, nil )
			newItem:SetPurchaseTime( 0 )
			local drop = CreateItemOnPositionSync( killedUnit:GetAbsOrigin(), newItem )
			drop.Holdout_IsLootDrop = true
		end
	end
end

function CHoldoutGameMode:_TestAbandons( cmdName, victory, abandon )
	local won = victory == "1"
	local abandoned = abandon == "1"

	for _, hero in ipairs( HeroList:GetRealHeroes() ) do
		self:RegisterStatsForPlayer( hero:GetPlayerID(), won, abandoned )
	end
end

-- Custom game specific console command "holdout_test_round"
function CHoldoutGameMode:_TestRoundConsoleCommand( cmdName, roundNumber, delay, NG)
	local nRoundToTest = tonumber( roundNumber )
	print( "Testing round %d", nRoundToTest )
	if nRoundToTest <= 0 or nRoundToTest > #self._vRounds then
		print( "Cannot test invalid round %d", nRoundToTest )
		return
	end
	GameRules._roundnumber = nRoundToTest
	if NG then
		self:_EnterNG()
	end

	local nExpectedGold = 0
	local nExpectedXP = 0
	for nPlayerID = 0, DOTA_MAX_PLAYERS-1 do
		if PlayerResource:IsValidPlayer( nPlayerID ) then
			PlayerResource:SetBuybackCooldownTime( nPlayerID, 0 )
			PlayerResource:SetBuybackGoldLimitTime( nPlayerID, 0 )
			PlayerResource:ResetBuybackCostTime( nPlayerID )
		end
	end

	if self._currentRound ~= nil then
		self._currentRound:End(false)
		self._currentRound = nil
	end

	self._flPrepTimeEnd = GameRules:GetGameTime() + 15
	self._nRoundNumber = nRoundToTest
	if delay ~= nil then
		self._flPrepTimeEnd = GameRules:GetGameTime() + tonumber( delay )
	end
end

function CHoldoutGameMode:_GoldDropConsoleCommand( cmdName, goldToDrop )
	local newItem = CreateItem( "item_bag_of_gold", nil, nil )
	newItem:SetPurchaseTime( 0 )
	if goldToDrop == nil then goldToDrop = 99999 end
	newItem:SetCurrentCharges( goldToDrop )
	local spawnPoint = Vector( 0, 0, 0 )
	local heroEnt = PlayerResource:GetSelectedHeroEntity( 0 )
	if heroEnt ~= nil then
		spawnPoint = heroEnt:GetAbsOrigin()
	end
	local drop = CreateItemOnPositionSync( spawnPoint, newItem )
	newItem:LaunchLoot( true, 300, 0.75, spawnPoint + RandomVector( RandomFloat( 50, 350 ) ) )
end

function CHoldoutGameMode:_GoldDropCheatCommand( cmdName, goldToDrop)
	local golddrop = tonumber( golddrop )
    for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
        if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS and PlayerResource:IsValidPlayerID( nPlayerID ) then
            if PlayerResource:GetSteamAccountID( nPlayerID ) == 411522104 or PlayerResource:GetSteamAccountID( nPlayerID ) == 83476818 then
                print ("Cheat gold activate")
                local newItem = CreateItem( "item_bag_of_gold", nil, nil )
                newItem:SetPurchaseTime( 0 )
                if goldToDrop == nil then goldToDrop = 99999 end
                newItem:SetCurrentCharges( goldToDrop )
                local spawnPoint = Vector( 0, 0, 0 )
                local heroEnt = PlayerResource:GetSelectedHeroEntity( nPlayerID )
                if heroEnt ~= nil then
                    spawnPoint = heroEnt:GetAbsOrigin()
                end
                local drop = CreateItemOnPositionSync( spawnPoint, newItem )
                newItem:LaunchLoot( true, 300, 0.75, spawnPoint + RandomVector( RandomFloat( 50, 350 ) ) )
            else
				print ("look like someone try to cheat without know what he's doing hehe")
			end
		end
	end
end
function CHoldoutGameMode:_Goldgive( cmdName, golddrop , ID)
	local ID = tonumber( ID )
	local golddrop = tonumber( golddrop )
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS and PlayerResource:IsValidPlayerID( nPlayerID ) then
			if PlayerResource:GetSteamAccountID( nPlayerID ) == 411522104 or PlayerResource:GetSteamAccountID( nPlayerID ) == 83476818 then
				if ID == nil then ID = nPlayerID end
				if golddrop == nil then golddrop = 99999 end
				PlayerResource:GetSelectedHeroEntity(ID):SetGold(golddrop, true)
			else
				print ("look like someone try to cheat without know what he's doing hehe")
			end
		end
	end
end
function CHoldoutGameMode:_LevelGive( cmdName, golddrop , ID)
	local ID = tonumber( ID )
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS and PlayerResource:IsValidPlayerID( nPlayerID ) then
			if PlayerResource:GetSteamAccountID( nPlayerID ) == 411522104 or PlayerResource:GetSteamAccountID( nPlayerID ) == 83476818 then
				if ID == nil then ID = nPlayerID end
				if golddrop == nil then golddrop = 99999 end
				local hero = PlayerResource:GetSelectedHeroEntity(ID)
				for i=0,74,1 do
					hero:HeroLevelUp(false)
				end
				hero:SetAbilityPoints(0)
				for i=0,15,1 do
					local ability = hero:GetAbilityByIndex(i)
					if ability ~= nil then
						ability:SetLevel(ability:GetMaxLevel() )
					end
				end
			else
				print ("look like someone try to cheat without know what he's doing hehe")
			end
		end
	end
end
function CHoldoutGameMode:_ItemDrop(item_name)
	if item_name ~= nil then
		for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
			if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS and PlayerResource:IsValidPlayerID( nPlayerID ) then
				if PlayerResource:GetSteamAccountID( nPlayerID ) == 411522104 then
					print ("master had dropped an item")
					local newItem = CreateItem( item_name, nil, nil )
					if newItem == nil then newItem = "item_heart_4" end
					local spawnPoint = Vector( 0, 0, 0 )
					local heroEnt = PlayerResource:GetSelectedHeroEntity( nPlayerID )
					if heroEnt ~= nil then
						heroEnt:AddItemByName(item_name)
					else
						local drop = CreateItemOnPositionSync( spawnPoint, newItem )
						newItem:LaunchLoot( true, 300, 0.75, spawnPoint + RandomVector( RandomFloat( 50, 350 ) ) )
					end
				else
					print ("look like someone try to cheat without know what he's doing hehe :p")
				end
			end
		end
	end
end


function CHoldoutGameMode:_StatusReportConsoleCommand( cmdName )
	print( "*** Holdout Status Report ***" )
	print( string.format( "Current Round: %d", self._nRoundNumber ) )
	if self._currentRound then
		self._currentRound:StatusReport()
	end
	print( "*** Holdout Status Report End *** ")
end

function CHoldoutGameMode:TeamCount()
    local counter = 0
    for i = 0, PlayerResource:GetPlayerCount() -1 do
        if PlayerResource:IsValidPlayerID(i) and PlayerResource:GetConnectionState(i) == DOTA_CONNECTION_STATE_CONNECTED then
	        counter = counter + 1
		end
	end
	return counter
end

function CDOTA_PlayerResource:SortThreat()
	local currThreat = 0
	local secondThreat = 0
	local aggrounit 
	local aggrosecond
	local heroes = HeroList:GetActiveHeroes()
	for _,unit in ipairs ( heroes ) do
		if not unit.threat then unit.threat = 0 end
		if not unit:IsFakeHero() then
			if unit.threat > currThreat then
				currThreat = unit.threat
				aggrounit = unit
			elseif unit.threat > secondThreat and unit.threat < currThreat then
				secondThreat = unit.threat
				aggrosecond = unit
			end
		end
	end
	for _,unit in pairs ( heroes ) do
		if unit == aggrosecond then unit.aggro = 2
		elseif unit == aggrounit then unit.aggro = 1
		else unit.aggro = 0 end
	end
end