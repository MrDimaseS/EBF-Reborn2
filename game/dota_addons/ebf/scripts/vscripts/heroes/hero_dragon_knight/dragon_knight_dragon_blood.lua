dragon_knight_dragon_blood = class({})

function dragon_knight_dragon_blood:GetIntrinsicModifierName()
    return "modifier_dragon_knight_dragon_blood_passive"
end

modifier_dragon_knight_dragon_blood_passive = class({})
LinkLuaModifier( "modifier_dragon_knight_dragon_blood_passive", "heroes/hero_dragon_knight/dragon_knight_dragon_blood", LUA_MODIFIER_MOTION_NONE )

function modifier_dragon_knight_dragon_blood_passive:IsHidden()
    return true
end
function modifier_dragon_knight_dragon_blood_passive:IsPurgable()
    return false
end
function modifier_dragon_knight_dragon_blood_passive:OnCreated()
    self:OnRefresh()
end
function modifier_dragon_knight_dragon_blood_passive:OnRefresh()
    self.magic_damage = self:GetSpecialValueFor("magic_attack_damage")
    self.bonus_aoe = self:GetSpecialValueFor("bonus_radius")
    self.corrosive_breath_duration = self:GetSpecialValueFor("poison_duration")
    self.frost_duration = self:GetSpecialValueFor("freeze_duration")
    self.elder_dragon_form_bonus = self:GetSpecialValueFor("elder_dragon_form_bonus") / 100 + 1
    self:GetCaster()._aoeModifiersList = self:GetCaster()._aoeModifiersList or {}
    self:GetCaster()._aoeModifiersList[self] = true
end
function modifier_dragon_knight_dragon_blood_passive:OnDestroy()
    self:GetCaster()._aoeModifiersList[self] = nil
end
function modifier_dragon_knight_dragon_blood_passive:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_AOE_BONUS_CONSTANT_STACKING,
        MODIFIER_EVENT_ON_ATTACK
    }
end
function modifier_dragon_knight_dragon_blood_passive:GetModifierProcAttack_BonusDamage_Magical()
    return self.magic_damage * TernaryOperator(self.elder_dragon_form_bonus, self:GetCaster():HasModifier("modifier_dragon_knight_elder_dragon_form_buff"), 1.0)
end
function modifier_dragon_knight_dragon_blood_passive:GetModifierAoEBonusConstantStacking()
    return self.bonus_aoe * TernaryOperator(self.elder_dragon_form_bonus, self:GetCaster():HasModifier("modifier_dragon_knight_elder_dragon_form_buff"), 1.0)
end
function modifier_dragon_knight_dragon_blood_passive:OnAttack(event)
    if IsClient()
    or (self.corrosive_breath_duration == 0 and self.frost_duration == 0)
    or not event.attacker
    or not event.target
    or event.attacker ~= self:GetParent()
    then return end

    local duration = TernaryOperator(self.corrosive_breath_duration, self.corrosive_breath_duration ~= 0, self.frost_duration)
    event.target:AddNewModifier(event.attacker, self:GetAbility(), "modifier_dragon_knight_dragon_blood_debuff", { duration = duration, dragon_form = event.attacker:HasModifier("modifier_dragon_knight_elder_dragon_form_buff") })
end

modifier_dragon_knight_dragon_blood_debuff = class({})
LinkLuaModifier( "modifier_dragon_knight_dragon_blood_debuff", "heroes/hero_dragon_knight/dragon_knight_dragon_blood", LUA_MODIFIER_MOTION_NONE )

function modifier_dragon_knight_dragon_blood_debuff:IsHidden()
    return false
end
function modifier_dragon_knight_dragon_blood_debuff:IsDebuff()
    return true
end
function modifier_dragon_knight_dragon_blood_debuff:IsPurgable()
    return true
end
function modifier_dragon_knight_dragon_blood_debuff:OnCreated(params)
    self:OnRefresh(params)
    if IsClient() then return end

    if self.corrosive_breath_damage ~= 0 then
        self:StartIntervalThink(1.0)
    end
end
function modifier_dragon_knight_dragon_blood_debuff:OnRefresh(params)
    self.corrosive_breath_damage = self:GetSpecialValueFor("poison_damage")
    self.corrosive_breath_armor = self:GetSpecialValueFor("poison_armor")
    self.frost_bonus_movement_speed = self:GetSpecialValueFor("freeze_movement_slow")
    self.frost_bonus_attack_speed = self:GetSpecialValueFor("freeze_attack_slow")
    self.frost_healing_reduction = self:GetSpecialValueFor("freeze_heal_reduction")
    self.elder_dragon_form_bonus = TernaryOperator(self:GetSpecialValueFor("elder_dragon_form_bonus") / 100 + 1, params.dragon_form, 1.0)
end
function modifier_dragon_knight_dragon_blood_debuff:OnIntervalThink()
    self:GetAbility():DealDamage(self:GetCaster(), self:GetParent(), self.corrosive_breath_damage * self.elder_dragon_form_bonus, { damage_type = DAMAGE_TYPE_PHYSICAL })
end
function modifier_dragon_knight_dragon_blood_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE
    }
end
function modifier_dragon_knight_dragon_blood_debuff:GetModifierPhysicalArmorBonus()
    return -self.corrosive_breath_armor * self.elder_dragon_form_bonus
end
function modifier_dragon_knight_dragon_blood_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self.frost_bonus_movement_speed * self.elder_dragon_form_bonus
end
function modifier_dragon_knight_dragon_blood_debuff:GetModifierAttackSpeedBonus_Constant()
    return self.frost_bonus_attack_speed * self.elder_dragon_form_bonus
end
function modifier_dragon_knight_dragon_blood_debuff:GetModifierHealthRegenPercentage()
    return self.frost_healing_reduction * self.elder_dragon_form_bonus
end
function modifier_dragon_knight_dragon_blood_debuff:GetModifierHealAmplify_PercentageTarget()
    return self.frost_healing_reduction * self.elder_dragon_form_bonus
end
function modifier_dragon_knight_dragon_blood_debuff:GetModifierLifestealRegenAmplify_Percentage()
    return self.frost_healing_reduction * self.elder_dragon_form_bonus
end
function modifier_dragon_knight_dragon_blood_debuff:GetModifierSpellLifestealRegenAmplify_Percentage()
    return self.frost_healing_reduction * self.elder_dragon_form_bonus
end