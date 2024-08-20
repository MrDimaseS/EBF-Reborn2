-- Flash AI

local lastHealth = nil

function Spawn(entityKeyValues)
    if not IsServer() then
        return
    end

    thisEntity.smokeScreen = thisEntity:FindAbilityByName("boss_flash_smoke_screen")
    thisEntity.permanentInvisibility = thisEntity:FindAbilityByName("boss_flash_permanent_invisibility")

    thisEntity:SetContextThink("FlashThink", FlashThink, 1)
    lastHealth = thisEntity:GetHealth()
end

function FlashThink()
    if not thisEntity:IsAlive() then
        return -1
    end

    if GameRules:IsGamePaused() then
        return 1
    end

    local currentHealth = thisEntity:GetHealth()
    local healthLost = lastHealth - currentHealth
    lastHealth = currentHealth

    if healthLost > thisEntity:GetMaxHealth() * 0.25 then
        if IsAnotherFlashBossAround() then
            if thisEntity.smokeScreen and thisEntity.smokeScreen:IsFullyCastable() then
                CastSmokeScreen()
            end
            RunAway()
            return 3
        else
            if thisEntity.smokeScreen and thisEntity.smokeScreen:IsFullyCastable() then
                CastSmokeScreen()
                return 1 -- Add a delay to ensure the cast completes
            end
            ContinueAttacking()
            return 1
        end
    elseif healthLost > thisEntity:GetMaxHealth() * 0.01 then
        if thisEntity.smokeScreen and thisEntity.smokeScreen:IsFullyCastable() then
            CastSmokeScreen()
            return 1 -- Add a delay to ensure the cast completes
        end
        ContinueAttacking()
        return 1
    end

    local enemies = FindUnitsInRadius(
        thisEntity:GetTeamNumber(),
        thisEntity:GetOrigin(),
        nil,
        10000, -- Search range
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    if #enemies > 0 then
        local target = enemies[1]
        if thisEntity:IsInvisible() then
            thisEntity:RemoveModifierByName("modifier_invisible")
        end
        thisEntity:MoveToTargetToAttack(target)
        return 0.5
    end

    return 0.5
end

function CastSmokeScreen()
    local order = {
        UnitIndex = thisEntity:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
        Position = thisEntity:GetAbsOrigin(),
        AbilityIndex = thisEntity.smokeScreen:entindex(),
        Queue = false,
    }
    ExecuteOrderFromTable(order)
end

function RunAway()
    local runDirection = FindRandomPointAround(thisEntity:GetAbsOrigin(), 1200)
    thisEntity:MoveToPosition(runDirection)
end

function ContinueAttacking()
    local enemies = FindUnitsInRadius(
        thisEntity:GetTeamNumber(),
        thisEntity:GetOrigin(),
        nil,
        10000, -- Search range
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    if #enemies > 0 then
        local target = enemies[1]
        thisEntity:MoveToTargetToAttack(target)
    else
    end
end

function IsAnotherFlashBossAround()
    local units = FindUnitsInRadius(
        thisEntity:GetTeamNumber(),
        thisEntity:GetOrigin(),
        nil,
        2000, -- Search radius
        DOTA_UNIT_TARGET_TEAM_FRIENDLY,
        DOTA_UNIT_TARGET_ALL,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    for _, unit in pairs(units) do
        if unit ~= thisEntity and unit:GetUnitName() == thisEntity:GetUnitName() then
            return true
        end
    end

    return false
end

function FindRandomPointAround(origin, radius)
    local x = RandomFloat(-1, 1)
    local y = RandomFloat(-1, 1)
    local vec = Vector(x, y, 0):Normalized()
    local point = origin + vec * radius
    return point
end