lone_druid_synergy = class({})

function lone_druid_synergy:IsStealable()
    return false
end

function lone_druid_synergy:IsHiddenWhenStolen()
    return false
end

function lone_druid_synergy:GetIntrinsicModifierName()
    return "modifier_lone_druid_synergy_handle"
end

function lone_druid_synergy:OnHeroCalculateStatBonus()
	if not IsSafeEntity( self.linkedSpiritBear ) then return end
	local modifier = self.linkedSpiritBear:FindModifierByName("modifier_lone_druid_synergy_aura")
	if modifier then
		local bear = self.linkedSpiritBear
		bear:RemoveModifierByName( "modifier_lone_druid_synergy_aura" )
	end
end

function lone_druid_synergy:OnToggle()
	if not self.linkedSpiritBear then return end
	local caster = self:GetCaster()
	if self:GetToggleState() then
		self.linkedSpiritBear:AddNewModifier( caster, self, "modifier_lone_druid_synergy_damage_share", {} )
		caster:AddNewModifier( self.linkedSpiritBear, self, "modifier_lone_druid_synergy_damage_share", {} )
	else
		self.linkedSpiritBear:RemoveModifierByName("modifier_lone_druid_synergy_damage_share")
		caster:RemoveModifierByName("modifier_lone_druid_synergy_damage_share")
	end
end

modifier_lone_druid_synergy_handle = class({})
LinkLuaModifier( "modifier_lone_druid_synergy_handle", "heroes/hero_lone_druid/lone_druid_synergy", LUA_MODIFIER_MOTION_NONE )

function modifier_lone_druid_synergy_handle:OnCreated()
	if IsServer() then
		if not self:GetAbility():GetToggleState() then
			self:GetAbility():ToggleAbility()
		end
	end
	self:OnRefresh()
end

function modifier_lone_druid_synergy_handle:OnRefresh()
	self.bonus_attack_damage = self:GetSpecialValueFor("bonus_attack_damage")
	self.bonus_max_health = self:GetSpecialValueFor("bonus_max_health")
end

function modifier_lone_druid_synergy_handle:IsHidden()
	return true
end

function modifier_lone_druid_synergy_handle:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEALTH_BONUS, 
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_lone_druid_synergy_handle:GetModifierHealthBonus(params)
	return self.bonus_max_health
end

function modifier_lone_druid_synergy_handle:GetModifierPreAttack_BonusDamage(params)
	return self.bonus_attack_damage
end

function modifier_lone_druid_synergy_handle:IsAura()
	return true
end

function modifier_lone_druid_synergy_handle:GetModifierAura()
	return "modifier_lone_druid_synergy_aura"
end

function modifier_lone_druid_synergy_handle:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_lone_druid_synergy_handle:GetAuraSearchType()
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_lone_druid_synergy_handle:GetAuraRadius()
	return 9999
end

function modifier_lone_druid_synergy_handle:GetAuraEntityReject( target )
	if target:GetClassname() == "npc_dota_lone_druid_bear" then
		return false
	end
	return true
end

function modifier_lone_druid_synergy_handle:IsHidden()
	return true
end

function modifier_lone_druid_synergy_handle:IsPurgable()
	return false
end

function modifier_lone_druid_synergy_handle:RemoveOnDeath()
	return false
end

function modifier_lone_druid_synergy_handle:DestroyOnExpire()
	return false
end

modifier_lone_druid_synergy_aura = class({})
LinkLuaModifier( "modifier_lone_druid_synergy_aura", "heroes/hero_lone_druid/lone_druid_synergy", LUA_MODIFIER_MOTION_NONE )

function modifier_lone_druid_synergy_aura:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:GetAbility().linkedSpiritBear = self:GetParent()
		-- self:StartIntervalThink( 0.25 )
		self:OnIntervalThink( )
	end
end

