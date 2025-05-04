item_spark_of_courage = class({})

function item_spark_of_courage:GetIntrinsicModifierName()
	return "modifier_item_spark_of_courage_passive"
end

modifier_item_spark_of_courage_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_spark_of_courage_passive", "items/item_spark_of_courage.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_spark_of_courage_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_spark_of_courage_passive:OnRefresh()
	self.damage = self:GetSpecialValueFor("damage")
	self.armor = self:GetSpecialValueFor("armor")
	
	self.health_pct = self:GetSpecialValueFor("health_pct")
	self.threshold_bonus = self:GetSpecialValueFor("threshold_bonus") / 100
end

function modifier_item_spark_of_courage_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE ,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end

function modifier_item_spark_of_courage_passive:GetModifierPreAttack_BonusDamage()
	return self.damage * (1 + TernaryOperator( self.threshold_bonus, self:GetParent():GetHealthPercent() >= self.health_pct, 0 ))
end

function modifier_item_spark_of_courage_passive:GetModifierPhysicalArmorBonus()
	return self.armor * (1 + TernaryOperator( self.threshold_bonus, self:GetParent():GetHealthPercent() <= self.health_pct, 0 ))
end