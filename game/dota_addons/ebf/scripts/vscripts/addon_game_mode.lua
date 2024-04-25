print("Epic Boss Fight Reborn version 1.41")
print("Created by Plexus Du Menton")
print("Developed by houthakker / Mayhem / MrDimases")

require("epic_boss_fight_game_round")
require("epic_boss_fight_game_spawner")
require("libraries/Timers")
require("libraries/vector_targeting")
require("libraries/disable_help")
require("panoramaBridge")
require("bossManager")
require("libraries/utility")
require("ai/ai_core")

if CHoldoutGameMode == nil then
    CHoldoutGameMode = class({})
end

function Activate()
    GameRules.holdOut = CHoldoutGameMode()
    GameRules.holdOut:InitGameMode()
end

function CHoldoutGameMode:InitGameMode()

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

    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 0)
    -- end
    GameRules._getDeadCoreUnitsForGarbageCollection = {}

    GameRules:SetPreGameTime(30)
    GameRules:SetShowcaseTime(0)
    GameRules:SetStrategyTime(5)
    GameRules:SetPostGameTime(15)
    GameRules:SetCustomGameEndDelay(15.0)
    GameRules:SetHeroSelectionTime(60.0)
    GameRules:SetHeroSelectPenaltyTime(5.0)
    GameRules:SetCustomGameSetupAutoLaunchDelay(0)
    GameRules:SetHeroRespawnEnabled(true)

    if IsInToolsMode() or GameRules:IsCheatMode() then
        GameRules:SetPreGameTime(99999)
        GameRules:SetHeroSelectionTime(99999)
    end

    -- defining lifes
    if GetMapName() == "epic_boss_fight_normal" then
        Life._life = 4
        Life._MaxLife = 4
        GameRules._bonusLifeRoundDivider = 5
        GameRules.gameDifficulty = 1
        GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 10)
        GameRules:GetGameModeEntity():SetFixedRespawnTime(30)
    elseif GetMapName() == "epic_boss_fight_hard" then
        Life._life = 2
        Life._MaxLife = 2
        GameRules._bonusLifeRoundDivider = 10
        GameRules.gameDifficulty = 2
        GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 8)
        GameRules:GetGameModeEntity():SetFixedRespawnTime(60)
    elseif GetMapName() == "epic_boss_fight_impossible" then
        Life._life = 2
        Life._MaxLife = 2
        GameRules._bonusLifeRoundDivider = 15
        GameRules.gameDifficulty = 3
        GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 6)
    elseif GetMapName() == "epic_boss_fight_challenger" then
        Life._life = 1
        Life._MaxLife = 1
        GameRules._bonusLifeRoundDivider = 99
        GameRules.gameDifficulty = 3
        GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 6)
        GameRules:GetGameModeEntity():SetFixedRespawnTime(120)
    elseif GetMapName() == "epic_boss_fight_nightmare" then
        Life._life = 1
        Life._MaxLife = 1
        GameRules._bonusLifeRoundDivider = 99
        GameRules.gameDifficulty = 4
        GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 5)
        GameRules:GetGameModeEntity():SetFixedRespawnTime(180)
    end

    GameRules._live = Life._life
    GameRules._used_live = 0

    self:_ReadGameConfiguration()
    GameRules:SetUseUniversalShopMode(true)
    GameRules:SetTreeRegrowTime(15.0)
    GameRules:SetCreepMinimapIconScale(4)
    GameRules:SetRuneMinimapIconScale(1.5)
    GameRules:SetGoldTickTime(0.6)
    GameRules:SetGoldPerTick(1)
    GameRules:SetStartingGold(0)
    GameRules:SetEnableAlternateHeroGrids(false)
    GameRules:SetSameHeroSelectionEnabled(false)
    GameRules:GetGameModeEntity():SetPlayerHeroAvailabilityFiltered(true)
    GameRules:GetGameModeEntity():SetCameraDistanceOverride(1400)
    GameRules:GetGameModeEntity():SetTopBarTeamValuesOverride(true)
    GameRules:GetGameModeEntity():SetTopBarTeamValuesVisible(false)

    GameRules:GetGameModeEntity():SetCustomBuybackCooldownEnabled(true)
    GameRules:GetGameModeEntity():SetCustomBuybackCostEnabled(true)
    GameRules:GetGameModeEntity():SetFreeCourierModeEnabled(true)
    GameRules:GetGameModeEntity():SetSelectionGoldPenaltyEnabled(false)
    GameRules:GetGameModeEntity():DisableClumpingBehaviorByDefault(true)
    GameRules:GetGameModeEntity():SetCanSellAnywhere(true)

    xpTable = {
        [1] = 0
    }
    local baseXPNeeded = 500
    local sumXP = 0
    for level = 1, 200, 1 do
        local XPForLevel = baseXPNeeded * (level - 1)
        sumXP = sumXP + XPForLevel
        xpTable[level] = sumXP
    end
    GameRules:GetGameModeEntity():SetUseCustomHeroLevels(true)
    GameRules:GetGameModeEntity():SetCustomHeroMaxLevel(200)
    GameRules:GetGameModeEntity():SetCustomXPRequiredToReachNextLevel(xpTable)
    GameRules:GetGameModeEntity():SetLoseGoldOnDeath(false)
    GameRules:GetGameModeEntity():SetGiveFreeTPOnDeath(false)
    GameRules:GetGameModeEntity():SetStickyItemDisabled(true)
    GameRules:GetGameModeEntity():SetDefaultStickyItem("item_bottle_ebf")
    GameRules:GetGameModeEntity():SetTPScrollSlotItemOverride("item_bottle_ebf")

    GameRules:GetGameModeEntity():SetMaximumAttackSpeed(2000)
    GameRules:GetGameModeEntity():SetMinimumAttackSpeed(50)

    GameRules:GetGameModeEntity():SetInnateMeleeDamageBlockAmount(0)
    GameRules:GetGameModeEntity():SetInnateMeleeDamageBlockPerLevelAmount(0)
    GameRules:GetGameModeEntity():SetInnateMeleeDamageBlockPercent(0)

    GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_STRENGTH_HP, 22)
    GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_STRENGTH_HP_REGEN, 0.15)
    GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_AGILITY_ARMOR, 0.00)
    GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_AGILITY_ATTACK_SPEED, 0.0)
    GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_INTELLIGENCE_MANA, 2)
    GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_INTELLIGENCE_MANA_REGEN, 0.01)
    GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_INTELLIGENCE_MAGIC_RESIST, 0.0)

    -- Custom console commands

    Convars:RegisterCommand("reload_modifiers", function()
        if Convars:GetDOTACommandClient() and IsInToolsMode() then
            local player = Convars:GetDOTACommandClient()
            local hero = PlayerResource:GetSelectedHeroEntity(0)
            if hero then
                local modifierTable = {}
                for _, modifier in ipairs(hero:FindAllModifiers()) do
                    local modifierInfo = {}
                    modifierInfo.caster = modifier:GetCaster()
                    modifierInfo.ability = modifier:GetAbility()
                    modifierInfo.name = modifier:GetName()
                    modifierInfo.duration = modifier:GetDuration()

                    table.insert(modifierTable, modifierInfo)
                    modifier:Destroy()
                end
                for _, modifierInfo in ipairs(modifierTable) do
                    hero:AddNewModifier(modifierInfo.caster, modifierInfo.ability, modifierInfo.name, {
                        duration = modifierInfo.duration
                    })
                end
            end
        end
    end, "fixing bug", 0)

    Convars:RegisterCommand("deepdebugging", function()
        if not GameRules.DebugCalls then
            print("Starting DebugCalls")
            GameRules.DebugCalls = true

            debug.sethook(function(...)
                local info = debug.getinfo(2)
                local src = tostring(info.short_src)
                local name = tostring(info.name)
                local namewhat = tostring(info.namewhat)
                if name ~= "__index" then
                    print("Call: " .. src .. " -- " .. name .. " -- " .. namewhat)
                end
            end, "c")
        else
            print("Stopped DebugCalls")
            GameRules.DebugCalls = false
            debug.sethook(nil, "c")
        end
    end, "fixing bug", 0)

    -- Hook into game events allowing reload of functions at run time
    ListenToGameEvent("npc_spawned", Dynamic_Wrap(CHoldoutGameMode, "OnNPCSpawned"), self)
    ListenToGameEvent("player_reconnected", Dynamic_Wrap(CHoldoutGameMode, 'OnPlayerReconnected'), self)
    ListenToGameEvent("entity_killed", Dynamic_Wrap(CHoldoutGameMode, 'OnEntityKilled'), self)
    ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(CHoldoutGameMode, "OnGameRulesStateChange"), self)
    ListenToGameEvent("dota_player_pick_hero", Dynamic_Wrap(CHoldoutGameMode, "OnHeroPick"), self)
    ListenToGameEvent('player_connect_full', Dynamic_Wrap(CHoldoutGameMode, 'OnConnectFull'), self)
    ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(CHoldoutGameMode, 'OnAbilityUsed'), self)
    ListenToGameEvent("dota_player_gained_level", Dynamic_Wrap(CHoldoutGameMode, "OnHeroLevelUp"), self)

    ListenToGameEvent('game_start', Dynamic_Wrap(CHoldoutGameMode, 'OnGameStart'), self)

    CustomGameEventManager:RegisterListener('Boss_Master', Dynamic_Wrap(CHoldoutGameMode, 'Boss_Master'))

    CustomGameEventManager:RegisterListener('mute_sound', Dynamic_Wrap(CHoldoutGameMode, 'mute_sound'))
    CustomGameEventManager:RegisterListener('unmute_sound', Dynamic_Wrap(CHoldoutGameMode, 'unmute_sound'))
    CustomGameEventManager:RegisterListener('Health_Bar_Command', Dynamic_Wrap(CHoldoutGameMode, 'Health_Bar_Command'))
    CustomGameEventManager:RegisterListener("chat_time", CHoldoutGameMode.chat_time)

    CustomGameEventManager:RegisterListener('epic_boss_fight_ng_voted', function(id, event)
        return self:NewGamePlus_ProcessVotes(event)
    end)
    CustomGameEventManager:RegisterListener('Vote_Round', Dynamic_Wrap(CHoldoutGameMode, 'vote_Round'))
 
    GameRules:GetGameModeEntity():SetDamageFilter(Dynamic_Wrap(CHoldoutGameMode, "FilterDamage"), self)
    GameRules:GetGameModeEntity():SetAbilityTuningValueFilter(Dynamic_Wrap(CHoldoutGameMode, "FilterAbilityValues"),
        self)
    GameRules:GetGameModeEntity():SetHealingFilter(Dynamic_Wrap(CHoldoutGameMode, "FilterHealing"), self)
    GameRules:GetGameModeEntity():SetExecuteOrderFilter(Dynamic_Wrap(CHoldoutGameMode, "FilterOrders"), self)
    GameRules:GetGameModeEntity():SetModifyGoldFilter(Dynamic_Wrap(CHoldoutGameMode, "FilterGold"), self)

    -- Register OnThink with the game engine so it is called every 0.25 seconds
    GameRules:GetGameModeEntity():SetThink("OnThink", self, 0.25)
    panoramaBridge:Init()
    bossManager:Init(self)

    PlayerResource.disconnect = {}
