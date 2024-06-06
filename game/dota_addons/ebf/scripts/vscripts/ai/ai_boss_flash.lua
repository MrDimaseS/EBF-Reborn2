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

    if thisEntity:IsChanneling() then
        return 1
    end

    if thisEntity:GetCurrentActiveAbility() then
        return 1
    end

    local currentHealth = thisEntity:GetHealth()
    local healthLost = lastHealth - currentHealth
    lastHealth = currentHealth

    if healthLost > thisEntity:GetMaxHealth() * 0.05 and thisEntity.smokeScreen and thisEntity.smokeScreen:IsFullyCastable() then
        CastSmokeScreen()
        return 1
    end

    local enemies = FindUnitsInRadius(
        thisEntity:GetTeamNumber(),
        thisEntity:GetOrigin(),
        nil,
        thisEntity:GetAcquisitionRange(),
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
    ExecuteOrderFromTable({
        UnitIndex = thisEntity:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
        Position = thisEntity:GetAbsOrigin(),
        AbilityIndex = thisEntity.smokeScreen:entindex()
    })

    local runDirection = FindRandomPointAround(thisEntity:GetAbsOrigin(), 1200)
    thisEntity:MoveToPosition(runDirection)

    Timers:CreateTimer(5, function()
        if thisEntity:IsAlive() then
            local enemies = FindUnitsInRadius(
                thisEntity:GetTeamNumber(),
                thisEntity:GetOrigin(),
                nil,
                thisEntity:GetAcquisitionRange(),
                DOTA_UNIT_TARGET_TEAM_ENEMY,
                DOTA_UNIT_TARGET_HERO,
                DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_ANY_ORDER,
                false
            )

            if #enemies > 0 then
                local target = enemies[1]
                thisEntity:MoveToTargetToAttack(target)
            end
        end
    end)
end

function FindRandomPointAround(origin, radius)
    local x = RandomFloat(-1, 1)
    local y = RandomFloat(-1, 1)
    local vec = Vector(x, y, 0):Normalized()
    return origin + vec * radius
end