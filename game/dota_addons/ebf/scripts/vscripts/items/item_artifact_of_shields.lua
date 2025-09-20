item_artifact_of_shields = class({})

function item_artifact_of_shields:GetIntrinsicModifierName()
	return "modifier_item_artifact_of_shields_passive"
end

modifier_item_artifact_of_shields_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_artifact_of_shields_passive", "items/item_artifact_of_shields.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_artifact_of_shields_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_artifact_of_shields_passive:OnRefresh()
	self.threshold = self:GetSpecialValueFor("threshold")
end

function modifier_item_artifact_of_shields_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE}
end

function modifier_item_artifact_of_shields_passive:GetModifierIncomingDamage_Percentage( params )
	self._internalDamageCounter = (self._internalDamageCounter or 0) + params.damage
	while self._internalDamageCounter > self.threshold do
		self._internalDamageCounter = self._internalDamageCounter - self.threshold
		self:GetCaster():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_item_artifact_of_shields_buff", {} )
	end
end

function modifier_item_artifact_of_shields_passive:RemoveOnDeath()
	return false
end

modifier_item_artifact_of_shields_buff = class({})
LinkLuaModifier( "modifier_item_artifact_of_shields_buff", "items/item_artifact_of_shields.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_artifact_of_shields_buff:OnCreated(kv)
	self:OnRefresh(kv, true)
	self:SetStackCount( 0 )
end

function modifier_item_artifact_of_shields_buff:OnRefresh(kv, first)
	local bonus = self.bonus
	self.bonus = self:GetSpecialValueFor("bonus") or bonus
	local initial_value = self.initial_value
	self.initial_value = self:GetSpecialValueFor("initial_value") or initial_value
	if IsServer() then
		if not first then
			self:IncrementStackCount()
		end
		self:GetParent():CalculateGenericBonuses( )
		self:GetParent():CalculateStatBonus( false )
	end
end

function modifier_item_artifact_of_shields_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS}
end

function modifier_item_artifact_of_shields_buff:GetModifierExtraHealthBonus()
	return self.initial_value + math.floor( self.real_bonus * self:GetStackCount() + 0.5 )
end

function modifier_item_artifact_of_shields_buff:GetTexture()
	return "item_artifact_of_shields"
end

function modifier_item_artifact_of_shields_buff:IsPermanent()
	return true
end

function modifier_item_artifact_of_shields_buff:RemoveOnDeath()
	return false
end

function modifier_item_artifact_of_shields_buff:IsPurgable()
	return false
end