boss_forest_summoner_force_of_nature = class({})

function boss_forest_summoner_force_of_nature:IsStealable()
	return false
end

function boss_forest_summoner_force_of_nature:IsHiddenWhenStolen()
	return false
end

function boss_forest_summoner_force_of_nature:OnSpellStart()
    local caster = self:GetCaster()
    local trees = GridNav:GetAllTreesAroundPoint(caster:GetAbsOrigin(), 3000, true)
	local treants = self:GetSpecialValueFor("max_treants")
	for _, tree in ipairs( trees ) do
		local position = tree:GetAbsOrigin()
		local caster = self:GetCaster()
		if tree:IsStanding() then
			local treant = caster:CreateSummon( "npc_dota_boss_greater_treant", position, self:GetSpecialValueFor("duration"))
			FindClearSpaceForUnit(treant, position, true)
			tree:CutDown( caster:GetTeam() )
			
			treants = treants - 1
			if treants <= 0 then	
				return
			end
		end
	end
end