end

function CHoldoutGameMode:OnGameStart(event)
    CustomGameEventManager:Send_ServerToAllClients("UpdateLife", {
        life = Life._life
    })
end

function CHoldoutGameMode:NewGamePlus_StartVote()
    GameRules._NGPlusVotes = {}
    GameRules.forceEndTime = GameRules:GetGameTime() + 60
    for _, hero in ipairs(HeroList:GetActiveHeroes()) do
        GameRules._NGPlusVotes[hero:GetName()] = -1
    end
    CustomGameEventManager:Send_ServerToAllClients("epic_boss_fight_ng_vote_update", {
        active = true,
        endTime = GameRules.forceEndTime,
        votes = GameRules._NGPlusVotes
    })
end

function CHoldoutGameMode:NewGamePlus_ProcessVotes(event)
    local ID = event.pID
    local vote = event.vote
    local hero = PlayerResource:GetSelectedHeroName(ID)

    GameRules._NGPlusVotes[hero] = tonumber(vote);

    local yes = 0
    local no = 0
    local idk = 0
    for hero, vote in pairs(GameRules._NGPlusVotes) do
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
        CustomGameEventManager:Send_ServerToAllClients("epic_boss_fight_ng_vote_update", {
            active = false
        })
    elseif idk > 0 then
        CustomGameEventManager:Send_ServerToAllClients("epic_boss_fight_ng_vote_update", {
            votes = GameRules._NGPlusVotes
        })
    else -- everyone has voted
        if yes > 0 then -- at least one person wants NG+
            self:_EnterNG()
            self._nRoundNumber = 1
            self._flPrepTimeEnd = GameRules:GetGameTime() + 30
            GameRules.forceEndTime = nil
            CustomGameEventManager:Send_ServerToAllClients("epic_boss_fight_ng_vote_update", {
                active = false
            })
        else
            GameRules.forceEndTime = GameRules:GetGameTime() + 3
            CustomGameEventManager:Send_ServerToAllClients("epic_boss_fight_ng_vote_update", {
                endTime = GameRules.forceEndTime,
                votes = GameRules._NGPlusVotes
            })
        end
    end
end

function CHoldoutGameMode:FilterOrders(filterTable)
    if not filterTable.units then
        return true
    end
    local orderType = filterTable.order_type
    local unit = EntIndexToHScript(filterTable.units["0"] or 0)
    local ability = EntIndexToHScript(filterTable.entindex_ability)
    local target = EntIndexToHScript(filterTable.entindex_target)
    if orderType == DOTA_UNIT_ORDER_MOVE_TO_TARGET or orderType == DOTA_UNIT_ORDER_CAST_TARGET then
        if (target and target:GetTeam() == unit:GetTeam() and
            PlayerResource:IsDisableHelpSetForPlayerID(target:GetPlayerOwnerID(), unit:GetPlayerOwnerID())) then
            DisplayError(unit:GetPlayerOwnerID(), "dota_hud_error_target_has_disable_help")
            return false
        end
    end
    if ability and ability:GetName() == "rubick_spell_steal" and target == unit then
        DisplayError(unit:GetPlayerOwnerID(), "dota_hud_error_cant_cast_on_self")
        return false
    end
    return VectorTarget:OrderFilter(filterTable)
end

function CHoldoutGameMode:FilterGold(filterTable)
    local hero = PlayerResource:GetSelectedHeroEntity(filterTable.player_id_const)
    local startGold = filterTable.gold
    if hero then
        local bonusGold = 0
        if hero:HasAbility("alchemist_goblins_greed") then
            bonusGold = math.floor(startGold *
                                       hero:FindAbilityByName("alchemist_goblins_greed")
                    :GetSpecialValueFor("bonus_gold") / 100)
        end
        bonusGold = bonusGold + math.floor(startGold * (GameRules:GetPlayerGoldMultiplier() - 1))
        if bonusGold > 0 then
            bonusGold = bonusGold + (hero.bonusGoldExcessValue or 0)
            hero.bonusGoldExcessValue = bonusGold % 1
            hero:AddGold(bonusGold, true)
        end
    end
    return true
end

function CHoldoutGameMode:FilterHealing(filterTable)
    local healer_index = filterTable["entindex_healer_const"]
    local target_index = filterTable["entindex_target_const"]

    if not target_index then
        return true
    end
    local target = EntIndexToHScript(target_index)
    filterTable["heal"] = math.min(filterTable["heal"], target:GetMaxHealth())
    if not healer_index then
        return true
    end
    local healer = EntIndexToHScript(healer_index)
    healer.damage_healed_ingame = (healer.damage_healed_ingame or 0) + filterTable["heal"]

    return true
end

