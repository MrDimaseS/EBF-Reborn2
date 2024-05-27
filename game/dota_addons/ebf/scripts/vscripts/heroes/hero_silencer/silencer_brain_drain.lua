silencer_brain_drain = class({})

function silencer_brain_drain:GetIntrinsicModifierName()
	return "modifier_silencer_brain_drain_handler"
end

function silencer_brain_drain:IsStealable()
	return false
end

function silencer_brain_drain:ShouldUseResources()
	return false
end

modifier_silencer_brain_drain_handler = class({})
LinkLuaModifier("modifier_silencer_brain_drain_handler", "heroes/hero_silencer/silencer_brain_drain", LUA_MODIFIER_MOTION_NONE)


function modifier_silencer_brain_drain_handler:DeclareFunctions()
	return {MODIFIER_EVENT_ON_DEATH,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS}
end

function modifier_silencer_brain_drain_handler:OnDeath(params)
	local caster = self:GetCaster()
	if not caster:IsSameTeam( params.unit ) and ( params.attacker == caster or CalculateDistance( caster, params.unit ) <= self:GetSpecialValueFor("permanent_int_steal_range") ) then
		if params.unit:IsConsideredHero() then
			self:IncrementStackCount()
		end
	end
end

function modifier_silencer_brain_drain_handler:GetModifierBonusStats_Intellect()
	return self:GetSpecialValueFor("permanent_int_steal_amount") * self:GetStackCount()
end

function modifier_silencer_brain_drain_handler:IsHidden()
	return false
end