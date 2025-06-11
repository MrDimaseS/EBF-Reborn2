item_artifact_of_balance = class({})

function item_artifact_of_balance:GetIntrinsicModifierName()
	return "modifier_item_artifact_of_balance_passive"
end

modifier_item_artifact_of_balance_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_artifact_of_balance_passive", "items/item_artifact_of_balance.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_artifact_of_balance_passive:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink( self.threshold )
	end
end

function modifier_item_artifact_of_balance_passive:OnRefresh()
	self.threshold = self:GetSpecialValueFor("threshold")
end

function modifier_item_artifact_of_balance_passive:OnIntervalThink()
	self:GetParent():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_item_artifact_of_balance_buff", {} )
end

function modifier_item_artifact_of_balance_passive:RemoveOnDeath()
	return false
end

modifier_item_artifact_of_balance_buff = class({})
LinkLuaModifier( "modifier_item_artifact_of_balance_buff", "items/item_artifact_of_balance.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_artifact_of_balance_buff:OnCreated()
	self:OnRefresh()
	self:SetStackCount( self:GetSpecialValueFor("initial_value") )
end

function modifier_item_artifact_of_balance_buff:OnRefresh()
	self.bonus = self:GetSpecialValueFor("bonus")
	self.real_bonus = self.bonus * self:GetParent():GetHeroPowerAmplification(  )
	if IsServer() then
		self:IncrementStackCount()
		self:GetParent():CalculateGenericBonuses( )
		self:GetParent():CalculateStatBonus( false )
	end
end

function modifier_item_artifact_of_balance_buff:OnStackCountChanged()
	self.real_bonus = self.bonus * self:GetParent():GetHeroPowerAmplification(  )
end

function modifier_item_artifact_of_balance_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS }
end

function modifier_item_artifact_of_balance_buff:GetModifierBonusStats_Strength()
	return self.real_bonus * self:GetStackCount()
end

function modifier_item_artifact_of_balance_buff:GetModifierBonusStats_Agility()
	return self.real_bonus * self:GetStackCount()
end

function modifier_item_artifact_of_balance_buff:GetModifierBonusStats_Intellect()
	return self.real_bonus * self:GetStackCount()
end

function modifier_item_artifact_of_balance_buff:GetTexture()
	return "item_artifact_of_balance"
end

function modifier_item_artifact_of_balance_buff:IsPermanent()
	return true
end

function modifier_item_artifact_of_balance_buff:RemoveOnDeath()
	return false
end

function modifier_item_artifact_of_balance_buff:IsPurgable()
	return false
end