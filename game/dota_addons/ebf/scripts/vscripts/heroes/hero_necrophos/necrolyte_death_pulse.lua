necrolyte_death_pulse = class({})

function necrolyte_death_pulse:GetIntrinsicModifierName()
	return "modifier_necrolyte_death_pulse_autocast"
end

function necrolyte_death_pulse:GetCastRange( target, position )
	return self:GetSpecialValueFor("area_of_effect")
end

function necrolyte_death_pulse:ShouldUseResources()
	return true
end

function necrolyte_death_pulse:OnSpellStart( )
	local caster = self:GetCaster()
	
	self.deathPulses = self.deathPulses or {}
	self:DeathPulse( caster )
end

function necrolyte_death_pulse:DeathPulse( origin, bDisableSound )
	local caster = self:GetCaster()
	
	local speed = self:GetSpecialValueFor("projectile_speed")
	local radius = self:GetSpecialValueFor("area_of_effect")
	
	for _, unit in ipairs( caster:FindAllUnitsInRadius( origin:GetAbsOrigin(), radius ) ) do
		if unit ~= origin then
			local fxName = "particles/units/heroes/hero_necrolyte/necrolyte_pulse_enemy.vpcf"
			if caster:IsSameTeam(unit) then
				fxName = "particles/units/heroes/hero_necrolyte/necrolyte_pulse_friend.vpcf"
			end
			local projID = self:FireTrackingProjectile(fxName, unit, speed, {source = origin})
			self.deathPulses[projID] = {damage = damage, damage_type = damage_type}
		else
			self:OnProjectileHitHandle( origin, origin:GetAbsOrigin(), 0 )
		end
	end
	if not bDisableSound then origin:EmitSound("Hero_Necrolyte.DeathPulse") end
end

function necrolyte_death_pulse:OnProjectileHitHandle( target, position, projectileID )
	if target then
		local caster = self:GetCaster()
		
		local projData = self.deathPulses[projectileID]
		
		if caster:IsSameTeam(target) then
			target:HealEvent( self:GetSpecialValueFor("heal"), self, caster )
		else
			self:DealDamage( caster, target, self:GetSpecialValueFor("damage") )
		end
		target:EmitSound("Hero_Necrolyte.ProjectileImpact")
		
		self.deathPulses[projectileID] = nil
	end
end

necrolyte_death_seeker = class({})

function necrolyte_death_seeker:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	self.deathPulse = caster:FindAbilityByName("necrolyte_death_pulse")
	if self.deathPulse then
		local speed = self.deathPulse:GetSpecialValueFor("projectile_speed") * (1 + self:GetSpecialValueFor("projectile_multiplier") / 100)
		self:FireTrackingProjectile("particles/units/heroes/hero_necrolyte/necrolyte_death_seeker_enemy.vpcf", target, speed)
	end
	
	EmitSoundOn( "Hero_Necrolyte.DeathSeeker", caster )
end

function necrolyte_death_seeker:OnProjectileHit( target, position )
	if target then
		local caster = self:GetCaster()
		target:AddNewModifier( caster, self, "modifier_necrolyte_death_seeker_debuff", {duration = self:GetSpecialValueFor("ethereal_duration")} )
		self.deathPulse:DeathPulse( target )
	end
end

modifier_necrolyte_death_seeker_debuff = class({})
LinkLuaModifier( "modifier_necrolyte_death_seeker_debuff", "heroes/hero_necrophos/necrolyte_death_pulse", LUA_MODIFIER_MOTION_NONE )

function modifier_necrolyte_death_seeker_debuff:OnCreated()
	self.magic_resistance_reduction = self:GetSpecialValueFor("magic_resistance_reduction")
end

function modifier_necrolyte_death_seeker_debuff:CheckState()
	if self:GetParent():IsSameTeam( self:GetCaster() ) then
		return {[MODIFIER_STATE_ATTACK_IMMUNE] = true}
	else
		return {[MODIFIER_STATE_DISARMED] = true}
	end
end

function modifier_necrolyte_death_seeker_debuff:DeclareFunctions()
	return {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS}
end

function modifier_necrolyte_death_seeker_debuff:GetModifierMagicalResistanceBonus()
	return -self.magic_resistance_reduction
end

function modifier_necrolyte_death_seeker_debuff:GetEffectName()
	return "particles/items_fx/ghost.vpcf"
end

function modifier_necrolyte_death_seeker_debuff:GetStatusEffectName()
	return "particles/status_fx/status_effect_ghost.vpcf"
end

function modifier_necrolyte_death_seeker_debuff:StatusEffectPriority()
	return 5
end


modifier_necrolyte_death_pulse_autocast = class({})
LinkLuaModifier( "modifier_necrolyte_death_pulse_autocast", "heroes/hero_necrophos/necrolyte_death_pulse", LUA_MODIFIER_MOTION_NONE )

function modifier_necrolyte_death_pulse_autocast:OnCreated()
	self.active = false
	if IsServer() then
		self:StartIntervalThink( 0.33 )
	end
end

function modifier_necrolyte_death_pulse_autocast:OnIntervalThink()
	if self:GetAbility():IsFullyCastable() and self:GetAbility():GetAutoCastState() then
		self:GetCaster():CastAbilityNoTarget( self:GetAbility(), self:GetCaster():GetPlayerID() )
	end
end

function modifier_necrolyte_death_pulse_autocast:IsHidden()
	return true
end

function modifier_necrolyte_death_pulse_autocast:IsPurgable()
	return false
end