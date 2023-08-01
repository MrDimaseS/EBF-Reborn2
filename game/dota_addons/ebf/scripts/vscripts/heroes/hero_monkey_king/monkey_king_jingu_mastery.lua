monkey_king_jingu_mastery = class({})

function monkey_king_jingu_mastery:IsStealable()
	return false
end

function monkey_king_jingu_mastery:IsHiddenWhenStolen()
	return false
end

function monkey_king_jingu_mastery:GetIntrinsicModifierName()
	return "modifier_monkey_king_jingu_mastery_handle"
end

modifier_monkey_king_jingu_mastery_handle = class({})
LinkLuaModifier("modifier_monkey_king_jingu_mastery_handle", "heroes/hero_monkey_king/monkey_king_jingu_mastery", LUA_MODIFIER_MOTION_NONE)

function modifier_monkey_king_jingu_mastery_handle:DeclareFunctions()
    local funcs = { MODIFIER_EVENT_ON_ATTACK_LANDED }

    return funcs
end

function modifier_monkey_king_jingu_mastery_handle:OnAttackLanded(params)
	if IsServer() then
		local caster = self:GetCaster()
		local target = params.target
		local attacker = params.attacker

		if caster == attacker and not caster:HasModifier("modifier_monkey_king_quadruple_tap_bonuses") then
			if target:IsConsideredHero() or self:GetSpecialValueFor("works_on_creeps") > 0 then
				local duration = self:GetSpecialValueFor("counter_duration")
				local required_hits = self:GetSpecialValueFor("required_hits") - 1
				local buff = target:AddNewModifier( caster, self:GetAbility(), "modifier_monkey_king_quadruple_tap_counter", {duration = duration} )
				if buff:GetStackCount() < required_hits then
					buff:IncrementStackCount()
				else
					buff:Destroy()
					Timers:CreateTimer( 0.1, function()
						caster:AddNewModifier( caster, self:GetAbility(), "modifier_monkey_king_quadruple_tap_bonuses", {duration = self:GetSpecialValueFor("max_duration")}):SetStackCount( self:GetSpecialValueFor("charges") )
					end)
				end
			end
		end
	end
end

function modifier_monkey_king_jingu_mastery_handle:IsHidden()
	return true
end