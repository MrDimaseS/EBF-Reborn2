-- Butcher AI

function Spawn(entityKeyValues)
    if not IsServer() then
        return
    end

    Timers:CreateTimer(function()
        if thisEntity and not thisEntity:IsNull() and thisEntity:IsAlive() then
            return AIThink(thisEntity)
        end
    end)

    thisEntity.hook = thisEntity:FindAbilityByName("boss_butcher_meat_hook")
    thisEntity.dismember = thisEntity:FindAbilityByName("boss_butcher_dismember")
    thisEntity.blink = thisEntity:FindItemInInventory("item_butcher_overwhelming_blink")

    Timers:CreateTimer(0.1, function()
        thisEntity.hook:SetLevel(GameRules.gameDifficulty)
        thisEntity.dismember:SetLevel(GameRules.gameDifficulty)
    end)

end

function AIThink()
    if (not thisEntity:IsAlive()) then
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

    -- Use Blink Dagger
    if thisEntity.blink and thisEntity.blink:IsFullyCastable() then
        local blinkPosition = FindRandomPointAround(thisEntity:GetAbsOrigin(), 1200)
        ExecuteOrderFromTable({
            UnitIndex = thisEntity:entindex(),
            OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
            Position = blinkPosition,
            AbilityIndex = thisEntity.blink:entindex()
        })
        return thisEntity.blink:GetCastPoint() + 0.5
    end

    -- Launch Hook
    if thisEntity.hook and thisEntity.hook:IsFullyCastable() then
        local enemies = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetOrigin(), nil, thisEntity.hook:GetCastRange(), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
        if #enemies > 0 then
            local target = enemies[1] -- Target the first enemy in range
            local targetPosition = target:GetAbsOrigin()
            ExecuteOrderFromTable({
                UnitIndex = thisEntity:entindex(),
                OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
                Position = targetPosition,
                AbilityIndex = thisEntity.hook:entindex()
            })
            return thisEntity.hook:GetCastPoint() + 2.0
        else
        end
    else
    end

    -- Use Dismember
    if thisEntity.dismember and thisEntity.dismember:IsFullyCastable() then
        local closeEnemies = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetOrigin(), nil, 400, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
        if #closeEnemies > 0 then
            ExecuteOrderFromTable({
                UnitIndex = thisEntity:entindex(),
                OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
                AbilityIndex = thisEntity.dismember:entindex(),
                TargetIndex = closeEnemies[1]:entindex()
            })
            return thisEntity.dismember:GetChannelTime() + 0.5
        else
        end
    else
    end
    return 0.5
end

function FindRandomPointAround(origin, radius)
    local x = RandomFloat(-1, 1)
    local y = RandomFloat(-1, 1)
    local vec = Vector(x, y, 0):Normalized()
    return origin + vec * radius
end

