item_sange_and_yasha_2 = class({})

function item_sange_and_yasha_2:GetIntrinsicModifierName()
	return "modifier_item_sange_and_yasha_2_passive"
end

item_sange_and_yasha_3 = class(item_sange_and_yasha_2)
item_sange_and_yasha_4 = class(item_sange_and_yasha_2)
item_sange_and_yasha_5 = class(item_sange_and_yasha_2)


modifier_item_sange_and_yasha_2_passive = class({})
LinkLuaModifier( "modifier_item_sange_and_yasha_2_passive", "items/item_sange_and_yasha.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_sange_and_yasha_2_passive:OnCreated()
	self:OnRefresh()
	
	if IsServer() then
		if not self:GetCaster():IsIllusion() and self.aura_radius > 0 then
			local itemFX = ParticleManager:CreateParticle("particles/econ/events/fall_2021/radiance_owner_fall_2021.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster() )
			self:AddEffect( itemFX )
		end
		
		self:StartIntervalThink(1)
	end
end

function modifier_item_sange_and_yasha_2_passive:OnRefresh()
	self.bonus_agility = self:GetSpecialValueFor("bonus_agility")
	self.bonus_strength = self:GetSpecialValueFor("bonus_strength")
	
	self.movement_speed_percent_bonus = self:GetSpecialValueFor("movement_speed_percent_bonus")
	self.bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
	self.bonus_evasion = self:GetSpecialValueFor("bonus_evasion")
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.status_resistance = self:GetSpecialValueFor("status_resistance")
	self.bonus_mana_regen = self:GetSpecialValueFor("bonus_mana_regen")
	self.hp_regen_amp = self:GetSpecialValueFor("hp_regen_amp")
	
	self.bonus_mana = self:GetSpecialValueFor("bonus_mana")
	self.bonus_health = self:GetSpecialValueFor("bonus_health")
	self.health_per_str = self:GetSpecialValueFor("health_per_str")
	
	self.splash_damage = self:GetSpecialValueFor("splash_damage") / 100
	self.splash_damage_ranged = self:GetSpecialValueFor("splash_damage_ranged") / 100
	self.cleave_starting_width = self:GetSpecialValueFor("cleave_starting_width")
	self.cleave_ending_width = self:GetSpecialValueFor("cleave_ending_width")
	self.cleave_distance = self:GetSpecialValueFor("cleave_distance")
	
	self.aura_radius = self:GetSpecialValueFor("aura_radius")
	self.aura_damage = self:GetAbility():GetSpecialValueFor("aura_damage")
	self.aura_damage_illusions = self:GetAbility():GetSpecialValueFor("aura_damage_illusions")
	
	self.max_stacks = self:GetSpecialValueFor("max_stacks")
	self.total_duration = self:GetSpecialValueFor("buffer_duration") + self:GetSpecialValueFor("loss_timer")
end

function modifier_item_sange_and_yasha_2_passive:OnIntervalThink()
	if not self:GetAbility() or self:GetAbility():IsNull() 
	or not self:GetCaster() or self:GetCaster():IsNull() 
	or not self:GetParent() or self:GetParent():IsNull() then 
		self:Destroy()
		return
	end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self.aura_radius ) ) do
		ability:DealDamage( caster, enemy, TernaryOperator( self.aura_damage_illusions, caster:IsIllusion(), self.aura_damage ) )
	end
end

