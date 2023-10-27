require( "libraries/Timers" )
require( "lua_abilities/Check_Aghanim" )

if simple_item == nil then
    print ( '[simple_item] creating simple_item' )
    simple_item = {} -- Creates an array to let us beable to index simple_item when creating new functions
    simple_item.__index = simple_item
    simple_item.midas_gold_on_round = 0
    simple_item._round = 1
end



function refresher( keys )
    local caster = keys.caster
	local item = keys.ability
    
    -- Reset cooldown for abilities
    caster:RefreshAllCooldowns(true)
end

-- Clears the force attack target upon expiration
function BerserkersCallEnd( keys )
    local target = keys.target

    target:SetForceAttackTarget(nil)
end

function simple_item:SetRoundNumer(round)
    simple_item._round = round
    simple_item.midas_gold_on_round = 0
    print (simple_item._round)
end
function simple_item:new() -- Creates the new class
    print ( '[simple_item] simple_item:new' )
    o = o or {}
    setmetatable( o, simple_item )
    return o
end

function simple_item:start() -- Runs whenever the simple_item.lua is ran
    print('[simple_item] simple_item started!')
end

function simple_item:midas_gold(bonus) -- Runs whenever the simple_item.lua is ran
    if simple_item._totalgold == nil then 
        simple_item._totalgold = 0
    end
    simple_item._totalgold = simple_item._totalgold + bonus
	CustomNetTables:SetTableValue("game_stats", "team", {midas_gold_earned = simple_item._totalgold})
end

function Cooldown_powder(keys)
    local item = keys.ability
    local caster = keys.caster
    local dust_effect = ParticleManager:CreateParticle("particles/chronos_powder.vpcf", PATTACH_ABSORIGIN  , caster)
    ParticleManager:SetParticleControl(dust_effect, 0, caster:GetAbsOrigin())
    if GetMapName() == "epic_boss_fight_impossible" or GetMapName() == "epic_boss_fight_challenger" or GetMapName() == "epic_boss_fight_nightmare" then
        item:StartCooldown(45)
    end
    if GetMapName() == "epic_boss_fight_hard" then
        item:StartCooldown(30)
    end
    if GetMapName() == "epic_boss_fight_normal" then
        item:StartCooldown(20)
    end
end

function ares_powder(keys)
    local caster = keys.caster
    local radius = keys.item:GetLevelSpecialValueFor("Radius", 0)
    caster.ennemyunit = FindUnitsInRadius(caster:GetTeam(),
                              caster:GetAbsOrigin(),
                              nil,
                              radius,
                              DOTA_UNIT_TARGET_TEAM_FRIENDLY,
                              DOTA_UNIT_TARGET_ALL,
                              DOTA_UNIT_TARGET_FLAG_NONE,
                              FIND_ANY_ORDER,
                              false)
    for _,unit in pairs(caster.ennemyunit) do
        unit:SetForceAttackTarget(nil)
        if caster:IsAlive() then
            local order = 
            {
                UnitIndex = target:entindex(),
                OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
                TargetIndex = caster:entindex()
            }
            ExecuteOrderFromTable(order)
        else
            unit:Stop()
        end
        unit:SetForceAttackTarget(caster)
    end
end
function ares_powder_end(keys)

    for _,unit in pairs(caster.ennemyunit) do
        unit:SetForceAttackTarget(nil)
    end
end

LinkLuaModifier( "healthBooster", "modifier/healthBooster.lua", LUA_MODIFIER_MOTION_NONE )

function SetCastPoints(keys)
	local caster = keys.caster
    local item = keys.ability
	for i = 0, caster:GetAbilityCount() - 1 do
        local ability = caster:GetAbilityByIndex( i )
        if ability then
			local castPoint = ability:GetCastPoint()
			ability:SetOverrideCastPoint(castPoint * (1 - item:GetSpecialValueFor("bonus_cooldown")/100 ) )
			ability.oldCastPoint = castPoint
        end
    end
end

function ResetCastPoints(keys)
	local caster = keys.caster
    local item = keys.ability
	for i = 0, caster:GetAbilityCount() - 1 do
        local ability = caster:GetAbilityByIndex( i )
        if ability then
			local castPoint = ability.oldCastPoint or ability:GetCastPoint()
			ability:SetOverrideCastPoint(castPoint)
        end
    end
end

function booster_1Test(keys)
    local caster = keys.caster
    local item = keys.ability
    local modifierName = "health_booster"
	local curr_health = caster:GetHealth()
    local health_stacks = caster:GetStrength()
    caster:SetModifierStackCount( modifierName, caster, health_stacks)
	if curr_health > caster:GetHealth() then
		caster:SetHealth(curr_health)
	end

end

function booster_1Apply(keys)
    local caster = keys.caster
    local item = keys.ability
    local modifierName = "health_booster"
	local curr_health = caster:GetHealth()
    local health_stacks = caster:GetStrength()
    item:ApplyDataDrivenModifier( caster, caster, modifierName, {})
    caster:SetModifierStackCount( modifierName, caster, health_stacks)

end

function booster_1(keys)
    local caster = keys.caster
    local item = keys.ability
    local booster = caster:AddNewModifier(hero, item, "healthBooster",{})
	local itemMod = caster:FindModifierByName("booster_effect")
	booster.linkedModifier = itemMod
end
function booster_1_end(keys)
    local caster = keys.caster
    caster:RemoveModifierByName( "healthBooster" )
