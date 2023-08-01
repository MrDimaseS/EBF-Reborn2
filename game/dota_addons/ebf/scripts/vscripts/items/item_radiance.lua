item_radiance_2 = class({})

function item_radiance_2:GetIntrinsicModifierName()
	return "modifier_item_radiance_2_passive"
end

item_radiance = class(item_radiance_2)
item_radiance_3 = class(item_radiance_2)

item_zero = class({})

function item_zero:GetIntrinsicModifierName()
	return "modifier_item_zero_passive"
end

modifier_item_radiance_2_passive = class({})
LinkLuaModifier( "modifier_item_radiance_2_passive", "items/item_radiance.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_radiance_2_passive:OnCreated()
	self.bonus_all = self:GetSpecialValueFor("bonus_all")
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.evasion = self:GetSpecialValueFor("evasion")
	
	self.aura_radius = self:GetSpecialValueFor("aura_radius")
	self.aura_damage = self:GetSpecialValueFor("aura_damage")
	self.aura_damage_illusions = self:GetSpecialValueFor("aura_damage_illusions")
	
	if IsServer() then
		if not self:GetCaster():IsIllusion() then
			local itemFX = ParticleManager:CreateParticle( "particles/items2_fx/radiance_owner.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster() )
			self:AddEffect( itemFX )
		end
		self:StartIntervalThink(1)
	end
end

function modifier_item_radiance_2_passive:OnIntervalThink()
	if not self:GetAbility() or self:GetAbility():IsNull() 
	or not self:GetCaster() or self:GetCaster():IsNull() 
	or not self:GetParent() or self:GetParent():IsNull() then 
		self:Destroy()
		return
	end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if caster:IsAlive() and not caster:IsInvulnerable() then
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self.aura_radius ) ) do
		   ability:DealDamage( caster, enemy, TernaryOperator( self.aura_damage_illusions, caster:IsIllusion(), self.aura_damage ) )
		end
	 end
end

function modifier_item_radiance_2_passive:DeclareFunctions(params)
	local funcs = {
					MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
					MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
					MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
					
					MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
					MODIFIER_PROPERTY_EVASION_CONSTANT
				}
    return funcs
end

function modifier_item_radiance_2_passive:GetModifierBonusStats_Strength()
	return self.bonus_all
end

function modifier_item_radiance_2_passive:GetModifierBonusStats_Agility()
	return self.bonus_all
end

function modifier_item_radiance_2_passive:GetModifierBonusStats_Intellect()
	return self.bonus_all
end

function modifier_item_radiance_2_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_radiance_2_passive:GetModifierEvasion_Constant()
	return self.evasion
end

function modifier_item_radiance_2_passive:IsAura()
	if not IsServer() then return end
	return self:GetCaster() and not self:GetCaster():IsNull() and self:GetCaster():IsAlive()
end

function modifier_item_radiance_2_passive:GetModifierAura()
	return "modifier_item_radiance_2_burn"
end

function modifier_item_radiance_2_passive:GetAuraRadius()
	return self.aura_radius
end

function modifier_item_radiance_2_passive:GetAuraDuration()
	return 0.5
end

function modifier_item_radiance_2_passive:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_item_radiance_2_passive:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_item_radiance_2_passive:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_item_radiance_2_passive:IsHidden()
	return true
end

function modifier_item_radiance_2_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

modifier_item_zero_passive = class(modifier_item_radiance_2_passive)
LinkLuaModifier( "modifier_item_zero_passive", "items/item_radiance.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_zero_passive:OnCreated()
	self.bonus_all = self:GetSpecialValueFor("bonus_all")
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.evasion = self:GetSpecialValueFor("evasion")
	
	self.aura_radius = self:GetSpecialValueFor("aura_radius")
	self.aura_damage = self:GetSpecialValueFor("aura_damage")
	self.aura_damage_illusions = self:GetSpecialValueFor("aura_damage_illusions")
	
	if IsServer() then
		if not self:GetCaster():IsIllusion() then
			local itemFX = ParticleManager:CreateParticle("particles/econ/events/fall_2021/radiance_owner_fall_2021.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster() )
			self:AddEffect( itemFX )
		end
		self:StartIntervalThink(1)
	end
end

function modifier_item_zero_passive:GetModifierAura()
	return "modifier_item_zero_burn"
end

modifier_item_radiance_2_burn = class({})
LinkLuaModifier( "modifier_item_radiance_2_burn", "items/item_radiance.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_radiance_2_burn:OnCreated()
	self.blind_pct = self:GetAbility():GetSpecialValueFor("blind_pct")
	self.aura_damage = self:GetAbility():GetSpecialValueFor("aura_damage")
	
	if IsServer() then
		self:StartIntervalThink(1)
		
		local FX = ParticleManager:CreateRopeParticle( "particles/items2_fx/radiance.vpcf", PATTACH_POINT_FOLLOW, self:GetParent(), self:GetCaster() )
		self:AddEffect( FX )
	end
end

function modifier_item_radiance_2_burn:DeclareFunctions(params)
	local funcs = {MODIFIER_PROPERTY_MISS_PERCENTAGE}
    return funcs
end

function modifier_item_radiance_2_burn:GetModifierMiss_Percentage()
	return self.blind_pct
end

modifier_item_zero_burn = class({})
LinkLuaModifier( "modifier_item_zero_burn", "items/item_radiance.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_zero_burn:OnCreated()
	self.aura_miss_pct = self:GetAbility():GetSpecialValueFor("aura_miss_pct")
	self.aura_movespeed = self:GetAbility():GetSpecialValueFor("aura_movespeed")
	self.aura_attackspeed = self:GetAbility():GetSpecialValueFor("aura_attackspeed")
	self.aura_heal_reduction = self:GetAbility():GetSpecialValueFor("aura_heal_reduction")
	self.aura_damage = self:GetAbility():GetSpecialValueFor("aura_damage")
	
	if IsServer() then
		self:StartIntervalThink(1)
		
		local FX = ParticleManager:CreateRopeParticle( "particles/econ/events/fall_2021/radiance_fall_2021.vpcf", PATTACH_POINT_FOLLOW, self:GetParent(), self:GetCaster() )
		self:AddEffect( FX )
	end
end

function modifier_item_zero_burn:DeclareFunctions(params)
	local funcs = {	MODIFIER_PROPERTY_MISS_PERCENTAGE, 
					MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, 
					MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
					MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
					MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
					MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE}
    return funcs
end

function modifier_item_zero_burn:GetModifierMiss_Percentage()
	return self.aura_miss_pct
end

function modifier_item_zero_burn:GetModifierMoveSpeedBonus_Percentage()
	return self.aura_movespeed
end

function modifier_item_zero_burn:GetModifierAttackSpeedBonus_Constant()
	return self.aura_attackspeed
end

function modifier_item_zero_burn:GetModifierHealAmplify_PercentageSource()
	return self.aura_heal_reduction
end

function modifier_item_zero_burn:GetModifierHPRegenAmplify_Percentage()
	return self.aura_heal_reduction
end

function modifier_item_zero_burn:GetModifierLifestealRegenAmplify_Percentage()
	return self.aura_heal_reduction
end