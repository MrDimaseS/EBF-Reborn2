void_spirit_astral_step = class({})

function void_spirit_astral_step:IsStealable()
	return false
end

function void_spirit_astral_step:IsHiddenWhenStolen()
	return false
end

function void_spirit_astral_step:OnAbilityPhaseStart()
	EmitSoundOn( "Hero_VoidSpirit.AstralStep.Start", self:GetCaster() )
	return true
end

function void_spirit_astral_step:OnAbilityPhaseInterrupted()
	StopSoundOn( "Hero_VoidSpirit.AstralStep.Start", self:GetCaster() )
end

function void_spirit_astral_step:OnSpellStart()
	local caster = self:GetCaster()
	local origin = caster:GetAbsOrigin()
	local position = self:GetCursorPosition()
	position = origin + CalculateDirection( position, caster ) * math.max( self:GetSpecialValueFor("min_travel_distance"), math.min( CalculateDistance( position, caster ), self:GetSpecialValueFor("max_travel_distance") ) )
	ParticleManager:FireParticle( "particles/units/heroes/hero_void_spirit/astral_step/void_spirit_astral_step.vpcf", PATTACH_POINT, caster, {[0] = origin, [1] = position} )
	FindClearSpaceForUnit( caster, position, true )
	
	caster:AddNewModifier( caster, self, "modifier_void_spirit_astral_attack_buff", {} )
	for _, enemy in ipairs( caster:FindEnemyUnitsInLine( origin, position, self:GetSpecialValueFor("radius") * 2 ) ) do
		self:ApplyMark( enemy )
		caster:PerformGenericAttack(enemy, true, {ability = self})
		EmitSoundOn( "Hero_VoidSpirit.AstralStep.Target", caster )
	end
	caster:RemoveModifierByName("modifier_void_spirit_astral_attack_buff")
	
	EmitSoundOn( "Hero_VoidSpirit.AstralStep.End", caster )
	
	local activatesResonantPulse = self:GetSpecialValueFor("activates_resonant_pulse") == 1
	if activatesResonantPulse then
		local resonantPulse = caster:FindAbilityByName("void_spirit_resonant_pulse")
		if resonantPulse and resonantPulse:IsTrained() then
			resonantPulse:OnSpellStart()
		end
	end
	local refreshesDissimilate = self:GetSpecialValueFor("refreshes_dissimilate") == 1
	if refreshesDissimilate then
		local dissimilate = caster:FindAbilityByName("void_spirit_dissimilate")
		if dissimilate and dissimilate:IsTrained() and not dissimilate:IsCooldownReady() then
			dissimilate:EndCooldown()
		end
	end
	
end

function void_spirit_astral_step:ApplyMark( target )
	local caster = self:GetCaster()
	local delay = self:GetSpecialValueFor("pop_damage_delay")
	target:AddNewModifier( caster, self, "modifier_void_spirit_astral_step_effect", {duration = delay} )
	target:AddNewModifier( caster, self, "modifier_void_spirit_astral_step_mark", {duration = delay} )
end


modifier_void_spirit_astral_step_mark = class({})
LinkLuaModifier("modifier_void_spirit_astral_step_mark", "heroes/hero_void_spirit/void_spirit_astral_step", LUA_MODIFIER_MOTION_NONE)

function modifier_void_spirit_astral_step_mark:OnCreated()
	self.dmg = self:GetSpecialValueFor("pop_damage")
	self.early_bonus_duration = 1 + self:GetSpecialValueFor("early_bonus_duration") / 100
	self.lifesteal = self:GetSpecialValueFor("lifesteal") / 100
	self.ministun = self:GetSpecialValueFor("ministun")
	if IsServer() then
		self._preventInstantProc = self:GetAbility()._preventInstantProc
	end
end

