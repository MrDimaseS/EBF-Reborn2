necrolyte_heartstopper_aura = class({})

function necrolyte_heartstopper_aura:GetCastRange( target, position )
	return self:GetSpecialValueFor("aura_radius")
end

function necrolyte_heartstopper_aura:GetIntrinsicModifierName()
	return "modifier_necrophos_heart_stopper_passive"
end

modifier_necrophos_heart_stopper_passive = class({})
LinkLuaModifier( "modifier_necrophos_heart_stopper_passive", "heroes/hero_necrophos/necrolyte_heartstopper_aura", LUA_MODIFIER_MOTION_NONE )

function modifier_necrophos_heart_stopper_passive:IsAura()
	return true
end

function modifier_necrophos_heart_stopper_passive:GetModifierAura()
	return "modifier_necrophos_heart_stopper_passive_degen"
end

function modifier_necrophos_heart_stopper_passive:GetAuraRadius()
	return self:GetSpecialValueFor("aura_radius")
end

function modifier_necrophos_heart_stopper_passive:GetAuraDuration()
	return 0.5
end

function modifier_necrophos_heart_stopper_passive:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_necrophos_heart_stopper_passive:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_necrophos_heart_stopper_passive:IsHidden()
	return true
end

modifier_necrophos_heart_stopper_passive_degen = class({})
LinkLuaModifier( "modifier_necrophos_heart_stopper_passive_degen", "heroes/hero_necrophos/necrolyte_heartstopper_aura", LUA_MODIFIER_MOTION_NONE )

function modifier_necrophos_heart_stopper_passive_degen:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink(0.33)
	end
end

function modifier_necrophos_heart_stopper_passive_degen:OnRefresh()
	self.aura_damage = self:GetSpecialValueFor("aura_damage")
	self.creep_damage = self:GetSpecialValueFor("creep_damage")
	self.heal_regen_to_damage = self:GetSpecialValueFor("heal_regen_to_damage") / 100
end

function modifier_necrophos_heart_stopper_passive_degen:OnIntervalThink()
	local damage = self:GetParent():GetMaxHealth() * ( TernaryOperator( self.aura_damage, self:GetParent():IsConsideredHero(), self.creep_damage ) ) / 100 + self:GetCaster():GetHealthRegen() * self.heal_regen_to_damage
	local ability = self:GetAbility()
	if ability and not ability:IsNull() then
		ability:DealDamage( self:GetCaster(), self:GetParent(), math.ceil(damage) * 0.33, {damage_type = DAMAGE_TYPE_MAGICAL, damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL} )
	else
		self:Destroy()
	end
end