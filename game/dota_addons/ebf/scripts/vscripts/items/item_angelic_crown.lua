item_angelic_crown = class({})

function item_angelic_crown:GetIntrinsicModifierName()
	return "modifier_item_angelic_crown_passive"
end

modifier_item_angelic_crown_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_angelic_crown_passive", "items/item_angelic_crown.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_angelic_crown_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_angelic_crown_passive:OnRefresh()
	self.spell_amp = self:GetSpecialValueFor("spell_amp")
	self.heal_amp = self:GetSpecialValueFor("heal_amp")
	
	self.bonus_buff_durations = self:GetSpecialValueFor("bonus_buff_durations") / 100
end

function modifier_item_angelic_crown_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,				
			MODIFIER_EVENT_ON_MODIFIER_ADDED }
end

function modifier_item_angelic_crown_passive:GetModifierSpellAmplify_Percentage()
	return self.spell_amp
end

function modifier_item_angelic_crown_passive:GetModifierHealAmplify_PercentageTarget()
	return self.heal_amp
end

function modifier_item_angelic_crown_passive:OnModifierAdded( params )
	if params.unit == self:GetParent() then return end
	if params.attacker ~= self:GetParent() then return end
	if not params.attacker:IsSameTeam( params.unit ) then return end
	if params.added_buff:IsDebuff() then return end
	if params.added_buff:GetDuration() <= 0 then return end
	params.added_buff:SetDuration( params.added_buff:GetDuration() * (1 + self.bonus_buff_durations), true )
end