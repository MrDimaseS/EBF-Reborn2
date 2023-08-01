modifier_last_man_standing = class({})

function modifier_last_man_standing:OnCreated()
	if IsServer() then
		local nFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_bounty_hunter/bounty_hunter_track_shield.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent() )
		self:AddOverHeadEffect( nFX )
	end
end

function modifier_last_man_standing:IsHidden()
	return false
end

function modifier_last_man_standing:CheckState()
	local state = { [MODIFIER_STATE_INVISIBLE] = false
				}
	if self:GetParent():HasModifier("modifier_smoke_of_deceit") then return end
	return state
end

function modifier_last_man_standing:GetPriority()
	return MODIFIER_PRIORITY_SUPER_ULTRA
end

function modifier_last_man_standing:GetEffectName()
	return "particles/units/heroes/hero_bounty_hunter/bounty_hunter_track_trail.vpcf"
end

function modifier_last_man_standing:IsDebuff()
	return true
end

function modifier_last_man_standing:IsPurgable()
	return false
end

function modifier_last_man_standing:GetTexture()
	return "bounty_hunter_track"
end