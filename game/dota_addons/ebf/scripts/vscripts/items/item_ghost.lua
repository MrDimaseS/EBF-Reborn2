item_ghost = class({})

function item_ghost:GetIntrinsicModifierName()
	return "modifier_item_ghost_passive"
end

function item_ghost:OnSpellStart()
	local caster = self:GetCaster()
	
	caster:AddNewModifier( caster, self, "modifier_item_ghost_form_ally", {duration = self:GetSpecialValueFor("duration")} )
	EmitSoundOn( "DOTA_Item.GhostScepter.Activate", caster )
end

item_ethereal_blade = class({})

function item_ethereal_blade:GetAOERadius()
	return self:GetSpecialValueFor("bounce_radius") + self:GetSpecialValueFor("bonus_aoe")
end

function item_ethereal_blade:GetIntrinsicModifierName()
	return "modifier_item_ethereal_blade_passive"
end

function item_ethereal_blade:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	self.bounceProjectile = true
	local projectile = self:FireTrackingProjectile(self:GetProjectileFXName(), target, self:GetSpecialValueFor("projectile_speed"))
	EmitSoundOn( self:GetCastSoundName(), caster )
end

function item_ethereal_blade:GetProjectileFXName()
	return "particles/items_fx/ethereal_blade.vpcf"
end

function item_ethereal_blade:GetCastSoundName()
	return "DOTA_Item.EtherealBlade.Activate"
end

function item_ethereal_blade:GetTargetSoundName()
	return  "DOTA_Item.EtherealBlade.Target"
end

function item_ethereal_blade:GetAlliedModifierName()
	return "modifier_item_ghost_form_ally"
end

function item_ethereal_blade:GetEnemyModifierName()
	return "modifier_item_ghost_form_enemy"
end

function item_ethereal_blade:OnProjectileHit( target, position )
	if target then
		local caster = self:GetCaster()
		
		local modifierName = TernaryOperator( self:GetAlliedModifierName(), caster:IsSameTeam( target ), self:GetEnemyModifierName() )
		target:AddNewModifier( caster, self, modifierName, {duration = self:GetSpecialValueFor("duration")} )
		EmitSoundOn( self:GetTargetSoundName(), target )
		
		if not caster:IsSameTeam( target ) then
			self:DealDamage( caster, target, caster:GetPrimaryStatValue() * self:GetSpecialValueFor("blast_agility_multiplier") + self:GetSpecialValueFor("blast_damage_base") )
		elseif tonumber(self:GetSpecialValueFor("allies_benefit")) == 1 then
			target:HealEvent( caster:GetPrimaryStatValue() * self:GetSpecialValueFor("blast_agility_multiplier") + self:GetSpecialValueFor("blast_damage_base"), self, caster )
		end
		local bounceRadius = self:GetSpecialValueFor("bounce_radius")
		if bounceRadius > 0 and self.bounceProjectile then
			self.bounceProjectile = false
			local units = caster:FindFriendlyUnitsInRadius( target:GetAbsOrigin(), bounceRadius )
			if caster:IsSameTeam( target ) then
				units = caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), bounceRadius )
			end
			local newTarget = units[1]
			if newTarget then
				local projectile = self:FireTrackingProjectile(self:GetProjectileFXName(), newTarget, self:GetSpecialValueFor("projectile_speed"), {source = target})
				EmitSoundOn( self:GetCastSoundName(), target )
			end
		end
	end
end

item_ethereal_blade_2 = class(item_ethereal_blade)
item_ethereal_blade_3 = class(item_ethereal_blade)
item_ethereal_blade_4 = class(item_ethereal_blade)
item_ethereal_blade_5 = class(item_ethereal_blade)

