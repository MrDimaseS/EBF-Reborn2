winter_wyvern_winters_curse = class({})

function winter_wyvern_winters_curse:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local duration = self:GetSpecialValueFor("duration")
    local radius = self:GetSpecialValueFor("radius")

    if target:TriggerSpellAbsorb(self) then return end

    target:AddNewModifier(caster, self, "modifier_winter_wyvern_winters_curse_ebf", {duration = duration})
    target:AddNewModifier(caster, self, "modifier_winter_wyvern_winters_curse_ebf_enemy_aura", {duration = duration})

    local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_winter_wyvern/wyvern_winters_curse_ground.vpcf", PATTACH_ABSORIGIN, target)
                ParticleManager:SetParticleControl(nfx, 2, Vector(radius, 1, 1))

    EmitSoundOn("Hero_Winter_Wyvern.WintersCurse.Cast", caster)
    EmitSoundOn("Hero_Winter_Wyvern.WintersCurse.Target", target)
end

modifier_winter_wyvern_winters_curse_ebf = class({})
LinkLuaModifier("modifier_winter_wyvern_winters_curse_ebf", "heroes/hero_winter_wyvern/winter_wyvern_winters_curse", LUA_MODIFIER_MOTION_NONE)

function modifier_winter_wyvern_winters_curse_ebf:OnCreated()
    self.parent = self:GetParent()
    self.radius = self:GetSpecialValueFor("radius")
    self.nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_winter_wyvern/wyvern_winters_curse.vpcf", PATTACH_ABSORIGIN, self.parent)
               ParticleManager:SetParticleControl(self.nfx, 2, Vector(1, 1, self.radius))
    self.overhead = ParticleManager:CreateParticle("particles/units/heroes/hero_winter_wyvern/wyvern_winters_curse_overhead.vpcf", PATTACH_OVERHEAD_FOLLOW, self.parent)

    if IsServer() then
        for _, cursed_units in ipairs(self:GetCaster():FindEnemyUnitsInRadius(self.parent:GetAbsOrigin(), self.radius)) do
            if cursed_units:HasModifier("modifier_winter_wyvern_winters_curse_ebf_enemy") then
                cursed_units:SetForceAttackTargetAlly(self.parent)
                cursed_units:MoveToTargetToAttack(self.parent)
                cursed_units:SetAttacking(self.parent)

                ExecuteOrderFromTable({
                    UnitIndex = cursed_units:entindex(),
                    OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
                    TargetIndex = self.parent:entindex()
			    })
            end
        end
    end
end

function modifier_winter_wyvern_winters_curse_ebf:OnDestroy()
    ParticleManager:DestroyParticle(self.nfx, false)
    ParticleManager:DestroyParticle(self.overhead, false)
end

function modifier_winter_wyvern_winters_curse_ebf:CheckState()
    return
    {
        [MODIFIER_STATE_INVISIBLE] = false,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_FROZEN] = true,
        [MODIFIER_STATE_SPECIALLY_DENIABLE] = true
    }
end

modifier_winter_wyvern_winters_curse_ebf_enemy = class({})
LinkLuaModifier("modifier_winter_wyvern_winters_curse_ebf_enemy", "heroes/hero_winter_wyvern/winter_wyvern_winters_curse", LUA_MODIFIER_MOTION_NONE)

function modifier_winter_wyvern_winters_curse_ebf_enemy:OnCreated()
    if IsServer() then
        self.nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_winter_wyvern/wyvern_winters_curse_buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
        self:AddEffect(self.nfx)
    end
    self.aspd_bonus = self:GetSpecialValueFor("bonus_attack_speed")
end


function modifier_winter_wyvern_winters_curse_ebf_enemy:OnDestroy()
    if IsServer() then
        self:GetParent():SetForceAttackTargetAlly(nil)
    end
end

function modifier_winter_wyvern_winters_curse_ebf_enemy:DeclareFunctions()
    return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT}
end

function modifier_winter_wyvern_winters_curse_ebf_enemy:CheckState()
    if IsServer() then
        return
        {
            [MODIFIER_STATE_TAUNTED] = true,
            [MODIFIER_STATE_SILENCED] = true,
            [MODIFIER_STATE_MUTED] = true,
            --[MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS] = self.enemy
        }
    end
end

function modifier_winter_wyvern_winters_curse_ebf_enemy:GetModifierAttackSpeedBonus_Constant()
    return self.aspd_bonus
end

modifier_winter_wyvern_winters_curse_ebf_enemy_aura = class({})
LinkLuaModifier("modifier_winter_wyvern_winters_curse_ebf_enemy_aura", "heroes/hero_winter_wyvern/winter_wyvern_winters_curse", LUA_MODIFIER_MOTION_NONE)

function modifier_winter_wyvern_winters_curse_ebf_enemy_aura:IsHidden()
    return true
end

function modifier_winter_wyvern_winters_curse_ebf_enemy_aura:OnCreated()
    self:OnRefresh()
end

function modifier_winter_wyvern_winters_curse_ebf_enemy_aura:OnRefresh()
    self.affects_allies = self:GetSpecialValueFor("affects_allies")
    self.radius = self:GetSpecialValueFor("radius")
end

function modifier_winter_wyvern_winters_curse_ebf_enemy_aura:IsAura()
    return true
end

function modifier_winter_wyvern_winters_curse_ebf_enemy_aura:GetAuraRadius()
    return self.radius
end

function modifier_winter_wyvern_winters_curse_ebf_enemy_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_winter_wyvern_winters_curse_ebf_enemy_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_ALL
end

function modifier_winter_wyvern_winters_curse_ebf_enemy_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS
end

function modifier_winter_wyvern_winters_curse_ebf_enemy_aura:GetModifierAura()
    return "modifier_winter_wyvern_winters_curse_ebf_enemy"
end



--[[
modifier_winter_wyvern_winters_curse_ebf_ally = class({})
LinkLuaModifier("modifier_winter_wyvern_winters_curse_ebf_ally", "heroes/hero_winter_wyvern/winter_wyvern_winters_curse", LUA_MODIFIER_MOTION_NONE)

modifier_winter_wyvern_winters_curse_ebf_ally_aura = class({})
LinkLuaModifier("modifier_winter_wyvern_winters_curse_ebf_ally_aura", "heroes/hero_winter_wyvern/winter_wyvern_winters_curse", LUA_MODIFIER_MOTION_NONE)

function modifier_winter_wyvern_winters_curse_ebf_ally_aura:IsHidden()
    return true
end

function modifier_winter_wyvern_winters_curse_ebf_ally_aura:OnCreated()
    self:OnRefresh()
end

function modifier_winter_wyvern_winters_curse_ebf_ally_aura:OnRefresh()
    self.radius = self:GetSpecialValueFor("radius")
end

function modifier_winter_wyvern_winters_curse_ebf_ally_aura:IsAura()
    return true
end

function modifier_winter_wyvern_winters_curse_ebf_ally_aura:GetAuraRadius()
    return self.radius
end

function modifier_winter_wyvern_winters_curse_ebf_ally_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_winter_wyvern_winters_curse_ebf_ally_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_ALL
end

function modifier_winter_wyvern_winters_curse_ebf_ally_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS
end

function modifier_winter_wyvern_winters_curse_ebf_ally_aura:GetModifierAura()
    return "modifier_winter_wyvern_winters_curse_ebf_ally"
end]]