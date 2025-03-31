alchemist_midas_touch = class({})

function alchemist_midas_touch:GetIntrinsicModifierName()
	return "modifier_alchemist_midas_touch_passive"
end

modifier_alchemist_midas_touch_passive = class({})
LinkLuaModifier( "modifier_alchemist_midas_touch_passive", "heroes/hero_alchemist/alchemist_midas_touch", LUA_MODIFIER_MOTION_NONE )

function modifier_alchemist_midas_touch_passive:IsHidden()
    return true
end
function modifier_alchemist_midas_touch_passive:OnCreated()
    self:OnRefresh()
end
function modifier_alchemist_midas_touch_passive:OnRefresh()
    self.chance = self:GetSpecialValueFor("chance")
    self.duration = self:GetSpecialValueFor("duration")
end
function modifier_alchemist_midas_touch_passive:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end
function modifier_alchemist_midas_touch_passive:OnAttackLanded(params)
    if params.attacker ~= self:GetParent() then return end
	if params.attacker:PassivesDisabled() then return end
	if not self:GetAbility():IsFullyCastable() then return end
    
    if self:RollPRNG(self.chance) then
        params.target:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_alchemist_midas_touch", { duration = self.duration })
		self:GetAbility():SetCooldown()
        if IsClient() then return end
        -- sounds
        local sound = "General.Coins"
        params.target:EmitSoundParams(sound, 0, 0.5, 0)
    end
end

modifier_alchemist_midas_touch = class({})
LinkLuaModifier( "modifier_alchemist_midas_touch", "heroes/hero_alchemist/alchemist_midas_touch", LUA_MODIFIER_MOTION_NONE )

function modifier_alchemist_midas_touch:IsHidden()
    return false
end
function modifier_alchemist_midas_touch:IsDebuff()
    return true
end
function modifier_alchemist_midas_touch:IsStunDebuff()
	return true
end
function modifier_alchemist_midas_touch:IsPurgable()
	return false
end
function modifier_alchemist_midas_touch:GetEffectName()
    return "particles/econ/items/axe/axe_ti9_immortal/axe_ti9_gold_call_crack_01.vpcf"
end
function modifier_alchemist_midas_touch:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
function modifier_alchemist_midas_touch:GetStatusEffectName()
	return "particles/econ/items/effigies/status_fx_effigies/status_effect_aghs_gold_statue.vpcf"
end
function modifier_alchemist_midas_touch:OnCreated()
    self:OnRefresh()
end
function modifier_alchemist_midas_touch:OnRefresh()
    self.damage_increase = self:GetSpecialValueFor("damage_increase")
end
function modifier_alchemist_midas_touch:StatusEffectPriority()
	return 10
end
function modifier_alchemist_midas_touch:CheckState()
    return {
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_FROZEN] = true
    }
end
function modifier_alchemist_midas_touch:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
    }
end
function modifier_alchemist_midas_touch:GetModifierIncomingDamage_Percentage()
    return self.damage_increase
end