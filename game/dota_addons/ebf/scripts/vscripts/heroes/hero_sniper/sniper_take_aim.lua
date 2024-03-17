sniper_take_aim = class({})

function sniper_take_aim:GetIntrinsicModifierName()
	return "modifier_sniper_take_aim"
end

function sniper_take_aim:OnSpellStart()	
	local caster = self:GetCaster()
	caster:AddNewModifier( caster, self, "modifier_sniper_take_aim_active", {duration = self:GetSpecialValueFor("duration")} )
	
	EmitSoundOn( "Hero_Sniper.TakeAim.Cast", caster)
end

modifier_sniper_take_aim = class({})
LinkLuaModifier( "modifier_sniper_take_aim","heroes/hero_sniper/sniper_take_aim.lua",LUA_MODIFIER_MOTION_NONE )
function modifier_sniper_take_aim:OnCreated(table)
	self.range = self:GetSpecialValueFor("bonus_attack_range")
end

function modifier_sniper_take_aim:OnRefresh(table)
	self:OnCreated()
end

function modifier_sniper_take_aim:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACK_RANGE_BONUS}
end

function modifier_sniper_take_aim:GetModifierAttackRangeBonus()
	return self:GetSpecialValueFor("bonus_attack_range")
end

function modifier_sniper_take_aim:IsPurgeException()
	return false
end

function modifier_sniper_take_aim:IsPurgable()
	return false
end

function modifier_sniper_take_aim:IsHidden()
	return true
end

modifier_sniper_take_aim_active = class({})
LinkLuaModifier( "modifier_sniper_take_aim_active","heroes/hero_sniper/sniper_take_aim.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_sniper_take_aim_active:OnCreated()
	self.chance = self:GetSpecialValueFor("headshot_chance")
	self.active_attack_range_bonus = self:GetSpecialValueFor("active_attack_range_bonus")
	self.slow = self:GetSpecialValueFor("slow")
end

function modifier_sniper_take_aim_active:OnRefresh()
	self:OnCreated()
end

function modifier_sniper_take_aim_active:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACK_RANGE_BONUS, MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL, MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_sniper_take_aim_active:GetModifierOverrideAbilitySpecial(params)
	if params.ability:GetName() == "sniper_headshot" then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "proc_chance" then
			return 1
		end
	end
end

function modifier_sniper_take_aim_active:GetModifierOverrideAbilitySpecialValue(params)
	if params.ability:GetName() == "sniper_headshot" then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "proc_chance" then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( specialValue, params.ability_special_level )
			return flBaseValue + self.chance
		end
	end
end

function modifier_sniper_take_aim_active:GetModifierAttackRangeBonus()
	return self.active_attack_range_bonus
end

function modifier_sniper_take_aim_active:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end