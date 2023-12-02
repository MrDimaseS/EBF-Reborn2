ursa_enrage = class({})

function ursa_enrage:IsStealable()
	return true
end

function ursa_enrage:IsHiddenWhenStolen()
	return false
end

function ursa_enrage:GetBehavior()
	if self:GetCaster():HasScepter() then
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_UNRESTRICTED
	else
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
	end
end

function ursa_enrage:GetIntrinsicModifierName()
	return "modifier_ursa_enrage_shard_handler"
end

function ursa_enrage:OnSpellStart()
	local caster = self:GetCaster()

	
	if caster:HasModifier("modifier_ursa_enrage_active") then
		caster:RemoveModifierByName("modifier_ursa_enrage_active")
	else
		EmitSoundOn("Hero_Ursa.Enrage", caster)

		caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_4)
		caster:Purge(false, true, false, true, true)
		caster:AddNewModifier(caster, self, "modifier_ursa_enrage_active", {Duration = self:GetTalentSpecialValueFor("duration")})
		self:SetCooldown(0.5)
	end
end

modifier_ursa_enrage_shard_handler = class({})
LinkLuaModifier("modifier_ursa_enrage_shard_handler", "heroes/hero_ursa/ursa_enrage", LUA_MODIFIER_MOTION_NONE)

function modifier_ursa_enrage_shard_handler:OnCreated()
	self.shard_spellcast_duration = self:GetTalentSpecialValueFor("shard_spellcast_duration")
end

function modifier_ursa_enrage_shard_handler:DeclareFunctions()
	local decFuncs = {
		MODIFIER_EVENT_ON_ABILITY_FULLY_CAST
	}
	return decFuncs
end

function modifier_ursa_enrage_shard_handler:OnAbilityFullyCast( params )
	if params.unit == self:GetCaster() and self:GetCaster():HasShard() and self:GetAbility():GetCooldownTimeRemaining() > 0 then
		self:GetAbility():ModifyCooldown( -self.shard_spellcast_duration )
	end
end

function modifier_ursa_enrage_shard_handler:IsHidden()
	return true
end

modifier_ursa_enrage_active = class({})
LinkLuaModifier("modifier_ursa_enrage_active", "heroes/hero_ursa/ursa_enrage", LUA_MODIFIER_MOTION_NONE)

function modifier_ursa_enrage_active:OnCreated()
	local caster = self:GetCaster()
	self.damage_reduction = self:GetTalentSpecialValueFor("damage_reduction")
	self.status_resistance = self:GetTalentSpecialValueFor("status_resistance")
	self.shard_spellcast_duration = self:GetTalentSpecialValueFor("shard_spellcast_duration")
end

function modifier_ursa_enrage_active:OnDestroy()
	local caster = self:GetCaster()
	if IsServer() then
		self:GetAbility():SetCooldown()
	end
end

function modifier_ursa_enrage_active:DeclareFunctions()
	local decFuncs = {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_PROPERTY_MODEL_SCALE,
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
		MODIFIER_EVENT_ON_ABILITY_FULLY_CAST
	}
	return decFuncs
end

function modifier_ursa_enrage_active:GetModifierModelScale()
	return 40
end

function modifier_ursa_enrage_active:GetModifierIncomingDamage_Percentage()
	return -self.damage_reduction
end

function modifier_ursa_enrage_active:GetModifierStatusResistanceStacking()
	return self.status_resistance
end

function modifier_ursa_enrage_active:OnAbilityFullyCast( params )
	if params.unit == self:GetCaster() and self:GetCaster():HasShard() then
		self:SetDuration( self:GetRemainingTime() + self.shard_spellcast_duration, true )
	end
end

function modifier_ursa_enrage_active:GetEffectName()
	return "particles/units/heroes/hero_ursa/ursa_enrage_buff.vpcf"
end

function modifier_ursa_enrage_active:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_ursa_enrage_active:GetHeroEffectName()
	return "particles/units/heroes/hero_ursa/ursa_enrage_hero_effect.vpcf"
end

function modifier_ursa_enrage_active:HeroEffectPriority()
	return 11
end

function modifier_ursa_enrage_active:IsHidden()
	return false
end

function modifier_ursa_enrage_active:IsPurgable()
	return false
end