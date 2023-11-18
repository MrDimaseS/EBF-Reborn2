pugna_decrepify = class({})

function pugna_decrepify:GetBehavior()
	local behavior = DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK +  DOTA_ABILITY_BEHAVIOR_IGNORE_CHANNEL
	if self:GetSpecialValueFor("radius") > 0 then
		behavior = behavior + DOTA_ABILITY_BEHAVIOR_AOE
	end
	return behavior
end

function pugna_decrepify:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function pugna_decrepify:OnSpellStart()
	local caster = self:GetCaster()
	local hTarget = self:GetCursorTarget()
	
	local duration = self:GetSpecialValueFor("AbilityDuration")
	local radius = self:GetSpecialValueFor("radius")
	
	
	local lifeDrain = caster:FindAbilityByName("pugna_life_drain")
	local triggerForHero = true
	local lifeDrainTargets
	if lifeDrain:IsTrained() and lifeDrain:IsCooldownReady() and not caster:PassivesDisabled() then
		lifeDrainTargets = {}
	end
	
	if caster:GetTeam() == hTarget:GetTeam() then
		hTarget:AddNewModifier(caster, self, "modifier_pugna_decrepify_ally", {duration = duration})
	elseif not hTarget:TriggerSpellAbsorb( self ) then
		hTarget:AddNewModifier(caster, self, "modifier_pugna_decrepify_enemy", {duration = duration})
		if lifeDrainTargets then
			table.insert( lifeDrainTargets, hTarget )
		end
	end
	EmitSoundOn("Hero_Pugna.Decrepify", hTarget)
	if radius > 0 then
		for _, unit in ipairs( caster:FindAllUnitsInRadius( hTarget:GetAbsOrigin(), radius ) ) do
			if unit ~= hTarget then
				if caster:IsSameTeam( unit ) then
					unit:AddNewModifier(caster, self, "modifier_pugna_decrepify_ally", {duration = duration})
				elseif not unit:TriggerSpellAbsorb( self ) then
					unit:AddNewModifier(caster, self, "modifier_pugna_decrepify_enemy", {duration = duration})
					if lifeDrainTargets then
						table.insert( lifeDrainTargets, unit )
					end
				end
			end
		end
	end
	if lifeDrainTargets and #lifeDrainTargets > 0 then
		for _, unit in ipairs( lifeDrainTargets ) do
			if not unit:IsConsideredHero() or triggerForHero then
				lifeDrain:ApplyLifeDrain(unit)
				if triggerForHero and unit:IsConsideredHero() then
					triggerForHero = false
				end
			end
		end
		lifeDrain:SetCooldown()
	end
end

LinkLuaModifier( "modifier_pugna_decrepify_ally", "heroes/hero_pugna/pugna_decrepify" ,LUA_MODIFIER_MOTION_NONE )
modifier_pugna_decrepify_ally = class({})

function modifier_pugna_decrepify_ally:OnCreated()
	self:OnRefresh()
end

function modifier_pugna_decrepify_ally:OnRefresh()
	self.heal_amp = self:GetAbility():GetSpecialValueFor("bonus_heal_amp_pct_allies")
	self.slow = self:GetAbility():GetSpecialValueFor("bonus_movement_speed_allies")
end

function modifier_pugna_decrepify_ally:CheckState()
    local state = {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
	}
	return state
end

function modifier_pugna_decrepify_ally:DeclareFunctions()
	local funcs = { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
					MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL, 
					MODIFIER_PROPERTY_EVASION_CONSTANT,
					MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
					MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
					MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET }
	return funcs
end

function modifier_pugna_decrepify_ally:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

function modifier_pugna_decrepify_ally:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_pugna_decrepify_ally:GetModifierEvasion_Constant()
	return 100
end

function modifier_pugna_decrepify_ally:GetModifierHealAmplify_PercentageTarget()
	return self.heal_amp
end

function modifier_pugna_decrepify_ally:GetModifierHPRegenAmplify_Percentage()
	return self.heal_amp
end

function modifier_pugna_decrepify_ally:GetEffectName()
	return "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf"
end

function modifier_pugna_decrepify_ally:GetStatusEffectName()
	return "particles/status_fx/status_effect_ghost.vpcf"
end

function modifier_pugna_decrepify_ally:StatusEffectPriority()
	return 15
end

LinkLuaModifier( "modifier_pugna_decrepify_enemy", "heroes/hero_pugna/pugna_decrepify" ,LUA_MODIFIER_MOTION_NONE )
modifier_pugna_decrepify_enemy = class({})

function modifier_pugna_decrepify_enemy:OnCreated()
	self.magic_damage = self:GetAbility():GetSpecialValueFor("bonus_spell_damage_pct")
	self.slow = self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
end

function modifier_pugna_decrepify_enemy:OnRefresh()
	self.magic_damage = self:GetAbility():GetSpecialValueFor("bonus_spell_damage_pct")
	self.slow = self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
end

function modifier_pugna_decrepify_enemy:CheckState()
    local state = {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_DISARMED] = true,
	}
	return state
end

function modifier_pugna_decrepify_enemy:DeclareFunctions()
	funcs = { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			  MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DECREPIFY_UNIQUE }
	return funcs
end

function modifier_pugna_decrepify_enemy:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

function modifier_pugna_decrepify_enemy:GetModifierMagicalResistanceDecrepifyUnique()
	return self.magic_damage
end

function modifier_pugna_decrepify_enemy:GetEffectName()
	return "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf"
end

function modifier_pugna_decrepify_enemy:GetStatusEffectName()
	return "particles/status_fx/status_effect_ghost.vpcf"
end

function modifier_pugna_decrepify_enemy:StatusEffectPriority()
	return 15
end