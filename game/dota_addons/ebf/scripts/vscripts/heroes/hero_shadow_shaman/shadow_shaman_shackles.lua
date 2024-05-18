shadow_shaman_shackles = class({})

function shadow_shaman_shackles:GetChannelTime()
	self.duration = self:GetSpecialValueFor( "channel_time" )
	return self.duration
end

function shadow_shaman_shackles:OnSpellStart()
	local hTarget = self:GetCursorTarget()
	local hCaster = self:GetCaster()
	
	-- cosmetic
	EmitSoundOn("Hero_ShadowShaman.Shackles.Cast", hCaster)
	
	if not hTarget:TriggerSpellAbsorb( self ) then
		local mod = hTarget:AddNewModifier(hCaster, self, "modifier_shadow_shaman_bound_shackles", {duration = self:GetSpecialValueFor("channel_time")})
	end
end


LinkLuaModifier("modifier_shadow_shaman_bound_shackles", "heroes/hero_shadow_shaman/shadow_shaman_shackles", LUA_MODIFIER_MOTION_NONE)
modifier_shadow_shaman_bound_shackles = class({})

function modifier_shadow_shaman_bound_shackles:OnCreated(kv)
	self.duration = self:GetRemainingTime()
	self.damage = self:GetAbility():GetSpecialValueFor("total_damage")
	self.heal = self:GetAbility():GetSpecialValueFor("total_heal")
	self.tick = self:GetAbility():GetSpecialValueFor("tick_interval")
	EmitSoundOn("Hero_ShadowShaman.Shackles", self:GetParent())
	if IsServer() then
		self:StartIntervalThink(self.tick)
		
		local origin = self:GetCaster()
		if kv.origin then origin = EntIndexToHScript( tonumber(kv.origin) ) end
		local shackles = ParticleManager:CreateParticle("particles/units/heroes/hero_shadowshaman/shadowshaman_shackle.vpcf", PATTACH_POINT_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControlEnt(shackles, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(shackles, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(shackles, 3, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(shackles, 4, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
		
		ParticleManager:SetParticleControlEnt(shackles, 5, origin, PATTACH_POINT_FOLLOW, "attach_attack1", origin:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(shackles, 6, origin, PATTACH_POINT_FOLLOW, "attach_attack2", origin:GetAbsOrigin(), true)
		
		self:AddParticle(shackles, false, false, 10, false, false)
		
		
	end
	self.shackleTargets = self.shackleTargets or {}
	table.insert( self.shackleTargets, self )
end

function modifier_shadow_shaman_bound_shackles:OnRefresh()
	self.duration = self:GetRemainingTime()
	self.damage = self:GetAbility():GetSpecialValueFor("total_damage") / self.duration
	self.tick = self:GetAbility():GetSpecialValueFor("tick_interval")
	EmitSoundOn("Hero_ShadowShaman.Shackles", self:GetParent())
end

function modifier_shadow_shaman_bound_shackles:OnIntervalThink()
	if not self:GetCaster():IsChanneling() then self:Destroy() end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local target = self:GetParent()
	ability:DealDamage( caster, target, self.damage*self.tick )
	caster:HealEvent( self.heal*self.tick, ability, caster )
	ApplyDamage({ victim = self:GetParent(), attacker = self:GetCaster(), damage = self.damage*self.tick, damage_type = self:GetAbility():GetAbilityDamageType(), ability = self:GetAbility()})
end

function modifier_shadow_shaman_bound_shackles:OnDestroy()
	StopSoundOn("Hero_ShadowShaman.Shackles", self:GetParent())
	if IsServer() then
		table.removeval(self:GetAbility().shackles, self)
		if #self:GetAbility().shackles == 0 then
			self:GetCaster():InterruptChannel()
		end
	end
end

function modifier_shadow_shaman_bound_shackles:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION
	}

	return funcs
end

function modifier_shadow_shaman_bound_shackles:GetOverrideAnimation()
	return ACT_DOTA_DISABLED
end

function modifier_shadow_shaman_bound_shackles:GetStatusEffectName()
	return "particles/status_fx/status_effect_shaman_shackle.vpcf"
end

function modifier_shadow_shaman_bound_shackles:StatusEffectPriority()
	return 10
end


function modifier_shadow_shaman_bound_shackles:CheckState()
	local state = {
	[MODIFIER_STATE_STUNNED] = true,
	}

	return state
end