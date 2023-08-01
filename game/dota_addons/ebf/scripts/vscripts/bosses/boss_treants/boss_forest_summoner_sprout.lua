boss_forest_summoner_sprout = class({})

function boss_forest_summoner_sprout:IsStealable()
	return true
end

function boss_forest_summoner_sprout:IsHiddenWhenStolen()
	return false
end

function boss_forest_summoner_sprout:GetAOERadius()
	return self:GetSpecialValueFor("tree_radius")
end

function boss_forest_summoner_sprout:PiercesDisableResistance()
    return true
end

function boss_forest_summoner_sprout:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	if self:GetCursorTarget() then
		local point = self:GetCursorTarget():GetAbsOrigin()
	end
	local duration = self:GetSpecialValueFor("duration")
	local vision_range = self:GetSpecialValueFor("vision_range")
	local trees = self:GetSpecialValueFor("tree_count")
	local radius = self:GetSpecialValueFor("tree_radius")
	local angle = math.pi/(trees/2)
	
	-- Creates 16 temporary trees at each 45 degree interval around the clicked point
	for i=1,trees do
		local position = Vector(point.x+radius*math.sin(angle * (i-1)), point.y+radius*math.cos(angle * (i-1)), point.z)
		local tree = CreateTempTree(position, duration)
	end
	-- Gives vision to the caster's team in a radius around the clicked point for the duration
	AddFOWViewer(caster:GetTeam(), point, vision_range, duration, false)
	local sprout = ParticleManager:FireParticle("particles/units/heroes/hero_furion/furion_sprout.vpcf", PATTACH_WORLDORIGIN, nil, {[0] = point})
	EmitSoundOnLocationWithCaster(point, "Hero_Furion.Sprout", caster)
	
	ResolveNPCPositions( point, vision_range + radius ) 
end