modifier_glyph_buff = class({})

function modifier_glyph_buff:OnCreated()
	self.damage_dealt = 25
end

function modifier_glyph_buff:DeclareFunctions()
	return { MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE  }
end

function modifier_glyph_buff:GetModifierTotalDamageOutgoing_Percentage( params )
	return self.damage_dealt
end

function modifier_glyph_buff:IsPurgable()
	return false
end

function modifier_glyph_buff:GetPriority()
	return MODIFIER_PRIORITY_HIGH
end

function modifier_glyph_buff:GetTexture()
	return "fountain_glyph"
end

function modifier_glyph_buff:GetEffectName()
	return "particles/items_fx/glyph_creeps.vpcf"
end

function modifier_glyph_buff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW 
end
