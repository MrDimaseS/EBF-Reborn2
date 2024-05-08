minion_frost_elemental_ice_blast = class({})

function minion_frost_elemental_ice_blast:OnSpellStart()
	local caster = self:GetCaster()
	local targetPos = self:GetCursorPosition()
	
	local vDir = CalculateDirection(targetPos, caster)
	local vDistance = CalculateDistance(targetPos, caster)
	local speed = self:GetSpecialValueFor("speed")
	
	self:FireLinearProjectile("", vDir * speed, vDistance, 0)
	ParticleManager:FireParticle("particles/units/heroes/hero_ancient_apparition/ancient_apparition_ice_blast_final.vpcf", PATTACH_ABSORIGIN, caster, { [0] = caster:GetAbsOrigin(),
																																						[1] = speed * vDir,
																																						[5] = Vector( vDistance / speed, 1, 1 )})
	EmitSoundOn("Hero_Ancient_Apparition.IceBlastRelease.Cast.Self", caster)
end

function minion_frost_elemental_ice_blast:OnProjectileHit( target, position )
	if not target then
		local caster = self:GetCaster()
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( position, self:GetSpecialValueFor("radius") ) ) do
			self:DealDamage( caster, enemy )
			enemy:AddNewModifier( caster, self, "modifier_ice_blast", {duration = self:GetSpecialValueFor("frostbite_duration")} )
		end
		EmitSoundOnLocationWithCaster( position, "Hero_Ancient_Apparition.IceBlast.Target", caster )
	end
end