modifier_item_ghost_form_ally = class({})
LinkLuaModifier( "modifier_item_ghost_form_ally", "items/item_ghost.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_ghost_form_ally:OnCreated()
	self:OnRefresh()
end

function modifier_item_ghost_form_ally:OnRefresh()
	self.ethereal_damage_bonus = self:GetSpecialValueFor("ethereal_damage_bonus")
	self.restoration_amp = self:GetSpecialValueFor("restoration_amp")
	self.allies_ignore = self:GetSpecialValueFor("allies_ignore") == 1
	self.allies_benefit = self:GetSpecialValueFor("allies_benefit") == 1
	if self.allies_ignore then
		self.ethereal_damage_bonus = 0
	end
	if self.allies_benefit then
		self.slow = -self:GetSpecialValueFor("blast_movement_slow")
	end
end

function modifier_item_ghost_form_ally:DeclareFunctions()
	return {
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DECREPIFY_UNIQUE,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
			MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
			MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_EVASION_CONSTANT
	}
end

function modifier_item_ghost_form_ally:GetModifierMagicalResistanceDecrepifyUnique()
	return self.ethereal_damage_bonus
end

function modifier_item_ghost_form_ally:GetModifierEvasion_Constant()
	return 100
end

function modifier_item_ghost_form_ally:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_item_ghost_form_ally:GetModifierSpellLifestealRegenAmplify_Percentage()
	return self.restoration_amp
end

function modifier_item_ghost_form_ally:GetModifierMPRegenAmplify_Percentage()
	return self.restoration_amp
end

function modifier_item_ghost_form_ally:GetModifierHealAmplify_PercentageSource()
	return self.restoration_amp
end

function modifier_item_ghost_form_ally:GetModifierHPRegenAmplify_Percentage()
	return self.restoration_amp
end

function modifier_item_ghost_form_ally:GetModifierLifestealRegenAmplify_Percentage()
	return self.restoration_amp
end

function modifier_item_ghost_form_ally:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

function modifier_item_ghost_form_ally:GetEffectName()
	return "particles/items_fx/ghost.vpcf"
end

function modifier_item_ghost_form_ally:GetStatusEffectName()
	return "particles/status_fx/status_effect_ghost.vpcf"
end

function modifier_item_ghost_form_ally:StatusEffectPriority()
	return 5
end

modifier_item_ghost_form_enemy = class(modifier_item_ghost_form_ally)
LinkLuaModifier( "modifier_item_ghost_form_enemy", "items/item_ghost.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_ghost_form_enemy:OnRefresh()
	self.ethereal_damage_bonus = self:GetSpecialValueFor("ethereal_damage_bonus")
	self.slow = self:GetSpecialValueFor("blast_movement_slow")
end

function modifier_item_ghost_form_enemy:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

function modifier_item_ghost_form_enemy:CheckState()
	return {[MODIFIER_STATE_DISARMED] = true}
end

function modifier_item_ghost_form_enemy:GetAbsoluteNoDamagePhysical()
	return nil
end

function modifier_item_ghost_form_enemy:GetModifierEvasion_Constant()
	return 0
end

modifier_item_ghost_passive = class({})
LinkLuaModifier( "modifier_item_ghost_passive", "items/item_ghost.lua" ,LUA_MODIFIER_MOTION_NONE )


function modifier_item_ghost_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_ghost_passive:OnRefresh()
	self.bonus_all = self:GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_ghost_passive:DeclareFunctions()
	return {
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
end

function modifier_item_ghost_passive:GetModifierBonusStats_Agility()
	return self.bonus_all
end

function modifier_item_ghost_passive:GetModifierBonusStats_Strength()
	return self.bonus_all
end

function modifier_item_ghost_passive:GetModifierBonusStats_Intellect()
	return self.bonus_all
end

function modifier_item_ghost_passive:IsHidden()
	return true
end

function modifier_item_ghost_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end


modifier_item_ethereal_blade_passive = class(modifier_item_ghost_passive)
LinkLuaModifier( "modifier_item_ethereal_blade_passive", "items/item_ghost.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_ethereal_blade_passive:OnRefresh()
	self.bonus_agility = self:GetSpecialValueFor("bonus_other")
	self.bonus_strength = self:GetSpecialValueFor("bonus_other")
	self.bonus_intellect = self:GetSpecialValueFor("bonus_other")
	
	self.bonus_evasion = self:GetSpecialValueFor("bonus_evasion")
	self.bonus_aoe = self:GetSpecialValueFor("bonus_aoe")
	self.bonus_cast_range = self:GetSpecialValueFor("bonus_cast_range")
	self.status_resistance = self:GetSpecialValueFor("status_resistance")
	self.regen_amp = self:GetSpecialValueFor("regen_amp")
	self.bonus_mana = self:GetSpecialValueFor("bonus_mana")
	self.bonus_mana_regen = self:GetSpecialValueFor("bonus_mana_regen")
	
	self:GetCaster()._aoeModifiersList = self:GetCaster()._aoeModifiersList or {}
	self:GetCaster()._aoeModifiersList[self] = true
end

function modifier_item_ethereal_blade_passive:OnDestroy()
	self:GetCaster()._aoeModifiersList[self] = nil
end

function modifier_item_ethereal_blade_passive:DeclareFunctions()
	return {
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_EVASION_CONSTANT,
			MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
			MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
			MODIFIER_PROPERTY_AOE_BONUS_CONSTANT,
			MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
			MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_MANA_BONUS,
			MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}
end

function modifier_item_ethereal_blade_passive:GetModifierBonusStats_Agility()
	return self.bonus_agility
end

function modifier_item_ethereal_blade_passive:GetModifierBonusStats_Strength()
	return self.bonus_strength
end

function modifier_item_ethereal_blade_passive:GetModifierBonusStats_Intellect()
	return self.bonus_intellect
end

function modifier_item_ethereal_blade_passive:GetModifierAoEBonusConstant()
	return self.bonus_aoe
end

function modifier_item_ethereal_blade_passive:GetModifierEvasion_Constant()
	return self.bonus_evasion
end

function modifier_item_ethereal_blade_passive:GetModifierCastRangeBonusStacking()
	return self.bonus_cast_range
end

function modifier_item_ethereal_blade_passive:GetModifierStatusResistanceStacking()
	return self.status_resistance
end

function modifier_item_ethereal_blade_passive:GetModifierHealAmplify_PercentageSource()
	return self.regen_amp
end

function modifier_item_ethereal_blade_passive:GetModifierHPRegenAmplify_Percentage()
	return self.regen_amp
end

function modifier_item_ethereal_blade_passive:GetModifierLifestealRegenAmplify_Percentage()
	return self.regen_amp
end

function modifier_item_ethereal_blade_passive:GetModifierSpellLifestealRegenAmplify_Percentage()
	return self.regen_amp
end

function modifier_item_ethereal_blade_passive:GetModifierConstantManaRegen()
	return self.bonus_mana_regen
end

function modifier_item_ethereal_blade_passive:GetModifierManaBonus()
	return self.bonus_mana
end