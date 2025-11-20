mars_arena_of_blood = class({})

function mars_arena_of_blood:IsStealable()
	return true
end

function mars_arena_of_blood:IsHiddenWhenStolen()
	return false
end

function mars_arena_of_blood:GetAOERadius()	
	return self:GetSpecialValueFor("radius")		
end

function mars_arena_of_blood:OnUpgrade()
	local caster = self:GetCaster()
	local bulwark = caster:FindAbilityByName("mars_bulwark")
	if bulwark then
		bulwark._marsSoldiers = {}
		local soldiers = self:GetSpecialValueFor("bulwark_soldier_count")
		local soldierOffset = self:GetSpecialValueFor("bulwark_soldier_offset")
		for i = 1, soldiers do
			local soldier= CreateUnitByName( "aghsfort_mars_bulwark_soldier", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeam() )
			soldier:AddNewModifier( caster, self, "modifier_mars_arena_of_blood_mars_soldier", {} )
			soldier._isCurrentlyActive = false
			soldier._soldierOffset = math.ceil(i/2) * soldierOffset * (-1)^i
			soldier:AddNoDraw()
			table.insert( bulwark._marsSoldiers, soldier )
		end
	end
	-- setup assistants
	if not self._fakeWarriors then
		self._fakeWarriors = {}
		for i = 1, 14 do
			CreateUnitByNameAsync( "npc_dota_practice_hero", Vector(0,0,0), true, nil, nil, self:GetTeam(), function( dummy )
				dummy.hasBeenProcessed = true
				dummy._healthBarDummy = true
				dummy:SetOriginalModel("models/development/invisiblebox.vmdl")
				dummy:SetModel("models/development/invisiblebox.vmdl")
				dummy:AddNewModifier(caster, self, "modifier_mars_arena_of_blood_mars_soldier", {})
				table.insert( self._fakeWarriors, dummy ) 
			end )
		end
	end
	if not self._obstacleBlockers then
		self._obstacleBlockers = {}
		for i = 1, 28 do
			CreateUnitByNameAsync( "npc_dota_practice_hero", Vector(0,0,0), true, nil, nil, DOTA_TEAM_BADGUYS, function( dummy )
				dummy.hasBeenProcessed = true
				dummy._healthBarDummy = true
				dummy:AddNoDraw()
				dummy:AddNewModifier(caster, self, "modifier_hidden_generic", {})
				table.insert( self._obstacleBlockers, dummy )
			end )
		end
	end
end