IGNORE_SPELL_AMP_KV = {
    ["jakiro_liquid_ice"] = {
        ["pct_health_damage"] = true
    },
    ["sandking_caustic_finale"] = {
        ["caustic_finale_damage_pct"] = true
    },
    ["morphling_adaptive_strike_agi"] = {
        ["damage_min"] = true,
        ["damage_max"] = true
    },
    ["bloodseeker_bloodrage"] = {
        ["shard_max_health_dmg_pct"] = true
    },
    ["bloodseeker_rupture"] = {
        ["hp_pct"] = true
    },
    ["abyssal_underlord_firestorm"] = {
        ["burn_damage"] = true
    },
    ["phoenix_sun_ray"] = {
        ["hp_perc_damage"] = true
    },
    ["venomancer_noxious_plague"] = {
        ["health_damage"] = true
    },
    ["venomancer_poison_nova"] = {
        ["damage"] = true
    },
    ["warlock_fatal_bonds"] = {
        ["damage_share_percentage"] = true
    },
    ["enigma_midnight_pulse"] = {
        ["damage_percent"] = true
    },
    ["enigma_black_hole"] = {
        ["scepter_pct_damage"] = true
    },
    ["obsidian_destroyer_arcane_orb"] = {
        ["mana_pool_damage_pct"] = true
    },
    ["phantom_assassin_fan_of_knives"] = {
        ["pct_health_damage_initial"] = true,
        ["pct_health_damage"] = true
    },
    ["huskar_life_break"] = {
        ["health_cost_percent"] = true,
        ["health_damage"] = true,
        ["tooltip_health_cost_percent"] = true,
        ["tooltip_health_damage"] = true
    },
    ["winter_wyvern_arctic_burn"] = {
        ["percent_damage"] = true
    },
    ["elder_titan_earth_splitter"] = {
        ["damage_pct"] = true
    },
    ["item_orchid"] = {
        ["silence_damage_percent"] = true
    },
    ["item_bloodthorn"] = {
        ["silence_damage_percent"] = true
    },
    ["item_bloodthorn_2"] = {
        ["silence_damage_percent"] = true
    },
    ["item_bloodthorn_3"] = {
        ["silence_damage_percent"] = true
    },
    ["item_bloodthorn_4"] = {
        ["silence_damage_percent"] = true
    },
    ["item_bloodthorn_5"] = {
        ["silence_damage_percent"] = true
    }
}

-- spell_name = spell_amp_reduction (100 for no spell amp)
IGNORE_SPELL_AMP_FILTER = {
    ["muerta_pierce_the_veil"] = 75,
    ["shadow_demon_disseminate"] = 100,
    ["item_revenants_brooch"] = 100,
    ["item_revenants_brooch_2"] = 100,
    ["item_revenants_brooch_3"] = 100,
    ["item_revenants_brooch_4"] = 100,
    ["item_revenants_brooch_5"] = 100,
    ["item_devastator"] = 100,
    ["item_devastator_2"] = 100,
    ["item_devastator_3"] = 100,
    ["item_devastator_4"] = 100,
    ["item_devastator_5"] = 100,
    ["drow_ranger_multishot"] = 100
}

function CHoldoutGameMode:FilterAbilityValues(filterTable)
    if self.preventLoopGarbage then
        return
    end
    local caster_index = filterTable["entindex_caster_const"]
    local ability_index = filterTable["entindex_ability_const"]
    if not caster_index or not ability_index then
        return true
    end
    local ability = EntIndexToHScript(ability_index)
    local caster = EntIndexToHScript(caster_index)

    if ability and IGNORE_SPELL_AMP_KV[ability:GetName()] and
        IGNORE_SPELL_AMP_KV[ability:GetName()][filterTable.value_name_const] then
        local value = filterTable.value
        self.preventLoopGarbage = true
        -- get the real ability value because valve hates me
        local realValue = ability:GetSpecialValueFor(filterTable.value_name_const)
        self.preventLoopGarbage = false
        filterTable.value = realValue / (1 + caster:GetSpellAmplification(false)) - (realValue - value)
    end
    return true
end

function CHoldoutGameMode:FilterDamage(filterTable)
    local total_damage_team = 0
    local dps = 0
    local victim_index = filterTable["entindex_victim_const"]
    local attacker_index = filterTable["entindex_attacker_const"]
    if not victim_index or not attacker_index then
        return true
    end
    local damage = filterTable["damage"] -- Post reduction
    local inflictor = filterTable["entindex_inflictor_const"]
    local victim = EntIndexToHScript(victim_index)
    local attacker = EntIndexToHScript(attacker_index)
    local ability = (inflictor ~= nil) and EntIndexToHScript(inflictor)
    local original_attacker = attacker -- make a copy for threat
    local damagetype = filterTable["damagetype_const"]
    if damage <= 0 then
        return true
    end
    --- DAMAGE MANIPULATION ---
    if ability and IGNORE_SPELL_AMP_FILTER[ability:GetName()] then
        filterTable.damage = damage /
                                 (1 +
                                     (attacker:GetSpellAmplification(false) *
                                         (IGNORE_SPELL_AMP_FILTER[ability:GetName()] / 100)))
    end
    -- MUERTA SPECIFIC FIX
    if ability and ability:GetName() == "muerta_gunslinger" and
        attacker:HasModifier("modifier_muerta_pierce_the_veil_buff") then
        filterTable.damage = damage /
                                 (1 +
                                     (attacker:GetSpellAmplification(false) *
                                         (IGNORE_SPELL_AMP_FILTER["muerta_pierce_the_veil"] / 100)))
    end
    if attacker and attacker:IsRealHero() and ability and ability:GetAbilityDamage() > 0 then
        filterTable.damage = filterTable.damage * (1 + attacker:GetLevel() * 0.2)
    end

    if attacker.GetPlayerOwner and attacker:GetPlayerOwner() and attacker ~= victim then
        local heroToAssign = PlayerResource:GetSelectedHeroEntity(attacker:GetPlayerOwner():GetPlayerID())
        heroToAssign.damage_dealt_ingame = (heroToAssign.damage_dealt_ingame or 0) + filterTable["damage"]
        heroToAssign.last_damage_dealt = filterTable["damage"]
    end
    if victim.GetPlayerOwner and victim:GetPlayerOwner() and attacker ~= victim then
        local heroToAssign = PlayerResource:GetSelectedHeroEntity(victim:GetPlayerOwner():GetPlayerID())
        heroToAssign.damage_taken_ingame = (heroToAssign.damage_taken_ingame or 0) + filterTable["damage"]
    end

    return true
end

function GetHeroDamageDone(hero)
    return hero.damageDone
end

function CHoldoutGameMode:OnAbilityUsed(keys)
    -- will be used in future :p
    local player = PlayerResource:GetPlayer(keys.PlayerID)
    local hero = EntIndexToHScript(keys.caster_entindex)
    local abilityname = keys.abilityname
end

function CHoldoutGameMode:_EnterNG()
    print("Enter NG+ :D")
    self._NewGamePlus = true
    GameRules._NewGamePlus = true
end

