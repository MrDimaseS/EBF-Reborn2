mirana_invis = class({})

function mirana_invis:IsStealable()
    return true
end

function mirana_invis:IsHiddenWhenStolen()
    return false
end

function mirana_invis:OnAbilityPhaseStart()
    ParticleManager:FireParticle("particles/units/heroes/hero_mirana/mirana_moonlight_cast.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster(), {})
    return true
end

function mirana_invis:OnSpellStart()
    local caster = self:GetCaster()

    EmitSoundOn("Ability.MoonlightShadow", caster)

    local friends = caster:FindFriendlyUnitsInRadius(caster:GetAbsOrigin(), FIND_UNITS_EVERYWHERE)
    for _,friend in pairs(friends) do
        ParticleManager:FireParticle("particles/units/heroes/hero_mirana/mirana_moonlight_ray.vpcf", PATTACH_POINT_FOLLOW, friend, {})
        friend:AddNewModifier(caster, self, "modifier_mirana_invis", {Duration = self:GetSpecialValueFor("duration")})
    end
end

modifier_mirana_invis = class({})
LinkLuaModifier("modifier_mirana_invis", "heroes/hero_mirana/mirana_invis", LUA_MODIFIER_MOTION_NONE)

function modifier_mirana_invis:OnCreated()
	self.fade_delay = self:GetSpecialValueFor("fade_delay")
	self.bonus_movement_speed = self:GetSpecialValueFor("bonus_movement_speed")
	self.evasion = self:GetSpecialValueFor("evasion")
	self.magic_resistance = self:GetSpecialValueFor("magic_resistance")
	self.spell_amplification = self.evasion * self:GetSpecialValueFor("spell_amplification")
	if IsServer() then
		self:StartIntervalThink( self.fade_delay )
	end
end

function modifier_mirana_invis:OnRemoved()
    if IsServer() then
		if IsEntitySafe( self.invis ) then self.invis:Destroy() end
    end
end

function modifier_mirana_invis:OnIntervalThink()
	self:StartIntervalThink( -1 )
	self.invis = self:GetParent():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_invisible", {duration = self:GetRemainingTime()} )
end

function modifier_mirana_invis:GetEffectName()
    return "particles/units/heroes/hero_mirana/mirana_moonlight_owner.vpcf"
end

function modifier_mirana_invis:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

function modifier_mirana_invis:DeclareFunctions()
    funcs = {
                MODIFIER_EVENT_ON_ATTACK_LANDED,
                MODIFIER_EVENT_ON_ABILITY_EXECUTED,
				MODIFIER_PROPERTY_EVASION_CONSTANT,
				MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
				MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
				MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
            }
    return funcs
end

function modifier_mirana_invis:GetModifierEvasion_Constant()
    return self.evasion
end

function modifier_mirana_invis:GetModifierSpellAmplify_Percentage()
    return self.spell_amplification
end

function modifier_mirana_invis:GetModifierMagicalResistanceBonus()
    return self.magic_resistance
end

function modifier_mirana_invis:GetModifierMoveSpeedBonus_Percentage()
    return self.bonus_movement_speed
end

function modifier_mirana_invis:OnAttackLanded(params)
	if params.attacker == self:GetParent() then
		self:StartIntervalThink( self.fade_delay )
	end
end

function modifier_mirana_invis:OnAbilityExecuted(params)
	if params.unit == self:GetParent() then
		self:StartIntervalThink( self.fade_delay )
	end
end