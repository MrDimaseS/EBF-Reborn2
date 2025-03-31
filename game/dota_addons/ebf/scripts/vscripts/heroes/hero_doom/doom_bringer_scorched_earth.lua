doom_bringer_scorched_earth = class({})

function doom_bringer_scorched_earth:OnSpellStart()
    print("silly")
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")

    caster:AddNewModifier(caster, self, "modifier_doom_bringer_scorched_earth_ebf", { duration = duration })
end

modifier_doom_bringer_scorched_earth_ebf = class({})
LinkLuaModifier( "modifier_doom_bringer_scorched_earth_ebf", "heroes/hero_doom/doom_bringer_scorched_earth", LUA_MODIFIER_MOTION_NONE )

function modifier_doom_bringer_scorched_earth_ebf:IsHidden()
    return false
end
function modifier_doom_bringer_scorched_earth_ebf:IsDebuff()
    return false
end
function modifier_doom_bringer_scorched_earth_ebf:IsPurgable()
    return false
end
function modifier_doom_bringer_scorched_earth_ebf:IsAura()
	return true
end
function modifier_doom_bringer_scorched_earth_ebf:GetModifierAura()
	return "modifier_doom_bringer_scorched_earth_ebf_aura"
end
function modifier_doom_bringer_scorched_earth_ebf:GetAuraRadius()
	return self.radius
end
function modifier_doom_bringer_scorched_earth_ebf:GetAuraDuration()
	return 0.5
end
function modifier_doom_bringer_scorched_earth_ebf:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end
function modifier_doom_bringer_scorched_earth_ebf:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HEROES_AND_CREEPS
end
function modifier_doom_bringer_scorched_earth_ebf:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NONE
end
function modifier_doom_bringer_scorched_earth_ebf:OnCreated()
   self:OnRefresh() 
   if IsClient() then return end

   -- particles
    local particle = "particles/units/heroes/hero_doom_bringer/doom_scorched_earth.vpcf"
    local effect = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(effect, 1, Vector(self.radius, 0, 0))
    self:AddParticle(effect, false, false, -1, false, false)

    -- sounds
    local sound = "Hero_DoomBringer.ScorchedEarthAura"
    EmitSoundOn(sound, self:GetParent())
end
function modifier_doom_bringer_scorched_earth_ebf:OnRefresh()
    self.radius = self:GetSpecialValueFor("radius")
    self.bonus_movement_speed_pct = self:GetSpecialValueFor("bonus_movement_speed_pct")
    
    self.incoming_healing = self:GetSpecialValueFor("incoming_healing")
    self.attack_speed = self:GetSpecialValueFor("attack_speed")
end
function modifier_doom_bringer_scorched_earth_ebf:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
end
function modifier_doom_bringer_scorched_earth_ebf:GetModifierMoveSpeedBonus_Percentage()
    return self.bonus_movement_speed_pct
end
function modifier_doom_bringer_scorched_earth_ebf:GetModifierHealAmplify_PercentageTarget()
    return self.incoming_healing
end
function modifier_doom_bringer_scorched_earth_ebf:GetModifierHPRegenAmplify_Percentage()
    return self.incoming_healing
end
function modifier_doom_bringer_scorched_earth_ebf:GetModifierLifestealRegenAmplify_Percentage()
    return self.incoming_healing
end
function modifier_doom_bringer_scorched_earth_ebf:GetModifierSpellLifestealRegenAmplify_Percentage()
    return self.incoming_healing
end
function modifier_doom_bringer_scorched_earth_ebf:GetModifierAttackSpeedBonus_Constant()
    return self.attack_speed
end

modifier_doom_bringer_scorched_earth_ebf_aura = class({})
LinkLuaModifier( "modifier_doom_bringer_scorched_earth_ebf_aura", "heroes/hero_doom/doom_bringer_scorched_earth", LUA_MODIFIER_MOTION_NONE )

function modifier_doom_bringer_scorched_earth_ebf_aura:IsHidden()
    return false
end
function modifier_doom_bringer_scorched_earth_ebf_aura:IsDebuff()
    return true
end
function modifier_doom_bringer_scorched_earth_ebf_aura:IsPurgable()
    return false
end
function modifier_doom_bringer_scorched_earth_ebf_aura:OnCreated()
    self:OnRefresh()

    if IsClient() then return end
    self:StartIntervalThink(1.0)
end
function modifier_doom_bringer_scorched_earth_ebf_aura:OnRefresh()
    self.damage_per_second = self:GetSpecialValueFor("damage_per_second")
    self.attack_speed_slow = self:GetSpecialValueFor("attack_speed_slow")
    self.movement_slow = self:GetSpecialValueFor("movement_slow")
end
function modifier_doom_bringer_scorched_earth_ebf_aura:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    if ability then
        ability:DealDamage(caster, parent, self.damage_per_second, { damage_type = DAMAGE_TYPE_MAGICAL })

        -- particles
        local particle = "particles/units/heroes/hero_doom_bringer/doom_bringer_scorched_earth_debuff.vpcf"
        local effect = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, parent)
        ParticleManager:ReleaseParticleIndex(effect)
    else
        self:Destroy()
    end
end
function modifier_doom_bringer_scorched_earth_ebf_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
end
function modifier_doom_bringer_scorched_earth_ebf_aura:GetModifierMoveSpeedBonus_Percentage()
    return -self.movement_slow
end
function modifier_doom_bringer_scorched_earth_ebf_aura:GetModifierAttackSpeedBonus_Constant()
    return -self.attack_speed_slow
end