end

function Have_Item(unit,item_name)
    local haveit = false
    for itemSlot = 0, 5, 1 do
        local Item = unit:GetItemInSlot( itemSlot )
        if Item ~= nil and Item:GetName() == item_name then
            haveit = true
        end
    end
    return haveit
end

function add_soul_charge(keys)
    local caster = keys.caster
    local item = keys.ability

    if caster.Soul_Charge== nil then
        caster.Soul_Charge = 0 
    end
    caster.Soul_Charge = caster.Soul_Charge + 1
    if caster.Soul_Charge == 1 then 
        item:ApplyDataDrivenModifier(caster, caster, "gauntlet_bonus_soul", {})
    end
    caster:SetModifierStackCount( "gauntlet_bonus_soul", caster, caster.Soul_Charge)
    Timers:CreateTimer(20.0,function()
        caster.Soul_Charge = caster.Soul_Charge - 1
        caster:SetModifierStackCount( "gauntlet_bonus_soul", caster, caster.Soul_Charge)
        if caster.Soul_Charge == 0 then
            caster:RemoveModifierByName( "gauntlet_bonus_soul" )
        end
    end)

end

function scale_asura(keys)
    local caster = keys.caster
    local item = keys.ability
    
        Timers:CreateTimer(0.1,function()
                local stack = GameRules._roundnumber
                caster:SetModifierStackCount( "scale_per_round_heart", caster, stack)
                caster:SetModifierStackCount( "scale_per_round_plate", caster, stack)
                caster:SetModifierStackCount( "scale_per_round_rapier", caster, stack)
                caster:SetModifierStackCount( "scale_per_round_staff", caster, stack)
                caster:SetModifierStackCount( "scale_per_round_sword", caster, stack)
				caster:SetModifierStackCount( "scale_per_round_core", caster, stack)
				caster:SetModifierStackCount( "scale_per_round_wand", caster, stack)
                caster:SetModifierStackCount( "scale_display", caster, stack)
                return 0.1
        end)

end

function Berserker(keys)
    local caster = keys.caster
    local target = keys.target
    local item = keys.ability
    caster.check = true
    
    Timers:CreateTimer(0.5,function()
        if HasCustomItem(caster,item) then
            local damage_total = item:GetLevelSpecialValueFor("health_percent_damage", item:GetLevel()-1) * caster:GetHealth() * 0.01
            if caster:GetModifierStackCount( "berserker_bonus_damage", ability ) ~= damage_total and caster.check == true and item ~= nil then
                if not caster:IsIllusion() then
                    item:ApplyDataDrivenModifier(caster, caster, "berserker_bonus_damage", {})
                    caster:SetModifierStackCount( "berserker_bonus_damage", item, damage_total )
                end
            end
            return 0.5
        end
    end)
end

function Berserker_destroy(keys)
    local caster = keys.caster
    local target = keys.target
    local item = keys.ability
    local health_reduction = item:GetLevelSpecialValueFor("health_percent_lose", item:GetLevel()-1) * caster:GetMaxHealth() * 0.01
    caster.check = false
    Timers:CreateTimer(0.1,function()
        caster:SetModifierStackCount( "berserker_bonus_damage", item, 0 )
        caster:RemoveModifierByName( "berserker_bonus_damage" )
    end)
end

function Pierce(keys)
    local caster = keys.caster
    local target = keys.target
    local item = keys.ability
    local percent = item:GetLevelSpecialValueFor("bonus_attack_damage", 0)
    local damage = keys.damage_on_hit*percent*0.01
    local damageTable = {victim = target,
                attacker = caster,
                damage = damage,
                damage_type = DAMAGE_TYPE_PURE,
                }
    ApplyDamage(damageTable)
end

function CD_cuirass_4(keys)
    keys.ability:StartCooldown(33)
end

function CD_Bahamut(keys)
    for _,unit in pairs ( Entities:FindAllByName( "npc_dota_hero*")) do
        if unit:GetTeam() == DOTA_TEAM_GOODGUYS then
            for itemSlot = 0, 5, 1 do --a For loop is needed to loop through each slot and check if it is the item that it needs to drop
                    if unit ~= nil then --checks to make sure the killed unit is not nonexistent.
                        local Item = unit:GetItemInSlot( itemSlot ) -- uses a variable which gets the actual item in the slot specified starting at 0, 1st slot, and ending at 5,the 6th slot.
                        if Item ~= nil and Item:GetName() == "item_cuirass_5" or Item ~= nil and Item:GetName() == "item_asura_plate" then
                            Item:StartCooldown(40)
                        end
                    end
            end
        end
    end
    for _,unit in pairs ( Entities:FindAllByName( "npc_dota_creature")) do
        if unit:GetTeam() == DOTA_TEAM_GOODGUYS and unit:HasInventory() then
            for itemSlot = 0, 5, 1 do --a For loop is needed to loop through each slot and check if it is the item that it needs to drop
                    if unit ~= nil then --checks to make sure the killed unit is not nonexistent.
                        local Item = unit:GetItemInSlot( itemSlot ) -- uses a variable which gets the actual item in the slot specified starting at 0, 1st slot, and ending at 5,the 6th slot.
                        if Item ~= nil and Item:GetName() == "item_cuirass_5" or Item ~= nil and Item:GetName() == "item_asura_plate" then
                            Item:StartCooldown(40)
                        end
                    end
            end
        end
    end
        
