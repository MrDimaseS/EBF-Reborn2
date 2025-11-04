tidehunter_ravage = class({})

function tidehunter_ravage:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function tidehunter_ravage:OnSpellStart()
    if IsClient() then return end
    local caster = self:GetCaster()
    local maxRadius = self:GetSpecialValueFor("radius")
    local speed = self:GetSpecialValueFor("speed")
    local duration = self:GetSpecialValueFor("duration")
    local damage = self:GetSpecialValueFor("damage")
    local launch_dur = self:GetSpecialValueFor("launch_duration")

    local leviathan = caster:FindModifierByName("modifier_tidehunter_ravage_leviathan")
    local bonus_dmg = self:GetSpecialValueFor("bonus_dmg")
    local buff_dur = self:GetSpecialValueFor("buff_dur")
    local debuff_dur = self:GetSpecialValueFor("debuff_dur")

    local nfx3 = ParticleManager:CreateParticle("particles/units/heroes/hero_tidehunter/tidehunter_spell_ravage.vpcf", PATTACH_POINT, caster)
    ParticleManager:SetParticleControl(nfx3, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(nfx3, 1, Vector(maxRadius/5, 1, speed))
    ParticleManager:SetParticleControl(nfx3, 2, Vector(maxRadius * 2/5, 1, speed))
    ParticleManager:SetParticleControl(nfx3, 3, Vector(maxRadius * 3/5, 1, speed))
    ParticleManager:SetParticleControl(nfx3, 4, Vector(maxRadius * 4/5, 1, speed))
    ParticleManager:SetParticleControl(nfx3, 5, Vector(maxRadius, 1, speed))
    ParticleManager:ReleaseParticleIndex(nfx3)
    EmitSoundOn("Ability.Ravage", caster)

    local i = 0
    local t = 25
    Timers:CreateTimer(0,function()
        if 250+i < maxRadius then
            local enemies = caster:FindEnemyUnitsInRing(caster:GetAbsOrigin(), 250+i, 1+i, {})
            for _,enemy in pairs(enemies) do
                if not enemy:HasModifier("modifier_tidehunter_ravage") and not enemy:IsNull() then
                    EmitSoundOn("Hero_Tidehunter.RavageDamage", enemy)
                    enemy:AddNewModifier(caster, self, "modifier_tidehunter_ravage", {Duration = launch_dur})
                    self:Stun(enemy, duration + launch_dur)

                    if bonus_dmg ~= 0 then
                        if not leviathan then
                            caster:AddNewModifier(caster, self, "modifier_tidehunter_ravage_leviathan", {duration = buff_dur})
                            caster:FindModifierByName("modifier_tidehunter_ravage_leviathan"):IncrementStackCount()
                        else
                            caster:FindModifierByName("modifier_tidehunter_ravage_leviathan"):SetDuration(buff_dur, true)
                        end
                    else
                        enemy:AddNewModifier(caster, self, "modifier_tidehunter_ravage_mawcaller", {duration = debuff_dur})
                    end
                    self:DealDamage(caster, enemy, damage)
                end
            end
            i = i + t
            return FrameTime()
        else
            return nil
        end
    end)
end

modifier_tidehunter_ravage_leviathan = class({})
LinkLuaModifier("modifier_tidehunter_ravage_leviathan", "heroes/hero_tidehunter/tidehunter_ravage", LUA_MODIFIER_MOTION_NONE)
function modifier_tidehunter_ravage_leviathan:IsBuff()
    return true
end

function modifier_tidehunter_ravage_leviathan:IsHidden()
    return self:GetStackCount() == 0
end

function modifier_tidehunter_ravage_leviathan:IsPurgable()
    return true
end

function modifier_tidehunter_ravage_leviathan:OnCreated()
    self:OnRefresh()
end

function modifier_tidehunter_ravage_leviathan:OnRefresh()
    self.bonus_dmg = self:GetSpecialValueFor("bonus_dmg")
end

function modifier_tidehunter_ravage_leviathan:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_TOOLTIP
    }
end

function modifier_tidehunter_ravage_leviathan:GetModifierPreAttack_BonusDamage()
    return self.bonus_dmg * self:GetStackCount()
end

function modifier_tidehunter_ravage_leviathan:OnTooltip()
    return self.bonus_dmg * self:GetStackCount()
end

modifier_tidehunter_ravage_mawcaller = class({})
LinkLuaModifier("modifier_tidehunter_ravage_mawcaller", "heroes/hero_tidehunter/tidehunter_ravage", LUA_MODIFIER_MOTION_NONE)

function modifier_tidehunter_ravage_mawcaller:IsPurgable()
    return true
end

function modifier_tidehunter_ravage_mawcaller:OnCreated()
    self:OnRefresh()
end

function modifier_tidehunter_ravage_mawcaller:OnRefresh()
    self.mres_reduc = self:GetSpecialValueFor("mres_reduc")
end

function modifier_tidehunter_ravage_mawcaller:DeclareFunctions()
    return {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS}
end

function modifier_tidehunter_ravage_mawcaller:GetModifierMagicalResistanceBonus()
    return -self.mres_reduc
end