	item_blade_mail = class({})

function item_blade_mail:GetCastRange( target, position )
	return self:GetSpecialValueFor("reflection_radius") - self:GetCaster():GetCastRangeBonus()
end

function item_blade_mail:GetIntrinsicModifierName()
	return "modifier_item_blade_mail_passive"
end

function item_blade_mail:GetEffectName()
	return "particles/items_fx/blademail.vpcf"
end

function item_blade_mail:GetEffectModifier()
	return "modifier_item_blade_mail_passive_taunt"
end

function item_blade_mail:GetDefaultFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
end

function item_blade_mail:HandleReturn( baseDamage )
	local caster = self:GetCaster()
	caster._superiorBladeMail = caster._superiorBladeMail or {}
	caster._superiorBladeMail[self:GetIntrinsicModifierName()] = caster._superiorBladeMail[self:GetIntrinsicModifierName()] or self
	
	self._evaluatedBaseDamage = baseDamage
	
	if baseDamage > caster._superiorBladeMail[self:GetIntrinsicModifierName()]._evaluatedBaseDamage then
		caster._superiorBladeMail[self:GetIntrinsicModifierName()] = self
	end
end

function item_blade_mail:ApplyReturn( attacker )
	local caster = self:GetCaster()
	
	self:DealDamage( caster, attacker, self._evaluatedBaseDamage, {damage_type = self:GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_REFLECTION} )
	caster._internalBladeMailCD[self:GetIntrinsicModifierName()] = GameRules:GetGameTime()
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

item_conquerors_splint = class(item_blade_mail)

function item_conquerors_splint:HandleReturn( baseDamage )
	local caster = self:GetCaster()
	caster._superiorBladeMail = caster._superiorBladeMail or {}
	caster._superiorBladeMail[self:GetIntrinsicModifierName()] = caster._superiorBladeMail[self:GetIntrinsicModifierName()] or self
	
	local attack_chance = self:GetSpecialValueFor("passive_reflect_pct")
	self._triggeredProc = self:RollPRNG( attack_chance )
	self._evaluatedBaseDamage = baseDamage
	
	if baseDamage > caster._superiorBladeMail[self:GetIntrinsicModifierName()]._evaluatedBaseDamage or ( self._triggeredProc and not caster._superiorBladeMail[self:GetIntrinsicModifierName()]._triggeredProc ) then
		caster._superiorBladeMail[self:GetIntrinsicModifierName()] = self
	end
end

function item_conquerors_splint:ApplyReturn( attacker )
	local caster = self:GetCaster()
	
	if self._triggeredProc then
		caster:PerformGenericAttack( attacker, true, {bonusDamage = self._evaluatedBaseDamage, suppressCleave = true})
	else
		self:DealDamage( caster, attacker, self._evaluatedBaseDamage, {damage_type = self:GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_REFLECTION} )
	end
	caster._internalBladeMailCD[self:GetIntrinsicModifierName()] = GameRules:GetGameTime()
end

function item_conquerors_splint:GetDefaultFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
    }
end

function item_conquerors_splint:GetIntrinsicModifierName()
	return "modifier_item_conquerors_splint_passive"
end

item_conquerors_splint_2 = class(item_conquerors_splint)
item_conquerors_splint_3 = class(item_conquerors_splint)
item_conquerors_splint_4 = class(item_conquerors_splint)
item_conquerors_splint_5 = class(item_conquerors_splint)

item_martyrs_bulwark = class(item_blade_mail)

function item_martyrs_bulwark:GetEffectName()
	return "particles/items2_fx/mjollnir_shield.vpcf"
end

function item_blade_mail:GetEffectModifier()
	return "modifier_item_blade_mail_passive_taunt"
end

function item_martyrs_bulwark:GetDefaultFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
end

function item_martyrs_bulwark:HandleReturn( baseDamage )
	local caster = self:GetCaster()
	caster._superiorBladeMail = caster._superiorBladeMail or {}
	caster._superiorBladeMail[self:GetIntrinsicModifierName()] = caster._superiorBladeMail[self:GetIntrinsicModifierName()] or self
	
	local chain_chance = self:GetSpecialValueFor("chain_chance")
	self._triggeredProc = self:RollPRNG( chain_chance )
	self._evaluatedBaseDamage = baseDamage
	
	if baseDamage > caster._superiorBladeMail[self:GetIntrinsicModifierName()]._evaluatedBaseDamage or ( self._triggeredProc and not caster._superiorBladeMail[self:GetIntrinsicModifierName()]._triggeredProc ) then
		caster._superiorBladeMail[self:GetIntrinsicModifierName()] = self
	end
