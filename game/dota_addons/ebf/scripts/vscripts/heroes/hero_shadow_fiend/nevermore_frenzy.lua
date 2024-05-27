nevermore_frenzy = class({})

function nevermore_frenzy:CastFilterResult()
	if IsClient() then return end
	local souls = self:GetCaster():FindModifierByName("modifier_nevermore_necromastery_passive")
	if not souls or souls:GetStackCount() < self:GetSpecialValueFor("soul_cost") then
		return UF_FAIL_CUSTOM
	end
	return UF_SUCCESS
end

function nevermore_frenzy:GetCustomCastError()
	return "Not Enough Souls"
end

function nevermore_frenzy:OnSpellStart()
	local caster = self:GetCaster()
	
	EmitSoundOn( "Hero_Nevermore.Frenzy", caster )
	local souls = caster:FindModifierByName("modifier_nevermore_necromastery_passive")
	if souls then
		souls:SetStackCount( math.max( 0, souls:GetStackCount() - self:GetSpecialValueFor("soul_cost") ) )
	end
	caster:AddNewModifier( caster, self, "modifier_nevermore_frenzy", {duration = self:GetSpecialValueFor("duration")} )
end