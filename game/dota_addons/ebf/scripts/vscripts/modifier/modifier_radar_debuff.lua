modifier_radar_debuff = class({})

function modifier_radar_debuff:OnCreated()
	self.damage_taken = 25
end

function modifier_radar_debuff:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end

function modifier_radar_debuff:GetModifierIncomingDamage_Percentage( params )
	return self.damage_taken
end

function modifier_radar_debuff:IsPurgable()
	return false
end

function modifier_radar_debuff:GetPriority()
	return MODIFIER_PRIORITY_HIGH
end

function modifier_radar_debuff:GetTexture()
	return "bounty_hunter_track"
end

function modifier_radar_debuff:GetEffectName()
	return "particles/units/heroes/hero_phantom_assassin/phantom_assassin_mark_overhead.vpcf"
end

function modifier_radar_debuff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW 
end
