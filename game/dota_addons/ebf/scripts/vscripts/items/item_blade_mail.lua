item_blade_mail2 = class({})

function item_blade_mail2:GetCastRange( target, position )
	return self:GetSpecialValueFor("radius") - self:GetCaster():GetCastRangeBonus()
end

function item_blade_mail2:GetIntrinsicModifierName()
	return "modifier_blade_mail"
end

function item_blade_mail2:OnSpellStart()
	local caster = self:GetCaster()

	EmitSoundOn("Hero_Axe.Berserkers_Call", caster)
	EmitSoundOn("DOTA_Item.BladeMail.Activate", caster)

	if caster:HasModifier("modifier_blade_mail_taunt") then
		caster:RemoveModifierByName("modifier_blade_mail_taunt")
	end
	caster:AddNewModifier(caster,self, "modifier_blade_mail_taunt", {Duration = self:GetSpecialValueFor("duration")})
end

item_blade_mail = class(item_blade_mail2)
item_blade_mail3 = class(item_blade_mail2)
item_blade_mail4 = class(item_blade_mail2)

function item_blade_mail4:BurnAuraModifier()
	return "modifier_item_blade_mail4_burn"
end

item_blade_mail5 = class(item_blade_mail4)

modifier_blade_mail = class({})
LinkLuaModifier( "modifier_blade_mail", "items/item_blade_mail.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_blade_mail:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_blade_mail:OnCreated()
	self.health_regen = self:GetAbility():GetSpecialValueFor("health_regen")
	self.bonus_all = self:GetAbility():GetSpecialValueFor("bonus_all")
	self.bonus_armor = self:GetAbility():GetSpecialValueFor("bonus_armor")
	self.bonus_damage = self:GetAbility():GetSpecialValueFor("bonus_damage")
	self.evasion = self:GetAbility():GetSpecialValueFor("evasion")
	
	self.aura_radius = self:GetAbility():GetSpecialValueFor("aura_radius")
	self.aura_damage = self:GetAbility():GetSpecialValueFor("aura_damage")
	self.aura_damage_illusions = self:GetSpecialValueFor("aura_damage_illusions")
	self.active_aura_damage = self:GetAbility():GetSpecialValueFor("active_aura_damage")
	
	self.reflection_pct = self:GetSpecialValueFor("passive_reflection_pct") / 100
	self.active_reflection_pct = self:GetSpecialValueFor("active_reflection_pct") / 100
	self.reflection_const = self:GetSpecialValueFor("passive_reflection_constant")
	
	if IsServer() and self.aura_radius > 0 then
		if not self:GetCaster():IsIllusion() then
			local itemFX = ParticleManager:CreateParticle( "particles/econ/events/fall_2022/radiance/radiance_owner_fall2022.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster() )
			self:AddEffect( itemFX )
		end
		self:StartIntervalThink(1)
	end
end

function modifier_blade_mail:OnIntervalThink()
	if not self:GetAbility() or self:GetAbility():IsNull() 
	or not self:GetCaster() or self:GetCaster():IsNull() 
	or not self:GetParent() or self:GetParent():IsNull() then 
		self:Destroy()
		return
	end
	
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self.aura_radius ) ) do
		local damage = TernaryOperator( self.active_aura_damage, caster:HasModifier("modifier_blade_mail_taunt"), self.aura_damage )
		ability:DealDamage( caster, enemy, TernaryOperator( self.aura_damage_illusions, caster:IsIllusion(), damage ) )
	end
end

function modifier_blade_mail:DeclareFunctions(params)
local funcs = {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_EVASION_CONSTANT,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_ON_ATTACK_FAIL
    }
    return funcs
end

function modifier_blade_mail:OnAttackFail(params)
    local hero = self:GetParent()
	local attacker = params.attacker
	local blademailActive = hero:HasModifier("modifier_blade_mail_taunt")

	if HasBit(params.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) or HasBit(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) then return end
	
	if attacker:GetTeamNumber()  ~= hero:GetTeamNumber() and params.target == hero then
		local baseDamage = self.reflection_const * TernaryOperator( 1 + self.active_reflection_pct, blademailActive, 1 )
		
		if blademailActive then EmitSoundOn("DOTA_Item.BladeMail.Damage", hero) end
		self:GetAbility():DealDamage( hero, attacker, baseDamage, {damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL +DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_REFLECTION} )
	end
end

