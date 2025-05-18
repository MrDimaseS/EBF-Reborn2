item_vindicators_axe = class({})

function item_vindicators_axe:GetIntrinsicModifierName()
	return "modifier_item_vindicators_axe_passive"
end

modifier_item_vindicators_axe_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_vindicators_axe_passive", "items/item_vindicators_axe.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_vindicators_axe_passive:OnCreated()
	self:OnRefresh()
end

PARENT_IS_DEBUFFED = 1
PARENT_CANNOT_ATTACK = 2

function modifier_item_vindicators_axe_passive:OnRefresh()
	self.bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
	self.bonus_slow_resist = self:GetSpecialValueFor("bonus_slow_resist")
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
	
	if IsServer() then
		self:StartIntervalThink( 0.2 )
	end
end

function modifier_item_vindicators_axe_passive:OnIntervalThink()
	local bits = 0
	local parent = self:GetParent()
	local debuffs = 0
	for _, modifier in ipairs( parent:FindAllModifiers() ) do
		if modifier:IsDebuff() then
			bits = SetBit( bits, PARENT_IS_DEBUFFED )
			debuffs = debuffs + 1
		end
		local tState = {}
		modifier:CheckStateToTable(tState)
		if tState[tostring(MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS)] 
		or tState[tostring(MODIFIER_STATE_DISARMED)] 
		or tState[tostring(MODIFIER_STATE_CANNOT_TARGET_ENEMIES)] 
		or tState[tostring(MODIFIER_STATE_STUNNED)] 
		or tState[tostring(MODIFIER_STATE_HEXED)] 
		or tState[tostring(MODIFIER_STATE_NIGHTMARED)] 
		or tState[tostring(MODIFIER_STATE_FROZEN)] 
		or tState[tostring(MODIFIER_STATE_COMMAND_RESTRICTED)] 
		or tState[tostring(MODIFIER_STATE_FEARED)] 
		then
			bits = SetBit( bits, PARENT_CANNOT_ATTACK )
		end
	end
	self:SetStackCount( debuffs * 100 + bits )
end

function modifier_item_vindicators_axe_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_SLOW_RESISTANCE_STACKING,
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end

function modifier_item_vindicators_axe_passive:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

function modifier_item_vindicators_axe_passive:GetModifierSlowResistance_Stacking()
	return self.bonus_attack_speed
end

function modifier_item_vindicators_axe_passive:GetModifierPreAttack_BonusDamage()
	if HasBit(self:GetStackCount(), PARENT_IS_DEBUFFED) then
		return self.bonus_damage * math.floor( self:GetStackCount() / 100 )
	end
end

function modifier_item_vindicators_axe_passive:GetModifierPhysicalArmorBonus()
	if HasBit(self:GetStackCount(), PARENT_CANNOT_ATTACK) then
		return self.bonus_armor
	end
end