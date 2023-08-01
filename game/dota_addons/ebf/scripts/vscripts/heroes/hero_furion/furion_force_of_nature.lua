furion_force_of_nature = class({})

function furion_force_of_nature:IsStealable()
	return false
end

function furion_force_of_nature:IsHiddenWhenStolen()
	return false
end

function furion_force_of_nature:GetAOERadius()
	return self:GetSpecialValueFor("area_of_effect")
end

function furion_force_of_nature:OnSpellStart()
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    local treants = caster:FindFriendlyUnitsInRadius(caster:GetAbsOrigin(), FIND_UNITS_EVERYWHERE, {})

    local radius = self:GetSpecialValueFor("area_of_effect")

    local trees = GridNav:GetAllTreesAroundPoint(point, radius, true)
	
    if #trees > 1 then
    	GridNav:DestroyTreesAroundPoint(point, radius, true)
		local treants = math.min(#trees, self:GetSpecialValueFor("max_treants"))
	    for i=1, treants do
	    	local randoVect = Vector(RandomInt(-radius,radius), RandomInt(-radius,radius), 0)
			local pointRando = point + randoVect

	    	self:SpawnTreant(pointRando)
	    end
	end
end

function furion_force_of_nature:SpawnTreant(position, bGreater)
	local caster = self:GetCaster()
	local tree = caster:CreateSummon( TernaryOperator( "npc_dota_furion_treant_large", bGreater, "npc_dota_furion_treant" ), position, self:GetSpecialValueFor("duration"))
	FindClearSpaceForUnit(tree, position, true)
	local maxHP = self:GetSpecialValueFor("treant_health_tooltip")
	if bGreater then
		maxHP = maxHP * (1 + self:GetSpecialValueFor("treant_large_bonus") / 100)
	end
	tree:SetBaseMaxHealth(maxHP)
	tree:SetMaxHealth(maxHP)
	tree:SetHealth(maxHP)
	local ad = self:GetSpecialValueFor("treant_dmg_tooltip")
	if bGreater then
		ad = ad * (1 + self:GetSpecialValueFor("treant_large_bonus") / 100)
	end
	tree:SetBaseDamageMax(ad)
	tree:SetBaseDamageMin(ad)
	
	tree:MoveToPositionAggressive(position)
end