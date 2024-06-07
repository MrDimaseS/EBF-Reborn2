zuus_arc_lightning = class({})

function zuus_arc_lightning:GetIntrinsicModifierName()
	return "modifier_zuus_arc_lightning_passive"
end

function zuus_arc_lightning:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	local damage = self:GetSpecialValueFor("arc_damage")
	local radius = self:GetSpecialValueFor("radius")
	local jumpCount = self:GetSpecialValueFor("jump_count")
	local jumpDelay = self:GetSpecialValueFor("jump_delay")
	
	local applyAttack = self:GetSpecialValueFor("apply_attack")
	local buffDur = self:GetSpecialValueFor("buff_duration")
	
	if buffDur > 0 then
		caster:AddNewModifier( caster, self, "modifier_zuus_arc_lightning_divine_rampage", {duration = buffDur} )
	end
	
	
	self:ChainLightning( target, caster, damage, applyAttack )
	local targetsHit = {[target] = true}
	local prevTarget = target
	Timers:CreateTimer(jumpDelay, function()
		jumpCount = jumpCount - 1
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( prevTarget:GetAbsOrigin(), radius ) ) do
			if not targetsHit[enemy] then
				targetsHit[enemy] = true
				self:ChainLightning( enemy, prevTarget, damage, applyAttack )
				prevTarget = enemy
				if jumpCount > 1 then
					return jumpDelay
				end
			end
		end
	end)
end

function zuus_arc_lightning:ChainLightning( target, source, damage, bAttack )
	local caster = self:GetCaster()
	
	ParticleManager:FireRopeParticle("particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf", PATTACH_POINT_FOLLOW, source, target, {})
	EmitSoundOn("Hero_Zuus.ArcLightning.Target", target)
	
	if target:TriggerSpellAbsorb( self ) then return end
	
	local dmgMax = self:GetSpecialValueFor("bonus_damage_max") / 100
	local dmgMin = self:GetSpecialValueFor("bonus_damage_min") / 100
	local rangeMax = self:GetSpecialValueFor("range_damage_max")
	local rangeMin = self:GetSpecialValueFor("range_damage_min")
	
	local damageMultiplier = 1
	if dmgMax > 0 then
		local bonusDamage = dmgMax - dmgMin
		local damageThreshold = rangeMin - rangeMax
		local distance = CalculateDistance( caster, target ) - rangeMax
		damageMultiplier = dmgMin + bonusDamage * math.min( math.max( 0, (damageThreshold-distance)/damageThreshold ), 1 )
	end
	
	self:DealDamage( caster, target, damage * damageMultiplier )
	if bAttack then
		caster:PerformGenericAttack( target, true )
	end
end

LinkLuaModifier("modifier_zuus_arc_lightning_divine_rampage", "heroes/hero_zeus/zuus_arc_lightning", LUA_MODIFIER_MOTION_NONE)
modifier_zuus_arc_lightning_divine_rampage = class({})

function modifier_zuus_arc_lightning_divine_rampage:OnCreated()
	self:OnRefresh()
end

function modifier_zuus_arc_lightning_divine_rampage:OnRefresh()
	self.bonus_spell_damage = self:GetSpecialValueFor("bonus_spell_damage") / 100
	if IsServer() then
		self:AddIndependentStack( self:GetRemainingTime() )
	end
end

function modifier_zuus_arc_lightning_divine_rampage:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL, 
			MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE, 
			MODIFIER_PROPERTY_TOOLTIP,
			MODIFIER_EVENT_ON_ABILITY_FULLY_CAST }
end

function modifier_zuus_arc_lightning_divine_rampage:OnAbilityFullyCast( params ) 
	if params.unit ~= self:GetParent() then return end
	if params.ability:GetAbilityName() == "zuus_lightning_bolt"
	or params.ability:GetAbilityName() == "zuus_heavenly_jump" 
	or params.ability:GetAbilityName() == "zuus_thundergods_wrath" then
		Timers:CreateTimer( function() self:Destroy() end )
	end
end

function modifier_zuus_arc_lightning_divine_rampage:GetModifierOverrideAbilitySpecial(params)
	if params.ability:GetAbilityName() == "zuus_lightning_bolt"
	or params.ability:GetAbilityName() == "zuus_heavenly_jump" 
	or params.ability:GetAbilityName() == "zuus_thundergods_wrath" then
		if params.ability_special_value == "damage" then
			return 1
		end
	end
end

function modifier_zuus_arc_lightning_divine_rampage:GetModifierOverrideAbilitySpecialValue(params)
	if params.ability:GetAbilityName() == "zuus_lightning_bolt"
	or params.ability:GetAbilityName() == "zuus_heavenly_jump" 
	or params.ability:GetAbilityName() == "zuus_thundergods_wrath" then
		if params.ability_special_value == "damage"then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( params.ability_special_value, params.ability_special_level )
			return flBaseValue * ( 1 + self:GetStackCount() * self.bonus_spell_damage )
		end
	end
end

function modifier_zuus_arc_lightning_divine_rampage:OnTooltip() 
	return self:GetStackCount() * self.bonus_spell_damage * 100
end

LinkLuaModifier("modifier_zuus_arc_lightning_passive", "heroes/hero_zeus/zuus_arc_lightning", LUA_MODIFIER_MOTION_NONE)
modifier_zuus_arc_lightning_passive = class({})

function modifier_zuus_arc_lightning_passive:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_START}
end

function modifier_zuus_arc_lightning_passive:OnAttackStart(params)
	if params.attacker ~= self:GetParent() then return end
	if not self:GetAbility():GetAutoCastState() then return end 
	if not self:GetAbility():IsFullyCastable() then return end 
	if params.attacker:IsSilenced() then return end
	
	params.attacker:Stop()
	params.attacker:CastAbilityOnTarget( params.target, self:GetAbility(), params.attacker:GetPlayerOwnerID() )
end

function modifier_zuus_arc_lightning_passive:IsHidden()
	return true
end

function modifier_zuus_arc_lightning_passive:IsPurgable()
	return false
end