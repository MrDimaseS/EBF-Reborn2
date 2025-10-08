chaos_knight_phantasm = class({})


function chaos_knight_phantasm:OnSpellStart()
    local caster = self:GetCaster()
    local invul_duration = self:GetSpecialValueFor("invuln_duration")
    ProjectileManager:ProjectileDodge(caster)
    EmitSoundOn("Hero_ChaosKnight.Phantasm", caster)

    caster:AddNewModifier(caster, self, "modifier_chaos_knight_phantasm_immune", {duration = invul_duration})
    caster:Purge(false, true, false, false, false)
end

function chaos_knight_phantasm:CreateAbilityIllusion(illusion_Duration, illusion_Count, position)
    local caster = self:GetCaster()
    local outgoing = self:GetSpecialValueFor("outgoing_dmg") - 100
    local incoming = self:GetSpecialValueFor("incoming_dmg") - 100

    local illu_duration = illusion_Duration or self:GetSpecialValueFor("illusion_duration")
    local illu_count = illusion_Count or self:GetSpecialValueFor("illusion_count")
    
    local illusion = caster:ConjureImage(
    {
        outgoing_damage = outgoing,
        incoming_damage = incoming,
        position = position or caster:GetAbsOrigin(),
        illusion_modifier = "modifier_chaos_knight_phantasm_handler",
    }, illu_duration, caster, illu_count)
    return illusion
end

modifier_chaos_knight_phantasm_immune = class({})
LinkLuaModifier("modifier_chaos_knight_phantasm_immune", "heroes/hero_chaos_knight/chaos_knight_phantasm", LUA_MODIFIER_MOTION_NONE)

function modifier_chaos_knight_phantasm_immune:CheckState()
	return {[MODIFIER_STATE_ATTACK_IMMUNE] = true,
			[MODIFIER_STATE_MAGIC_IMMUNE] = true,
			[MODIFIER_STATE_INVULNERABLE] = true,
			[MODIFIER_STATE_NO_HEALTH_BAR] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			[MODIFIER_STATE_UNSELECTABLE] = true,
			[MODIFIER_STATE_UNTARGETABLE] = true,
			[MODIFIER_STATE_OUT_OF_GAME] = true,
            [MODIFIER_STATE_STUNNED] = true,}
end

function modifier_chaos_knight_phantasm_immune:GetEffectName()
    return "particles/units/heroes/hero_chaos_knight/chaos_knight_phantasm.vpcf"
end

function modifier_chaos_knight_phantasm_immune:OnRemoved()
    local caster = self:GetCaster()
    if IsServer() then
        local illusions = caster:FindFriendlyUnitsInRadius(caster:GetAbsOrigin(), FIND_UNITS_EVERYWHERE)
        for _, illusion in pairs(illusions) do
            if illusion:HasModifier("modifier_chaos_knight_phantasm_handler") then
                illusion:ForceKill(false)
            end
        end
        self:GetAbility():CreateAbilityIllusion()
    end
end

modifier_chaos_knight_phantasm_handler = class({})
LinkLuaModifier("modifier_chaos_knight_phantasm_handler", "heroes/hero_chaos_knight/chaos_knight_phantasm", LUA_MODIFIER_MOTION_NONE)
function modifier_chaos_knight_phantasm_handler:IsStrongIllusion()
    return true
end
function modifier_chaos_knight_phantasm_handler:AllowIllusionDuplicate()
    return true
end
function modifier_chaos_knight_phantasm_handler:GetTexture()
    return "chaos_knight_phantasm"
end

function modifier_chaos_knight_phantasm_handler:CheckState()
        return
        {
            [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        }
end
