item_bottle_ebf = class({})

function item_bottle_ebf:GetBehavior()
	if self:GetCurrentCharges() == 0 then
		return DOTA_ABILITY_BEHAVIOR_PASSIVE
	else
		return DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_SUPPRESS_ASSOCIATED_CONSUMABLE
	end
end

function item_bottle_ebf:GetAbilityTextureName()
	if self:GetCurrentCharges() == 3 then
		return "bottle"
	elseif self:GetCurrentCharges() == 2 then
		return "bottle_medium"
	elseif self:GetCurrentCharges() == 1 then
		return "bottle_small"
	else
		return "bottle_empty"
	end
end

function item_bottle_ebf:OnSpellStart()
	if self:GetCurrentCharges() == 0 then return end
	local caster = self:GetCaster()
	
	caster:AddNewModifier( caster, self, "modifier_item_bottle_ebf", {duration = self:GetSpecialValueFor("restore_time") } )
	EmitSoundOn( "Bottle.Drink", caster )
	
	self:SetCurrentCharges( math.max( 0, self:GetCurrentCharges() - 1 ) )
end

modifier_item_bottle_ebf = class({})
LinkLuaModifier( "modifier_item_bottle_ebf", "items/item_bottle_ebf.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_bottle_ebf:OnCreated()
	self:OnRefresh()
end

function modifier_item_bottle_ebf:OnRefresh()
	self.health_regen = (self:GetSpecialValueFor("base_health_restore") + self:GetParent():GetLevel() * self:GetSpecialValueFor("lvl_health_restore")) / self:GetRemainingTime()
	self.health_regen_pct = self:GetSpecialValueFor("health_restore_pct") / self:GetRemainingTime()
	self.mana_regen = (self:GetSpecialValueFor("base_mana_restore") + self:GetParent():GetLevel() * self:GetSpecialValueFor("lvl_mana_restore")) / self:GetRemainingTime()
	self.mana_regen_pct = self:GetSpecialValueFor("mana_restore_pct") / self:GetRemainingTime()
end
			
function modifier_item_bottle_ebf:OnDestroy()
	self:GetParent().cooldownModifiers[self] = nil
end

function modifier_item_bottle_ebf:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
			MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
			MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
			MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE,
			}
end

function modifier_item_bottle_ebf:GetModifierConstantHealthRegen()
	return self.health_regen
end

function modifier_item_bottle_ebf:GetModifierHealthRegenPercentage()
	return self.health_regen_pct
end

function modifier_item_bottle_ebf:GetModifierConstantManaRegen()
	return self.mana_regen
end

function modifier_item_bottle_ebf:GetModifierTotalPercentageManaRegen()
	return self.mana_regen_pct
end

function modifier_item_bottle_ebf:GetEffectName()
	return "particles/items_fx/bottle.vpcf"
end

function modifier_item_bottle_ebf:GetTexture()
	return "bottle"
end