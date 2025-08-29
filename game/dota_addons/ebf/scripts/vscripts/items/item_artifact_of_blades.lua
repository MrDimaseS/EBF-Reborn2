item_artifact_of_blades = class({})

function item_artifact_of_blades:GetIntrinsicModifierName()
	return "modifier_item_artifact_of_blades_passive"
end

modifier_item_artifact_of_blades_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_artifact_of_blades_passive", "items/item_artifact_of_blades.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_artifact_of_blades_passive:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:GetCaster():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_item_artifact_of_blades_buff", {} )
	end
end

function modifier_item_artifact_of_blades_passive:OnRefresh()
	self.threshold = self:GetSpecialValueFor("threshold")
end

function modifier_item_artifact_of_blades_passive:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK}
end

function modifier_item_artifact_of_blades_passive:OnAttack( params )
	if params.attacker ~= self:GetParent() then return end
	if params.no_attack_cooldown then return end
	self._internalDamageCounter = (self._internalDamageCounter or 0) + 1
	while self._internalDamageCounter >= self.threshold do
		self._internalDamageCounter = self._internalDamageCounter - self.threshold
		self:GetCaster():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_item_artifact_of_blades_buff", {} )
	end
end

function modifier_item_artifact_of_blades_passive:RemoveOnDeath()
	return false
end

modifier_item_artifact_of_blades_buff = class({})
LinkLuaModifier( "modifier_item_artifact_of_blades_buff", "items/item_artifact_of_blades.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_artifact_of_blades_buff:OnCreated()
	self:OnRefresh(nil, bFirst)
	if IsServer() then
		self:SetStackCount( self:GetSpecialValueFor("initial_value") )
	end
end

function modifier_item_artifact_of_blades_buff:OnRefresh(kv, first)
	self.bonus = self.bonus or self:GetSpecialValueFor("bonus")
	self.real_bonus = self.bonus * self:GetParent():GetHeroPowerAmplification(  )
	if IsServer() then
		if not first then
			self:IncrementStackCount()
		end
		self:GetParent():CalculateGenericBonuses( )
		self:GetParent():CalculateStatBonus( false )
	end
end

function modifier_item_artifact_of_blades_buff:OnStackCountChanged()
	self.real_bonus = self.bonus * self:GetParent():GetHeroPowerAmplification(  )
end

function modifier_item_artifact_of_blades_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE}
end

function modifier_item_artifact_of_blades_buff:GetModifierPreAttack_BonusDamage()
	return math.floor( ( self.real_bonus or self.bonus ) * self:GetStackCount() + 0.5 )
end

function modifier_item_artifact_of_blades_buff:GetTexture()
	return "item_artifact_of_blades"
end

function modifier_item_artifact_of_blades_buff:IsPermanent()
	return true
end

function modifier_item_artifact_of_blades_buff:RemoveOnDeath()
	return false
end

function modifier_item_artifact_of_blades_buff:IsPurgable()
	return false
end