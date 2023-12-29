item_blade_mail = class({})

function item_blade_mail:GetCastRange( target, position )
	return self:GetSpecialValueFor("radius") - self:GetCaster():GetCastRangeBonus()
end

function item_blade_mail:GetIntrinsicModifierName()
	return "modifier_item_blade_mail_passive"
end

function item_blade_mail:GetDefaultFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
    }
end

function item_blade_mail:ApplyReturn( damage, attacker )
	self:DealDamage( self:GetCaster(), attacker, damage, {damage_type = self:GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_REFLECTION} )
end

function item_blade_mail:OnSpellStart()
	local caster = self:GetCaster()

	EmitSoundOn("Hero_Axe.Berserkers_Call", caster)
	EmitSoundOn("DOTA_Item.BladeMail.Activate", caster)

	if caster:HasModifier("modifier_item_blade_mail_passive_taunt") then
		caster:RemoveModifierByName("modifier_item_blade_mail_passive_taunt")
	end
	caster:AddNewModifier(caster,self, "modifier_item_blade_mail_passive_taunt", {Duration = self:GetSpecialValueFor("duration")})
end

item_martyrs_bulwark = class(item_blade_mail)

function item_martyrs_bulwark:GetDefaultFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
end

function item_martyrs_bulwark:ApplyReturn( damage, attacker )
	local caster = self:GetCaster()
	
	caster:ChainLightning( attacker, damage )
	self:DealDamage( caster, attacker, damage, {damage_type = self:GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_REFLECTION} )
	if caster:HasModifier("modifier_item_blade_mail_passive_taunt") then
		local enemies = caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self:GetSpecialValueFor("radius") )
		local bounces = self:GetSpecialValueFor("static_strikes")
		for _, enemy in ipairs( enemies ) do
			if enemy ~= attacker then
				caster:ChainLightning( enemy, damage )
				bounces = bounces - 1
			end
			if bounces <= 0 then
				return
			end
		end
	end
end

function item_martyrs_bulwark:ChainLightning( target, damage )
	
end

function item_martyrs_bulwark:GetIntrinsicModifierName()
	return "modifier_item_martyrs_bulwark_passive"
end

item_martyrs_bulwark_2 = class(item_martyrs_bulwark)
item_martyrs_bulwark_3 = class(item_martyrs_bulwark)
item_martyrs_bulwark_4 = class(item_martyrs_bulwark)
item_martyrs_bulwark_5 = class(item_martyrs_bulwark)

modifier_item_blade_mail_passive = class({})
LinkLuaModifier( "modifier_item_blade_mail_passive", "items/item_blade_mail.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_blade_mail_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_blade_mail_passive:OnCreated()
	self.bonus_hp = self:GetAbility():GetSpecialValueFor("bonus_hp")
	self.bonus_intellect = self:GetAbility():GetSpecialValueFor("bonus_intellect")
	self.bonus_armor = self:GetAbility():GetSpecialValueFor("bonus_armor")
	self.bonus_damage = self:GetAbility():GetSpecialValueFor("bonus_damage")
	self.bonus_attack_speed = self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
	
	self.active_reflection_pct = self:GetSpecialValueFor("active_reflection_pct") / 100
	self.reflection_const = self:GetSpecialValueFor("passive_reflection_constant")
end

function modifier_item_blade_mail_passive:DeclareFunctions(params)
	local funcs = self:GetAbility():GetDefaultFunctions()
    return funcs
end

function modifier_item_blade_mail_passive:OnTakeDamage(params)
    local hero = self:GetParent()
    local dmg = params.damage
	local dmgtype = params.damage_type
	local attacker = params.attacker
	local blademailActive = hero:HasModifier("modifier_item_blade_mail_passive_taunt")

	if HasBit(params.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) or HasBit(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) then return end
	
	if attacker:GetTeamNumber()  ~= hero:GetTeamNumber() and params.unit == hero then
		if blademailActive or params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
			local baseDamage = self.reflection_const * TernaryOperator( 1 + self.active_reflection_pct, blademailActive, 1 )
			if blademailActive then EmitSoundOn("DOTA_Item.BladeMail.Damage", hero) end
			self:GetAbility():ApplyReturn(baseDamage, attacker)
		end
	end
end

function modifier_item_blade_mail_passive:GetModifierHealthBonus()
	return self.bonus_hp
end

function modifier_item_blade_mail_passive:GetModifierBonusStats_Intellect()
	return self.bonus_intellect
end

function modifier_item_blade_mail_passive:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_item_blade_mail_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_blade_mail_passive:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

function modifier_item_blade_mail_passive:IsHidden()
	return true
end

function modifier_item_blade_mail_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_blade_mail_passive:IsHidden()
	return true
end

modifier_item_martyrs_bulwark_passive = class({})
LinkLuaModifier( "modifier_item_martyrs_bulwark_passive", "items/item_blade_mail.lua" ,LUA_MODIFIER_MOTION_NONE )

modifier_item_blade_mail_passive_taunt = class({})
LinkLuaModifier( "modifier_item_blade_mail_passive_taunt", "items/item_blade_mail.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_blade_mail_passive_taunt:OnCreated(table)
	self.radius = self:GetTalentSpecialValueFor("radius")
end

function modifier_item_blade_mail_passive_taunt:IsAura()
	return true
end

function modifier_item_blade_mail_passive_taunt:GetModifierAura()
	return "modifier_item_blade_mail_passive_taunt_aura"
end

function modifier_item_blade_mail_passive_taunt:GetAuraRadius()
	return self.radius
end

function modifier_item_blade_mail_passive_taunt:GetAuraDuration()
	return self:GetRemainingTime()
end

function modifier_item_blade_mail_passive_taunt:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_item_blade_mail_passive_taunt:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_item_blade_mail_passive_taunt:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_item_blade_mail_passive_taunt:GetHeroEffectName()
	return "particles/units/heroes/hero_axe/axe_beserkers_call_hero_effect.vpcf"
end

modifier_item_blade_mail_passive_taunt_aura = class({})
LinkLuaModifier( "modifier_item_blade_mail_passive_taunt_aura", "items/item_blade_mail.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_blade_mail_passive_taunt_aura:OnCreated()
	if IsServer() then 
		self.allowOrder = true
		ExecuteOrderFromTable({
			UnitIndex = self:GetParent():entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
			TargetIndex = self:GetCaster():entindex()
		})
		self.allowOrder = false
		self:StartIntervalThink( 0.1 )
	end
end

function modifier_item_blade_mail_passive_taunt_aura:OnIntervalThink()
	if not self:GetParent():IsAttackingEntity( self:GetCaster() ) and not self:GetParent():HasActiveAbility() then
		self.allowOrder = true
		ExecuteOrderFromTable({
			UnitIndex = self:GetParent():entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
			TargetIndex = self:GetCaster():entindex()
		})
		self.allowOrder = false
	end
end

function modifier_item_blade_mail_passive_taunt_aura:CheckState()
	if not self.allowOrder then
		return {[MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS] = true}
	end
end

function modifier_item_blade_mail_passive_taunt_aura:GetEffectName()
	return "particles/units/heroes/hero_axe/axe_beserkers_call.vpcf"
end

function modifier_item_blade_mail_passive_taunt_aura:GetStatusEffectName()
	return "particles/status_fx/status_effect_beserkers_call.vpcf"
end

function modifier_item_blade_mail_passive_taunt_aura:StatusEffectPriority()
	return 1
end