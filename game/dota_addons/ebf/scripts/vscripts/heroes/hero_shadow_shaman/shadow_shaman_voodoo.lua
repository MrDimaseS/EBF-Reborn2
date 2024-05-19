shadow_shaman_voodoo = class({})

function shadow_shaman_voodoo:GetIntrinsicModifierName()
	return "modifier_shadow_shaman_voodoo_passive"
end

function shadow_shaman_voodoo:ShouldUseResources()
	return true
end

function shadow_shaman_voodoo:GetCastRange( target, position )
	return self:GetSpecialValueFor("cast_range")
end

function shadow_shaman_voodoo:CastFilterResultTarget( target )
	if target ~= self:GetCaster() then
		return UnitFilter( target, TernaryOperator( DOTA_UNIT_TARGET_TEAM_BOTH, self:GetSpecialValueFor("ally_duration") > 0, DOTA_UNIT_TARGET_TEAM_ENEMY), DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, self:GetCaster():GetTeamNumber() )
	else
		return UF_FAIL_OTHER
	end
end

function shadow_shaman_voodoo:OnSpellStart()
	local target = self:GetCursorTarget()
	local caster = self:GetCaster()
	
	-- cosmetic
	EmitSoundOn("Hero_ShadowShaman.Hex.Target", caster)
	if target:IsSameTeam( caster ) then
		target:AddNewModifier(caster, self, "modifier_shadow_shaman_voodoo_effect", {duration = self:GetSpecialValueFor("ally_duration")})
	else
		target:AddNewModifier( caster, self, "modifier_shadow_shaman_voodoo", {duration = self:GetSpecialValueFor("duration")} )
	end
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
	local ability = self:GetAbility()
	if self:GetAbility():IsCooldownReady() and not self:GetParent():PassivesDisabled() then
		if caster:HasModifier("modifier_shadow_shaman_voodoo_effect") then return end
		self.lingerModifier = caster:AddNewModifier( caster, ability, "modifier_shadow_shaman_voodoo_effect", {} )
	elseif IsModifierSafe( self.lingerModifier ) and self.lingerModifier:GetRemainingTime() < 0 then
		caster:RemoveModifierByName( "modifier_shadow_shaman_voodoo_effect" )
	else
		self.lingerModifier = nil
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
	return {MODIFIER_EVENT_ON_TAKEDAMAGE, MODIFIER_EVENT_ON_ATTACK_START }
end

function modifier_shadow_shaman_voodoo_effect:OnAttackStart( params )
	if params.target == self:GetParent() then
		self:ResolveEffect( params.attacker )
	end
end

function modifier_shadow_shaman_voodoo_effect:OnTakeDamage( params )
	if params.unit == self:GetParent() and not params.attacker:IsSameTeam( params.unit ) then
		self:ResolveEffect( params.attacker )
	end
end

function modifier_shadow_shaman_voodoo_effect:ResolveEffect( target )
	if (self:GetRemainingTime() < 0 and self.triggered) or ( self:GetAbility():GetAutoCastState() and self:GetCaster() == self:GetParent() ) then return end
	if not self.triggered then
		self.triggered = true
		self:SetDuration( self.linger_duration, true )
		if self:GetAbility():IsCooldownReady() then self:GetAbility():SetCooldown() end
	end
	target:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_shadow_shaman_voodoo", {duration = self:GetSpecialValueFor("duration")} )
end