item_hand_of_midas_ebf = class({})

function item_hand_of_midas_ebf:GetIntrinsicModifierName()
	return "modifier_hand_of_midas_passive"
end

function item_hand_of_midas_ebf:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	caster:AddGold( self._currentGoldStorage )
	self:Destroy()
end

modifier_hand_of_midas_passive = class({})
LinkLuaModifier( "modifier_hand_of_midas_passive", "items/item_hand_of_midas.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_hand_of_midas_passive:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:SetHasCustomTransmitterData(true)
	end
end

function modifier_hand_of_midas_passive:OnRefresh()
	self.bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
	if IsServer() then
		print("midas refresh?")
		self:SendBuffRefreshToClients()
	end
end

function modifier_hand_of_midas_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_TOOLTIP}
end

function modifier_hand_of_midas_passive:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

function modifier_hand_of_midas_passive:OnTooltip()
	return self.total_gold
end

function modifier_hand_of_midas_passive:AddCustomTransmitterData()
	return { total_gold = self:GetAbility()._currentGoldStorage }
end

function modifier_hand_of_midas_passive:HandleCustomTransmitterData(data)
	self.total_gold = data.total_gold
	print( self.total_gold, data.total_gold )
end

function modifier_hand_of_midas_passive:IsHidden()
	return false
end

function modifier_hand_of_midas_passive:IsPurgable()
	return false
end

function modifier_hand_of_midas_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end