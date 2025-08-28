chaos_knight_reins_of_chaos = class({})

function chaos_knight_reins_of_chaos:GetIntrinsicModifierName()
    return "modifier_chaos_knight_reins_of_chaos_passive"
end

function chaos_knight_reins_of_chaos:GetBehavior()
    return DOTA_ABILITY_BEHAVIOR_PASSIVE
end

modifier_chaos_knight_reins_of_chaos_passive = class({})
LinkLuaModifier("modifier_chaos_knight_reins_of_chaos_passive", "heroes/hero_chaos_knight/chaos_knight_reins_of_chaos", LUA_MODIFIER_MOTION_NONE)

function modifier_chaos_knight_reins_of_chaos_passive:IsHidden()
    return false
end

function modifier_chaos_knight_reins_of_chaos_passive:IsPurgable()
    return false
end

function modifier_chaos_knight_reins_of_chaos_passive:IsBuff()
    return true
end

function modifier_chaos_knight_reins_of_chaos_passive:OnCreated()
    self:OnRefresh()
end

function modifier_chaos_knight_reins_of_chaos_passive:OnRefresh()
    self.parent = self:GetParent()

    self.entropal = self:GetSpecialValueFor("does_entropal")
    self.uncertainoi = self:GetSpecialValueFor("does_uncertainoi")

    self.illusion_chance_pct = self:GetSpecialValueFor("illusion_chance_pct")
    self.illusion_count = self:GetSpecialValueFor("illusion_count")
    self.illusion_bonus_damage = self:GetSpecialValueFor("illusion_bonus_damage")
    self.illusion_bonus_aspd = self:GetSpecialValueFor("illusion_bonus_aspd")
    self.illusion_buff_range = self:GetSpecialValueFor("illusion_buff_range")

    self.debuff_bonus_damage = self:GetSpecialValueFor("debuff_bonus_damage")

    if IsServer() then
		self:StartIntervalThink(0.1)
	end
end

function modifier_chaos_knight_reins_of_chaos_passive:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
end

function modifier_chaos_knight_reins_of_chaos_passive:OnIntervalThink()
	if self.parent:PassivesDisabled() then
		return
	end
    local caster = self:GetCaster()
    local illusions = 0
    if self.entropal > 0 then
        for _, unit in ipairs(caster:FindFriendlyUnitsInRadius(caster:GetAbsOrigin(), self.illusion_buff_range, {flag = DOTA_UNIT_TARGET_FLAG_NONE})) do
            if unit:IsIllusion() then
                illusions = illusions + 1
            end
        end
    end
    self:SetStackCount(illusions)
end

function modifier_chaos_knight_reins_of_chaos_passive:GetModifierPreAttack_BonusDamage()
    return self.illusion_bonus_damage * self:GetStackCount()
end

function modifier_chaos_knight_reins_of_chaos_passive:GetModifierAttackSpeedBonus_Constant()
	return self.illusion_bonus_aspd * self:GetStackCount()
end

function modifier_chaos_knight_reins_of_chaos_passive:GetModifierTotalDamageOutgoing_Percentage( params )
    local parent = self:GetParent()
	if params.target:IsSameTeam( parent ) then return end
	local debuffs = 0

    if self.uncertainoi > 0 then
        for _, modifier in ipairs( params.target:FindAllModifiers() ) do
		    if modifier:GetCaster() == parent and not (modifier:IsDebuff() == false) then
			    debuffs = debuffs + 1
		    end
	    end
    end
	return self.debuff_bonus_damage * debuffs
end
