luna_lunar_blessing = class({})

function luna_lunar_blessing:GetIntrinsicModifierName()
	return "modifier_luna_lunar_blessing_passive"
end
function luna_lunar_blessing:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

modifier_luna_lunar_blessing_passive = class({})
LinkLuaModifier( "modifier_luna_lunar_blessing_passive", "heroes/hero_luna/luna_lunar_blessing.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_luna_lunar_blessing_passive:OnCreated()
	self:OnRefresh()
end
function modifier_luna_lunar_blessing_passive:OnRefresh()
	self.radius = self:GetSpecialValueFor("radius")
	self.night_vision_bonus = self:GetSpecialValueFor("night_vision_bonus")
	self.night_vision_bonus_per_level = self:GetSpecialValueFor("night_vision_bonus_per_level")
	self.stacking_damage_duration = self:GetSpecialValueFor("stacking_damage_duration")

	if IsServer() then
		for _, unit in ipairs(self:GetCaster():FindAllUnitsInRadius(self:GetCaster():GetAbsOrigin(), self.radius)) do
			if unit:HasModifier("modifier_luna_lunar_blessing_passive_aura") then
				unit:RemoveModifierByName("modifier_luna_lunar_blessing_passive_aura")
			end
		end		
	end
end
function modifier_luna_lunar_blessing_passive:IsAura()
	return true
end
function modifier_luna_lunar_blessing_passive:GetModifierAura()
	return "modifier_luna_lunar_blessing_passive_aura"
end
function modifier_luna_lunar_blessing_passive:GetAuraRadius()
	return self.radius
end
function modifier_luna_lunar_blessing_passive:GetAuraDuration()
	return 0.5
end
function modifier_luna_lunar_blessing_passive:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end
function modifier_luna_lunar_blessing_passive:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO
end
function modifier_luna_lunar_blessing_passive:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NONE
end
function modifier_luna_lunar_blessing_passive:IsHidden()
	return true
end
function modifier_luna_lunar_blessing_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end
function modifier_luna_lunar_blessing_passive:GetBonusNightVision()
	local total_bonus = self.night_vision_bonus + self.night_vision_bonus_per_level * self:GetCaster():GetLevel()
	return total_bonus
end
function modifier_luna_lunar_blessing_passive:OnAttackLanded(event)
	if event.attacker == self:GetParent() and self.stacking_damage_duration ~= 0 then
		self:AddIndependentStack({ duration = self.stacking_damage_duration })
	end
end

modifier_luna_lunar_blessing_passive_aura = class({})
LinkLuaModifier( "modifier_luna_lunar_blessing_passive_aura", "heroes/hero_luna/luna_lunar_blessing.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_luna_lunar_blessing_passive_aura:OnCreated()
	self:OnRefresh()
end
function modifier_luna_lunar_blessing_passive_aura:OnRefresh()
	self.damage = self:GetSpecialValueFor("damage")
	self.self_multiplier = self:GetSpecialValueFor("self_multiplier")
	self.night_multiplier = self:GetSpecialValueFor("night_multiplier")

	self.stacking_damage = self:GetSpecialValueFor("stacking_damage")
	self.stacking_damage_duration = self:GetSpecialValueFor("stacking_damage_duration")

	self.armor = self:GetSpecialValueFor("armor")

	if IsServer() then
		self:StartIntervalThink(0.25)
	end
end
function modifier_luna_lunar_blessing_passive_aura:OnIntervalThink()
	local buff = self:GetCaster():FindModifierByName("modifier_luna_lunar_blessing_passive")
	if buff and buff:GetStackCount() ~= self:GetStackCount() then
		self:SetStackCount(buff:GetStackCount())
	elseif not buff and self:GetStackCount() > 0 then
		self:SetStackCount(0)
	end
end
function modifier_luna_lunar_blessing_passive_aura:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end
function modifier_luna_lunar_blessing_passive_aura:GetModifierPreAttack_BonusDamage()
	local multiplier = 1.0
	if self:GetCaster() == self:GetParent() then
		multiplier = multiplier * self.self_multiplier
	end
	if self:GetCaster():GetCurrentVisionRange() == self:GetCaster():GetNightTimeVisionRange() then
		multiplier = multiplier * self.night_multiplier
	end

	return (self.damage + self.stacking_damage * self:GetStackCount()) * multiplier
end
function modifier_luna_lunar_blessing_passive_aura:GetModifierPhysicalArmorBonus()
	local multiplier = 1.0
	if self:GetCaster() == self:GetParent() then
		multiplier = multiplier * self.self_multiplier
	end
	if self:GetCaster():GetCurrentVisionRange() == self:GetCaster():GetNightTimeVisionRange() then
		multiplier = multiplier * self.night_multiplier
	end

	return self.armor * multiplier
end