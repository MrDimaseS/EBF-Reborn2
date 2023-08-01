shadow_shaman_voodoo = class({})

function shadow_shaman_voodoo:GetIntrinsicModifierName()
	return "modifier_shadow_shaman_voodoo_passive"
end

function shadow_shaman_voodoo:GetBehavior()
	if self:GetSpecialValueFor("cast_range") > 0 then
		return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
	else
		return DOTA_ABILITY_BEHAVIOR_PASSIVE
	end
end

function shadow_shaman_voodoo:ShouldUseResources()
	return true
end

function shadow_shaman_voodoo:GetCastRange( target, position )
	return self:GetSpecialValueFor("cast_range")
end

function shadow_shaman_voodoo:CastFilterResultTarget( target )
	if target ~= self:GetCaster() then
		return UnitFilter( target, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, self:GetCaster():GetTeamNumber() )
	else
		return UF_FAIL_OTHER
	end
end

function shadow_shaman_voodoo:OnSpellStart()
	local target = self:GetCursorTarget()
	local caster = self:GetCaster()
	
	-- cosmetic
	EmitSoundOn("Hero_ShadowShaman.Hex.Target", caster)
	target:AddNewModifier(caster, self, "modifier_shadow_shaman_voodoo_effect", {duration = self:GetSpecialValueFor("ally_duration")})
	caster:RemoveModifierByName("modifier_shadow_shaman_voodoo_effect")
end


LinkLuaModifier("modifier_shadow_shaman_voodoo_passive", "heroes/hero_shadow_shaman/shadow_shaman_voodoo", LUA_MODIFIER_MOTION_NONE)
modifier_shadow_shaman_voodoo_passive = class({})

function modifier_shadow_shaman_voodoo_passive:OnCreated()
	if IsServer() then
		self:StartIntervalThink( 0.1 )
	end
end

function modifier_shadow_shaman_voodoo_passive:OnIntervalThink()
	local caster = self:GetCaster()
	if caster:HasModifier("modifier_shadow_shaman_voodoo_effect") then return end
	local ability = self:GetAbility()
	if self:GetAbility():IsCooldownReady() then
		caster:AddNewModifier( caster, ability, "modifier_shadow_shaman_voodoo_effect", {} )
	end
end

function modifier_shadow_shaman_voodoo_passive:IsHidden()
	return true
end

function modifier_shadow_shaman_voodoo_passive:IsPurgable()
	return false
end

LinkLuaModifier("modifier_shadow_shaman_voodoo_effect", "heroes/hero_shadow_shaman/shadow_shaman_voodoo", LUA_MODIFIER_MOTION_NONE)
modifier_shadow_shaman_voodoo_effect = class({})

function modifier_shadow_shaman_voodoo_effect:OnCreated()
	self.linger_duration = self:GetSpecialValueFor("linger_duration")
end

function modifier_shadow_shaman_voodoo_effect:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_shadow_shaman_voodoo_effect:OnTakeDamage( params )
	if params.unit == self:GetParent() then
		if self:GetParent():PassivesDisabled() and self:GetRemainingTime() < 0 then return end
		if not self.triggered then
			self.triggered = true
			self:SetDuration( self.linger_duration, true )
			self:GetAbility():SetCooldown()
		end
		params.attacker:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_shadow_shaman_voodoo", {duration = self:GetSpecialValueFor("duration")} )
	end
end