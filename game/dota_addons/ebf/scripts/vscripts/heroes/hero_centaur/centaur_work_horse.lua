centaur_work_horse = class({})

function centaur_work_horse:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")

    local enemies = caster:FindEnemyUnitsInRadius(caster:GetAbsOrigin(), 99999)
    for _, enemy in ipairs(enemies) do
        if enemy:HasModifier("modifier_centaur_stampede_immune") then
            enemy:RemoveModifierByName("modifier_centaur_stampede_immune")
        end
    end

    caster:AddNewModifier(caster, self, "modifier_centaur_stampede_buff", { duration = duration })
    
    -- gestures
    caster:StartGesture(ACT_DOTA_CENTAUR_STAMPEDE)

    -- sounds
    local sound = "Hero_Centaur.Stampede.Cast"
    EmitSoundOn(sound, caster)
end