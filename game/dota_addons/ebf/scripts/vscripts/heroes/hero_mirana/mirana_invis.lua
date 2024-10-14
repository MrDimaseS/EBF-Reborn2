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
        friend:AddNewModifier(caster, self, "modifier_mirana_moonlight_shadow_buff", {Duration = self:GetSpecialValueFor("duration")})
    end
end

function mirana_invis:OnSpellStart()
    local caster = self:GetCaster()

    EmitSoundOn("Ability.MoonlightShadow", caster)

    local friends = caster:FindFriendlyUnitsInRadius(caster:GetAbsOrigin(), FIND_UNITS_EVERYWHERE)
    for _,friend in pairs(friends) do
        ParticleManager:FireParticle("particles/units/heroes/hero_mirana/mirana_moonlight_ray.vpcf", PATTACH_POINT_FOLLOW, friend, {})
        friend:AddNewModifier(caster, self, "modifier_mirana_moonlight_shadow_buff", {Duration = self:GetSpecialValueFor("duration")})
    end
end

modifier_mirana_moonlight_shadow_buff = class({})
LinkLuaModifier("modifier_mirana_moonlight_shadow_buff", "heroes/hero_mirana/mirana_invis", LUA_MODIFIER_MOTION_NONE)

function modifier_mirana_moonlight_shadow_buff:OnCreated()
	self.fade_delay = self:GetSpecialValueFor("fade_delay")
	self.current_fade_delay = self.fade_delay
	self.bonus_movement_speed = self:GetSpecialValueFor("bonus_movement_speed")
	-- new moon facet
	self.evasion = self:GetSpecialValueFor("evasion")
	self.magic_resistance = self:GetSpecialValueFor("magic_resistance")
	-- full moon facet
	self.gain_pct = TernaryOperator( 1, self:GetParent() == self:GetCaster(), self:GetSpecialValueFor("ally_pct") / 100 )
	self.attack_speed_sec = self:GetSpecialValueFor("attack_speed_sec") * 0.1 * self.gain_pct
	self.attack_dmg_sec = self:GetSpecialValueFor("attack_dmg_sec") * 0.1 * self.gain_pct
	self.max_damage_time = self:GetSpecialValueFor("max_damage_time")
	
	self.attack_speed = 0
	self.attack_dmg = 0
	
	self:StartIntervalThink( 0.1 )
end

function modifier_mirana_moonlight_shadow_buff:OnRemoved()
    if IsServer() then
		if IsEntitySafe( self.invis ) then self.invis:Destroy() end
    end
end

function modifier_mirana_moonlight_shadow_buff:OnIntervalThink()
	-- full moon handling
	if self.max_damage_time > 0 then
		self.max_damage_time = self.max_damage_time - 0.1
		self.attack_speed = self.attack_speed + self.attack_dmg_sec
		self.attack_dmg = self.attack_dmg + self.attack_dmg_sec
	end
	if IsServer() then
		-- invis handling
		if self.current_fade_delay > 0 then
			self.current_fade_delay = self.current_fade_delay - 0.1
		elseif not IsModifierSafe( self.invis ) then
			self.invis = self:GetParent():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_invisible", {duration = self:GetRemainingTime()} )
		end
	end
end

function modifier_mirana_moonlight_shadow_buff:GetEffectName()
    return "particles/units/heroes/hero_mirana/mirana_moonlight_owner.vpcf"
end

function modifier_mirana_moonlight_shadow_buff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

function modifier_mirana_moonlight_shadow_buff:DeclareFunctions()
    return {MODIFIER_EVENT_ON_ATTACK,
			MODIFIER_EVENT_ON_ABILITY_EXECUTED,
			MODIFIER_PROPERTY_EVASION_CONSTANT,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_mirana_moonlight_shadow_buff:GetModifierAttackSpeedBonus_Constant()
    return self.attack_speed
end

function modifier_mirana_moonlight_shadow_buff:GetModifierBaseDamageOutgoing_Percentage()
    return self.attack_dmg
end

function modifier_mirana_moonlight_shadow_buff:GetModifierEvasion_Constant()
    return self.evasion
end

function modifier_mirana_moonlight_shadow_buff:GetModifierMagicalResistanceBonus()
    return self.magic_resistance
end

function modifier_mirana_moonlight_shadow_buff:GetModifierMoveSpeedBonus_Percentage()
    return self.bonus_movement_speed
end

function modifier_mirana_moonlight_shadow_buff:OnAttack(params)
	if params.attacker == self:GetParent() then
		self.current_fade_delay = self.fade_delay
	end
end

function modifier_mirana_moonlight_shadow_buff:OnAbilityExecuted(params)
	if params.unit == self:GetParent() then
		self.current_fade_delay = self.fade_delay
	end
end