function modifier_void_spirit_astral_step_mark:OnDestroy()
	if IsClient() then return end
	local parent = self:GetParent()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	EmitSoundOn( "Hero_VoidSpirit.AstralStep.MarkExplosion", parent )
	local damage = ability:DealDamage( caster, parent, self.dmg )
	if self.lifesteal > 0 then
		local lifesteal = self.lifesteal
		if not parent:IsConsideredHero() then
			lifesteal =  lifesteal * (100 - 80)/100
		end
		caster:HealWithParams( damage * lifesteal, ability, false, true, self, true )
		caster:HealEvent(damage * lifesteal, ability, caster, {heal_type = DOTA_HEAL_TYPE_LIFESTEAL})
	end
	ParticleManager:FireParticle("particles/units/heroes/hero_void_spirit/astral_step/void_spirit_astral_step_dmg.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
	if self.ministun > 0 then
		ability:Stun( parent, self.ministun )
	end
end

function modifier_void_spirit_astral_step_mark:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_void_spirit_astral_step_mark:OnTakeDamage( params )
	local parent = self:GetParent()
	if params.unit ~= parent then return end
	if not params.inflictor then return end
	if params.inflictor:IsItem() then return end
	if params.inflictor == self._preventInstantProc then return end
	
	parent:AddNewModifier( caster, self, "modifier_void_spirit_astral_step_effect", {duration = self:GetSpecialValueFor("pop_damage_delay") * self.early_bonus_duration} )
	self:Destroy()
end

function modifier_void_spirit_astral_step_mark:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_void_spirit_astral_step_mark:GetEffectName()
	return "particles/units/heroes/hero_void_spirit/planeshift/void_spirit_planeshift_marked_overhead.vpcf"
end

modifier_void_spirit_astral_attack_buff = class({})
LinkLuaModifier("modifier_void_spirit_astral_attack_buff", "heroes/hero_void_spirit/void_spirit_astral_step", LUA_MODIFIER_MOTION_NONE)

function modifier_void_spirit_astral_attack_buff:OnCreated()
	self.lifesteal = self:GetSpecialValueFor("lifesteal")
	self.crit = self:GetSpecialValueFor("crit")
	
	self:GetParent()._attackLifestealModifiersList = self:GetParent()._attackLifestealModifiersList or {}
	self:GetParent()._attackLifestealModifiersList[self] = true
end

function modifier_void_spirit_astral_attack_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
			MODIFIER_PROPERTY_PHYSICAL_LIFESTEAL}
end

function modifier_void_spirit_astral_attack_buff:GetCritDamage()
	return 1 + self.crit / 100
end

function modifier_void_spirit_astral_attack_buff:GetModifierPreAttack_CriticalStrike()
	return self.crit
end

function modifier_void_spirit_astral_attack_buff:GetModifierProperty_PhysicalLifesteal(params)
	return self.lifesteal
end

function modifier_void_spirit_astral_attack_buff:IsHidden()
	return true
end

modifier_void_spirit_astral_step_effect = class({})
LinkLuaModifier("modifier_void_spirit_astral_step_effect", "heroes/hero_void_spirit/void_spirit_astral_step", LUA_MODIFIER_MOTION_NONE)

function modifier_void_spirit_astral_step_effect:OnCreated()
	self:OnRefresh()
end

function modifier_void_spirit_astral_step_effect:OnRefresh()
	self.slow = self:GetSpecialValueFor("movement_slow_pct")
	self.attack_slow = self:GetSpecialValueFor("attack_speed_slow")
	self.armor_loss = self:GetSpecialValueFor("armor_loss")
end

function modifier_void_spirit_astral_step_effect:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			}
end

function modifier_void_spirit_astral_step_effect:GetModifierMoveSpeedBonus_Percentage()
	return -self.slow
end

function modifier_void_spirit_astral_step_effect:GetModifierAttackSpeedBonus_Constant()
	return -self.attack_slow
end

function modifier_void_spirit_astral_step_effect:GetModifierPhysicalArmorBonus()
	return self.armor_loss
end

function modifier_void_spirit_astral_step_effect:GetEffectName()
	return "particles/units/heroes/hero_void_spirit/astral_step/void_spirit_astral_step_debuff.vpcf"
end

function modifier_void_spirit_astral_step_effect:GetStatusEffectName()
	return "particles/status_fx/status_effect_void_spirit_astral_step_debuff.vpcf"
end

function modifier_void_spirit_astral_step_effect:StatusEffectPriority()
	return 3
end