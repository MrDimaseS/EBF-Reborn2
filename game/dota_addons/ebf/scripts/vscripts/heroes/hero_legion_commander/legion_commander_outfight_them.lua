legion_commander_outfight_them = class({})

function legion_commander_outfight_them:GetIntrinsicModifierName()
	return "modifier_legion_commander_outfight_them_innate"
end

modifier_legion_commander_outfight_them_innate = class({})
LinkLuaModifier("modifier_legion_commander_outfight_them_innate", "heroes/hero_legion_commander/legion_commander_outfight_them", LUA_MODIFIER_MOTION_NONE)

function modifier_legion_commander_outfight_them_innate:OnCreated()
	self.heal_bonus_pct = self:GetSpecialValueFor("heal_bonus_pct")
	self.duration = self:GetSpecialValueFor("duration")
	self:SetStackCount(1)
end

function modifier_legion_commander_outfight_them_innate:OnIntervalThink()
	self:SetStackCount(1)
	self:StartIntervalThink( -1 )
end

function modifier_legion_commander_outfight_them_innate:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK, 
			 MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
			 MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
			 MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
			 MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
		}
end

function modifier_legion_commander_outfight_them_innate:OnAttack( params )
	if not ( params.attacker == self:GetCaster() and params.target:IsConsideredHero() ) then return end
	self:SetStackCount(0)
	self:StartIntervalThink( self.duration )
	self:SetDuration( self.duration, true )
end

function modifier_legion_commander_outfight_them_innate:GetModifierHPRegenAmplify_Percentage()
	if self:GetStackCount() == 0 then
		return self.heal_bonus_pct
	end
end

function modifier_legion_commander_outfight_them_innate:GetModifierHealAmplify_PercentageTarget()
	if self:GetStackCount() == 0 then
		return self.heal_bonus_pct
	end
end

function modifier_legion_commander_outfight_them_innate:GetModifierLifestealRegenAmplify_Percentage()
	if self:GetStackCount() == 0 then
		return self.heal_bonus_pct
	end
end

function modifier_legion_commander_outfight_them_innate:GetModifierSpellLifestealRegenAmplify_Percentage()
	if self:GetStackCount() == 0 then
		return self.heal_bonus_pct
	end
end

function modifier_legion_commander_outfight_them_innate:IsHidden()
	return self:GetStackCount() == 1
end

function modifier_legion_commander_outfight_them_innate:IsPurgable()
	return false
end

function modifier_legion_commander_outfight_them_innate:DestroyOnExpire()
	return false
end
