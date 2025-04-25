bristleback_warpath = class({})

function bristleback_warpath:GetIntrinsicModifierName()
    return "modifier_bristleback_warpath_passive"
end
function bristleback_warpath:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")
    caster:AddNewModifier(caster, self, "modifier_bristleback_warpath_active_ebf", { duration = duration })
    self:AddStack()
end
function bristleback_warpath:AddStack()
    if self:GetCaster():PassivesDisabled() then return end
    local stack_duration = self:GetSpecialValueFor("stack_duration")
    local max_stacks = self:GetSpecialValueFor("max_stacks")
    local passive = self:GetCaster():FindModifierByName("modifier_bristleback_warpath_passive")
    if passive then
        passive:AddIndependentStack({ duration = stack_duration, limit = max_stacks })
    end
end
function bristleback_warpath:GetStackCount()
    local passive = self:GetCaster():FindModifierByName("modifier_bristleback_warpath_passive")
    if passive then
        return passive:GetStackCount()
    else
        return 0
    end
end
function bristleback_warpath:IsActive()
    return self:GetCaster():HasModifier("modifier_bristleback_warpath_active_ebf")
end

modifier_bristleback_warpath_passive = class({})
LinkLuaModifier( "modifier_bristleback_warpath_passive", "heroes/hero_bristleback/bristleback_warpath", LUA_MODIFIER_MOTION_NONE )

function modifier_bristleback_warpath_passive:IsHidden()
    return false
end
function modifier_bristleback_warpath_passive:IsDebuff()
    return false
end
function modifier_bristleback_warpath_passive:IsPurgable()
    return false
end
function modifier_bristleback_warpath_passive:OnCreated()
    self:OnRefresh()
end
function modifier_bristleback_warpath_passive:OnRefresh()
    self.damage_per_stack = self:GetSpecialValueFor("damage_per_stack")
    self.movespeed_per_stack = self:GetSpecialValueFor("movespeed_per_stack")
    self.active_multiplier = self:GetSpecialValueFor("active_multiplier")
    self.stack_duration = self:GetSpecialValueFor("stack_duration")
    self.max_stacks = self:GetSpecialValueFor("max_stacks")

    self.goo_damage_per_stack = self:GetSpecialValueFor("goo_damage_per_stack")
    self.spell_amp_per_stack = self:GetSpecialValueFor("spell_amp_per_stack")
    self.attack_speed_per_stack = self:GetSpecialValueFor("attack_speed_per_stack")
end
function modifier_bristleback_warpath_passive:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
end
function modifier_bristleback_warpath_passive:GetModifierPreAttack_BonusDamage()
    local active = self:GetCaster():HasModifier("modifier_bristleback_warpath_active_ebf")
    return self.damage_per_stack * self:GetStackCount() * TernaryOperator(self.active_multiplier, active, 1.0)
end
function modifier_bristleback_warpath_passive:GetModifierMoveSpeedBonus_Percentage()
    local active = self:GetCaster():HasModifier("modifier_bristleback_warpath_active_ebf")
    return self.movespeed_per_stack * self:GetStackCount() * TernaryOperator(self.active_multiplier, active, 1.0)
end
function modifier_bristleback_warpath_passive:GetModifierSpellAmplify_Percentage()
    local active = self:GetCaster():HasModifier("modifier_bristleback_warpath_active_ebf")
    return self.spell_amp_per_stack * self:GetStackCount() * TernaryOperator(self.active_multiplier, active, 1.0)
end
function modifier_bristleback_warpath_passive:GetModifierAttackSpeedBonus_Constant()
    local active = self:GetCaster():HasModifier("modifier_bristleback_warpath_active_ebf")
    return self.attack_speed_per_stack * self:GetStackCount() * TernaryOperator(self.active_multiplier, active, 1.0)
end

modifier_bristleback_warpath_active_ebf = class({})
LinkLuaModifier( "modifier_bristleback_warpath_active_ebf", "heroes/hero_bristleback/bristleback_warpath", LUA_MODIFIER_MOTION_NONE )

function modifier_bristleback_warpath_active_ebf:IsHidden()
    return false
end
function modifier_bristleback_warpath_active_ebf:IsDebuff()
    return false
end
function modifier_bristleback_warpath_active_ebf:IsPurgable()
    return false
end
function modifier_bristleback_warpath_active_ebf:OnCreated()
    self:OnRefresh()

	self:GetParent().cooldownModifiers = self:GetParent().cooldownModifiers or {}
	self:GetParent().cooldownModifiers[self] = true
    
    self:GetParent()._spellLifestealModifiersList = self:GetParent()._spellLifestealModifiersList or {}
    self:GetParent()._spellLifestealModifiersList[self] = true

    self:GetParent()._attackLifestealModifiersList = self:GetParent()._attackLifestealModifiersList or {}
    self:GetParent()._attackLifestealModifiersList[self] = true
end
function modifier_bristleback_warpath_active_ebf:OnDestroy()
	self:GetParent().cooldownModifiers[self] = nil
    self:GetParent()._spellLifestealModifiersList[self] = nil
    self:GetParent()._attackLifestealModifiersList[self] = nil
end
function modifier_bristleback_warpath_active_ebf:OnRefresh()
    self.active_cast_speed = self:GetSpecialValueFor("active_cast_speed")
    self.active_spell_lifesteal = self:GetSpecialValueFor("active_spell_lifesteal")
    self.active_lifesteal = self:GetSpecialValueFor("active_lifesteal")
end
function modifier_bristleback_warpath_active_ebf:GetModifierCastSpeed(params)
	return self.active_cast_speed
end
function modifier_bristleback_warpath_active_ebf:GetModifierProperty_MagicalLifesteal(params)
	return self.active_spell_lifesteal
end
function modifier_bristleback_warpath_active_ebf:GetModifierProperty_PhysicalLifesteal(params)
	return self.active_lifesteal
end