end

function CD_pure(keys)
    local CD = keys.cooldown
    if keys.ability:GetCooldownTimeRemaining() <=CD then
        keys.ability:StartCooldown(CD)
    end
end

function ArcticBlast( keys )
    local caster = keys.caster
    local item = keys.ability
	
	local unitsToHit = {}
	local currentRadius = 150
	local endRadius = item:GetSpecialValueFor("blast_radius")
	local blastSpeed = item:GetSpecialValueFor("blast_speed")
	
	local radiusStep = blastSpeed * 0.1
	
	local damage = item:GetSpecialValueFor("blast_damage")
	local active_duration = item:GetSpecialValueFor("blast_debuff_duration")
	
	EmitSoundOn( "DOTA_Item.ShivasGuard.Activate", caster )
	ParticleManager:FireParticle( keys.EffectName or "particles/items2_fx/shivas_guard_active.vpcf", PATTACH_POINT_FOLLOW, caster, {[1] = Vector( endRadius, endRadius / blastSpeed , blastSpeed )})
	Timers:CreateTimer( function()
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), currentRadius ) ) do
			if not unitsToHit[enemy:entindex()] then
				item:DealDamage( caster, enemy, damage, {damage_type = DAMAGE_TYPE_MAGICAL} )
				item:ApplyDataDrivenModifier(caster, enemy, "modifier_cuirass_slow", { duration = active_duration })
				unitsToHit[enemy:entindex()] = true
				ParticleManager:FireParticle( "particles/items2_fx/shivas_guard_impact.vpcf", PATTACH_POINT_FOLLOW, unit )
			end
		end
		if currentRadius < endRadius then
			currentRadius = currentRadius + radiusStep
			return 0.1
		end
	end)
end

function BahaBlast( keys )
    local caster = keys.caster
    local item = keys.ability
	
	local unitsToHit = {}
	local currentRadius = 150
	local endRadius = item:GetSpecialValueFor("blast_radius")
	local blastSpeed = item:GetSpecialValueFor("blast_speed")
	
	local radiusStep = blastSpeed * 0.1
	
	local damage = item:GetSpecialValueFor("blast_damage")
	local active_duration = item:GetSpecialValueFor("blast_debuff_duration")
	local duration = item:GetSpecialValueFor("duration")
	
	EmitSoundOn( "DOTA_Item.ShivasGuard.Activate", caster )
	ParticleManager:FireParticle( keys.EffectName or "particles/items2_fx/shivas_guard_active.vpcf", PATTACH_POINT_FOLLOW, caster, {[1] = Vector( endRadius, endRadius / blastSpeed , blastSpeed )})
	Timers:CreateTimer( function()
		for _, unit in ipairs( caster:FindAllUnitsInRadius( caster:GetAbsOrigin(), currentRadius ) ) do
			if not unitsToHit[unit:entindex()] then
				unitsToHit[unit:entindex()] = true
				if unit:IsSameTeam( caster ) then
					item:ApplyDataDrivenModifier(caster, unit, "modifier_black_king_bar_immune", { duration = duration })
				else
					item:DealDamage( caster, unit, damage, {damage_type = DAMAGE_TYPE_MAGICAL} )
					item:ApplyDataDrivenModifier(caster, unit, "modifier_cuirass_slow", { duration = active_duration })
				end
				ParticleManager:FireParticle( "particles/items2_fx/shivas_guard_impact.vpcf", PATTACH_POINT_FOLLOW, unit )
			end
		end
		if currentRadius < endRadius then
			currentRadius = currentRadius + radiusStep
			return 0.1
		end
	end)
end

function item_blink_boots_check_charge(keys)
	local item = keys.ability

	item:SetCurrentCharges( item:GetCurrentAbilityCharges() )
end

function item_blink_boots_blink(keys)
    local item = keys.ability
    local caster = keys.caster
	
	local nMaxBlink = 1500 
	local nClamp = 1200
	local vPoints = item:GetCursorPosition() 
	
	caster:Blink( item:GetCursorPosition(), {distance = nMaxBlink + caster:GetCastRangeBonus(), clamp = nClamp + caster:GetCastRangeBonus() } )
	
	item:SetCurrentCharges( item:GetCurrentAbilityCharges() )
	
	if not item.checkTimer then
		item.checkTimer = Timers:CreateTimer(0.3,function() 
			if item:GetCurrentCharges() < item:GetMaxAbilityCharges(1) then
				if item:GetCurrentCharges() < item:GetCurrentAbilityCharges() then
					item:SetCurrentCharges(item:GetCurrentAbilityCharges())
				end
				return 0.1
			else
				item.checkTimer = nil
			end
		end)
	end
end


function item_dagon_datadriven_on_spell_start(keys)
    local caster = keys.caster
    local item = keys.ability
    local int_multiplier = item:GetLevelSpecialValueFor("damage_per_int", 0) 
    local damage = caster:GetIntellect() * int_multiplier + item:GetLevelSpecialValueFor("damage_base", 0) 
    
    local dagon_particle = ParticleManager:CreateParticle("particles/dagon_mystic.vpcf",  PATTACH_ABSORIGIN_FOLLOW, keys.caster)
    ParticleManager:SetParticleControlEnt(dagon_particle, 1, keys.target, PATTACH_POINT_FOLLOW, "attach_hitloc", keys.target:GetAbsOrigin(), false)
    local particle_effect_intensity = (200 + caster:GetIntellect()^0.2) --Control Point 2 in Dagon's particle effect takes a number between 400 and 800, depending on its level.
    ParticleManager:SetParticleControl(dagon_particle, 2, Vector(particle_effect_intensity))
    
    keys.caster:EmitSound("DOTA_Item.Dagon.Activate")
    keys.target:EmitSound("DOTA_Item.Dagon5.Target")
        
    ApplyDamage({victim = keys.target, attacker = keys.caster, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL,})
