modifier_hide_healthbar = class({})

function modifier_hide_healthbar:CheckState()
	return { [MODIFIER_STATE_NO_HEALTH_BAR] = true }
end

function modifier_hide_healthbar:IsHidden()
	return true
end

function modifier_hide_healthbar:IsPermanent()
	return true
end

function modifier_hide_healthbar:IsPurgable()
	return false
end