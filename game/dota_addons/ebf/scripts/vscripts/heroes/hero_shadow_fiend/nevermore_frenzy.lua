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
	caster:AddNewModifier( caster, self, "modifier_nevermore_frenzy_ebf", {duration = self:GetSpecialValueFor("duration")} )
end

modifier_nevermore_frenzy_ebf = class({})
LinkLuaModifier( "modifier_nevermore_frenzy_ebf","heroes/hero_shadow_fiend/nevermore_frenzy.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_nevermore_frenzy_ebf:OnCreated()
	self:OnRefresh()
end

function modifier_nevermore_frenzy_ebf:OnRefresh()
	self.attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
	self.cast_speed = self:GetSpecialValueFor("cast_speed_pct")
	self.soul_cost = self:GetSpecialValueFor("soul_cost")
end

function modifier_nevermore_frenzy_ebf:OnRemoved()
	if IsClient() then return end
	local parent = self:GetParent()
	local souls = parent:FindModifierByName("modifier_nevermore_necromastery_passive")
	if souls then
		souls:SetStackCount( math.max( 0, souls:GetStackCount() - self.soul_cost ) )
	end
end

function modifier_nevermore_frenzy_ebf:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_CASTTIME_PERCENTAGE}
end

function modifier_nevermore_frenzy_ebf:GetModifierPercentageCasttime()
	return self.cast_speed - 100
end

function modifier_nevermore_frenzy_ebf:GetModifierAttackSpeedBonus_Constant()
	return self.attack_speed
end

function modifier_nevermore_frenzy_ebf:GetEffectName()
	return "particles/items2_fx/mask_of_madness.vpcf"
end