winter_wyvern_splinter_blast = class({})

function winter_wyvern_splinter_blast:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    self:Spit(caster, target)
end

function winter_wyvern_splinter_blast:Spit(caster, target)
    local speed = self:GetSpecialValueFor("projectile_speed")
    self:FireTrackingProjectile("particles/units/heroes/hero_winter_wyvern/wyvern_splinter_blast.vpcf", target, speed, {source = caster})
    EmitSoundOn("Hero_Winter_Wyvern.SplinterBlast.Cast", caster)
end

function winter_wyvern_splinter_blast:OnProjectileThinkHandle(handle)
    EmitSoundOn("Hero_Winter_Wyvern.SplinterBlast.Projectile", handle)
end

function winter_wyvern_splinter_blast:OnProjectileHit_ExtraData()
end

function winter_wyvern_splinter_blast:Split()

end