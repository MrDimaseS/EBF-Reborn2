mars_arena_of_blood = class({})


function mars_arena_of_blood:IsStealable()
	return true
end

function mars_arena_of_blood:IsHiddenWhenStolen()
	return false
end

function mars_arena_of_blood:GetAOERadius()	
	return self:GetTalentSpecialValueFor("radius")		
end

function mars_arena_of_blood:OnSpellStart()			
	-- Ability properties
	local target_point = self:GetCursorPosition()
	local caster = self:GetCaster()		

	local formation_time = self:GetTalentSpecialValueFor("formation_time")
	local duration = self:GetTalentSpecialValueFor("duration")
	local radius = self:GetTalentSpecialValueFor("radius")

	EmitSoundOnLocationWithCaster(target_point, "Hero_Mars.ArenaOfBlood.Start", caster)

	local thinker = CreateModifierThinker(caster, self, "modifier_mars_arena_of_blood_thinker", {duration = formation_time+duration}, target_point, caster:GetTeamNumber(), true)
	thinker:AddNewModifier(caster, self, "modifier_hidden_generic", {})
	-- Wait for formation to finish setting up
	Timers:CreateTimer(formation_time, function()
		-- Apply thinker modifier on target location
		EmitSoundOnLocationWithCaster(target_point, "Hero_Mars.ArenaOfBlood", caster)
		-- create dummies for spear
		local offset = 360 / 28
		local initialDirection = Vector(0,1,0)
		for i = 1, 28 do
			local position = target_point + RotateVector2D(initialDirection, ToRadians( offset * (i-1) ) ) * radius
			dummy = CreateUnitByName("npc_dota_practice_hero", position, false, nil, nil, DOTA_TEAM_BADGUYS)
			
			dummy:AddNoDraw()
			dummy:AddNewModifier(caster, self, "modifier_kill", {duration = duration})
			dummy:AddNewModifier(caster, self, "modifier_hidden_generic", {})
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
	self.radius = self:GetAbility():GetTalentSpecialValueFor("radius")
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

function modifier_mars_arena_of_blood_damage_reduction:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_mars_arena_of_blood_damage_reduction:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_mars_arena_of_blood_damage_reduction:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
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
	local caster = self:GetCaster()
	self.damage_amplification = self:GetTalentSpecialValueFor("damage_amplification")
	self.damage_reduction = self:GetTalentSpecialValueFor("damage_reduction")
end

function modifier_mars_arena_of_blood_aura_buff:OnIntervalThink()
	local parent = self:GetParent()
	for i = 0, parent:GetAbilityCount() - 1 do
		local ability = parent:GetAbilityByIndex( i )
		if ability and not ability:IsCooldownReady() then
			ability:ModifyCooldown( -self.cdr  )
		end
	end
end

function modifier_mars_arena_of_blood_aura_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
	}

	return funcs
end

function modifier_mars_arena_of_blood_aura_buff:GetModifierIncomingDamage_Percentage()
	return self.damage_reduction
end

function modifier_mars_arena_of_blood_aura_buff:GetModifierTotalDamageOutgoing_Percentage()
	return self.damage_amplification
end

function modifier_mars_arena_of_blood_aura_buff:GetActivityTranslationModifiers()
	return "arena_of_blood"
end

function modifier_mars_arena_of_blood_aura_buff:GetEffectName()
	return "particles/units/heroes/hero_mars/mars_arena_of_blood_heal.vpcf"
end