end

function item_martyrs_bulwark:ApplyReturn( attacker )
	local caster = self:GetCaster()
	
	if self._triggeredProc then
		self:ChainLightning( caster, attacker, self:GetSpecialValueFor("chain_damage") )
	else
		self:DealDamage( caster, attacker, self._evaluatedBaseDamage, {damage_type = self:GetAbilityDamageType(), damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_REFLECTION} )
	end
	caster._internalBladeMailCD[self:GetIntrinsicModifierName()] = GameRules:GetGameTime()
end

function item_martyrs_bulwark:ChainLightning( source, target, damage )
	local caster = self:GetCaster()
	local currentTarget = target
	local currentSource = caster
	if source == caster then
		local targets = {[target] = true}
		local bounces = self:GetSpecialValueFor("chain_strikes") + 1
		local delay = self:GetSpecialValueFor("chain_delay")
		Timers:CreateTimer( 0, function()
			if currentSource == nil then return end
			if currentTarget == nil then return end
			
			bounces = bounces - 1
			self:DealDamage( caster, currentTarget, damage, {damage_type = self:GetAbilityDamageType()} )
			ParticleManager:FireRopeParticle("particles/items_fx/chain_lightning.vpcf", PATTACH_POINT_FOLLOW, currentTarget, currentSource)
			EmitSoundOn( "Item.Maelstrom.Chain_Lightning.Jump", currentTarget )
			targets[currentTarget] = true
			currentSource = currentTarget
				
			for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( currentTarget:GetAbsOrigin(), self:GetSpecialValueFor("chain_radius") ) ) do
				currentTarget = nil
				if not targets[enemy] then
					currentTarget = enemy
					break
				end
			end
			if currentTarget and bounces > 0 then
				return delay
			end
		end)
	end
end

function item_martyrs_bulwark:OnSpellStart()
	local caster = self:GetCaster()

	EmitSoundOn("DOTA_Item.Mjollnir.Activate", caster)

	if caster:HasModifier("modifier_item_blade_mail_passive_taunt") then
		caster:RemoveModifierByName("modifier_item_blade_mail_passive_taunt")
	end
	caster:AddNewModifier(caster,self, "modifier_item_blade_mail_passive_taunt", {Duration = self:GetSpecialValueFor("duration")})
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
	self:OnRefresh()
end

function modifier_item_blade_mail_passive:OnRefresh()
	self.bonus_hp_regen = self:GetAbility():GetSpecialValueFor("bonus_hp_regen")
	self.bonus_all = self:GetAbility():GetSpecialValueFor("bonus_all")
	self.bonus_armor = self:GetAbility():GetSpecialValueFor("bonus_armor")
	self.bonus_damage = self:GetAbility():GetSpecialValueFor("bonus_damage")
	self.bonus_attack_speed = self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
	
	self.active_reflection_pct = self:GetSpecialValueFor("active_reflection_pct") / 100
	self.reflection_const = self:GetSpecialValueFor("passive_reflection_constant")
	self.reflection_radius = self:GetSpecialValueFor("reflection_radius")
	self.internal_cd = self:GetSpecialValueFor("internal_cd")
	
	self.chain_damage = self:GetSpecialValueFor("chain_damage")
	self.chain_chance = self:GetSpecialValueFor("chain_chance")
	
	self.crit_chance = self:GetSpecialValueFor("crit_chance")
	self.reflect_crit_chance = self:GetSpecialValueFor("reflect_crit_chance")
	self.crit_multiplier = self:GetSpecialValueFor("crit_multiplier")
	
	self:GetParent()._internalBladeMailCD = self:GetParent()._internalBladeMailCD or {}
	self:GetParent()._internalBladeMailCD[self:GetName()] = GameRules:GetGameTime()
	
	self:GetParent()._suppressFurtherProcs = self:GetParent()._suppressFurtherProcs or {}
	self:GetParent()._suppressFurtherProcs[self:GetName()] = false
end

function modifier_item_blade_mail_passive:DeclareFunctions(params)
	local funcs = self:GetAbility():GetDefaultFunctions()
    return funcs
end