function CHoldoutGameMode:OnHeroPick(event)
    local hero = EntIndexToHScript(event.heroindex)
    local playerID = hero:GetPlayerOwnerID()

    -- set hero base stats to their intended values

    if playerID == -1 then
        return
    end
    if PlayerResource:GetSelectedHeroEntity(playerID) and hero ~= PlayerResource:GetSelectedHeroEntity(playerID) then
        return
    end -- ignore non-main units like meepo, spirit bear etc
    hero.damageDone = 0
    hero.Ressurect = 0
    -- stats:ModifyStatBonuses(hero)
    local ID = hero:GetPlayerID()
    hero:SetGold(0, false)
    hero:SetGold(0, true)

    local fountain = nil
    for _, unit in pairs(Entities:FindAllByName("*fountain*")) do
        if unit:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
            fountain = unit
        end
    end

    for i = 0, 10 do
        local ability = hero:GetAbilityByIndex(i)
        if ability and ability:IsInnateAbility() then
            ability:SetLevel(1)
        end
    end

    local courierPosition = hero:GetAbsOrigin()
    if fountain ~= nil then
        courierPosition = fountain:GetAbsOrigin()
    end

    CustomGameEventManager:Send_ServerToAllClients("UpdateLife", {
        life = Life._life
    })

    hero.damage_dealt_ingame = 0
    hero.damage_taken_ingame = 0
    hero.damage_healed_ingame = 0

    print(hero:GetUnitName())
    hero._heroManaType = GameRules.HeroKV[hero:GetUnitName()].ManaType or "Mana"

    if hero:GetManaType() == "Mana" then
        hero:SetBaseManaRegen((hero:GetBaseIntellect() / 5) * 0.04)
    else
        hero:SetBaseManaRegen(0)
    end

    CustomNetTables:SetTableValue("game_stats", tostring(playerID), {
        damage_dealt = 0,
        damage_taken = 0,
        damage_healed = 0,
        last_damage_dealt = 0
    })
    CustomNetTables:SetTableValue("hero_attributes", tostring(hero:entindex()), {
        mana_type = hero._heroManaType,
        strength = hero:GetStrength(),
        agility = hero:GetAgility(),
        intellect = hero:GetIntellect()
    })
    CustomNetTables:SetTableValue("hero_attributes", tostring(hero:entindex()), {
        mana_type = hero._heroManaType,
        strength = hero:GetStrength(),
        agility = hero:GetAgility(),
        intellect = hero:GetIntellect(),
        str_gain = hero:GetStrengthGain(),
        agi_gain = hero:GetAgilityGain(),
        int_gain = hero:GetIntellectGain(),
        spell_amp = hero:GetSpellAmplification(false)
    })

    PlayerResource:SetCustomBuybackCooldown(playerID, 10)
    PlayerResource:SetCustomBuybackCost(playerID, 100)

    -- local tp = hero:FindItemInInventory( "item_tpscroll" )
    -- if tp then
    -- hero:RemoveItem( tp )
    -- end
    hero:AddItemByName("item_bottle_ebf")
    hero:AddItemByName("item_tier1_token")
    -- if PlayerResource:GetPatronTier(playerID) >= 2 then
    -- hero:AddItemByName( "item_aegis" )
    -- end
end

function CHoldoutGameMode:OnHeroLevelUp(event)
    local playerID = EntIndexToHScript(event.player):GetPlayerID()
    local unit = EntIndexToHScript(event.hero_entindex)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if hero == unit then
        if hero:GetLevel() == 17 or hero:GetLevel() == 19 or hero:GetLevel() == 21 or hero:GetLevel() == 22 or
            hero:GetLevel() == 23 or hero:GetLevel() == 24 then
            hero:SetAbilityPoints(hero:GetAbilityPoints() + 1)
        end
        for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
            local item = hero:GetItemInSlot(i)
            if current_item then
                item:OnUnequip()
                item:OnEquip()
                item:RefreshIntrinsicModifier()
            end
        end
        local neutralItem = hero:GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT)
        if neutralItem then
            neutralItem:OnUnequip()
            neutralItem:OnEquip()
            neutralItem:RefreshIntrinsicModifier()
        end
        for i = 0, hero:GetAbilityCount() - 1 do
            local ability = hero:GetAbilityByIndex(i)
            if ability then
                if ability:IsAttributeBonus() then
                    local passive = hero:FindModifierByName(ability:GetIntrinsicModifierName())
                    if passive then
                        passive:Destroy()
                    end
                end
                ability:RefreshIntrinsicModifier()
            end
        end
    end
end

