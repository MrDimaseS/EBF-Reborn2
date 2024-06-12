LinkLuaModifier("modifier_shadow_shaman_hex_ward_hex", "heroes/hero_shadow_shaman/shadow_shaman_hex_ward", LUA_MODIFIER_MOTION_NONE)

shadow_shaman_hex_ward = class({})

shadow_shaman_hex_ward.current_ward = nil

function shadow_shaman_hex_ward:OnSpellStart()
    local hCaster = self:GetCaster()
    local vTargetPosition = self:GetCursorPosition()
    local ward_duration = self:GetSpecialValueFor("ward_duration")

    if shadow_shaman_hex_ward.current_ward and not shadow_shaman_hex_ward.current_ward:IsNull() then
        shadow_shaman_hex_ward.current_ward:ForceKill(false)
    end

    local ward = CreateUnitByName("npc_dota_hex_ward", vTargetPosition, true, hCaster, hCaster, hCaster:GetTeamNumber())
    ward:AddNewModifier(hCaster, self, "modifier_kill", {duration = ward_duration})
    ward:AddNewModifier(hCaster, self, "modifier_shadow_shaman_hex_ward_hex", {})

    shadow_shaman_hex_ward.current_ward = ward
end

modifier_shadow_shaman_hex_ward_hex = class({})

function modifier_shadow_shaman_hex_ward_hex:OnCreated(kv)
    if IsServer() then
        self:StartIntervalThink(1) 
    end
end

function modifier_shadow_shaman_hex_ward_hex:OnIntervalThink()
    local radius = self:GetAbility():GetSpecialValueFor("radius")
    local hex_chance = self:GetAbility():GetSpecialValueFor("hex_chance")
    local hex_duration_min = self:GetAbility():GetSpecialValueFor("hex_duration_min")
    local hex_duration_max = self:GetAbility():GetSpecialValueFor("hex_duration_max")

    local enemies = FindUnitsInRadius(
        self:GetParent():GetTeamNumber(),
        self:GetParent():GetAbsOrigin(),
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    for _, enemy in pairs(enemies) do
        if not enemy:HasModifier("modifier_shadow_shaman_voodoo") and RollPercentage(hex_chance) then
            enemy:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_shadow_shaman_voodoo", {duration = RandomFloat(hex_duration_min, hex_duration_max)})
        end
    end
end

