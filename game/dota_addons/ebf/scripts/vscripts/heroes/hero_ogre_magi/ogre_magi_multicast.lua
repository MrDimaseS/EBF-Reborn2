ogre_magi_multicast = class({})

function ogre_magi_multicast:GetIntrinsicModifierName()
	return "modifier_ogre_magi_multicast_passive"
end

modifier_ogre_magi_multicast_passive = class({})
LinkLuaModifier("modifier_ogre_magi_multicast_passive", "heroes/hero_ogre_magi/ogre_magi_multicast", LUA_MODIFIER_MOTION_NONE)

function modifier_ogre_magi_multicast_passive:OnCreated()
	self:OnRefresh()
end

function modifier_ogre_magi_multicast_passive:OnRefresh()
	if IsServer() then
		local caster = self:GetCaster()
		caster:RemoveModifierByName("modifier_ogre_magi_fireblast_multicast")
		caster:RemoveModifierByName("modifier_ogre_magi_ignite_multicast")
	end
end

function modifier_ogre_magi_multicast_passive:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
	}
	return funcs
end

function modifier_ogre_magi_multicast_passive:OnAbilityFullyCast(params)
	if IsServer() then
		local caster = self:GetCaster()
		if params.unit == caster and params.target and params.ability:GetCooldownTimeRemaining() > 0 then
			local two_times = self:GetSpecialValueFor("multicast_2_times") * 10
			local three_times = self:GetSpecialValueFor("multicast_3_times") * 10
			local four_times = self:GetSpecialValueFor("multicast_4_times") * 10
			local multiCast = 1
			local currentCasts = 0

			local tick_rate = self:GetSpecialValueFor("multicast_delay")
			local bonusCastRange = self:GetSpecialValueFor("multicast_buffer_range")

			local ability = params.ability
			local roll = RandomInt(1, 1000)
			if roll <= four_times then
				multiCast = 3

			elseif roll <= three_times then
				multiCast = 2
			elseif roll <= two_times then
				multiCast = 1
			end
			if multiCast > 0 then
				local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_ogre_magi/ogre_magi_multicast.vpcf", PATTACH_POINT_FOLLOW, caster)
							ParticleManager:SetParticleControlEnt(nfx, 0, caster, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
							ParticleManager:SetParticleControl(nfx, 1, Vector(multiCast+1, 1, 1))
							ParticleManager:ReleaseParticleIndex(nfx)
				
				local castRange = params.ability:GetTrueCastRange() + bonusCastRange
				local friendly = params.unit:IsSameTeam( params.target )
				Timers:CreateTimer( tick_rate, function()
					local target = params.target
					if friendly then
						for _, ally in ipairs( caster:FindFriendlyUnitsInRadius( caster:GetAbsOrigin(), castRange, {flag = params.ability:GetAbilityTargetFlags(), type = params.ability:GetAbilityTargetType() } ) ) do
							target = ally
							break
						end
					else
						for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), castRange, {flag = params.ability:GetAbilityTargetFlags(), type = params.ability:GetAbilityTargetType() } ) ) do
							target = enemy
							break
						end
					end
					if target then
						caster:SetCursorCastTarget( target )
						params.ability:OnSpellStart()
					end
					multiCast = multiCast - 1
					if multiCast > 0 then
						return tick_rate
					end
				end)
			end
		end
	end
end

function modifier_ogre_magi_multicast_passive:IsHidden()
	return true
end