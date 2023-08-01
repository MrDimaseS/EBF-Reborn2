neutral_upgrade = class({})

function neutral_upgrade:GetIntrinsicModifierName()
	return "modifier_neutral_upgrade_ebfr_passive"
end


modifier_neutral_upgrade_ebfr_passive = class({})
LinkLuaModifier("modifier_neutral_upgrade_ebfr_passive", "bosses/neutral_upgrade", 0)

function modifier_neutral_upgrade_ebfr_passive:OnCreated()
	self:OnRefresh()
end

function modifier_neutral_upgrade_ebfr_passive:OnRefresh()
	self.increase_pct = self:GetSpecialValueFor("increase_pct")
	self.increase_reward_pct = self:GetSpecialValueFor("increase_reward_pct")
	self.increase_damage = self:GetSpecialValueFor("increase_damage")
	self.increase_aspd = self:GetSpecialValueFor("increase_aspd")
	self.increase_health = self:GetSpecialValueFor("increase_health")
	self.increase_armor = self:GetSpecialValueFor("increase_armor")
	self.increase_magic_resist = self:GetSpecialValueFor("increase_magic_resist")
	self.increase_gold = self:GetSpecialValueFor("increase_gold")
	
	local parent = self:GetParent()
	self.baseDamage = self.baseDamage or math.ceil( (parent:GetDamageMax() + parent:GetDamageMax())/2 )
	if IsServer() then
		local roundNumber = GameRules._roundnumber
		if GameRules._NewGamePlus then
			roundNumber = roundNumber + 25
		end
		self:SetStackCount( roundNumber )
		
		self.baseMinGold = self.baseMinGold or parent:GetMinimumGoldBounty()
		self.baseMaxGold = self.baseMaxGold or parent:GetMaximumGoldBounty()
		
		local preGold =  self:GetParent():GetMinimumGoldBounty()
		parent:SetMinimumGoldBounty( (self.baseMinGold + self.increase_gold * self:GetStackCount() ) * ( 1 + self:GetStackCount() * self.increase_reward_pct / 100 ) )
		parent:SetMaximumGoldBounty( (self.baseMaxGold + self.increase_gold * self:GetStackCount() ) * ( 1 + self:GetStackCount() * self.increase_reward_pct / 100 ) )
		
		parent:SetDeathXP( 0 )
		
		parent:CalculateGenericBonuses()
		
		self:StartIntervalThink(0.25)
		
		for i = 0, parent:GetAbilityCount() - 1 do
			local ability = parent:GetAbilityByIndex( i )
			if ability and ability ~= self:GetAbility() then
				ability:SetLevel( math.ceil( self:GetStackCount() / 3 ) )
			end
		end
	end
end

function modifier_neutral_upgrade_ebfr_passive:OnSetStackCountChanged(previousStacks)
	if previousStacks ~= self:GetStackCount() and IsClient() then
		self:OnRefresh()
	end
end

function modifier_neutral_upgrade_ebfr_passive:OnIntervalThink()
	if self:GetStackCount() ~= GameRules._roundnumber then
		self:SetStackCount( GameRules._roundnumber )
		self:OnRefresh()
	end
end

function modifier_neutral_upgrade_ebfr_passive:DeclareFunctions(params)
	local funcs = {
		MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE,
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
    return funcs
end

function modifier_neutral_upgrade_ebfr_passive:GetModifierExtraHealthPercentage()
	return self:GetStackCount() * self.increase_pct
end

function modifier_neutral_upgrade_ebfr_passive:GetModifierExtraHealthBonus()
	return self:GetStackCount()^2 * self.increase_health
end

function modifier_neutral_upgrade_ebfr_passive:GetModifierBaseAttack_BonusDamage()
	return self.baseDamage * self:GetStackCount() * self.increase_pct / 100
end

function modifier_neutral_upgrade_ebfr_passive:GetModifierPreAttack_BonusDamage()
	return self:GetStackCount()^2 * self.increase_damage
end

function modifier_neutral_upgrade_ebfr_passive:GetModifierAttackSpeedBonus_Constant()
	return self:GetStackCount() * self.increase_aspd
end

function modifier_neutral_upgrade_ebfr_passive:GetModifierPhysicalArmorBonus()
	return self:GetStackCount() * self.increase_armor
end

function modifier_neutral_upgrade_ebfr_passive:GetModifierMagicalResistanceBonus()
	return self:GetStackCount() * self.increase_magic_resist
end

function modifier_neutral_upgrade_ebfr_passive:IsHidden()
	return true
end