gyrocopter_flight_of_the_valkyrie = class({})

function gyrocopter_flight_of_the_valkyrie:IsStealable()
	return true
end

function gyrocopter_flight_of_the_valkyrie:IsHiddenWhenStolen()
	return false
end

function gyrocopter_flight_of_the_valkyrie:OnSpellStart()
	local caster = self:GetCaster()
	
	self.disableLoop = false
	caster:AddNewModifier( caster, self, "modifier_gyrocopter_flight_of_the_valkyrie_active", {duration = self:GetSpecialValueFor("AbilityDuration")} )
	EmitSoundOn("Hero_Gyrocopter.FlackCannon.Activate", caster)
end

modifier_gyrocopter_flight_of_the_valkyrie_active = class({})
LinkLuaModifier( "modifier_gyrocopter_flight_of_the_valkyrie_active", "heroes/hero_gyrocopter/gyrocopter_flight_of_the_valkyrie.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_gyrocopter_flight_of_the_valkyrie_active:OnCreated()
	self:OnRefresh()
end

function modifier_gyrocopter_flight_of_the_valkyrie_active:OnRefresh()
	self.spell_amp = self:GetSpecialValueFor("spell_amp")
	self.bonus_movespeed = self:GetSpecialValueFor("bonus_movespeed")
	if IsServer() then
		self:StartIntervalThink(0)
	end
end

function modifier_gyrocopter_flight_of_the_valkyrie_active:OnIntervalThink()
	local caster = self:GetCaster()
	if not caster:IsMoving() then
		caster:SetAbsOrigin( caster:GetAbsOrigin() + caster:GetForwardVector() * caster:GetIdealSpeed() * FrameTime() )
	end
end

function modifier_gyrocopter_flight_of_the_valkyrie_active:CheckState()
	return {[MODIFIER_STATE_FLYING] = true}
end

function modifier_gyrocopter_flight_of_the_valkyrie_active:DeclareFunctions()
	funcs = {MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_TURN_RATE_OVERRIDE, MODIFIER_PROPERTY_IGNORE_CAST_ANGLE }
	return funcs
end

function modifier_gyrocopter_flight_of_the_valkyrie_active:GetModifierSpellAmplify_Percentage(params)
	return self.spell_amp
end

function modifier_gyrocopter_flight_of_the_valkyrie_active:GetModifierMoveSpeedBonus_Constant(params)
	return self.bonus_movespeed
end

function modifier_gyrocopter_flight_of_the_valkyrie_active:GetModifierIgnoreCastAngle(params)
	return 1
end

function modifier_gyrocopter_flight_of_the_valkyrie_active:GetModifierTurnRate_Override(params)
	return 0.1
end