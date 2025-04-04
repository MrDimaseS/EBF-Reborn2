dragon_knight_elder_dragon_form = class({})

function dragon_knight_elder_dragon_form:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")

    caster:AddNewModifier(caster, self, "modifier_dragon_knight_elder_dragon_form_buff", { duration = duration })
    
    local breathe_fire = caster:FindAbilityByName("dragon_knight_breathe_fire")
    if not breathe_fire then return end
    if breathe_fire:IsHidden() then return end -- already swapped em
    
	local fireball = caster:FindAbilityByName("dragon_knight_fireball")
    caster:SwapAbilities(
        breathe_fire:GetAbilityName(),
        fireball:GetAbilityName(),
        false,
        true
    )
end

modifier_dragon_knight_elder_dragon_form_buff = class({})
LinkLuaModifier( "modifier_dragon_knight_elder_dragon_form_buff", "heroes/hero_dragon_knight/dragon_knight_elder_dragon_form", LUA_MODIFIER_MOTION_NONE )

function modifier_dragon_knight_elder_dragon_form_buff:IsHidden()
    return false
end
function modifier_dragon_knight_elder_dragon_form_buff:IsDebuff()
    return false
end
function modifier_dragon_knight_elder_dragon_form_buff:IsPurgable()
    return false
end
function modifier_dragon_knight_elder_dragon_form_buff:OnCreated()
    self.parent = self:GetParent()
    self.form = TernaryOperator("red", self:GetSpecialValueFor("is_red_dragon") == 1, TernaryOperator("green", self:GetSpecialValueFor("is_green_dragon") == 1, "blue"))
    self.bonus_movement_speed = self:GetSpecialValueFor("bonus_movement_speed")
    self.bonus_attack_range = self:GetSpecialValueFor("bonus_attack_range")
    self.bonus_attack_damage = self:GetSpecialValueFor("bonus_attack_damage")
    self.ranged_splash_radius = self:GetSpecialValueFor("ranged_splash_radius")
    self.ranged_splash_damage_pct = self:GetSpecialValueFor("ranged_splash_damage_pct")
    self.model_scale = self:GetSpecialValueFor("model_scale")

    if IsClient() then return end

    self.previous_attack_capability = self.parent:GetAttackCapability()
    self.parent:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
    if self.form == "red" then
        self.projectile = "particles/units/heroes/hero_dragon_knight/dragon_knight_elder_dragon_fire.vpcf"
        self.attack_sound = "Hero_DragonKnight.ElderDragonShoot2.Attack"
        self.transform = "particles/units/heroes/hero_dragon_knight/dragon_knight_transform_red.vpcf"
    elseif self.form == "green" then
        self.projectile = "particles/units/heroes/hero_dragon_knight/dragon_knight_elder_dragon_corrosive.vpcf"
        self.attack_sound = "Hero_DragonKnight.ElderDragonShoot1.Attack"
        self.transform = "particles/units/heroes/hero_dragon_knight/dragon_knight_transform_green.vpcf"
    elseif self.form == "blue" then
        self.projectile = "particles/units/heroes/hero_dragon_knight/dragon_knight_elder_dragon_frost.vpcf"
        self.attack_sound = "Hero_DragonKnight.ElderDragonShoot3.Attack"
        self.transform = "particles/units/heroes/hero_dragon_knight/dragon_knight_transform_blue.vpcf"
    else
        print("ruh roh raggy")
        return
    end

    -- particles
    local particle = self.transform
    local effect =  ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, self.parent)
    ParticleManager:ReleaseParticleIndex(effect)

    -- sounds
    local sound = "Hero_DragonKnight.ElderDragonForm"
    EmitSoundOn(sound, self.parent)
