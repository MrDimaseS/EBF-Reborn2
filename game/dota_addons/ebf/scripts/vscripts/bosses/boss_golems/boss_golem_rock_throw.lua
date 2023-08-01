boss_golem_rock_throw = class({})

function boss_golem_rock_throw:OnSpellStart()
	local caster = self:GetCaster()
	local position = self:GetCursorPosition()
	
	local speed = self:GetSpecialValueFor("speed")
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( position, self:GetSpecialValueFor("radius") ) ) do
		self:FireTrackingProjectile("particles/neutral_fx/mud_golem_hurl_boulder.vpcf", enemy, speed)
	end
end

function boss_golem_rock_throw:OnProjectileHit( target, position )
	if target then
		local caster = self:GetCaster()
		
		local damage = self:GetSpecialValueFor("damage")
		local duration = self:GetSpecialValueFor("duration")
		self:DealDamage( caster, target, damage )
		self:Stun( target, duration )
		
		CreateUnitByName( "npc_dota_boss_mud_golem", target:GetAbsOrigin() + RandomVector( 250 ), true, nil, nil, caster:GetTeam() )
	end
end