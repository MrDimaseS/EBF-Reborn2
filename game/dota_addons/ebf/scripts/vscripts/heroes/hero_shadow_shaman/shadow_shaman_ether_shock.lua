shadow_shaman_ether_shock = class({})

function shadow_shaman_ether_shock:ShouldUseResources()
	return true
end

function shadow_shaman_ether_shock:OnSpellStart( hSource )
	local target = self:GetCursorTarget()
	local caster = self:GetCaster()
	local source = hSource or caster
	
	local direction = CalculateDirection( target, source )
	local startRadius = self:GetSpecialValueFor("start_radius")
	local endRadius = self:GetSpecialValueFor("end_radius")
	local endDistance = self:GetSpecialValueFor("end_distance")
	local maxTargets = self:GetSpecialValueFor("targets") - 1
	-- cosmetic
	EmitSoundOn("Hero_ShadowShaman.EtherShock", source)
	
	local targets = {}
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( source:GetAbsOrigin() + direction * startRadius, startRadius ) ) do
		targets[enemy] = false
	end
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( source:GetAbsOrigin() + direction * endDistance, endRadius ) ) do
		targets[enemy] = false
	end
	targets[target] = true
	
	self:EtherShock( target, source )
	for zapTarget, affected in pairs( targets ) do
		if not affected then
			self:EtherShock( zapTarget, source )
			maxTargets = maxTargets - 1
			if maxTargets <= 0 then
				break
			end
		end
	end
end

function shadow_shaman_ether_shock:EtherShock( target, source )
	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")
	EmitSoundOn("Hero_ShadowShaman.EtherShock.Target", target)
	ParticleManager:FireRopeParticle( "particles/units/heroes/hero_shadowshaman/shadowshaman_ether_shock.vpcf", PATTACH_POINT_FOLLOW, caster, target, {[0] = source, [10] = target, [11] = target} )
	self:DealDamage( caster, target, damage )
end