function modifier_item_blade_mail_passive:OnAttackLanded(params)
    local hero = self:GetParent()
    local ability = self:GetAbility()
    local dmg = params.damage
	local dmgtype = params.damage_type
	local attacker = params.attacker
	local blademailActive = IsModifierSafe( hero:FindModifierByNameAndAbility("modifier_item_blade_mail_passive_taunt", self:GetAbility() ) )
	
	if not ( IsEntitySafe( attacker ) and attacker:IsAlive() ) then return end
	if self.OnAttackLandedBehavior then self:OnAttackLandedBehavior( params ) end
	if not blademailActive then
		if not hero._internalBladeMailCD[self:GetName()] then hero._internalBladeMailCD[self:GetName()] = GameRules:GetGameTime() end
		if GameRules:GetGameTime() < hero._internalBladeMailCD[self:GetName()] + self.internal_cd then return end
		if CalculateDistance( hero, attacker ) > self.reflection_radius then return end
	end
	if not attacker:IsSameTeam( hero ) and params.target == hero then
		local baseDamage = self.reflection_const * TernaryOperator( 1 + self.active_reflection_pct, blademailActive, 1 )
		self:GetAbility():HandleReturn(baseDamage)
		if blademailActive then
			EmitSoundOn("DOTA_Item.BladeMail.Damage", hero)
		end
		if not hero._suppressFurtherProcs[self:GetName()] then
			hero._suppressFurtherProcs[self:GetName()] = true
			Timers:CreateTimer( function()
				hero._superiorBladeMail[self:GetName()]:ApplyReturn( attacker )
				hero._suppressFurtherProcs[self:GetName()] = false
				hero._superiorBladeMail = nil
			end)
		end
		
	end
end

function modifier_item_blade_mail_passive:GetModifierBonusStats_Intellect()
	return self.bonus_all
end

function modifier_item_blade_mail_passive:GetModifierBonusStats_Strength()
	return self.bonus_all
end

function modifier_item_blade_mail_passive:GetModifierBonusStats_Agility()
	return self.bonus_all
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

modifier_item_conquerors_splint_passive = class(modifier_item_blade_mail_passive)
LinkLuaModifier( "modifier_item_conquerors_splint_passive", "items/item_blade_mail.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_conquerors_splint_passive:GetModifierConstantHealthRegen()
	return self.bonus_hp_regen
end

function modifier_item_conquerors_splint_passive:GetModifierPreAttack_CriticalStrike( params )
	local crit_chance = TernaryOperator( self.reflect_crit_chance, params.target:IsAttackingEntity( params.attacker ), self.crit_chance )
	local roll = RollPseudoRandomPercentage( crit_chance, DOTA_PSEUDO_RANDOM_CUSTOM_GENERIC, params.attacker )
	if roll then
		return self.crit_multiplier
	end
end

function modifier_item_conquerors_splint_passive:GetCritDamage()
	return self.crit_multiplier / 100
end

modifier_item_martyrs_bulwark_passive = class(modifier_item_blade_mail_passive)
LinkLuaModifier( "modifier_item_martyrs_bulwark_passive", "items/item_blade_mail.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_martyrs_bulwark_passive:OnAttackLandedBehavior( params )
    local hero = self:GetParent()
	local attacker = params.attacker
	hero._internalBulwarkHitCooldown = hero._internalBulwarkHitCooldown or GameRules:GetGameTime()
	if GameRules:GetGameTime() < hero._internalBulwarkHitCooldown + self.internal_cd then return end
	if attacker == hero and (RollPercentage( self.chain_chance ) or hero:HasModifier("modifier_item_blade_mail_passive_taunt")) then
		self:GetAbility():ChainLightning( hero, params.target, self.chain_damage )
		hero._internalBulwarkHitCooldown = GameRules:GetGameTime()
	end
end

modifier_item_blade_mail_passive_taunt = class({})
LinkLuaModifier( "modifier_item_blade_mail_passive_taunt", "items/item_blade_mail.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_blade_mail_passive_taunt:OnCreated(table)
	self.reflection_radius = self:GetSpecialValueFor("reflection_radius")
	self.taunts_enemies = tonumber(self:GetSpecialValueFor("taunts_enemies")) == 1
end

function modifier_item_blade_mail_passive_taunt:IsAura()
	return self.taunts_enemies
end

function modifier_item_blade_mail_passive_taunt:GetModifierAura()
	return "modifier_item_blade_mail_passive_taunt_aura"
end

function modifier_item_blade_mail_passive_taunt:GetAuraRadius()
	return self.reflection_radius
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

function modifier_item_blade_mail_passive_taunt:GetEffectName()
	return self:GetAbility():GetEffectName()
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