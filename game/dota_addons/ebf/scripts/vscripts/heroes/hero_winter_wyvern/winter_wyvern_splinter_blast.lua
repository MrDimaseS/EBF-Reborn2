winter_wyvern_splinter_blast = class({})

function winter_wyvern_splinter_blast:OnSpellStart()
    local target = self:GetCursorTarget()
    self:Spit( target )
end

function winter_wyvern_splinter_blast:Spit(target, bSecondary)
    local caster = self:GetCaster()
	
	local secondary = bSecondary or false
    local speed = self:GetSpecialValueFor("projectile_speed")
	local projectileFX = "particles/units/heroes/hero_winter_wyvern/wyvern_splinter_blast.vpcf"
	if bSecondary then
		projectileFX = "particles/units/heroes/hero_winter_wyvern/wyvern_splinter_blast.vpcf"
	end
    local projectile = self:FireTrackingProjectile(projectileFX, target, speed, {source = caster})
	self._projectiles = self._projectiles or {}
	self._projectiles[projectile] = {secondary = secondary}
    EmitSoundOn("Hero_Winter_Wyvern.SplinterBlast.Cast", caster)
    EmitSoundOn("Hero_Winter_Wyvern.SplinterBlast.Projectile", caster)
end

function winter_wyvern_splinter_blast:OnProjectileHitHandle(target, position, projectile)
	if target then
		local caster = self:GetCaster()
		local projectileData = self._projectiles[projectile]
		if not projectileData then return end
		local damage = self:GetSpecialValueFor("damage")
		if projectileData.secondary then
			
			EmitSoundOn("Hero_Winter_Wyvern.SplinterBlast.Splinter", target )
		else
			EmitSoundOn("Hero_Winter_Wyvern.SplinterBlast.Target", target )
		end
	end
end