end
function modifier_dragon_knight_elder_dragon_form_buff:OnDestroy()
    if IsClient() then return end

    self.parent:SetAttackCapability(self.previous_attack_capability)
    
    local caster = self:GetCaster()
    local breathe_fire = caster:FindAbilityByName("dragon_knight_breathe_fire")
    if not breathe_fire then return end
	local fireball = caster:FindAbilityByName("dragon_knight_fireball")
	if not fireball then return end

    caster:SwapAbilities(
        fireball:GetAbilityName(),
        breathe_fire:GetAbilityName(),
        false,
        true
    )
    
    -- particles
    local particle = self.transform
    local effect =  ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, self.parent)
    ParticleManager:ReleaseParticleIndex(effect)

    -- sounds
    local sound = "Hero_DragonKnight.ElderDragonForm.Revert"
    EmitSoundOn(sound, self.parent)
end
function modifier_dragon_knight_elder_dragon_form_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_PROPERTY_MODEL_CHANGE,
        MODIFIER_PROPERTY_MODEL_SCALE,
        MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,
        MODIFIER_PROPERTY_PROJECTILE_NAME,
        MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK
    }
end
function modifier_dragon_knight_elder_dragon_form_buff:GetModifierBaseAttack_BonusDamage()
    return self.bonus_attack_damage
end
function modifier_dragon_knight_elder_dragon_form_buff:GetModifierMoveSpeedBonus_Constant()
    return self.bonus_movement_speed
end
function modifier_dragon_knight_elder_dragon_form_buff:GetModifierAttackRangeBonus()
    return self.bonus_attack_range
end
function modifier_dragon_knight_elder_dragon_form_buff:GetModifierModelChange()
    return "models/heroes/dragon_knight/dragon_knight_dragon.vmdl"
end
function modifier_dragon_knight_elder_dragon_form_buff:GetModifierModelScale()
    return self.model_scale
end
function modifier_dragon_knight_elder_dragon_form_buff:GetAttackSound()
    return self.attack_sound
end
function modifier_dragon_knight_elder_dragon_form_buff:GetModifierProjectileName()
    return self.projectile
end
function modifier_dragon_knight_elder_dragon_form_buff:GetModifierProjectileSpeedBonus()
    return 900
end
function modifier_dragon_knight_elder_dragon_form_buff:GetModifierProcAttack_Feedback(event)
    if not event.target
    or event.target:GetTeamNumber() == self.parent:GetTeamNumber()
    then return end

    -- splash damage and modifiers
    local wyrms_wrath = self.parent:FindAbilityByName("dragon_knight_dragon_blood")
    local magic_damage = wyrms_wrath:GetSpecialValueFor("magic_attack_damage")
    local corrosive_breath_duration = wyrms_wrath:GetSpecialValueFor("poison_duration")
    local frost_duration = wyrms_wrath:GetSpecialValueFor("freeze_duration")
    local elder_dragon_form_bonus = wyrms_wrath:GetSpecialValueFor("elder_dragon_form_bonus") / 100 + 1
    local duration = TernaryOperator(corrosive_breath_duration, corrosive_breath_duration ~= 0, frost_duration)

    local ability = self:GetAbility()
    local enemies = self.parent:FindEnemyUnitsInRadius(event.target:GetOrigin(), self.ranged_splash_radius)
    for _, enemy in ipairs(enemies) do
        if enemy ~= event.target then
            ability:DealDamage(
                self.parent,
                enemy,
                event.damage * self.ranged_splash_damage_pct / 100.0,
                {
                    damage_type = DAMAGE_TYPE_PHYSICAL,
                    damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL
                }
            )

            if magic_damage ~= 0 then
                ability:DealDamage(self.parent, enemy, magic_damage * elder_dragon_form_bonus, { damage_type = DAMAGE_TYPE_MAGICAL })
            end
            if duration ~= 0 and wyrms_wrath then
                enemy:AddNewModifier(self.parent, wyrms_wrath, "modifier_dragon_knight_dragon_blood_debuff", { duration = duration, dragon_form = true })
            end
        end
    end
end