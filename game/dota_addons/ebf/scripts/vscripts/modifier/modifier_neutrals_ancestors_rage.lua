modifier_neutrals_ancestors_rage = class({})

function modifier_neutrals_ancestors_rage:OnCreated()
	if IsServer() then
		self:StartIntervalThink(0.25)
	end
end

function modifier_neutrals_ancestors_rage:OnIntervalThink()
	if self:GetParent():GetTeamNumber() ~= DOTA_TEAM_NEUTRALS then
		self:Destroy()
	end
end

function modifier_neutrals_ancestors_rage:OnStackCountChanged()
	if IsServer() and self:GetStackCount() > 0 then
		local FX = ParticleManager:CreateParticle("particles/boss/ancestral_rage_overhead_overhead.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent() )
		ParticleManager:SetParticleControl( FX, 2, Vector( math.floor(self:GetStackCount()/10), self:GetStackCount() % 10, 0 ) )
		ParticleManager:SetParticleControl( FX, 3, Vector( 255, 255, 255 ) )
		self:AddOverHeadEffect( FX )
	end
end

function modifier_neutrals_ancestors_rage:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, 
			MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE}
end

function modifier_neutrals_ancestors_rage:GetModifierIncomingDamage_Percentage()
	return 100 / (1+self:GetStackCount()) - 100
end

function modifier_neutrals_ancestors_rage:GetModifierTotalDamageOutgoing_Percentage()
	return 100 * self:GetStackCount()
end

function modifier_neutrals_ancestors_rage:GetTexture()
	return "warlock_golem_flaming_fists"
end

function modifier_neutrals_ancestors_rage:IsHidden()
	return false
end

function modifier_neutrals_ancestors_rage:IsPurgable()
	return false
end