function modifier_item_sange_and_yasha_2_passive:DeclareFunctions()
	return {
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE_UNIQUE,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_EVASION_CONSTANT,
			MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
			MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
			MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_HEALTH_BONUS,
			MODIFIER_PROPERTY_MANA_BONUS,
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
			MODIFIER_EVENT_ON_ATTACK,
			MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_item_sange_and_yasha_2_passive:OnAttack( params )
	if params.attacker == self:GetParent() and params.attacker:IsRealHero() then
	elseif params.target == self:GetParent() then
		local modifier = params.target:AddNewModifier( params.target, self:GetAbility(), "modifier_item_sange_and_yasha_vengeance", {duration = self.total_duration} )
		modifier:SetStackCount( math.min( modifier:GetStackCount() + 1, self.max_stacks ) )
		modifier:ForceRefresh()
	end
end


function modifier_item_sange_and_yasha_2_passive:OnAttackLanded( params )
	if params.attacker == self:GetParent() and params.attacker:IsRealHero() then
		if self.splash_damage > 0 then
			local ability = self:GetAbility()
			local units = 0
			local direction = CalculateDirection( params.target, params.attacker)
			local splash = params.attacker:FindEnemyUnitsInCone( direction, params.target:GetAbsOrigin(), self.cleave_ending_width, self.cleave_distance)
			local splashFX = ParticleManager:CreateParticle( "particles/items_fx/battlefury_cleave.vpcf", PATTACH_POINT, params.attacker )
			ParticleManager:SetParticleControl( splashFX, units, params.attacker:GetAbsOrigin() ) 
			ParticleManager:SetParticleControlTransformForward( splashFX, units, params.attacker:GetAbsOrigin(), direction ) 
			
			local splashDamage = params.original_damage * TernaryOperator( self.splash_damage_ranged, params.attacker:IsRangedAttacker(), self.splash_damage )
			for _, unit in ipairs( splash ) do
				if unit ~= params.target then
					units = units + 1
					ParticleManager:SetParticleControl( splashFX, units, unit:GetAbsOrigin() )
					ability:DealDamage( params.attacker, unit, splashDamage, {damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL } )
				end
			end
			ParticleManager:ReleaseParticleIndex( splashFX )
		end
		local modifier = params.attacker:AddNewModifier( params.attacker, self:GetAbility(), "modifier_item_sange_and_yasha_patience", {duration = self.total_duration} )
		modifier:SetStackCount( math.min( modifier:GetStackCount() + 1, self.max_stacks ) )
		modifier:ForceRefresh()
	end
end

function modifier_item_sange_and_yasha_2_passive:GetModifierBonusStats_Strength()
	return self.bonus_strength
end

function modifier_item_sange_and_yasha_2_passive:GetModifierBonusStats_Agility()
	return self.bonus_agility
end

function modifier_item_sange_and_yasha_2_passive:GetModifierMoveSpeedBonus_Percentage_Unique()
	return self.movement_speed_percent_bonus
end

function modifier_item_sange_and_yasha_2_passive:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

function modifier_item_sange_and_yasha_2_passive:GetModifierEvasion_Constant()
	return self.bonus_evasion
end

function modifier_item_sange_and_yasha_2_passive:GetModifierStatusResistanceStacking()
	return self.status_resistance
end

function modifier_item_sange_and_yasha_2_passive:GetModifierHealAmplify_PercentageSource()
	return self.hp_regen_amp
end

function modifier_item_sange_and_yasha_2_passive:GetModifierHPRegenAmplify_Percentage()
	return self.hp_regen_amp
end

function modifier_item_sange_and_yasha_2_passive:GetModifierLifestealRegenAmplify_Percentage()
	return self.hp_regen_amp
end

function modifier_item_sange_and_yasha_2_passive:GetModifierHealthBonus()
	return self.bonus_health + self.health_per_str * self:GetParent():GetStrength()
end

function modifier_item_sange_and_yasha_2_passive:GetModifierManaBonus()
	return self.bonus_mana
end

function modifier_item_sange_and_yasha_2_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_sange_and_yasha_2_passive:GetModifierConstantManaRegen()
	return self.bonus_mana_regen
end

function modifier_item_sange_and_yasha_2_passive:IsHidden()
	return true
end

function modifier_item_sange_and_yasha_2_passive:IsPurgable()
	return false
end

function modifier_item_sange_and_yasha_2_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

modifier_item_sange_and_yasha_vengeance = class({})
LinkLuaModifier( "modifier_item_sange_and_yasha_vengeance", "items/item_sange_and_yasha.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_sange_and_yasha_vengeance:OnCreated()
	self:OnRefresh()
end

function modifier_item_sange_and_yasha_vengeance:OnRefresh()
	self.attacked_buff = self:GetSpecialValueFor("attacked_buff")
	self.buffer_duration = self:GetSpecialValueFor("buffer_duration")
		self.loss_per_sec = self:GetSpecialValueFor("loss_timer") / self:GetStackCount()
	self.loss_float = 0
	
	if IsServer() then
		self:StartIntervalThink(self.buffer_duration)
	end
end

function modifier_item_sange_and_yasha_vengeance:OnIntervalThink()
	if self:GetStackCount() > 1 then
		self:DecrementStackCount( ) 
		self:StartIntervalThink(self.loss_per_sec)
	end
end

function modifier_item_sange_and_yasha_vengeance:DeclareFunctions()
	return {MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE}
end

function modifier_item_sange_and_yasha_vengeance:GetModifierDamageOutgoing_Percentage()
	return self.attacked_buff * self:GetStackCount()
end

modifier_item_sange_and_yasha_patience = class({})
LinkLuaModifier( "modifier_item_sange_and_yasha_patience", "items/item_sange_and_yasha.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_sange_and_yasha_patience:OnCreated()
	self:OnRefresh()
end

function modifier_item_sange_and_yasha_patience:OnRefresh()
	self.attack_buff = self:GetSpecialValueFor("attack_buff")
	self.buffer_duration = self:GetSpecialValueFor("buffer_duration")
	self.loss_per_sec = self:GetSpecialValueFor("loss_timer") / self:GetStackCount()
	self.loss_float = 0
	
	if IsServer() then
		self:StartIntervalThink(self.buffer_duration)
	end
end

function modifier_item_sange_and_yasha_patience:OnIntervalThink()
	if self:GetStackCount() > 1 then
		self:DecrementStackCount( ) 
		self:StartIntervalThink(self.loss_per_sec)
	end
end

function modifier_item_sange_and_yasha_patience:DeclareFunctions()
	return {MODIFIER_PROPERTY_EVASION_CONSTANT}
end

function modifier_item_sange_and_yasha_patience:GetModifierEvasion_Constant()
	return self.attack_buff * self:GetStackCount()
end
