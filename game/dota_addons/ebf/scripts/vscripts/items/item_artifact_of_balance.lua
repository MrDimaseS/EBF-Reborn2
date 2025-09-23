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
	if not self:GetParent():HasModifier("modifier_item_artifact_of_balance_buff") then
		self:GetParent():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_item_artifact_of_balance_buff", {} )
	end
end

function modifier_item_artifact_of_balance_passive:OnIntervalThink()
	self:GetParent():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_item_artifact_of_balance_buff", {} )
end

function modifier_item_artifact_of_balance_passive:RemoveOnDeath()
	return false
end

modifier_item_artifact_of_balance_buff = class({})
LinkLuaModifier( "modifier_item_artifact_of_balance_buff", "items/item_artifact_of_balance.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_artifact_of_balance_buff:OnCreated(kv)
	self:OnRefresh(kv, true)
end

function modifier_item_artifact_of_balance_buff:OnRefresh(kv, bFirst)
	local bonus = self.bonus or 0
	self.bonus = math.max( self:GetSpecialValueFor("bonus"), or bonus )
	print( bonus, self:GetSpecialValueFor("bonus"), self.bonus, "bonus")
	local initial_value = self.initial_value or 0
	self.initial_value = self:GetSpecialValueFor("initial_value") or initial_value
	print( initial_value, self:GetSpecialValueFor("initial_value"), self.initial_value, "initial_value")
	if IsServer() then
		if not bFirst then
			self:IncrementStackCount()
		end
		self:GetParent():CalculateGenericBonuses( )
		self:GetParent():CalculateStatBonus( false )
	end
end

function modifier_item_artifact_of_balance_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS }
end

function modifier_item_artifact_of_balance_buff:GetModifierBonusStats_Strength()
	return self.initial_value + self.bonus * self:GetStackCount()
end

function modifier_item_artifact_of_balance_buff:GetModifierBonusStats_Agility()
	return self.initial_value + self.bonus * self:GetStackCount()
end

function modifier_item_artifact_of_balance_buff:GetModifierBonusStats_Intellect()
	return self.initial_value + self.bonus * self:GetStackCount()
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