end

function ShowPopup( data )
    if not data then return end

    local target = data.Target or nil
    if not target then error( "ShowNumber without target" ) end
    local number = tonumber( data.Number or nil )
    local pfx = data.Type or "miss"
    local player = data.Player or nil
    local color = data.Color or Vector( 255, 255, 255 )
    local duration = tonumber( data.Duration or 1 )
    local presymbol = tonumber( data.PreSymbol or nil )
    local postsymbol = tonumber( data.PostSymbol or nil )

    local path = "particles/msg_fx/msg_" .. pfx .. ".vpcf"
    local particle = ParticleManager:CreateParticle(path, PATTACH_OVERHEAD_FOLLOW, target)
    if player ~= nil then
        local particle = ParticleManager:CreateParticleForPlayer( path, PATTACH_OVERHEAD_FOLLOW, target, player)
    end

    local digits = 0
    if number ~= nil then digits = #tostring( number ) end
    if presymbol ~= nil then digits = digits + 1 end
    if postsymbol ~= nil then digits = digits + 1 end

    ParticleManager:SetParticleControl( particle, 1, Vector( presymbol, number, postsymbol ) )
    ParticleManager:SetParticleControl( particle, 2, Vector( duration, digits, 0 ) )
    ParticleManager:SetParticleControl( particle, 3, color )
end

function dev_armor(keys)
    local killedUnit = EntIndexToHScript( keys.caster_entindex )
    local origin = killedUnit:GetAbsOrigin()
    Timers:CreateTimer(0.03,function()
        killedUnit:RespawnHero(false, false, false)
        killedUnit:SetAbsOrigin(origin)
    end)

end

function check_admin(keys)
    local caster = keys.caster
    local item = keys.ability
    local ID = caster:GetPlayerID()
    -- if ID ~= nil and PlayerResource:IsValidPlayerID( ID ) then
        -- if PlayerResource:GetSteamAccountID( ID ) == 411522104 then
            -- print ("=)")
        -- else
            -- Timers:CreateTimer(0.3,function()
                -- FireGameEvent( 'custom_error_show', { player_ID = ID, error = "YOU HAVE NO RIGHT TO HAVE THIS ITEM!" } )
                -- caster:RemoveItem(item)
            -- end)
        -- end
    -- end
end



function Midas_OnHit(keys)
    local caster = keys.caster
    local item = keys.ability
    local player = PlayerResource:GetPlayer( caster:GetPlayerID() )
    local damage = keys.damage_on_hit
	local gold_modifier = 5 / HeroList:GetActiveHeroCount()
    local bonus_gold = math.max(1, math.floor( ( 1 + math.log( damage / 200, 2 ) ) * gold_modifier ) )
    local ID = 0
	
    if GetMapName() == "epic_boss_fight_impossible" or GetMapName() == "epic_boss_fight_nightmare" or GetMapName() == "epic_boss_fight_challenger" then
                if simple_item.midas_gold_on_round <= simple_item._round*150 and item:IsCooldownReady() and not caster:IsIllusion() then
                    simple_item:midas_gold(bonus_gold)
                end
    elseif item:IsCooldownReady() and not caster:IsIllusion() then
        simple_item:midas_gold(bonus_gold)
    end
    if item:IsCooldownReady() and not caster:IsIllusion() then
        simple_item.midas_gold_on_round = simple_item.midas_gold_on_round + bonus_gold
        for _,unit in ipairs ( HeroList:GetActiveHeroes() ) do
            if GetMapName() == "epic_boss_fight_impossible" or GetMapName() == "epic_boss_fight_nightmare" or GetMapName() == "epic_boss_fight_challenger" then
                if not unit:IsIllusion() and simple_item.midas_gold_on_round <= simple_item._round*150 then

                    local left_gold = (simple_item._round*150) - simple_item.midas_gold_on_round
                    if caster.show_popup ~= true then
                        caster.show_popup = true
                        SendOverheadEventMessage( nil, OVERHEAD_ALERT_XP, caster, left_gold, caster )
                        Timers:CreateTimer(3.0,function()
                            caster.show_popup = false
                        end)
                    end
					
					local end_bonus_gold = bonus_gold
					if unit:HasAbility("alchemist_goblins_greed") then
						end_bonus_gold = bonus_gold * unit:FindAbilityByName("alchemist_goblins_greed"):GetSpecialValueFor("bonus_gold") 
					end
                    local totalgold = unit:GetGold() + end_bonus_gold
                    unit:SetGold(0 , false)
                    unit:SetGold(totalgold, true)
                end
            else
                if not unit:IsIllusion() then
                    local end_bonus_gold = bonus_gold
					if unit:HasAbility("alchemist_goblins_greed") then
						end_bonus_gold = bonus_gold * unit:FindAbilityByName("alchemist_goblins_greed"):GetSpecialValueFor("bonus_gold") 
					end
                    local totalgold = unit:GetGold() + end_bonus_gold
                    unit:SetGold(0 , false)
                    unit:SetGold(totalgold, true)
                end
            end
        end
    end
