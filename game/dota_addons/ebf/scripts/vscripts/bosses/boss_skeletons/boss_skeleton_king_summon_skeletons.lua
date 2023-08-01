boss_skeleton_king_summon_skeletons = class({})

function boss_skeleton_king_summon_skeletons:OnSpellStart()
	local caster = self:GetCaster()
	
	self.skeletons = self.skeletons or {}
	for i = #self.skeletons, 1 do
		if self.skeletons[i] then
			if not IsEntitySafe( self.skeletons[i] ) or not self.skeletons[i]:IsAlive() then
				table.remove( self.skeletons, i )
			end
		end
	end
	local skeletonsToSummon = self:GetSpecialValueFor("skeletons_summoned")
	local maxSkeletons = self:GetSpecialValueFor("max_skeletons")
	local skeletonsToKill = (#self.skeletons + skeletonsToSummon) - maxSkeletons
	for i = 1, skeletonsToKill do
		local skeleton = self.skeletons[1]
		if IsEntitySafe( skeleton ) then
			skeleton:ForceKill( false )
		end
		table.remove( self.skeletons, 1 )
	end
	
	local delay = self:GetSpecialValueFor("summon_delay")
	Timers:CreateTimer( delay, function()
		skeletonsToSummon = skeletonsToSummon - 1 
		local skeleton = caster:CreateSummon( "npc_dota_boss_skeleton_minion", caster:GetAbsOrigin() - RandomVector( 256 ) )
		skeleton:SetMaximumGoldBounty( 0 )
		skeleton:SetMinimumGoldBounty( 0 )
		skeleton:SetDeathXP( 0 )
		
		table.insert( self.skeletons, skeleton )
		if skeletonsToSummon > 0 then
			return delay
		end
	end)
end