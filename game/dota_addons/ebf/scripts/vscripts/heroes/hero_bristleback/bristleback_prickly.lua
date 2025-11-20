bristleback_prickly = class({})

function bristleback_prickly:GetIntrinsicModifierName()
    return "modifier_bristleback_prickly_passive"
end

modifier_bristleback_prickly_passive = class({})
LinkLuaModifier( "modifier_bristleback_prickly_passive", "heroes/hero_bristleback/bristleback_prickly", LUA_MODIFIER_MOTION_NONE )

function modifier_bristleback_prickly_passive:IsHidden()
    return true
end
function modifier_bristleback_prickly_passive:IsPurgable()
    return false
end
function modifier_bristleback_prickly_passive:OnCreated()
    self:OnRefresh()
end
function modifier_bristleback_prickly_passive:OnRefresh()
    self.damage_amp_pct = self:GetSpecialValueFor("damage_amp_pct")
    self.debuff_amp_pct = self:GetSpecialValueFor("debuff_amp_pct")
    self.rear_angle = self:GetSpecialValueFor("angle")

    self.release_threshold = self:GetSpecialValueFor("release_threshold") / 100
	
    self.does_quills = self:GetSpecialValueFor("does_quills") ~= 0
    self.does_goo = self:GetSpecialValueFor("does_goo") ~= 0
    self.does_warpath = self:GetSpecialValueFor("does_warpath") ~= 0
    
    if self.does_quills then
        self.ability = self:GetCaster():FindAbilityByName("bristleback_quill_spray")
    elseif self.does_goo then
        self.ability = self:GetCaster():FindAbilityByName("bristleback_viscous_nasal_goo")
    elseif self.does_warpath then
        self.ability = self:GetCaster():FindAbilityByName("bristleback_warpath")
    end

    self.damage_taken = 0
end
function modifier_bristleback_prickly_passive:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end
function modifier_bristleback_prickly_passive:GetModifierTotalDamageOutgoing_Percentage(params)
    if self:GetParent() ~= params.attacker or params.attacker:PassivesDisabled() then return end

    local angle = params.attacker:GetAngleDifference(params.target)
    if self.rear_angle == 0 or 180 - angle > self.damage_amp_pct then
        return self.amp_pct
    else
        return 0
    end
end
function modifier_bristleback_prickly_passive:GetModifierMaxDebuffDuration(params)
    if self:GetParent() ~= params.caster or params.caster:PassivesDisabled() then return end

    local angle = params.caster:GetAngleDifference(params.target)
    if self.rear_angle == 0 or 180 - angle > self.rear_angle then
        return self.debuff_amp_pct
    else
        return 0
    end
end


function modifier_bristleback_prickly_passive:OnTakeDamage(params)
    if self:GetParent() ~= params.unit
    or params.unit:PassivesDisabled()
    or not IsEntitySafe(self.ability)
    or not IsEntitySafe(params.attacker)
    or HasBit(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION)
    then return end

    self.damage_taken = (self.damage_taken or 0) + params.damage
    local damage_required = params.unit:GetHealth() * self.release_threshold

    if self.damage_taken < damage_required or params.unit:GetHealth() < params.damage then return end
	
	if self.ability:IsTrained() then
		if self.does_goo then
			params.unit:StartGesture(ACT_DOTA_CAST_ABILITY_1)
			self.ability:DoGoo( params.attacker )
		elseif self.does_quills then
			self.ability:DoQuill( params.attacker )
		elseif self.does_warpath then
			self.ability:AddStack()
		end
	end

	self.damage_taken = self.damage_taken - damage_required
end