end

function Midas2_OnHit(keys)
    local target = keys.target
    local caster = keys.caster
    local item = keys.ability
    local player = PlayerResource:GetPlayer( caster:GetPlayerID() )
    local damage = keys.damage_on_hit
	local gold_modifier = 5 / HeroList:GetActiveHeroCount()
    local bonus_gold = math.max(1, ( 1 + math.log( damage / 150, 2 ) ) * gold_modifier )
    local ID = 0
    if GetMapName() == "epic_boss_fight_impossible" or GetMapName() == "epic_boss_fight_nightmare" or GetMapName() == "epic_boss_fight_challenger" then
                if simple_item.midas_gold_on_round <= simple_item._round*300 and item:IsCooldownReady() and not caster:IsIllusion() then
                    simple_item:midas_gold(bonus_gold)
                end
    elseif item:IsCooldownReady() and not caster:IsIllusion() then
        simple_item:midas_gold(bonus_gold)
    end
    if item:IsCooldownReady() and not caster:IsIllusion() then
        simple_item.midas_gold_on_round = simple_item.midas_gold_on_round + bonus_gold
        for _,unit in pairs ( HeroList:GetActiveHeroes() ) do
            if GetMapName() == "epic_boss_fight_impossible" or GetMapName() == "epic_boss_fight_nightmare" or GetMapName() == "epic_boss_fight_challenger" then
                if not unit:IsIllusion() and simple_item.midas_gold_on_round <= simple_item._round*300 then

                    local left_gold = (simple_item._round*300) - simple_item.midas_gold_on_round
                    if caster.show_popup ~= true then
                        caster.show_popup = true
                        SendOverheadEventMessage( nil, OVERHEAD_ALERT_XP, caster, left_gold, caster )
                        Timers:CreateTimer(3.0,function()
                            caster.show_popup = false
                        end)
                    end

                    local end_bonus_gold = bonus_gold
					if unit:HasAbility("alchemist_goblins_greed") then
						end_bonus_gold = bonus_gold * unit:FindAbilityByName("alchemist_goblins_greed"):GetSpecialValueFor("bonus_gold") 
					end
                    local totalgold = unit:GetGold() + end_bonus_gold
                    unit:SetGold(0 , false)
                    unit:SetGold(totalgold, true)
                end
            else
                if not unit:IsIllusion() then
                    local end_bonus_gold = bonus_gold
					if unit:HasAbility("alchemist_goblins_greed") then
						end_bonus_gold = bonus_gold * unit:FindAbilityByName("alchemist_goblins_greed"):GetSpecialValueFor("bonus_gold") 
					end
                    local totalgold = unit:GetGold() + end_bonus_gold
                    unit:SetGold(0 , false)
                    unit:SetGold(totalgold, true)
                end
            end
        end
    end
end

function Midas3_OnHit(keys)
    local target = keys.target
    local caster = keys.caster
    local item = keys.ability
    local player = PlayerResource:GetPlayer( caster:GetPlayerID() )
    local damage = keys.damage_on_hit
	local gold_modifier = 5 / HeroList:GetActiveHeroCount()
    local bonus_gold = math.max(1, ( 1 + math.log( damage / 100, 2 ) ) * gold_modifier )
    local ID = 0
    if GetMapName() == "epic_boss_fight_impossible" or GetMapName() == "epic_boss_fight_nightmare" or GetMapName() == "epic_boss_fight_challenger" then
                if simple_item.midas_gold_on_round <= simple_item._round*450 and item:IsCooldownReady() and not caster:IsIllusion() then
                    simple_item:midas_gold(bonus_gold)
                end
    elseif item:IsCooldownReady() and not caster:IsIllusion() then
        simple_item:midas_gold(bonus_gold)
    end
    if item:IsCooldownReady() and not caster:IsIllusion() then
        simple_item.midas_gold_on_round = simple_item.midas_gold_on_round + bonus_gold
        for _,unit in pairs ( HeroList:GetActiveHeroes() ) do
            if GetMapName() == "epic_boss_fight_impossible" or GetMapName() == "epic_boss_fight_nightmare" or GetMapName() == "epic_boss_fight_challenger" then
                if not unit:IsIllusion() and simple_item.midas_gold_on_round <= simple_item._round*450 then

                    local left_gold = (simple_item._round*450) - simple_item.midas_gold_on_round
                    if caster.show_popup ~= true then
                        caster.show_popup = true
                        SendOverheadEventMessage( nil, OVERHEAD_ALERT_XP, caster, left_gold, caster )
                        Timers:CreateTimer(3.0,function()
                            caster.show_popup = false
                        end)
                    end

					local end_bonus_gold = bonus_gold
					if unit:HasAbility("alchemist_goblins_greed") then
						end_bonus_gold = bonus_gold * unit:FindAbilityByName("alchemist_goblins_greed"):GetSpecialValueFor("bonus_gold") 
					end
                    local totalgold = unit:GetGold() + end_bonus_gold
                    unit:SetGold(0 , false)
                    unit:SetGold(totalgold, true)
                end
            else
                if not unit:IsIllusion() then
                    local end_bonus_gold = bonus_gold
					if unit:HasAbility("alchemist_goblins_greed") then
						end_bonus_gold = bonus_gold * unit:FindAbilityByName("alchemist_goblins_greed"):GetSpecialValueFor("bonus_gold") 
					end
                    local totalgold = unit:GetGold() + end_bonus_gold
                    unit:SetGold(0 , false)
                    unit:SetGold(totalgold, true)
                end
            end
        end
    end