function mars_arena_of_blood:OnSpellStart()			
	-- Ability properties
	local target_point = self:GetCursorPosition()
	local caster = self:GetCaster()		

	local formation_time = self:GetSpecialValueFor("formation_time")
	local duration = self:GetSpecialValueFor("duration")
	local radius = self:GetSpecialValueFor("radius")

	EmitSoundOnLocationWithCaster(target_point, "Hero_Mars.ArenaOfBlood.Start", caster)

	local thinker = CreateModifierThinker(caster, self, "modifier_mars_arena_of_blood_thinker", {duration = formation_time+duration}, target_point, caster:GetTeamNumber(), true)
	thinker:AddNewModifier(caster, self, "modifier_hidden_generic", {})
	-- Wait for formation to finish setting up
	Timers:CreateTimer(formation_time, function()
		-- Apply thinker modifier on target location
		EmitSoundOnLocationWithCaster(target_point, "Hero_Mars.ArenaOfBlood", caster)
		-- create dummies for spear
		local initialDirection = Vector(0,1,0)
		for i, dummy in ipairs( self._obstacleBlockers ) do
			local position = target_point + RotateVector2D(initialDirection, ToRadians( (360 / #self._obstacleBlockers) * (i-1) ) ) * radius
			dummy:SetAbsOrigin( position )
		end
		for i, dummy in ipairs( self._fakeWarriors ) do
			local position = target_point + RotateVector2D(initialDirection, ToRadians( (360 / #self._fakeWarriors) * (i-1) ) ) * radius
			dummy:SetAbsOrigin( position )
			dummy:SetForwardVector( CalculateDirection( target_point, dummy ) )
		end
		local aura = CreateModifierThinker(caster, self, "modifier_mars_arena_of_blood_damage_reduction", {duration = duration}, target_point, caster:GetTeamNumber(), true)
		aura:AddNewModifier(caster, self, "modifier_hidden_generic", {})
	end)
end

---------------------------------------------------
--				Arena modifier
---------------------------------------------------
modifier_mars_arena_of_blood_damage_reduction = class({})
LinkLuaModifier("modifier_mars_arena_of_blood_damage_reduction", "heroes/hero_mars/mars_arena_of_blood.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_mars_arena_of_blood_damage_reduction:IsHidden() return true end

function modifier_mars_arena_of_blood_damage_reduction:OnCreated(keys)
	self.radius = self:GetAbility():GetSpecialValueFor("radius")
	self.spear_replicate = self:GetAbility():GetSpecialValueFor("spear_replicate")
end

function modifier_mars_arena_of_blood_damage_reduction:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ABILITY_FULLY_CAST}
end

function modifier_mars_arena_of_blood_damage_reduction:OnAbilityFullyCast( params )
	local caster = self:GetCaster()
	if params.unit ~= caster then return end
	if params.ability:GetAbilityName() == "mars_spear" then
		local spears = self.spear_replicate
		local enemies = caster:FindEnemyUnitsInRadius( self:GetParent():GetAbsOrigin(), self.radius )
		for _, enemy in ipairs( enemies ) do
			local randomWarrior = self:GetAbility()._fakeWarriors[RandomInt( 1, #self:GetAbility()._fakeWarriors )]
			params.ability:LaunchSpear( randomWarrior, CalculateDirection( enemy, randomWarrior), true )
			spears = spears - 1
			if spears <= 0 then
				return
			end
		end
	elseif params.ability:GetAbilityName() == "mars_gods_rebuke" then
		for _, warrior in ipairs( self:GetAbility()._fakeWarriors ) do
			params.ability:Rebuke( warrior, self:GetParent():GetAbsOrigin(), true )
		end
	end
end

function modifier_mars_arena_of_blood_damage_reduction:IsAura()
    return true
end

function modifier_mars_arena_of_blood_damage_reduction:GetAuraDuration()
    return 0.5
end

function modifier_mars_arena_of_blood_damage_reduction:GetAuraRadius()
    return self.radius
end

function modifier_mars_arena_of_blood_damage_reduction:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_mars_arena_of_blood_damage_reduction:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_mars_arena_of_blood_damage_reduction:GetModifierAura()
    return "modifier_mars_arena_of_blood_aura_buff"
end

function modifier_mars_arena_of_blood_damage_reduction:IsAuraActiveOnDeath()
    return false
end

--Caster buff
modifier_mars_arena_of_blood_aura_buff = class({})
LinkLuaModifier("modifier_mars_arena_of_blood_aura_buff", "heroes/hero_mars/mars_arena_of_blood.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_mars_arena_of_blood_aura_buff:IsDebuff() return false end

function modifier_mars_arena_of_blood_aura_buff:OnCreated(table)
	self.damage_amplification = self:GetSpecialValueFor("damage_amplification")
	self.damage_reduction = -self:GetSpecialValueFor("damage_reduction")
	self.max_health_regen = self:GetSpecialValueFor("max_health_regen")
	self.attack_speed_increase = self:GetSpecialValueFor("attack_speed_increase")
	if IsServer() and self.attack_speed_increase > 0 then
		self:StartIntervalThink( 1 )
	end
end

function modifier_mars_arena_of_blood_aura_buff:OnIntervalThink()
	self:IncrementStackCount()
end

function modifier_mars_arena_of_blood_aura_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT 
	}

	return funcs
end

function modifier_mars_arena_of_blood_aura_buff:GetModifierIncomingDamage_Percentage()
	return self.damage_reduction
end

function modifier_mars_arena_of_blood_aura_buff:GetModifierTotalDamageOutgoing_Percentage()
	return self.damage_amplification
end

function modifier_mars_arena_of_blood_aura_buff:GetModifierHealthRegenPercentage()
	return self.max_health_regen
end

function modifier_mars_arena_of_blood_aura_buff:GetModifierAttackSpeedBonus_Constant()
	return self.attack_speed_increase * self:GetStackCount()
end

function modifier_mars_arena_of_blood_aura_buff:GetActivityTranslationModifiers()
	return "arena_of_blood"
end

function modifier_mars_arena_of_blood_aura_buff:GetEffectName()
	return "particles/units/heroes/hero_mars/mars_arena_of_blood_heal.vpcf"
end

modifier_mars_arena_of_blood_mars_soldier = class({})
LinkLuaModifier("modifier_mars_arena_of_blood_mars_soldier", "heroes/hero_mars/mars_arena_of_blood.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_mars_arena_of_blood_mars_soldier:CheckState()
	return {[MODIFIER_STATE_ROOTED] = true,
			[MODIFIER_STATE_DISARMED] = true,
			[MODIFIER_STATE_INVULNERABLE] = true,
			[MODIFIER_STATE_UNSELECTABLE] = true,
			[MODIFIER_STATE_CANNOT_MISS] = true,
			[MODIFIER_STATE_NO_HEALTH_BAR] = true,
			[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			[MODIFIER_STATE_UNTARGETABLE] = true,
			[MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
			[MODIFIER_STATE_ALLOW_PATHING_THROUGH_BASE_BLOCKER] = true,
			}
end