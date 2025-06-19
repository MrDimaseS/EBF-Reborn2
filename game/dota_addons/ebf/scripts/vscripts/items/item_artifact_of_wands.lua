item_artifact_of_wands = class({})

function item_artifact_of_wands:GetIntrinsicModifierName()
	return "modifier_item_artifact_of_wands_passive"
end

modifier_item_artifact_of_wands_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_artifact_of_wands_passive", "items/item_artifact_of_wands.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_artifact_of_wands_passive:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:GetCaster():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_item_artifact_of_wands_buff", {} )
	end
end

function modifier_item_artifact_of_wands_passive:OnRefresh()
	self.threshold = self:GetSpecialValueFor("threshold")
end

function modifier_item_artifact_of_wands_passive:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ABILITY_FULLY_CAST}
end

function modifier_item_artifact_of_wands_passive:OnAbilityFullyCast( params )
	if params.unit ~= self:GetParent() then return end
	if params.ability:GetCooldown( -1 ) == 0 then return end
	if params.ability:GetCooldownTimeRemaining() == 0 then return end
	self._internalDamageCounter = (self._internalDamageCounter or 0) + 1
	while self._internalDamageCounter >= self.threshold do
		self._internalDamageCounter = self._internalDamageCounter - self.threshold
		self:GetCaster():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_item_artifact_of_wands_buff", {} )
	end
end

function modifier_item_artifact_of_wands_passive:RemoveOnDeath()
	return false
end

modifier_item_artifact_of_wands_buff = class({})
LinkLuaModifier( "modifier_item_artifact_of_wands_buff", "items/item_artifact_of_wands.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_artifact_of_wands_buff:OnCreated()
	self:OnRefresh()
	self:SetStackCount( self:GetSpecialValueFor("initial_value") / self.bonus )
end

function modifier_item_artifact_of_wands_buff:OnRefresh()
	self.bonus = self:GetSpecialValueFor("bonus")
	self.real_bonus = self.bonus
	if IsServer() then
		self:IncrementStackCount()
		self:GetParent():CalculateGenericBonuses( )
		self:GetParent():CalculateStatBonus( false )
	end
end

function modifier_item_artifact_of_wands_buff:OnStackCountChanged()
	self.real_bonus = self.bonus
end

function modifier_item_artifact_of_wands_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE}
end

function modifier_item_artifact_of_wands_buff:GetModifierSpellAmplify_Percentage()
	return self.real_bonus * self:GetStackCount()
end

function modifier_item_artifact_of_wands_buff:GetTexture()
	return "item_artifact_of_wands"
end

function modifier_item_artifact_of_wands_buff:IsPermanent()
	return true
end

function modifier_item_artifact_of_wands_buff:RemoveOnDeath()
	return false
end

function modifier_item_artifact_of_wands_buff:IsPurgable()
	return false
end