end

function Berserker_damage(keys)
    local caster = keys.caster
    local target = keys.target
    local item = keys.ability
    local health_reduction = item:GetLevelSpecialValueFor("health_percent_lose", item:GetLevel()-1) * caster:GetHealth() * 0.01

    if caster:IsRealHero() then
        caster:SetHealth( math.max( 1, caster:GetHealth()-health_reduction ) )
    end
end

function Crests(keys)
    local caster = keys.caster
    local target = keys.target
    local item = keys.ability

    local armor_percent = item:GetLevelSpecialValueFor("active_armor_percent", 0) * 0.01
    local active_damage_reduction = item:GetLevelSpecialValueFor("active_damage_reduction", 0)
    local active_duration = item:GetLevelSpecialValueFor("active_duration", 0)

	--local new_armor_target = math.floor(target:GetPhysicalArmorValue() * (armor_percent)) --tester
	--local new_armor_caster = math.floor(caster:GetPhysicalArmorValue() * (armor_percent))
    local new_armor_target = math.floor( target:GetPhysicalArmorBaseValue() * (armor_percent))
    local new_armor_caster = math.floor( caster:GetPhysicalArmorBaseValue() * (armor_percent))

    local armor_modifier = "crest_armor_reduction"
    item:ApplyDataDrivenModifier(caster, target, armor_modifier, { duration = active_duration })
    target:SetModifierStackCount( armor_modifier, item, new_armor_target )


    item:ApplyDataDrivenModifier(caster, caster, armor_modifier, { duration = active_duration })
    caster:SetModifierStackCount( armor_modifier, item, new_armor_caster )
end

function veil(keys)
    local item = keys.ability
    local point = keys.target_points[1]

    local Magical_ress_reduction = item:GetLevelSpecialValueFor("MR_debuff", 0)
    local active_duration = item:GetLevelSpecialValueFor("active_duration", 0)
    local debuff_radius = item:GetLevelSpecialValueFor("debuff_radius", 0)
    local debuff = "veil_debuff"
    local nearbyUnits = FindUnitsInRadius(DOTA_TEAM_NEUTRALS,
                              point,
                              nil,
                              debuff_radius,
                              DOTA_UNIT_TARGET_TEAM_FRIENDLY,
                              DOTA_UNIT_TARGET_ALL,
                              DOTA_UNIT_TARGET_FLAG_NONE,
                              FIND_ANY_ORDER,
                              false)
    local new_armor_target =  0
    for _,unit in pairs(nearbyUnits) do
        --[[if unit.oldMR ~= nil then
            unit.oldMR = (unit:GetBaseMagicalResistanceValue() - unit.lastusedmr)
        end
        unit.oldMR = unit:GetBaseMagicalResistanceValue()
        unit.lastusedmr = Magical_ress_reduction
        ]]
        new_armor_target =  math.floor(unit:GetBaseMagicalResistanceValue()  + Magical_ress_reduction)
        
        unit:SetBaseMagicalResistanceValue(new_armor_target)
        item:ApplyDataDrivenModifier(caster, unit, debuff, { duration = active_duration })
        unit:SetModifierStackCount( debuff, item, 1 )
    end
end

function restoremagicress(keys)
    print ("test")
    local item = keys.ability
    local unit = keys.target
    local Magical_ress_reduction = item:GetLevelSpecialValueFor("MR_debuff", 0)
    --unit.oldMR = true
    unit:SetBaseMagicalResistanceValue(unit:GetBaseMagicalResistanceValue() - Magical_ress_reduction)
end

function Splash(keys)
    local caster = keys.caster
    local target = keys.target
    local item = keys.ability
    local radius = item:GetLevelSpecialValueFor("radius", 0)
    local percent = TernaryOperator( item:GetLevelSpecialValueFor("splash_damage_ranged", 0), caster:IsRangedAttacker(), item:GetLevelSpecialValueFor("splash_damage", 0) )
	
	if percent == 0 then
		percent = item:GetLevelSpecialValueFor("splash_damage", 0)
	end
	
	if caster:IsIllusion() then return end
	
    local damage = keys.damage_on_hit*percent*0.01
	
    for _,unit in ipairs( caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), radius ) ) do
        if unit ~= target then
            local damageTable = {victim = unit,
                        attacker = caster,
                        damage = damage,
                        damage_type = DAMAGE_TYPE_PHYSICAL,
						damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION
                        }
            ApplyDamage(damageTable)
        end
    end
end

function Splash_melee(keys)
    local caster = keys.caster
    local target = keys.target
    local item = keys.ability
    local radius = item:GetLevelSpecialValueFor("radius", 0)
    local percent = item:GetLevelSpecialValueFor("splash_damage", 0)
    local damage = keys.damage_on_hit*percent*0.01
    local nearbyUnits = FindUnitsInRadius(target:GetTeam(),
                              target:GetAbsOrigin(),
                              nil,
                              radius,
                              DOTA_UNIT_TARGET_TEAM_FRIENDLY,
                              DOTA_UNIT_TARGET_ALL,
                              DOTA_UNIT_TARGET_FLAG_NONE,
                              FIND_ANY_ORDER,
                              false)
    if caster:IsRangedAttacker() == false then
        for _,unit in pairs(nearbyUnits) do
            local damageTable = {victim = unit,
                                attacker = caster,
                                damage = damage,
                                damage_type = DAMAGE_TYPE_PURE,
								damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION
                                }
            ApplyDamage(damageTable)
        end
    end
