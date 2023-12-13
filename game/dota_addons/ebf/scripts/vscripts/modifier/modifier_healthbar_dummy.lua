modifier_healthbar_dummy = class({})

if IsServer() then
	function modifier_healthbar_dummy:OnCreated()
		self:StartIntervalThink(0)
		print("created!")
	end

	function modifier_healthbar_dummy:OnIntervalThink()
		local dummy = self:GetParent()
		if not ( IsEntitySafe( self:GetCaster() ) and self:GetCaster():IsAlive() ) then
			UTIL_Remove( dummy )
			return
		end
		if self:GetCaster():IsAlive() then
			dummy:SetAbsOrigin( self:GetCaster():GetAbsOrigin() )
			dummy:SetHealth( dummy:GetMaxHealth() * self:GetCaster():GetHealthPercent() / 100 )
		end
	end
end

function modifier_healthbar_dummy:IsHidden()
	return true
end

function modifier_healthbar_dummy:CheckState()
	self:GetCaster().checkingForHealthBars = true
	local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
					[MODIFIER_STATE_ROOTED] = true,
					[MODIFIER_STATE_ATTACK_IMMUNE] = true,
					[MODIFIER_STATE_MAGIC_IMMUNE] = true,
					[MODIFIER_STATE_DISARMED] = true,
					[MODIFIER_STATE_INVULNERABLE] = true,
					[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
					[MODIFIER_STATE_UNSELECTABLE] = true,
					[MODIFIER_STATE_OUT_OF_GAME] = true,
					[MODIFIER_STATE_NO_HEALTH_BAR] = self:GetCaster() and self:GetCaster():IsOutOfGame(),
				}
	return state
end