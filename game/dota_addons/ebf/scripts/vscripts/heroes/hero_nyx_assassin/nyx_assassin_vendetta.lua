nyx_assassin_vendetta = class({})

function nyx_assassin_vendetta:OnSpellStart()
	local caster = self:GetCaster()

	EmitSoundOn("Hero_NyxAssassin.Vendetta", caster)
	ParticleManager:FireParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_vendetta_start.vpcf", PATTACH_POINT_FOLLOW, caster)
	
	caster:AddNewModifier(caster, self, "modifier_nyx_assassin_vendetta_buff", {Duration = self:GetSpecialValueFor("duration")})
end

modifier_nyx_assassin_vendetta_buff = class({})
LinkLuaModifier( "modifier_nyx_assassin_vendetta_buff", "heroes/hero_nyx_assassin/nyx_assassin_vendetta.lua" ,LUA_MODIFIER_MOTION_NONE )
function modifier_nyx_assassin_vendetta_buff:OnCreated(table)
    self.movement_speed = self:GetSpecialValueFor("movement_speed")
    self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
    self.break_duration = self:GetSpecialValueFor("break_duration")
    self.attack_range_bonus = self:GetSpecialValueFor("attack_range_bonus")
    self.attack_animation_bonus = self:GetSpecialValueFor("attack_animation_bonus")
end

function modifier_nyx_assassin_vendetta_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_EVENT_ON_ABILITY_EXECUTED,
        MODIFIER_EVENT_ON_ATTACK_START,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS 
    }

    return funcs
end

function modifier_nyx_assassin_vendetta_buff:CheckState()
	return {[MODIFIER_STATE_INVISIBLE] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true}
end

function modifier_nyx_assassin_vendetta_buff:OnAbilityExecuted(params)
	if IsServer() then
		if params.unit == self:GetParent() and not self:GetParent():HasScepter() then
			self:Destroy()
		end
	end
end

function modifier_nyx_assassin_vendetta_buff:OnAttackLanded(params)
	if IsServer() then
		if params.attacker == self:GetParent() then
			EmitSoundOn("Hero_NyxAssassin.Vendetta.Crit", params.target)
			ParticleManager:FireParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_vendetta.vpcf", PATTACH_POINT, params.attacker, {[1]=params.target:GetAbsOrigin()})
			self:GetAbility():DealDamage(self:GetParent(), params.target, self.bonus_damage, {}, OVERHEAD_ALERT_DAMAGE)
			
			if self.break_duration > 0 then
				params.target:AddNewModifier( params.attacker, self:GetAbility(), "modifier_break", {duration = self.break_duration} )
				params.target:AddNewModifier( params.attacker, self:GetAbility(), "modifier_silence", {duration = self.break_duration} )
			end
			
			self:Destroy()
		end
	end
end

function modifier_nyx_assassin_vendetta_buff:GetModifierInvisibilityLevel()
    return 1
end

function modifier_nyx_assassin_vendetta_buff:GetModifierMoveSpeedBonus_Percentage()
    return self.movement_speed
end

function modifier_nyx_assassin_vendetta_buff:GetModifierAttackRangeBonus()
	return self.attack_range_bonus
end

function modifier_nyx_assassin_vendetta_buff:GetModifierAttackSpeedBonus_Constant()
	return self.attack_animation_bonus
end

function modifier_nyx_assassin_vendetta_buff:GetActivityTranslationModifiers()
	return "vendetta"
end

function modifier_nyx_assassin_vendetta_buff:IsHidden()
    return false
end

function modifier_nyx_assassin_vendetta_buff:IsPurgable()
    return false
end

function modifier_nyx_assassin_vendetta_buff:IsPurgeException()
    return false
end

function modifier_nyx_assassin_vendetta_buff:IsDebuff()
    return false
end

function modifier_nyx_assassin_vendetta_buff:GetEffectName()
    return "particles/units/heroes/hero_nyx_assassin/nyx_assassin_vendetta_speed.vpcf"
end