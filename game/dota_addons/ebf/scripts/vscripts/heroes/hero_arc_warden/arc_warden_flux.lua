arc_warden_flux = class({})

function arc_warden_flux:GetBehavior()
    if self:GetSpecialValueFor("applies_silence") ~= 0 then
        return self.BaseClass.GetBehavior( self )
    else
        return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE
    end
end

function arc_warden_flux:GetAOERadius()
    return self:GetSpecialValueFor("aoe_radius")
end

function arc_warden_flux:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local position = self:GetCursorPosition()

    if target:TriggerSpellAbsorb(self) then return end

    local duration =  self:GetSpecialValueFor("duration")
    local is_infinite = self:GetSpecialValueFor("is_infinite")

    if self:GetSpecialValueFor("applies_silence") ~= 0 then
        if is_infinite == 1 then
            target:AddNewModifier(caster, self, "modifier_arc_warden_flux_debuff", {duration = -1})
            self:Silence(target, -1)
        else
            target:AddNewModifier(caster, self, "modifier_arc_warden_flux_debuff", {duration = duration})
            self:Silence(target, duration)
        end
        self:EmitParticles(caster, target)
        EmitSoundOn("Hero_ArcWarden.Flux.Target", target)
    else
        for _, unit in ipairs(caster:FindEnemyUnitsInRadius(position, self:GetSpecialValueFor("aoe_radius"))) do
            unit:AddNewModifier(caster, self, "modifier_arc_warden_flux_debuff", {duration = duration})
            self:EmitParticles(caster, unit)
            EmitSoundOn("Hero_ArcWarden.Flux.Target", unit)
        end
    end
    EmitSoundOn("Hero_ArcWarden.Flux.Cast", caster)
end

function arc_warden_flux:EmitParticles(source, target)
    local nfx =
    ParticleManager:CreateParticle("particles/units/heroes/hero_arc_warden/arc_warden_flux_cast.vpcf", PATTACH_POINT, source)
	ParticleManager:SetParticleControlEnt(nfx, 0, source, PATTACH_POINT_FOLLOW, "attach_attack1", source:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(nfx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(nfx, 2, source, PATTACH_POINT_FOLLOW, "attach_attack2", source:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(nfx)

    return nfx
end

modifier_arc_warden_flux_debuff = class({})
LinkLuaModifier( "modifier_arc_warden_flux_debuff", "heroes/hero_arc_warden/arc_warden_flux", LUA_MODIFIER_MOTION_NONE)

function modifier_arc_warden_flux_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_arc_warden_flux_debuff:OnCreated()
    if IsServer() then
        self:StartIntervalThink(self:GetSpecialValueFor("think_interval"))
		local caster = self:GetCaster()
		local parent = self:GetParent()
		local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_arc_warden/arc_warden_flux_tempest_tgt.vpcf", PATTACH_POINT_FOLLOW, caster)
				ParticleManager:SetParticleControlEnt(nfx, 0, parent, PATTACH_ABSORIGIN_FOLLOW, "attach_attack1", parent:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(nfx, 1, parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(nfx, 2, parent, PATTACH_ABSORIGIN_FOLLOW, "attach_attack2", parent:GetAbsOrigin(), true)
				ParticleManager:SetParticleControl(nfx, 4, Vector(1,0,0))
				ParticleManager:SetParticleControl(nfx, 5, Vector(1,1,1))
				ParticleManager:SetParticleControl(nfx, 6, Vector(1,1,1))
		self:AttachEffect(nfx)
    end
end

function modifier_arc_warden_flux_debuff:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()

    local dps = self:GetSpecialValueFor("damage_per_second")
    local damage_per_unit = self:GetSpecialValueFor("damage_per_unit")
    local pure_damage = self:GetSpecialValueFor("pure_damage")

    local hp_pure_dmg = self:GetSpecialValueFor("hp_pure_damage") / 100

    local currentHP = parent:GetHealth()
    
    if pure_damage ~= 1 then
        self.damage_type = DAMAGE_TYPE_MAGICAL
    else
        self.damage_type = DAMAGE_TYPE_PURE
    end

    if self:GetSpecialValueFor("applies_silence") ~= 0 then
        self.roots = true
        if parent:IsRooted() then
            dps = dps * 2
            self:GetAbility():DealDamage(caster, parent, dps, {damage_type = self.damage_type})
        else
            self:GetAbility():DealDamage(caster, parent, dps, {damage_type = self.damage_type})
        end
    else
        self.roots = false
        local aoe_targets = caster:FindEnemyUnitsInRadius(parent:GetAbsOrigin(), self:GetSpecialValueFor("search_radius"))
        for _, unit in ipairs(aoe_targets) do
            if unit:HasModifier("modifier_arc_warden_flux_debuff") and unit ~= parent then
                dps = dps + (#aoe_targets * damage_per_unit)
            end

            local mFieldD = unit:HasModifier("modifier_arc_warden_magnetic_field_debuff")
            local fluxDebuff = unit:FindModifierByName("modifier_arc_warden_flux_debuff")
            if mFieldD then
                fluxDebuff:SetDuration(fluxDebuff:GetRemainingTime() + 0.5, true)
            end
        end
        self:GetAbility():DealDamage(caster, parent, dps, {damage_type = self.damage_type})
        if hp_pure_dmg ~= 0 then
            local currentHPdmg = (currentHP * hp_pure_dmg) * parent:GetMaxHealthDamageResistance()
            self:GetAbility():DealDamage(caster, parent, currentHPdmg, {damage_type = DAMAGE_TYPE_PURE})
        end
    end
end

function modifier_arc_warden_flux_debuff:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end

function modifier_arc_warden_flux_debuff:CheckState()
    return
    {
        [MODIFIER_STATE_ROOTED] = self.roots
    }
end

function modifier_arc_warden_flux_debuff:GetModifierMoveSpeedBonus_Percentage()
    return -self:GetSpecialValueFor("move_speed_slow_pct")
end

function modifier_arc_warden_flux_debuff:IsDebuff()
    return true
end