item_gale_guard = class({})

function item_gale_guard:GetIntrinsicModifierName()
	return "modifier_item_gale_guard_passive"
end

function item_gale_guard:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier( caster, self, "modifier_item_gale_guard", {duration = self:GetSpecialValueFor("barrier_duration")} )
end

modifier_item_gale_guard_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_gale_guard_passive", "items/item_gale_guard.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_gale_guard_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_gale_guard_passive:OnRefresh()
	self.armor = self:GetSpecialValueFor("armor")
	self.spell_amp = self:GetSpecialValueFor("spell_amp")
end

function modifier_item_gale_guard_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			}
end

function modifier_item_gale_guard_passive:GetModifierPhysicalArmorBonus( params )
	return self.armor
end

function modifier_item_gale_guard_passive:GetModifierSpellAmplify_Percentage()
	return self.spell_amp
end