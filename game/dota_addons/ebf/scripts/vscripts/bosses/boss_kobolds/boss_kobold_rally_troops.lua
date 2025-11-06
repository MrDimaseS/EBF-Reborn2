boss_kobold_rally_troops = class({})

function boss_kobold_rally_troops:OnSpellStart()
end

function boss_kobold_rally_troops:OnChannelFinish( interrupted )
	local caster = self:GetCaster()
	print( interrupted )
	if not interrupted then
		local serfs = self:GetSpecialValueFor("serfs_per_player")
		local radius = self:GetSpecialValueFor("radius")
		
		for _, hero in ipairs( HeroList:GetActiveHeroes() ) do
			for i = 1, serfs do
				CreateUnitByName( "npc_dota_boss_kobold_serf", hero:GetAbsOrigin() + ActualRandomVector( radius ), true, nil, nil, caster:GetTeam() )
			end
		end
	end
end