function modifier_lone_druid_synergy_aura:OnRefresh()
	self.stat_share = self:GetSpecialValueFor("stat_share_pct") / 100

	self.bonus_attack_damage = self:GetSpecialValueFor("bonus_attack_damage")
	self.bonus_max_health = self:GetSpecialValueFor("bonus_max_health") + self:GetCaster():GetStrength() * 22 * self.stat_share
	
	self.bonus_health_regen = self:GetCaster():GetStrength() * 0.15
	self.bonus_attack_speed = math.floor( math.min( self:GetCaster():GetAgility() * self.stat_share, 25*(self.stat_share*self:GetCaster():GetAgility())^(math.log(2)/math.log(10)) ) )
	self.bonus_mana = self.stat_share * self:GetCaster():GetIntellect() * 2
	self.bonus_mana_regen = self.stat_share * self:GetCaster():GetIntellect() * 0.01
	self.bonus_spell_amp = self.stat_share * ( self:GetCaster():GetStrength() + self:GetCaster():GetAgility() + self:GetCaster():GetIntellect() ) * 0.03

	self.bonus_base_damage = self.stat_share * ( self:GetCaster():GetStrength() + self:GetCaster():GetAgility() + self:GetCaster():GetIntellect() ) * 1.4
	
	if IsServer() then
		local agilityArmor = math.min( 0.065 * self:GetCaster():GetAgility(), 0.9*self:GetCaster():GetAgility()^(math.log(2)/math.log(5)) )
		self:GetParent():SetPhysicalArmorBaseValue( 10 + agilityArmor )
		
		local intArmor =  math.min( 0.04 * self:GetCaster():GetIntellect(), 0.55*self:GetCaster():GetIntellect()^(math.log(2)/math.log(5)) )
		self:GetParent():SetBaseMagicalResistanceValue( 25 + intArmor )
		
		local entangle = self:GetParent():FindAbilityByName("lone_druid_spirit_bear_entangle")
		local ult = self:GetCaster():FindAbilityByName("lone_druid_true_form")
		
		if entangle and ult and entangle:GetLevel() ~= ult:GetLevel() then
			entangle:SetLevel( ult:GetLevel() )
		end
	end
end

function modifier_lone_druid_synergy_aura:OnIntervalThink()
	local caster = self:GetCaster()
	local bear = self:GetParent()
	local ability = self:GetAbility()
	
	if ability:GetToggleState() and not bear:HasModifier("modifier_lone_druid_synergy_damage_share") and caster:IsAlive() then
		bear:AddNewModifier( caster, ability, "modifier_lone_druid_synergy_damage_share", {} )
		caster:AddNewModifier( bear, ability, "modifier_lone_druid_synergy_damage_share", {} )
	end
end

function modifier_lone_druid_synergy_aura:IsHidden()
	return true
end

function modifier_lone_druid_synergy_aura:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEALTH_BONUS, 
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_MANA_BONUS,
			MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			}
end

function modifier_lone_druid_synergy_aura:GetModifierHealthBonus(params)
	return self.bonus_max_health
end

function modifier_lone_druid_synergy_aura:GetModifierConstantHealthRegen(params)
	return self.bonus_health_regen
end

function modifier_lone_druid_synergy_aura:GetModifierPreAttack_BonusDamage(params)
	return self.bonus_attack_damage
end

function modifier_lone_druid_synergy_aura:GetModifierBaseAttack_BonusDamage(params)
	return self.bonus_base_damage
end

function modifier_lone_druid_synergy_aura:GetModifierAttackSpeedBonus_Constant(params)
	return self.bonus_attack_speed
end

function modifier_lone_druid_synergy_aura:GetModifierManaBonus(params)
	return self.bonus_mana
end

function modifier_lone_druid_synergy_aura:GetModifierConstantManaRegen(params)
	return self.bonus_mana_regen
end

function modifier_lone_druid_synergy_aura:GetModifierSpellAmplify_Percentage(params)
	return self.bonus_spell_amp
end

function modifier_lone_druid_synergy_aura:IsHidden()
	return true
end

modifier_lone_druid_synergy_damage_share = class({})
LinkLuaModifier( "modifier_lone_druid_synergy_damage_share", "heroes/hero_lone_druid/lone_druid_synergy", LUA_MODIFIER_MOTION_NONE )

function modifier_lone_druid_synergy_damage_share:OnDestroy()
	if IsServer() then
		self:GetCaster():RemoveModifierByName("modifier_lone_druid_synergy_damage_share")
	end
end

function modifier_lone_druid_synergy_damage_share:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE}
end

function modifier_lone_druid_synergy_damage_share:GetModifierIncomingDamage_Percentage(params)
	local ability = self:GetAbility()
	if params.inflictor == ability then return end
	local parent = self:GetParent()
	local caster = self:GetCaster()
	
	local damageTaken = params.original_damage
	
	local reduction = 1 - parent:GetMaxHealth() / ( caster:GetMaxHealth() + parent:GetMaxHealth() )
	
	local damageShared = damageTaken * reduction
	ability:DealDamage( caster, caster, damageShared, {damage_type = params.damage_type, damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL } )
	
	return -(reduction * 100)
end

function modifier_lone_druid_synergy_damage_share:IsPurgable()
	return false
end