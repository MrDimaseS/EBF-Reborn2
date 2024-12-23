lion_to_hell_and_back = class({})

function lion_to_hell_and_back:GetIntrinsicModifierName()
	return "modifier_lion_to_hell_and_back_innate"
end

function lion_to_hell_and_back:OnOwnerSpawned()
	local innate = self:GetCaster():FindModifierByName("modifier_lion_to_hell_and_back_innate")
	if innate then
		innate:ActivateBuff( innate.duration )
	end
end

modifier_lion_to_hell_and_back_innate = class({})
LinkLuaModifier("modifier_lion_to_hell_and_back_innate", "heroes/hero_lion/lion_to_hell_and_back", LUA_MODIFIER_MOTION_NONE)

function modifier_lion_to_hell_and_back_innate:OnCreated()
	self.duration = self:GetSpecialValueFor("duration")
	self.kill_duration = self:GetSpecialValueFor("kill_duration")
	self.kill_radius = self:GetSpecialValueFor("kill_radius")
	self.spell_amp = self:GetSpecialValueFor("spell_amp")
	self.debuff_amp = self:GetSpecialValueFor("debuff_amp")
	self:SetStackCount(1)
end

function modifier_lion_to_hell_and_back_innate:ActivateBuff( duration )
	self:SetStackCount(0)
	self:StartIntervalThink( duration )
	self:SetDuration( duration, true )
end

function modifier_lion_to_hell_and_back_innate:OnIntervalThink()
	self:SetStackCount(1)
	self:StartIntervalThink( -1 )
end

function modifier_lion_to_hell_and_back_innate:DeclareFunctions()
	return { MODIFIER_EVENT_ON_DEATH, 
			 MODIFIER_PROPERTY_MAX_DEBUFF_DURATION,
			 MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		}
end

function modifier_lion_to_hell_and_back_innate:OnDeath( params )
	if not params.unit:IsConsideredHero() then return end
	if params.unit:IsSameTeam( self:GetCaster() ) then return end
	local duration = self.kill_duration
	if self:GetRemainingTime() > duration then return end
	self:ActivateBuff( duration )
end

function modifier_lion_to_hell_and_back_innate:GetModifierMaxDebuffDuration()
	if self:GetStackCount() == 0 then
		return self.debuff_amp
	end
end

function modifier_lion_to_hell_and_back_innate:GetModifierSpellAmplify_Percentage()
	if self:GetStackCount() == 0 then
		return self.spell_amp
	end
end

function modifier_lion_to_hell_and_back_innate:IsHidden()
	return self:GetStackCount() == 1
end

function modifier_lion_to_hell_and_back_innate:IsPurgable()
	return false
end

function modifier_lion_to_hell_and_back_innate:DestroyOnExpire()
	return false
end

function modifier_lion_to_hell_and_back_innate:RemoveOnDeath()
	return false
end

function modifier_lion_to_hell_and_back_innate:IsPermanent()
	return true
end