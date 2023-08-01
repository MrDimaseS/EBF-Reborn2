status_immune = class({})

function status_immune:OnCreated()
	if not IsServer() then return end
	self:GetParent():RemoveGesture( ACT_DOTA_DISABLED )
	self:GetParent():RemoveGesture( ACT_DOTA_FLAIL )
end

function status_immune:CheckState()
	return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
end

function status_immune:GetPriority()
	return MODIFIER_PRIORITY_ULTRA
end

function status_immune:GetTexture()
	return "spawnlord_aura"
end

function status_immune:GetEffectName()
	return "particles/items_fx/black_king_bar_avatar.vpcf"
end

function status_immune:IsPurgable()
	return false
end