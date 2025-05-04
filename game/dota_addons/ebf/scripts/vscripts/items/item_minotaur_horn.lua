item_minotaur_horn = class({})

function item_minotaur_horn:GetIntrinsicModifierName()
	return "modifier_item_minotaur_horn_passive"
end

function item_minotaur_horn:OnSpellStart()
	local caster = self:GetCaster()
	EmitSoundOn("DOTA_Item.MinotaurHorn.Cast", caster )
	caster:Dispel( caster )
	caster:AddNewModifier( caster, self, "modifier_minotaur_horn_immune", {duration = self:GetSpecialValueFor("duration")} )
end

modifier_item_minotaur_horn_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_minotaur_horn_passive", "items/item_minotaur_horn.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_minotaur_horn_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_minotaur_horn_passive:OnRefresh()
	self.bonus_str = self:GetSpecialValueFor("bonus_str")
	self.bonus_hp_regen = self:GetSpecialValueFor("bonus_hp_regen")
end

function modifier_item_minotaur_horn_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT }
end

function modifier_item_minotaur_horn_passive:GetModifierBonusStats_Strength()
	return self.bonus_str
end

function modifier_item_minotaur_horn_passive:GetModifierConstantHealthRegen()
	return self.bonus_hp_regen
end