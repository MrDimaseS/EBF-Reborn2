item_desolator = class({})

function item_desolator:GetIntrinsicModifierName()
	return "modifier_item_desolator_passive"
end

item_desolator2 = class(item_desolator)
item_desolator3 = class(item_desolator)
item_desolator4 = class(item_desolator)
item_desolator5 = class(item_desolator)

modifier_item_desolator_soul_stealer = class({})
LinkLuaModifier( "modifier_item_desolator_soul_stealer", "items/item_desolator.lua", LUA_MODIFIER_MOTION_NONE )

modifier_item_desolator_passive = class({})
LinkLuaModifier( "modifier_item_desolator_passive", "items/item_desolator.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_desolator_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_desolator_passive:OnRefresh()
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.kill_bonus_damage = self:GetSpecialValueFor("kill_bonus_damage")/100
	self.corruption_duration = self:GetSpecialValueFor("corruption_duration")
	self.kill_duration = self:GetSpecialValueFor("kill_duration")
end

function modifier_item_desolator_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_EVENT_ON_ATTACK_LANDED,
			MODIFIER_EVENT_ON_DEATH}
end

function modifier_item_desolator_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage * (1 + TernaryOperator(self.kill_bonus_damage, self:GetParent():HasModifier("modifier_item_desolator_soul_stealer"), 0 ) )
end

function modifier_item_desolator_passive:OnAttackLanded( params )
	if params.attacker == self:GetParent() and not params.attacker:IsIllusion() then
		params.target:AddNewModifier( params.attacker, self:GetAbility(), "modifier_desolator_buff", {duration = self.corruption_duration} )
	end
end

function modifier_item_desolator_passive:OnDeath( params )
	if params.unit:HasModifier("modifier_desolator_buff") then
		self:GetParent():AddNewModifier( self:GetParent(), self:GetAbility(), "modifier_item_desolator_soul_stealer", {duration = self.kill_duration} )
	end
end

function modifier_item_desolator_passive:IsHidden()
	return true
end

function modifier_item_desolator_passive:IsPurgable()
	return false
end

function modifier_item_desolator_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end