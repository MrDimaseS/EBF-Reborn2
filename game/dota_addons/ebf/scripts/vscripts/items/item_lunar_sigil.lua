item_lunar_sigil = class({})

function item_lunar_sigil:GetIntrinsicModifierName()
	return "modifier_item_lunar_sigil_passive"
end

function item_lunar_sigil:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	local debuffDuration = self:GetSpecialValueFor("debuff_duration")
	target:AddNewModifier( caster, self, "modifier_item_lunar_sigil_active", {duration = debuffDuration} )
end

modifier_item_lunar_sigil_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_lunar_sigil_passive", "items/item_lunar_sigil.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_lunar_sigil_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_lunar_sigil_passive:OnRefresh()
	self.bonus_spell_amp = self:GetSpecialValueFor("bonus_spell_amp")
	self.bonus_mana = self:GetSpecialValueFor("bonus_mana")
	self.bonus_mana_regen = self:GetSpecialValueFor("bonus_mana_regen")
end

function modifier_item_lunar_sigil_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_MANA_BONUS,				
			MODIFIER_PROPERTY_MANA_REGEN_CONSTANT}
end

function modifier_item_lunar_sigil_passive:GetModifierSpellAmplify_Percentage()
	return self.bonus_spell_amp
end

function modifier_item_lunar_sigil_passive:GetModifierManaBonus()
	return self.bonus_mana
end

function modifier_item_lunar_sigil_passive:GetModifierConstantManaRegen()
	return self.bonus_mana_regen
end

modifier_item_lunar_sigil_active = class({})
LinkLuaModifier( "modifier_item_lunar_sigil_active", "items/item_lunar_sigil.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_lunar_sigil_active:OnCreated()
	self:OnRefresh()
	if IsServer() then
		local parent = self:GetParent()
		local FX = ParticleManager:CreateParticle("particles/items2_fx/lunar_sigil_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
		ParticleManager:SetParticleControlEnt( FX, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true )
		ParticleManager:SetParticleControl( FX, 2, Vector( parent:GetHullRadius() * 2, 0, 0 ) )
		self:AddEffect( FX )
	end
end

function modifier_item_lunar_sigil_active:OnRefresh()
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
end

function modifier_item_lunar_sigil_active:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE}
end

function modifier_item_lunar_sigil_active:GetModifierIncomingDamage_Percentage( params )
	if params.damage_category ~= DOTA_DAMAGE_CATEGORY_SPELL then return end
	if self.bonus_damage <= 0 then return end
	local bonusDamage = math.min( params.damage, self.bonus_damage )
	local dmgPct = (params.damage + bonusDamage) / params.damage
	self.bonus_damage = math.max( 0, self.bonus_damage - params.damage )
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, params.target, bonusDamage, self:GetCaster():GetPlayerOwner())
	if self.bonus_damage <= 0 then
		self:Destroy()
	end
	return dmgPct * 100 - 100
end