end

function Purge(keys)
	local hardDispel = false
	local caster = keys.caster
	if keys.HardPurge then hardDispel = true end
	caster:Dispel(caster, hardDispel)
end

function MekHeal(keys)	
	keys.caster:EmitSound("DOTA_Item.Mekansm.Activate")
	keys.caster:Purge(false, true, false, false, false)
	ParticleManager:CreateParticle("particles/infernoksm.vpcf", PATTACH_ABSORIGIN_FOLLOW, keys.caster)
	local pct = keys.ability:GetSpecialValueFor("heal_amount_pct") / 100
	local nearby_allied_units = FindUnitsInRadius(keys.caster:GetTeam(), keys.caster:GetAbsOrigin(), nil, keys.HealRadius,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		
	for i, nearby_ally in ipairs(nearby_allied_units) do  --Restore health and play a particle effect for every found ally.
		nearby_ally:Heal(keys.HealAmount + nearby_ally:GetMaxHealth() * pct, keys.ability)
		nearby_ally:GiveMana(keys.ManaAmount)
		
		nearby_ally:EmitSound("DOTA_Item.Mekansm.Target")
		ParticleManager:CreateParticle("particles/infernoksm.vpcf", PATTACH_ABSORIGIN_FOLLOW, nearby_ally)
		
		keys.ability:ApplyDataDrivenModifier(keys.caster, nearby_ally, "modifier_item_mekansm_datadriven_heal_armor", nil)
	end
end

function MekDegen(keys)	
	local degen = keys.ability:GetSpecialValueFor("aura_health_regen")
	ApplyDamage({victim = keys.target, attacker = keys.caster, damage = degen*keys.tick_rate, damage_type = DAMAGE_TYPE_PURE, ability = keys.ability, damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION})
end

function TankSelfHeal(keys)
	local caster = keys.caster
	local item = keys.ability
	
	local selfHeal = item:GetSpecialValueFor("titan_self_heal") / 100
	local radius = item:GetSpecialValueFor("radius")
	caster:EmitSound("Hero_Pugna.LifeDrain.Cast")
	local hp = caster:GetMaxHealth()
	caster:SetHealth(caster:GetHealth() + hp * selfHeal)
	SendOverheadEventMessage( caster, OVERHEAD_ALERT_HEAL , caster, hp * selfHeal, caster )
	local units = FindUnitsInRadius(caster:GetTeam(),
                              caster:GetAbsOrigin(),
                              nil,
                              radius,
                              DOTA_UNIT_TARGET_TEAM_ENEMY,
                              DOTA_UNIT_TARGET_ALL,
                              DOTA_UNIT_TARGET_FLAG_NONE,
                              FIND_ANY_ORDER,
                              false)
	for _,unit in pairs(units) do
		ApplyDamage({victim = unit, attacker = caster, damage = hp * selfHeal / 2, damage_type = DAMAGE_TYPE_PURE, ability = item, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION})
	end
end

function OrchidInit(keys) -- prevent int scaling from messing with my shit
	keys.target.oldhp = keys.target:GetHealth()
	keys.target.orchiddamage = 0
end

function OrchidAmp(keys)
	local target = keys.unit
	if not target:IsAlive() then return end
	if not target.orchiddamage then target.orchiddamage = 0 end
	if not target.oldhp then target.oldhp = target:GetHealth() end
	local damage = target.oldhp - target:GetHealth()
	target.oldhp = target:GetHealth()
	if damage <= 0 then return end
	local amp = keys.ability:GetSpecialValueFor("silence_damage_percent") / 100
	target.orchiddamage = target.orchiddamage + damage * amp
end

function OrchidPop(keys)
	local target = keys.target
	ApplyDamage({victim = keys.target, attacker = keys.caster, damage = target.orchiddamage, damage_type = keys.ability:GetAbilityDamageType(), ability = keys.ability, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION})
	target.orchiddamage = 0
end

function SharedPierce(keys)
    local caster = keys.caster
    local target = keys.target
	if target:IsIllusion() then return end
    local item = keys.ability
    local percent = item:GetLevelSpecialValueFor("target_pierce", 0)
    local damage = (keys.damage_on_hit*percent*0.01)
	if caster:IsIllusion() then
		damage = damage/7
	end
    local damageTable = {victim = target,
                attacker = caster,
                damage = damage,
                damage_type = DAMAGE_TYPE_PURE,
                ability = item,
				damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION
                }
    ApplyDamage(damageTable)
end

function Pierce_Splash(keys)
    local caster = keys.caster
    local target = keys.target
    local item = keys.ability
    local atkDamage = keys.damage_on_hit
	if target:IsIllusion() then return end
    local radius = item:GetSpecialValueFor("radius")
	local percent_p = item:GetSpecialValueFor("bonus_attack_damage") / 100
	local baseDamage = item:GetSpecialValueFor("bonus_chance_damage")
    local damage = keys.damage_on_hit
	local percent = TernaryOperator( item:GetLevelSpecialValueFor("splash_damage_ranged", 0) / 100, caster:IsRangedAttacker(), item:GetLevelSpecialValueFor("splash_damage", 0) / 100 ) * (1 - percent_p)
	
	if percent == 0 then
		percent = item:GetLevelSpecialValueFor("splash_damage", 0)
	end
	
	if caster:IsIllusion() then return end
	
	for _,unit in ipairs( caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), radius ) ) do
		if unit ~= target then
			local damageTable = {
				victim = unit,
				attacker = caster,
				damage = atkDamage*percent + ( atkDamage / unit:GetPhysicalArmorMultiplier() )* percent * percent_p,
				damage_type = DAMAGE_TYPE_PHYSICAL,
				ability = item,
				damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL
			}
			ApplyDamage(damageTable)
		else
			item:DealDamage( caster, target, baseDamage + damage * percent_p, {damage_type = DAMAGE_TYPE_PURE}, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE )
		end
	end
