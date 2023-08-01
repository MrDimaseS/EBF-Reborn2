skywrath_mage_shield_of_the_scion = class({})

function skywrath_mage_shield_of_the_scion:GetIntrinsicModifierName()
	return "modifier_skywrath_mage_shield_of_the_scion_handler"
end

modifier_skywrath_mage_shield_of_the_scion_handler = class({})
LinkLuaModifier( "modifier_skywrath_mage_shield_of_the_scion_handler","heroes/hero_skywrath_mage/skywrath_mage_shield_of_the_scion.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_skywrath_mage_shield_of_the_scion_handler:OnCreated()
	self.bonus_intelligence = self:GetSpecialValueFor("bonus_intelligence")
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
	
	self.stack_duration = self:GetSpecialValueFor("stack_duration")
	self.creep_chance = self:GetSpecialValueFor("creep_chance")
end

function modifier_skywrath_mage_shield_of_the_scion_handler:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}
end

function modifier_skywrath_mage_shield_of_the_scion_handler:GetModifierBonusStats_Intellect()
	return self.bonus_intelligence * self:GetStackCount()
end

function modifier_skywrath_mage_shield_of_the_scion_handler:GetModifierPhysicalArmorBonus()
	return self.bonus_armor * self:GetStackCount()
end

function modifier_skywrath_mage_shield_of_the_scion_handler:OnTakeDamage( params )
	if params.attacker == self:GetParent() and params.inflictor then
		if params.attacker:HasAbility( params.inflictor:GetAbilityName() ) then
			if params.unit:IsConsideredHero() or RollPercentage( self.creep_chance ) then
				self:AddIndependentStack( self.stack_duration )
				self:SetDuration( self.stack_duration, true )
				params.attacker:CalculateStatBonus( true )
			end
		end
	end
end

function modifier_skywrath_mage_shield_of_the_scion_handler:IsHidden()
	return self:GetStackCount() <= 0
end

function modifier_skywrath_mage_shield_of_the_scion_handler:DestroyOnExpire()
	return false
end

function modifier_skywrath_mage_shield_of_the_scion_handler:IsPurgable()
	return false
end

function modifier_skywrath_mage_shield_of_the_scion_handler:IsPermanent()
	return true
end