function modifier_blade_mail:OnTakeDamage(params)
    local hero = self:GetParent()
    local dmg = params.damage
	local dmgtype = params.damage_type
	local attacker = params.attacker
	local blademailActive = hero:HasModifier("modifier_blade_mail_taunt")

	if HasBit(params.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) or HasBit(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) then return end
	
	if attacker:GetTeamNumber()  ~= hero:GetTeamNumber() and params.unit == hero then
		if blademailActive or params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
			local baseDamage = self.reflection_const * TernaryOperator( 1 + self.active_reflection_pct, blademailActive, 1 )
			local damagePct = params.original_damage * TernaryOperator( self.reflection_pct + self.active_reflection_pct, blademailActive, self.reflection_pct )
			
			if blademailActive then EmitSoundOn("DOTA_Item.BladeMail.Damage", hero) end
			self:GetAbility():DealDamage( hero, attacker, baseDamage + damagePct, {damage_type = params.damage_type, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL +DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_REFLECTION} )
		end
	end
end

function modifier_blade_mail:GetModifierConstantHealthRegen()
	return self.health_regen
end

function modifier_blade_mail:GetModifierBonusStats_Strength()
	return self.bonus_all
end

function modifier_blade_mail:GetModifierBonusStats_Intellect()
	return self.bonus_all
end

function modifier_blade_mail:GetModifierBonusStats_Agility()
	return self.bonus_all
end

function modifier_blade_mail:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_blade_mail:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_blade_mail:GetModifierEvasion_Constant()
	return self.evasion
end

function modifier_blade_mail:IsAura()
	return self.aura_radius > 0
end

function modifier_blade_mail:GetModifierAura()
	return self:GetAbility():BurnAuraModifier()
end

function modifier_blade_mail:GetAuraRadius()
	return self.aura_radius
end

function modifier_blade_mail:GetAuraDuration()
	return 0.5
end

function modifier_blade_mail:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_blade_mail:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_blade_mail:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_blade_mail:IsHidden()
	return true
end

function modifier_blade_mail:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_blade_mail:IsHidden()
	return true
end


modifier_blade_mail_taunt = class({})
LinkLuaModifier( "modifier_blade_mail_taunt", "items/item_blade_mail.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_blade_mail_taunt:OnCreated(table)
	self.radius = self:GetTalentSpecialValueFor("radius")
end

function modifier_blade_mail_taunt:IsAura()
	return true
end

function modifier_blade_mail_taunt:GetModifierAura()
	return "modifier_blade_mail_taunt_aura"
end

function modifier_blade_mail_taunt:GetAuraRadius()
	return self.radius
end

function modifier_blade_mail_taunt:GetAuraDuration()
	return self:GetRemainingTime()
end

function modifier_blade_mail_taunt:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_blade_mail_taunt:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_blade_mail_taunt:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_blade_mail_taunt:GetHeroEffectName()
	return "particles/units/heroes/hero_axe/axe_beserkers_call_hero_effect.vpcf"
end

modifier_blade_mail_taunt_aura = class({})
LinkLuaModifier( "modifier_blade_mail_taunt_aura", "items/item_blade_mail.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_blade_mail_taunt_aura:OnCreated()
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

function modifier_blade_mail_taunt_aura:OnIntervalThink()
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

function modifier_blade_mail_taunt_aura:CheckState()
	if not self.allowOrder then
		return {[MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS] = true}
	end
end

function modifier_blade_mail_taunt_aura:GetEffectName()
	return "particles/units/heroes/hero_axe/axe_beserkers_call.vpcf"
end

function modifier_blade_mail_taunt_aura:GetStatusEffectName()
	return "particles/status_fx/status_effect_beserkers_call.vpcf"
end

function modifier_blade_mail_taunt_aura:StatusEffectPriority()
	return 1
end

modifier_item_blade_mail4_burn = class({})
LinkLuaModifier( "modifier_item_blade_mail4_burn", "items/item_blade_mail.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_blade_mail4_burn:OnCreated()
	self.blind_pct = self:GetAbility():GetSpecialValueFor("blind_pct")
	
	if IsServer() then
		self:StartIntervalThink(1)
		
		local FX = ParticleManager:CreateRopeParticle( "particles/econ/events/fall_2022/radiance_target_fall2022.vpcf", PATTACH_POINT_FOLLOW, self:GetParent(), self:GetCaster() )
		self:AddEffect( FX )
	end
end

function modifier_item_blade_mail4_burn:OnRefresh()
	self.blind_pct = math.max( self.blind_pct, self:GetAbility():GetSpecialValueFor("blind_pct") )
end

function modifier_item_blade_mail4_burn:DeclareFunctions(params)
	local funcs = {MODIFIER_PROPERTY_MISS_PERCENTAGE}
    return funcs
end

function modifier_item_blade_mail4_burn:GetModifierMiss_Percentage()
	return self.blind_pct
end