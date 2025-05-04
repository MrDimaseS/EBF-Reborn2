item_nemesis_curse = class({})

function item_nemesis_curse:GetIntrinsicModifierName()
	return "modifier_item_nemesis_curse_passive"
end

modifier_item_nemesis_curse_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_nemesis_curse_passive", "items/item_nemesis_curse.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_nemesis_curse_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_nemesis_curse_passive:OnRefresh()
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.spell_amp = self:GetSpecialValueFor("spell_amp")
	
	self.duration = self:GetSpecialValueFor("debuff_enemy_duration")
end

function modifier_item_nemesis_curse_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_EVENT_ON_ATTACK }
end


function modifier_item_nemesis_curse_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_nemesis_curse_passive:GetModifierSpellAmplify_Percentage()
	return self.spell_amp
end

function modifier_item_nemesis_curse_passive:OnAttack( params )
	local parent = self:GetParent()
	if params.attacker ~= parent then return end
	params.target:AddNewModifier( params.attacker, self:GetAbility(), "modifier_item_nemesis_curse_debuff", {duration = self.duration} )
end