end

function LightningJump(keys)
	local caster = keys.caster
	if caster:IsIllusion() then return end
	local target = keys.target
	local ability = keys.ability
	local jump_delay = 0.25
	local radius = 800
	local jump_damage = ability:GetSpecialValueFor("jump_damage")
	ApplyDamage({victim = target, attacker = caster, damage = jump_damage, damage_type = DAMAGE_TYPE_MAGICAL, ability = ability,})
	target:RemoveModifierByName("modifier_arc_lightning_hammer")
	
	-- Waits on the jump delay
	Timers:CreateTimer(jump_delay,
    function()
		-- Finds the current instance of the ability by ensuring both current targets are the same
		local current
		for i=0,ability.instance do
			if ability.target[i] ~= nil then
				if ability.target[i] == target then
					current = i
				end
			end
		end
	
		-- Adds a global array to the target, so we can check later if it has already been hit in this instance
		if target.hit == nil then
			target.hit = {}
		end
		-- Sets it to true for this instance
		target.hit[current] = true
	
		-- Decrements our jump count for this instance
		ability.jump_count[current] = ability.jump_count[current] - 1
	
		-- Checks if there are jumps left
		if ability.jump_count[current] > 0 then
			-- Finds units in the radius to jump to
			local units = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE , 0, false)
			local closest = radius
			local new_target
			for i,unit in ipairs(units) do
				-- Positioning and distance variables
				local unit_location = unit:GetAbsOrigin()
				local vector_distance = target:GetAbsOrigin() - unit_location
				local distance = (vector_distance):Length2D()
				-- Checks if the unit is closer than the closest checked so far
				if distance < closest then
					-- If the unit has not been hit yet, we set its distance as the new closest distance and it as the new target
					if unit.hit == nil then
						new_target = unit
						closest = distance
					elseif unit.hit[current] == nil then
						new_target = unit
						closest = distance
					end
				end
			end
			-- Checks if there is a new target
			if new_target ~= nil then
				-- Creates the particle between the new target and the last target
				local lightningBolt = ParticleManager:CreateParticle(keys.particle, PATTACH_WORLDORIGIN, target)
				ParticleManager:SetParticleControl(lightningBolt,0,Vector(target:GetAbsOrigin().x,target:GetAbsOrigin().y,target:GetAbsOrigin().z + target:GetBoundingMaxs().z ))   
				ParticleManager:SetParticleControl(lightningBolt,1,Vector(new_target:GetAbsOrigin().x,new_target:GetAbsOrigin().y,new_target:GetAbsOrigin().z + new_target:GetBoundingMaxs().z ))
				-- Sets the new target as the current target for this instance
				ability.target[current] = new_target
				-- Applies the modifer to the new target, which runs this function on it
				ability:ApplyDataDrivenModifier(caster, new_target, "modifier_arc_lightning_hammer", {})
			else
				-- If there are no new targets, we set the current target to nil to indicate this instance is over
				ability.target[current] = nil
			end
		else
			-- If there are no more jumps, we set the current target to nil to indicate this instance is over
			ability.target[current] = nil
		end
	end)
end

function NewInstance(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	
	if caster:IsIllusion() then return end
	
	-- Keeps track of the total number of instances of the ability (increments on cast)
	if ability.instance == nil then
		ability.instance = 0
		ability.jump_count = {}
		ability.target = {}
	else
		ability.instance = ability.instance + 1
	end
	
	-- Sets the total number of jumps for this instance (to be decremented later)
	ability.jump_count[ability.instance] = ability:GetLevelSpecialValueFor("jump_count", (ability:GetLevel() -1))
	-- Sets the first target as the current target for this instance
	ability.target[ability.instance] = target
	
	-- Creates the particle between the caster and the first target
	local lightningBolt = ParticleManager:CreateParticle(keys.particle, PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(lightningBolt,0,Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z + caster:GetBoundingMaxs().z ))   
    ParticleManager:SetParticleControl(lightningBolt,1,Vector(target:GetAbsOrigin().x,target:GetAbsOrigin().y,target:GetAbsOrigin().z + target:GetBoundingMaxs().z ))   
end

function scythe_decay(keys)
    local item = keys.ability
	local target = keys.target
	local magic_reduction = math.abs(keys.magic_reduction)
    local new_armor_target =  math.floor(target:GetBaseMagicalResistanceValue() - magic_reduction)
    target:SetBaseMagicalResistanceValue(new_armor_target)
    end