-- Read and assign configurable keyvalues if applicable
function CHoldoutGameMode:_ReadGameConfiguration()
    local kv = LoadKeyValues("scripts/maps/" .. GetMapName() .. ".txt")
    kv = kv or {} -- Handle the case where there is not keyvalues file

    GameRules.BossKV = LoadKeyValues("scripts/npc/units/npc_boss_units.txt")
    print(GameRules.BossKV, "loaded bossKV")

    self._bAlwaysShowPlayerGold = kv.AlwaysShowPlayerGold or false
    self._bRestoreHPAfterRound = kv.RestoreHPAfterRound or false
    self._bRestoreMPAfterRound = kv.RestoreMPAfterRound or false
    self._bRewardForTowersStanding = kv.RewardForTowersStanding or false
    self._bUseReactiveDifficulty = kv.UseReactiveDifficulty or false

    self._flPrepTimeBetweenRounds = tonumber(kv.PrepTimeBetweenRounds or 0)
    self._flItemExpireTime = tonumber(kv.ItemExpireTime or 10.0)

    self:_ReadRandomSpawnsConfiguration(kv["RandomSpawns"])
    self:_ReadLootItemDropsConfiguration(kv["ItemDrops"])
    self:_ReadRoundConfigurations(kv)

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

    local keyLoc = SERVER_LOCATION .. 'keycollection.json'
    local keyRequest = CreateHTTPRequestScriptVM("PUT", keyLoc)
    local keyData = {
        [GetDedicatedServerKeyV3(statSettings.modID)] = true
    }
    local encoded = json.encode(keyData)

    keyRequest:SetHTTPRequestRawPostBody("application/json", encoded)
    keyRequest:Send(function(result)
    end)

    local players = 0
    for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
        if PlayerResource:IsValidPlayerID(nPlayerID) then
            players = players + 1
        end
    end
    local averageMMR = 0
    local mmrTable = {}
    for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
        if PlayerResource:IsValidPlayerID(nPlayerID) then
            mmrTable[nPlayerID] = false
            CustomNetTables:SetTableValue("patrons", tostring(nPlayerID), {
                tier = PlayerResource:GetPatronTier(nPlayerID)
            })
            local AUTH_KEY = GetDedicatedServerKeyV3(statSettings.modID)

            local packageLocation = SERVER_LOCATION .. AUTH_KEY .. "/players/" ..
                                        tostring(PlayerResource:GetSteamID(nPlayerID)) .. '.json'
            local getRequest = CreateHTTPRequestScriptVM("GET", packageLocation)

            local decoded = {}
            getRequest:Send(function(result)
                if tostring(result.Body) ~= 'null' then
                    decoded = json.decode(result.Body)
                end
                mmrTable[nPlayerID] = decoded.mmr or 3000
                averageMMR = averageMMR + mmrTable[nPlayerID]

                if decoded.plays then
                    CustomNetTables:SetTableValue("plays", tostring(nPlayerID), {
                        plays = decoded.plays
                    })
                end
                if decoded.wins then
                    CustomNetTables:SetTableValue("wins", tostring(nPlayerID), {
                        wins = decoded.wins
                    })
                end
            end)
            CustomNetTables:SetTableValue("steamid", tostring(nPlayerID), {
                steamid = PlayerResource:GetSteamID(nPlayerID)
            })
        end
    end
    Timers:CreateTimer(function()
        for playerID, mmr in pairs(mmrTable) do
            if not mmr then -- mmr not gotten yet
                return 0.1
            end
        end
        -- all mmrs gotten
        averageMMR = averageMMR / players
        GameRules._averageMMRForMatch = averageMMR
        for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
            if PlayerResource:IsValidPlayerID(nPlayerID) then
                local playerMultiplier = 1 + (self._MaxPlayers - players) * (50 / (self._MaxPlayers - 1)) / 100
                local mmrPlayer = {
                    mmr = mmrTable[nPlayerID]
                }
                local winMMR = math.floor((10 + GameRules.gameDifficulty * 5) + 0.5)
                local lossMMR = (-2 * winMMR) * ((#self._vRounds - self._nRoundNumber) / #self._vRounds)

                if not IsDedicatedServer() or GameRules:IsCheatMode() or IsInToolsMode() then
                    winMMR = 0
                    lossMMR = 0
                end

                mmrPlayer.win = math.floor(winMMR * playerMultiplier + 0.5)
                mmrPlayer.loss = math.floor(lossMMR / playerMultiplier + 0.5)

                CustomNetTables:SetTableValue("mmr", tostring(nPlayerID), mmrPlayer)
            end
        end
    end)

    -- Function to decode base64
    local function base64decode(data)
        local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        data = string.gsub(data, "[^" .. b .. "=]", "")
        return (data:gsub(".", function(x)
            if x == "=" then
                return ""
            end
            local r, f = "", (b:find(x) - 1)
            for i = 6, 1, -1 do
                r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0")
            end
            return r
        end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
            if #x ~= 8 then
                return ""
            end
            local c = 0
            for i = 1, 8 do
                c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
            end
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
                local lb_mmr_steamID, lb_mmr_mmr, lb_mmr_plays, lb_mmr_wins = line:match(
                    "(%d+),%s*(%d+),%s*(%d+),%s*(%d+)")
                if lb_mmr_steamID and lb_mmr_mmr and lb_mmr_plays and lb_mmr_wins then
                    table.insert(leaderboard_mmr, {
                        steamID = lb_mmr_steamID,
                        mmr = lb_mmr_mmr,
                        plays = lb_mmr_plays,
                        wins = lb_mmr_wins
                    })
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
                    table.insert(leaderboard_wr, {
                        steamID = lb_wr_steamID,
                        mmr = lb_wr_mmr,
                        plays = lb_wr_plays,
                        wins = lb_wr_wins
                    })
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
            CustomNetTables:SetTableValue("game_state", "patchnotes_content", {
                content = result["Body"]
            })
        end
    end)

end

function CHoldoutGameMode:ChooseRandomSpawnInfo()
    if #self._vRandomSpawnsList == 0 then
        error("Attempt to choose a random spawn, but no random spawns are specified in the data.")
        return nil
    end
    return self._vRandomSpawnsList[RandomInt(1, #self._vRandomSpawnsList)]
end

-- Verify valid spawns are defined and build a table with them from the keyvalues file
function CHoldoutGameMode:_ReadRandomSpawnsConfiguration(kvSpawns)
    self._vRandomSpawnsList = {}
    if type(kvSpawns) ~= "table" then
        return
    end
    for _, sp in pairs(kvSpawns) do -- Note "_" used as a shortcut to create a temporary throwaway variable
        table.insert(self._vRandomSpawnsList, {
            szSpawnerName = sp.SpawnerName or "",
            szFirstWaypoint = sp.Waypoint or ""
        })
    end
end

-- If random drops are defined read in that data
function CHoldoutGameMode:_ReadLootItemDropsConfiguration(kvLootDrops)
    self._vLootItemDropsList = {}
    if type(kvLootDrops) ~= "table" then
        return
    end
    for _, lootItem in pairs(kvLootDrops) do
        table.insert(self._vLootItemDropsList, {
            szItemName = lootItem.Item or "",
            nChance = tonumber(lootItem.Chance or 0)
        })
    end
end

-- Set number of rounds without requiring index in text file
function CHoldoutGameMode:_ReadRoundConfigurations(kv)
    self._vRounds = {}
    while true do
        local szRoundName = string.format("Round%d", #self._vRounds + 1)
        local kvRoundData = kv[szRoundName]
        if kvRoundData == nil then
            return
        end
        local roundObj = CHoldoutGameRound()
        roundObj:ReadConfiguration(kvRoundData, self, #self._vRounds + 1)
        table.insert(self._vRounds, roundObj)
    end
end

-- When game state changes set state in script
function CHoldoutGameMode:OnGameRulesStateChange()
    local nNewState = GameRules:State_Get()
    if nNewState == DOTA_GAMERULES_STATE_HERO_SELECTION then
        GameRules.HeroKV = LoadKeyValues("scripts/npc/npc_heroes.txt")
        MergeTables(GameRules.HeroKV, LoadKeyValues("scripts/npc/npc_heroes_custom.txt"))
        local activeList = LoadKeyValues("scripts/npc/herolist.txt")
        local durableHeroes = {}
        local dpsHeroes = {}
        local supportHeroes = {}
        for heroName, available in pairs(activeList) do
            if tonumber(available) > 0 then
                local heroData = GameRules.HeroKV[heroName]
                local roles = splitString(heroData.Role, ",")
                local roleLevel = splitString(heroData.Rolelevels, ",")
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
                    table.insert(dpsHeroes, heroName)
                elseif Durable == "Escape" or highestRole == "Durable" then
                    table.insert(durableHeroes, heroName)
                else
                    table.insert(supportHeroes, heroName)
                end
            end
        end
        local container = {durableHeroes, supportHeroes, dpsHeroes}
        for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
            if PlayerResource:IsValidPlayerID(nPlayerID) then
                for hero, available in pairs(activeList) do
                    if tonumber(available) > 0 then
                        GameRules:AddHeroToPlayerAvailability(nPlayerID, DOTAGameManager:GetHeroIDByName(hero))
                    end
                end
            end
        end

    elseif nNewState == DOTA_GAMERULES_STATE_STRATEGY_TIME then
        GameRules:SetTimeOfDay(0.26)
        for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
            local player = PlayerResource:GetPlayer(nPlayerID)
            if player and not PlayerResource:HasSelectedHero(nPlayerID) then
                player:MakeRandomHeroSelection()
            end
        end
    elseif nNewState == DOTA_GAMERULES_STATE_PRE_GAME then
        if not self._preGameSetupDone then
            GameRules:SetTimeOfDay(0.26)
            if GameRules:IsCheatMode() then
                Say(nil, "type -startgame to start the game", false)
            end
            GameRules.neutralCamps = {
                easy = {},
                medium = {},
                hard = {},
                ancient = {}
            }

            for _, entity in ipairs(Entities:FindAllByClassname("trigger_multiple")) do
                if string.find(entity:GetName(), "easy_camp") then
                    table.insert(GameRules.neutralCamps.easy, entity)
                elseif string.find(entity:GetName(), "medium_camp") then
                    table.insert(GameRules.neutralCamps.medium, entity)
                elseif string.find(entity:GetName(), "hard_camp") then
                    table.insert(GameRules.neutralCamps.hard, entity)
                elseif string.find(entity:GetName(), "ancient_camp") then
                    table.insert(GameRules.neutralCamps.ancient, entity)
                end
            end
            self._preGameSetupDone = true
        end
    elseif nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        GameRules:SpawnNeutralCreeps()
        for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
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
        message = life .. " life has been gained",
        duration = 5
    }
    FireGameEvent("show_center_message", messageinfo)
    Life._life = Life._life + life
    GameRules._live = Life._life
    CustomGameEventManager:Send_ServerToAllClients("UpdateLife", {
        life = Life._life
    })
end

function CHoldoutGameMode:_regenlifecheck()
    if not self._roundsRegened[self._nRoundNumber] and self._nRoundNumber % GameRules._bonusLifeRoundDivider == 0 then
        self._roundsRegened[self._nRoundNumber] = true
        self:AddLife(1)
    end
    if self._regenNG == false and self._NewGamePlus == true then
        self._regenNG = true

		FireGameEvent("show_center_message", messageinfo)
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
    end
end

function CHoldoutGameMode:vote_Round(event)
    local ID = event.pID
    local vote = event.vote
    local player = PlayerResource:GetPlayer(ID)

    if player ~= nil then
        if vote == 1 then
            GameRules.voteRound_Yes = GameRules.voteRound_Yes + 1
            GameRules.voteRound_No = GameRules.voteRound_No - 1

            local event_data = {
                No = GameRules.voteRound_No,
                Yes = GameRules.voteRound_Yes
            }
            CustomGameEventManager:Send_ServerToAllClients("RoundVoteResults", event_data)
        end
    end
end

function CHoldoutGameMode:spawn_unit(place, unitname, radius, unit_number)
    if radius == nil then
        radius = 400
    end
    if core == nil then
        core = false
    end
    if unit_number == nil then
        unit_number = 1
    end
    for i = 0, unit_number - 1 do
        print("spawn unit : " .. unitname)
        PrecacheUnitByNameAsync(unitname, function()
            local unit = CreateUnitByName(unitname, place + RandomVector(RandomInt(radius, radius)), true, nil, nil,
                DOTA_TEAM_NEUTRALS)
            Timers:CreateTimer(0.03, function()
            end)
        end, nil)
    end
end

function CHoldoutGameMode:OnThink()
    if GameRules:State_Get() >= DOTA_GAMERULES_STATE_PRE_GAME and GameRules:State_Get() < DOTA_GAMERULES_STATE_POST_GAME then
        for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
            if PlayerResource:GetTeam(nPlayerID) == DOTA_TEAM_GOODGUYS and PlayerResource:IsValidPlayerID(nPlayerID) then
                if PlayerResource:HasSelectedHero(nPlayerID) then
                    local heroToAssign = PlayerResource:GetSelectedHeroEntity(nPlayerID)
                    if heroToAssign then
                        CustomNetTables:SetTableValue("game_stats", tostring(nPlayerID), {
                            damage_dealt = heroToAssign.damage_dealt_ingame,
                            damage_taken = heroToAssign.damage_taken_ingame,
                            damage_healed = heroToAssign.damage_healed_ingame,
                            last_damage_dealt = heroToAssign.last_damage_dealt
                        })
                    end
                end
            end
        end
    end
    if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        local ThinkDefeat = function()
            self:_CheckForDefeat()
        end
        status, err, ret = xpcall(ThinkDefeat, debug.traceback, self)
        if not status and not self.gameHasBeenBroken then
            self.gameHasBeenBroken = true
            Say(nil, "Bug Report:" .. err, false)
        end

        local ThinkNeutrals = function()
            self:_ManageNeutralScaling()
        end
        status, err, ret = xpcall(ThinkNeutrals, debug.traceback, self)
        if not status and not self.gameHasBeenBroken then
            self.gameHasBeenBroken = true
            Say(nil, "Bug Report:" .. err, false)
        end

        local ThinkLives = function()
            self:_regenlifecheck()
        end
        status, err, ret = xpcall(ThinkLives, debug.traceback, self)
        if not status and not self.gameHasBeenBroken then
            self.gameHasBeenBroken = true
            Say(nil, "Bug Report:" .. err, false)
        end

        local ThinkGeneric = function()
            ResolveNPCPositions(Vector(0, 0), 9999)
            for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
                if PlayerResource:GetTeam(nPlayerID) == DOTA_TEAM_GOODGUYS and PlayerResource:IsValidPlayerID(nPlayerID) then
                    if PlayerResource:HasSelectedHero(nPlayerID) and PlayerResource:GetConnectionState(nPlayerID) ==
                        DOTA_CONNECTION_STATE_DISCONNECTED then -- people that didn't manage to connect in time etc
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
                    GameRules._roundnumber = self._nRoundNumber
                    for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
                        if PlayerResource:GetTeam(nPlayerID) == DOTA_TEAM_GOODGUYS then
                            if PlayerResource:HasSelectedHero(nPlayerID) then
                                PlayerResource:SetCustomBuybackCost(nPlayerID, GameRules._roundnumber * 100)
                                local playerMultiplier = 1 + (self._MaxPlayers - HeroList:GetActiveHeroCount()) *
                                                             (50 / (self._MaxPlayers - 1)) / 100
                                local winMMR = 10 + GameRules.gameDifficulty * 5
                                local lossMMR = winMMR * (-2) * ((#self._vRounds - self._nRoundNumber) / #self._vRounds)
                                local mmrTable = CustomNetTables:GetTableValue("mmr", tostring(nPlayerID))
                                mmrTable.win = math.floor(winMMR * playerMultiplier + 0.5)
                                mmrTable.loss = math.floor(lossMMR / playerMultiplier + 0.5)
                                CustomNetTables:SetTableValue("mmr", tostring(nPlayerID), mmrTable)
                            end
                        end
                    end
					
                    if self._nRoundNumber > #self._vRounds then
                        if not self._NewGamePlus and not GameRules.forceEndTime then
                            self:NewGamePlus_StartVote()
                            for _, hero in ipairs(HeroList:GetRealHeroes()) do
                                if hero:GetPlayerOwner() then
                                    self:RegisterStatsForHero(hero, true)
                                end
                                local playerID = hero:GetPlayerID()
                                local won = true
                                self:RegisterStatsForPlayer(playerID, won)
                            end
                            self:RegisterStatsForRound("won")
                        elseif self._NewGamePlus then
                            GameRules:SetCustomVictoryMessage("Congratulations!")
                            GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
                            GameRules._finish = true
                        end
                    else
                        self._flPrepTimeEnd = GameRules:GetGameTime() + self._flPrepTimeBetweenRounds

                        -- GameRules.voteRound_No = PlayerResource:GetTeamPlayerCount()  --tester
                        GameRules.voteRound_No = self:TeamCount()
                        GameRules.voteRound_Yes = 0

                        CustomGameEventManager:Send_ServerToAllClients("Display_RoundVote", {})
                        local event_data = {
                            No = GameRules.voteRound_No,
                            Yes = GameRules.voteRound_Yes
                        }
                        CustomGameEventManager:Send_ServerToAllClients("RoundVoteResults", event_data)

                        Timers:CreateTimer(1, function()
                            -- if GameRules.voteRound_Yes == PlayerResource:GetTeamPlayerCount() then --tester
                            if GameRules.voteRound_Yes == self:TeamCount() then
                                CustomGameEventManager:Send_ServerToAllClients("Close_RoundVote", {})
                                if self._flPrepTimeEnd ~= nil then
                                    self._flPrepTimeEnd = 0
                                end
                            else
                                return 1
                            end
                        end)
                    end
                end
            elseif (GameRules.forceEndTime and GameRules.forceEndTime < GameRules:GetGameTime()) then
                local yes = 0
                local no = 0
                local idk = 0
                for hero, vote in pairs(GameRules._NGPlusVotes) do
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
                    CustomGameEventManager:Send_ServerToAllClients("epic_boss_fight_ng_vote_update", {
                        active = false
                    })
                else
                    GameRules:SetCustomVictoryMessage("Congratulations!")
                    GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
                    GameRules._finish = true
                end
            end
        end
        status, err, ret = pcall(ThinkGeneric, debug.traceback, self)
        if not status and not self.gameHasBeenBroken then
            self.gameHasBeenBroken = true
            Say(nil, "Bug Report:" .. err, false)
        end
    elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then -- Safe guard catching any state that may exist beyond DOTA_GAMERULES_STATE_POST_GAME
        return nil
    end
    return 0.5
end

function CHoldoutGameMode:RegisterStatsForRound(round)
    if self._statsSentForRound then return end
    self._statsSentForRound = true

    local requestBody = {
        action = "update_round_stats",
        round_number = round,
        difficulty_normal = GameRules.gameDifficulty == 1 and 1 or 0,
        difficulty_hard = GameRules.gameDifficulty == 2 and 1 or 0,
        difficulty_impossible = GameRules.gameDifficulty == 3 and 1 or 0,
        difficulty_challenger = GameRules.gameDifficulty == 4 and 1 or 0,
        difficulty_nightmare = GameRules.gameDifficulty == 5 and 1 or 0
    }

    local request = CreateHTTPRequestScriptVM("POST", "https://mbf2.info/api.php")
    request:SetHTTPRequestRawPostBody("application/json", json.encode(requestBody))
    request:Send(function(response)
        if response.StatusCode ~= 200 then
            -- Handle error
        end
    end)
end

function CHoldoutGameMode:RegisterStatsForPlayer(playerID, bWon, bAbandon)
    self.statsSentForPlayer = self.statsSentForPlayer or {}
    if self.statsSentForPlayer[playerID] then return end
    self.statsSentForPlayer[playerID] = true

    local playerMultiplier = 1 + (self._MaxPlayers - HeroList:GetActiveHeroCount()) * (50 / (self._MaxPlayers - 1)) / 100
    local winMMR = 10 + GameRules.gameDifficulty * 5
    local lossMMR = (-2 * winMMR) * ((#self._vRounds - self._nRoundNumber) / #self._vRounds)
    local winMMR = math.floor(winMMR * playerMultiplier + 0.5)
    local lossMMR = math.floor(lossMMR / playerMultiplier + 0.5)

    local mmrTable = CustomNetTables:GetTableValue("mmr", tostring(playerID))

    local putData = {}
    putData.wins = 0
    putData.plays = 1

    if bAbandon then -- an abandon was registered
        -- ... (existing code for handling abandons)

        putData.mmr = math.max(mmrTable.mmr - 120, -1)
        mmrTable.mmr = putData.mmr
        mmrTable.win = 0
        mmrTable.loss = lossMMR * 3
    else
        if bWon then
            putData.wins = 1
            putData.mmr = mmrTable.mmr + winMMR
            mmrTable.mmr = putData.mmr
            mmrTable.loss = 0
        else
            putData.mmr = math.max(mmrTable.mmr + lossMMR, 0)
            mmrTable.mmr = putData.mmr
            mmrTable.win = 0
        end
    end

    local requestBody = {
        action = "update_player_stats",
        player_id = playerID,
        steam_id = tostring(PlayerResource:GetSteamID(playerID)),
        mmr = putData.mmr,
        plays = putData.plays,
        wins = putData.wins
    }

    local request = CreateHTTPRequestScriptVM("POST", "https://mbf2.info/api.php")
    request:SetHTTPRequestRawPostBody("application/json", json.encode(requestBody))
    request:Send(function(response)
        if response.StatusCode == 200 then
            CustomNetTables:SetTableValue("mmr", tostring(playerID), mmrTable)
        else
            -- Handle error
        end
    end)
end

function CHoldoutGameMode:RegisterStatsForHero( hero, bWon )
    print("Registering stats for hero: " .. hero:GetUnitName())
    
    local heroName = string.gsub(hero:GetUnitName(), "npc_dota_hero_", "")
    print("Hero name: " .. heroName)
    
    self.statsSentForHero = self.statsSentForHero or {}
    if self.statsSentForHero[hero] then
        print("Stats already sent for this hero. Skipping.")
        return
    end
    self.statsSentForHero[hero] = true
    print("Sending stats for hero: " .. heroName)

    local requestBody = {
        hero_name = heroName,
        plays = 1,
        wins = bWon and 1 or 0,
        scepter_plays = hero:HasScepter() and 1 or 0,
        scepter_wins = hero:HasScepter() and bWon and 1 or 0,
        shard_plays = hero:HasShard() and 1 or 0,
        shard_wins = hero:HasShard() and bWon and 1 or 0
    }
    print("Request body:")
    for key, value in pairs(requestBody) do
        print(key .. ": " .. tostring(value))
    end

    local request = CreateHTTPRequestScriptVM("POST", "https://mbf2.info/api.php")
	local requestBody = {
		action = "update_hero_stats",
		hero_name = heroName,
		plays = 1,
		wins = bWon and 1 or 0,
		scepter_plays = hero:HasScepter() and 1 or 0,
		scepter_wins = hero:HasScepter() and bWon and 1 or 0,
		shard_plays = hero:HasShard() and 1 or 0,
		shard_wins = hero:HasShard() and bWon and 1 or 0
	}
	
	local requestBodyJson = json.encode(requestBody)
	
	request:SetHTTPRequestRawPostBody("application/json", requestBodyJson)
    print("Sending POST request to: https://mbf2.info/api.php")
    print("Request action: update_hero_stats")
    print("Request body: " .. json.encode(requestBody))
    
    request:Send(function(response)
        if response.StatusCode == 200 then
            print("Response received. Status code: " .. response.StatusCode)
            print("Response body: " .. response.Body)
        else
            print("Error sending request. Status code: " .. response.StatusCode)
            print("Response body: " .. response.Body)
            -- Handle error
        end
    end)
end

function CHoldoutGameMode:_RefreshPlayers(bWon)
    for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
        if PlayerResource:GetTeam(nPlayerID) == DOTA_TEAM_GOODGUYS then
            if PlayerResource:HasSelectedHero(nPlayerID) then
                local hero = PlayerResource:GetSelectedHeroEntity(nPlayerID)
                if hero ~= nil then
                    hero:Dispel(hero, true)
                    if hero:IsMoving() or hero:IsChanneling() or hero:IsInvulnerable() or hero:IsOutOfGame() then
                        hero:Heal(hero:GetMaxHealth(), nil)
                        hero:GiveMana(hero:GetMaxMana())
                        hero:Dispel(hero, true)
                    else
                        local ogPos = hero:GetAbsOrigin()
                        hero:RespawnHero(false, false)
                        hero:SetAbsOrigin(ogPos)
                        hero:RemoveModifierByName("modifier_fountain_invulnerability")
                    end

                    hero:RefreshAllCooldowns(true)
                    if bWon ~= nil then
                        local hBottle = hero:FindItemInInventory("item_bottle_ebf")
                        if hBottle then
                            local maxCharges = hBottle:GetSpecialValueFor("max_charges")
                            if bWon then
                                hBottle:SetCurrentCharges(math.min(hBottle:GetCurrentCharges() + 1, maxCharges))
                            else
                                hBottle:SetCurrentCharges(maxCharges)
                            end
                        end
                    end
                end
            end
        end
    end
end

function CHoldoutGameMode:_ManageNeutralScaling()
    for campType, camps in pairs(GameRules.neutralCamps) do
        for _, camp in ipairs(camps) do
            local newNeutralsSpawned = false
            for _, unit in ipairs(FindUnitsInRadius(DOTA_TEAM_NEUTRALS, camp:GetAbsOrigin(), nil, 128,
                DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
                if unit:IsNeutralUnitType() and not unit:HasAbility("neutral_upgrade") then
                    if not newNeutralsSpawned then
                        camp.neutralsCreepsSpawnedThisRound = camp.neutralsCreepsSpawnedThisRound or {}
                        table.insert(camp.neutralsCreepsSpawnedThisRound, {})
                        newNeutralsSpawned = true
                    end
                    local upgrader = unit:AddAbility("neutral_upgrade")
                    if camp:IsTouching(unit) then
                        table.insert(camp.neutralsCreepsSpawnedThisRound[#camp.neutralsCreepsSpawnedThisRound], unit)
                        if #camp.neutralsCreepsSpawnedThisRound > 1 then
                            unit:AddNewModifier(unit, nil, "modifier_neutrals_ancestors_rage", {}):SetStackCount(
                                #camp.neutralsCreepsSpawnedThisRound - 1)
                        end
                        if campType == "easy" then
                            unit:SetCoreHealth(unit:GetMaxHealth() + 50)
                            unit:SetAverageBaseDamage(unit:GetAverageBaseDamage() + 1,
                                unit:GetAverageBaseDamageVariance())
                            upgrader:SetLevel(1)
                        elseif campType == "medium" then
                            unit:SetCoreHealth(unit:GetMaxHealth() + 200)
                            unit:SetAverageBaseDamage(unit:GetAverageBaseDamage() + 3,
                                unit:GetAverageBaseDamageVariance())
                            upgrader:SetLevel(2)
                        elseif campType == "hard" then
                            unit:SetCoreHealth(unit:GetMaxHealth() + 350)
                            unit:SetAverageBaseDamage(unit:GetAverageBaseDamage() + 6,
                                unit:GetAverageBaseDamageVariance())
                            upgrader:SetLevel(3)
                        elseif campType == "ancient" then
                            unit:SetCoreHealth(unit:GetMaxHealth() + 500)
                            unit:SetAverageBaseDamage(unit:GetAverageBaseDamage() + 10,
                                unit:GetAverageBaseDamageVariance())
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
    for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
        if PlayerResource:GetTeam(nPlayerID) == DOTA_TEAM_GOODGUYS then
            PlayerNumberRadiant = PlayerNumberRadiant + 1
            if not PlayerResource:HasSelectedHero(nPlayerID) and self._nRoundNumber == 1 and self._currentRound == nil and
                not (PlayerResource:GetConnectionState(nPlayerID) == DOTA_CONNECTION_STATE_ABANDONED or
                    PlayerResource:GetConnectionState(nPlayerID) == DOTA_CONNECTION_STATE_DISCONNECTED) then
                AllRPlayersDead = false
            elseif PlayerResource:HasSelectedHero(nPlayerID) then
                local hero = PlayerResource:GetSelectedHeroEntity(nPlayerID)
                if PlayerResource:GetConnectionState(nPlayerID) == DOTA_CONNECTION_STATE_ABANDONED or
                    (PlayerResource:GetConnectionState(nPlayerID) == DOTA_CONNECTION_STATE_DISCONNECTED and
                        PlayerResource.disconnect[nPlayerID] and PlayerResource.disconnect[nPlayerID] + 5 * 60 <=
                        GameRules:GetGameTime()) then
                    self:RegisterStatsForPlayer(nPlayerID, false, true)
                end
                if hero and hero:NotDead() and PlayerResource:GetConnectionState(nPlayerID) ~=
                    DOTA_CONNECTION_STATE_ABANDONED then
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

    if AllRPlayersDead and PlayerNumberRadiant > 0 then
        if self._check_dead == false then
            self._check_check_dead = false
            Timers:CreateTimer(2.0, function()
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
            CustomGameEventManager:Send_ServerToAllClients("UpdateLife", {
                life = Life._life
            })

            self._check_dead = false
            for _, unit in pairs(Entities:FindAllByName("npc_dota_creature")) do
                if unit:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
                    unit:ForceKill(true)
                end
            end

            if delay ~= nil then
                self._flPrepTimeEnd = GameRules:GetGameTime() + tonumber(delay)
            end
            self:_RefreshPlayers(false)
        else
            self._check_dead = false
        end
    end
end

function CHoldoutGameMode:_OnLose()
    if not self._GameHasFinished then
        if not self._NewGamePlus then
            for _, hero in ipairs(HeroList:GetRealHeroes()) do
                if hero:GetPlayerOwner() then
                    self:RegisterStatsForHero(hero, false)
                end
                self:RegisterStatsForPlayer(hero:GetPlayerID(), false)
            end
            self:RegisterStatsForRound(GameRules._roundnumber)
        end
        Timers:CreateTimer(1.5, function()
            GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
        end)
        self._GameHasFinished = true
    end
end

function CHoldoutGameMode:_ThinkPrepTime()
    if GameRules:GetGameTime() >= self._flPrepTimeEnd then
        -- new
        CustomGameEventManager:Send_ServerToAllClients("Close_RoundVote", {})
        self._flPrepTimeEnd = nil

        if self._nRoundNumber > #self._vRounds then
            GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
            Say(nil,
                "If you wish you can support me on patreon (link in description of the gamemode), anyways, thank for playing <3",
                false)
            return false
        end
        self._currentRound = self._vRounds[self._nRoundNumber]
        self._currentRound:Begin()
        self:_RefreshPlayers()
        GameRules:SpawnNeutralCreeps()
        for campType, camps in pairs(GameRules.neutralCamps) do
            for _, camp in ipairs(camps) do
                camp.neutralsCreepsSpawnedThisRound = nil
            end
        end
        for _, unit in ipairs(FindUnitsInRadius(DOTA_TEAM_NEUTRALS, Vector(0, 0, 0), nil, -1,
            DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
            unit:RemoveModifierByName("modifier_neutrals_ancestors_rage")
        end
        return
    end

    if not self._entPrepTimeQuest then
        self._entPrepTimeQuest = SpawnEntityFromTableSynchronous("quest", {
            name = "PrepTime",
            title = "#DOTA_Quest_Holdout_PrepTime"
        })
        self._entPrepTimeQuest:SetTextReplaceValue(QUEST_TEXT_REPLACE_VALUE_ROUND, self._nRoundNumber)
        self._entPrepTimeQuest:SetTextReplaceString(self:GetDifficultyString())
        self:_RefreshPlayers()
        self._vRounds[self._nRoundNumber]:Precache()
    end
    CustomGameEventManager:Send_ServerToAllClients("UpdateTimeLeft", {
        nextRound = self._nRoundNumber,
        Time = self._flPrepTimeEnd - GameRules:GetGameTime()
    })
    CustomGameEventManager:Send_ServerToAllClients("CurrentRound", {
        roundCurrent = self._nRoundNumber
    })
    self._entPrepTimeQuest:SetTextReplaceValue(QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE,
        self._flPrepTimeEnd - GameRules:GetGameTime())
end

function CHoldoutGameMode:GetDifficultyString()
    local nDifficulty = self:TeamCount()
    if nDifficulty > 10 then
        return string.format("(+%d)", nDifficulty)
    elseif nDifficulty > 0 then
        return string.rep("+", nDifficulty)
    else
        return ""
    end
end

function CHoldoutGameMode:OnNPCSpawned(event)
    local spawnedUnit = EntIndexToHScript(event.entindex)
    if not spawnedUnit or spawnedUnit:GetClassname() == "npc_dota_thinker" or spawnedUnit:IsPhantom() then
        return
    end
    if spawnedUnit:IsCourier() then
        spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_invulnerable", {})
    end
    if spawnedUnit:IsNeutralUnitType() then -- make AI ignore neutrals.
        spawnedUnit:RemoveAbility("neutral_upgrade")
    end
    if spawnedUnit:IsIllusion() then
        --
    end
    if spawnedUnit:IsRealHero() then
        if not spawnedUnit:HasModifier("modifier_thinker_hero_regeneration") then
            spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_thinker_hero_regeneration", {})
        end
        if spawnedUnit:IsTempestDouble() then
            spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_special_bonus_attributes_stat_rescaling", {})
        end
        Timers:CreateTimer(function()
            local invuln = spawnedUnit:FindModifierByName("modifier_fountain_invulnerability")
            if IsModifierSafe(invuln) then
                invuln:SetDuration(10, true)
            end
        end)
        if GameRules.lastManStanding then
            GameRules.lastManStanding:RemoveModifierByName("modifier_last_man_standing")
        end
        if not spawnedUnit.buyBackInitialized and PlayerResource:GetGoldSpentOnBuybacks(spawnedUnit:GetPlayerID()) > 0 then -- only way to detect a buyback...
            spawnedUnit.buyBackInitialized = true
            if GetMapName() == "epic_boss_fight_nightmare" then
                PlayerResource:SetCustomBuybackCooldown(spawnedUnit:GetPlayerID(), 1800)
            else
                PlayerResource:SetCustomBuybackCooldown(spawnedUnit:GetPlayerID(), 180)
            end
        end
    end
end

function CHoldoutGameMode:OnPlayerReconnected(event)
    local nReconnectedPlayerID = event.PlayerID

    local player = PlayerResource:GetPlayer(nReconnectedPlayerID)
    if not PlayerResource:HasSelectedHero(nReconnectedPlayerID) then
        player:MakeRandomHeroSelection()
    end
end


function CHoldoutGameMode:OnEntityKilled(event)
    local killedUnit = EntIndexToHScript(event.entindex_killed)
    local attacker = EntIndexToHScript(event.entindex_attacker)
    if killedUnit.Asura_To_Give ~= nil then
        for _, unit in pairs(Entities:FindAllByName("npc_dota_hero*")) do
            unit.Asura_Core = unit.Asura_Core + killedUnit.Asura_To_Give
        end
    end
    if killedUnit:IsNeutralUnitType() and attacker.GetPlayerID then
        local killingPlayer = attacker:GetPlayerID()
        for _, hero in ipairs(HeroList:GetActiveHeroes()) do
            if hero:GetPlayerID() ~= killingPlayer then
                hero:AddGold(killedUnit:GetGoldBounty())
            end
        end
    end
    if killedUnit and killedUnit:IsRealHero() then
        local livingHeroes = {}
        if HeroList:GetActiveHeroCount() > 1 then
            for _, hero in ipairs(HeroList:GetActiveHeroes()) do
                if hero:IsAlive() then
                    table.insert(livingHeroes, hero)
                end
            end
            if #livingHeroes == 1 then
                GameRules.lastManStanding = livingHeroes[1]
                GameRules.lastManStanding:AddNewModifier(GameRules.lastManStanding, nil, "modifier_last_man_standing",
                    {})
            end
        end
    end
end

function CHoldoutGameMode:TeamCount()
    local counter = 0
    for i = 0, PlayerResource:GetPlayerCount() - 1 do
        if PlayerResource:IsValidPlayerID(i) and PlayerResource:GetConnectionState(i) == DOTA_CONNECTION_STATE_CONNECTED then
            counter = counter + 1
        end
    end
    return counter
end