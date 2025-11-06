lycan_shapeshift = class({})

function lycan_shapeshift:OnSpellStart()
    local caster = self:GetCaster()
    local transformation_time = self:GetSpecialValueFor("transformation_time")
    local duration = self:GetSpecialValueFor("duration")

    local has_wolfbite = self:GetSpecialValueFor("has_wolfbite")
    local wolfbite = caster:FindAbilityByName("lycan_wolf_bite")

    ParticleManager:FireParticle("particles/units/heroes/hero_lycan/lycan_shapeshift_cast.vpcf", PATTACH_ABSORIGIN, caster)
    caster:AddNewModifier(caster, self, "modifier_lycan_shapeshift_transform", {duration = transformation_time})
    Timers:CreateTimer(transformation_time, function()
        caster:AddNewModifier(caster, self, "modifier_lycan_shapeshift_ebf", {duration = duration})
        caster:AddNewModifier(caster, self, "modifier_lycan_shapeshift_ebf_aura", {duration = duration})
        
        if has_wolfbite ~= 0 then
            wolfbite:SetHidden(false)
            caster:AddNewModifier(caster, self, "modifier_lycan_wolf_bite_lifesteal", {duration = duration})
        end
    end)

    caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_4)
    EmitSoundOn("Hero_Lycan.Shapeshift.Cast", caster)

end


modifier_lycan_shapeshift_ebf = class({})
LinkLuaModifier("modifier_lycan_shapeshift_ebf", "heroes/hero_lycan/lycan_shapeshift", LUA_MODIFIER_MOTION_NONE)
function modifier_lycan_shapeshift_ebf:IsHidden()
    return true
end

function modifier_lycan_shapeshift_ebf:IsPurgable()
    return false
end

function modifier_lycan_shapeshift_ebf:OnCreated()
    self:OnRefresh()
end

function modifier_lycan_shapeshift_ebf:OnRefresh()
    self.lifesteal = self:GetSpecialValueFor("lifesteal")
    self.has_wolfbite = self:GetSpecialValueFor("has_wolfbite")
    self.wolfbite = self:GetParent():FindAbilityByName("lycan_wolf_bite")

    self:GetParent()._attackLifestealModifiersList = self:GetParent()._attackLifestealModifiersList or {}
	self:GetParent()._attackLifestealModifiersList[self] = true
end

function modifier_lycan_shapeshift_ebf:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_PHYSICAL_LIFESTEAL
    }
end

function modifier_lycan_shapeshift_ebf:GetModifierProperty_PhysicalLifesteal()
    return self.lifesteal
end

function modifier_lycan_shapeshift_ebf:OnDestroy()
    if IsServer() then
        if self.has_wolfbite ~= 0 then
            self.wolfbite:SetHidden(true)
        end
    end
end

modifier_lycan_shapeshift_ebf_aura = class({})
LinkLuaModifier("modifier_lycan_shapeshift_ebf_aura", "heroes/hero_lycan/lycan_shapeshift", LUA_MODIFIER_MOTION_NONE)


function modifier_lycan_shapeshift_ebf_aura:IsHidden()
    return true
end

function modifier_lycan_shapeshift_ebf_aura:IsAura()
    return true
end

function modifier_lycan_shapeshift_ebf_aura:GetAuraRadius()
    return 99999
end

function modifier_lycan_shapeshift_ebf_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_lycan_shapeshift_ebf_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_CREEP
end

function modifier_lycan_shapeshift_ebf_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS
end

function modifier_lycan_shapeshift_ebf_aura:GetAuraEntityReject(target)
    return not target:GetPlayerOwnerID() == self:GetParent():GetPlayerOwnerID()
end

function modifier_lycan_shapeshift_ebf_aura:GetModifierAura()
    return "modifier_lycan_shapeshift_ebf_summon"
end

modifier_lycan_shapeshift_ebf_summon = class({})
LinkLuaModifier("modifier_lycan_shapeshift_ebf_summon", "heroes/hero_lycan/lycan_shapeshift", LUA_MODIFIER_MOTION_NONE)

function modifier_lycan_shapeshift_ebf_summon:OnCreated()
    if IsServer() then
        self.lifesteal = self:GetSpecialValueFor("lifesteal")
        self.crit_chance = self:GetSpecialValueFor("crit_chance")
        self.crit_multiplier = self:GetSpecialValueFor("crit_multiplier")
        self.speed = self:GetSpecialValueFor("speed")
        self.current_speed = self:GetParent():GetBaseMoveSpeed()
        self:GetParent():SetBaseMoveSpeed(self.speed)

        self.nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_lycan/lycan_shapeshift_buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
                    ParticleManager:SetParticleControlEnt(self.nfx, 0 , self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), false)
                    ParticleManager:SetParticleControlEnt(self.nfx, 1 , self:GetParent(), PATTACH_POINT_FOLLOW, "attach_attack1", self:GetParent():GetAbsOrigin(), false)

        self:GetParent()._attackLifestealModifiersList = self:GetParent()._attackLifestealModifiersList or {}
	    self:GetParent()._attackLifestealModifiersList[self] = true
    end
end

function modifier_lycan_shapeshift_ebf_summon:OnDestroy()
    if IsServer() then
        self:GetParent():SetBaseMoveSpeed(self.current_speed)
        ParticleManager:DestroyParticle(self.nfx, true)
    end
end

function modifier_lycan_shapeshift_ebf_summon:CheckState()
    return
    {
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_UNSLOWABLE] = true
    }
end

function modifier_lycan_shapeshift_ebf_summon:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PHYSICAL_LIFESTEAL
    }
end

function modifier_lycan_shapeshift_ebf_summon:GetModifierProperty_PhysicalLifesteal()
    return self.lifesteal
end

function modifier_lycan_shapeshift_ebf_summon:GetModifierPreAttack_CriticalStrike()
    if self:RollPRNG(self.crit_chance) then
        return self.crit_multiplier
    end
end

function modifier_lycan_shapeshift_ebf_summon:GetCritDamage()
    return self.crit_multiplier / 100
end