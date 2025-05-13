item_spear_of_justice = class({})

function item_spear_of_justice:GetIntrinsicModifierName()
	return "modifier_item_spear_of_justice"
end

modifier_item_spear_of_justice_cooldown = class({})
LinkLuaModifier( "modifier_item_spear_of_justice_cooldown", "items/item_spear_of_justice.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_spear_of_justice_cooldown:IsPurgable()
	return false
end

function modifier_item_spear_of_justice_cooldown:IsDebuff()
	return true
end

modifier_item_spear_of_justice = class({})
LinkLuaModifier( "modifier_item_spear_of_justice", "items/item_spear_of_justice.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_spear_of_justice:OnCreated()
	self.bonus_strength = self:GetAbility():GetSpecialValueFor("bonus_strength")
	self.bonus_damage = self:GetAbility():GetSpecialValueFor("bonus_damage")
	self.bonus_attack_speed = self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
	self.bonus_mana_regen = self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
	self.bonus_health_regen = self:GetAbility():GetSpecialValueFor("bonus_health_regen")
	
	self.passive_cooldown = self:GetAbility():GetSpecialValueFor("passive_cooldown")
	self.ranged_cooldown = self:GetAbility():GetSpecialValueFor("ranged_cooldown")
	self.slow_duration = self:GetAbility():GetSpecialValueFor("slow_duration")
	
	self.splash_damage = self:GetSpecialValueFor("splash_damage") / 100
	self.splash_damage_ranged = self:GetSpecialValueFor("splash_damage_ranged") / 100
	self.cleave_starting_width = self:GetSpecialValueFor("cleave_starting_width")
	self.cleave_ending_width = self:GetSpecialValueFor("cleave_ending_width")
	self.cleave_distance = self:GetSpecialValueFor("cleave_distance")
end

function modifier_item_spear_of_justice:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_LANDED, 
			 MODIFIER_EVENT_ON_ATTACK, 
			 MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			 MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, 
			 MODIFIER_PROPERTY_ATTACK_RANGE_BONUS, 
			 MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, 
			 MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, 
			 MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, 
	}
end

function modifier_item_spear_of_justice:OnAttack(params)
	if params.attacker == self:GetParent() then
		if not params.attacker:IsIllusion() and not params.attacker:HasModifier("modifier_item_spear_of_justice_cooldown") and not params.attacker:HasModifier("modifier_item_spear_of_justice_buff") then
			local parent = self:GetParent()
			local CD = TernaryOperator( self.ranged_cooldown, parent:IsRangedAttacker(), self.passive_cooldown ) * parent:GetCooldownReduction()
			parent:AddNewModifier(parent, self:GetAbility(), "modifier_item_spear_of_justice_cooldown", {duration = CD})
			parent:AddNewModifier(parent, self:GetAbility(), "modifier_item_spear_of_justice_buff", {})
			params.target:AddNewModifier(parent, self:GetAbility(), "modifier_item_spear_of_justice_debuff", {duration = self.slow_duration})
		end
	end
end

function modifier_item_spear_of_justice:OnAttackLanded(params)
	if IsServer() then
		if params.attacker == self:GetParent() then
			if self.splash_damage > 0 and not params.attacker:IsIllusion() and not params.attacker:IsCleaveSuppressed() then
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
		end
	end
end

function modifier_item_spear_of_justice:GetModifierBonusStats_Strength(params)
	return self.bonus_strength
end

function modifier_item_spear_of_justice:GetModifierPreAttack_BonusDamage(params)
	return self.bonus_damage
end

function modifier_item_spear_of_justice:GetModifierAttackSpeedBonus_Constant(params)
	return self.bonus_attack_speed
end

function modifier_item_spear_of_justice:GetModifierConstantManaRegen(params)
	return self.bonus_mana_regen
end

function modifier_item_spear_of_justice:GetModifierConstantHealthRegen(params)
	return self.bonus_health_regen
end

function modifier_item_spear_of_justice:IsHidden()
	return true
end

function modifier_item_spear_of_justice:IsPurgable()
	return false
end

function modifier_item_spear_of_justice:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

modifier_item_spear_of_justice_buff = class({})
LinkLuaModifier( "modifier_item_spear_of_justice_buff", "items/item_spear_of_justice.lua" ,LUA_MODIFIER_MOTION_NONE )
function modifier_item_spear_of_justice_buff:OnCreated()
	self.duration = self:GetSpecialValueFor("duration")
end

function modifier_item_spear_of_justice_buff:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK, MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

function modifier_item_spear_of_justice_buff:OnAttack(params)
	if params.attacker == self:GetParent() then
		local parent = self:GetParent()
		params.target:AddNewModifier(parent, self:GetAbility(), "modifier_item_spear_of_justice_debuff", {duration = self.duration})
		self:Destroy()
	end
end

function modifier_item_spear_of_justice_buff:GetModifierBaseAttackTimeConstant(params)
	if self._checkingBaseAttackTime then return end
	self._checkingBaseAttackTime = true
	local batToDecrease = self:GetParent():GetBaseAttackTime()
	self._checkingBaseAttackTime = nil
	return batToDecrease/2
end

function modifier_item_spear_of_justice_buff:GetModifierAttackSpeedBonus_Constant(params)
	if self._checkingAttackSpeed then return end
	self._checkingAttackSpeed = true
	local attackSpeed = self:GetParent():GetAttackSpeed( false )
	self._checkingAttackSpeed = nil
	return attackSpeed * 100
end

modifier_item_spear_of_justice_debuff = class({})
LinkLuaModifier( "modifier_item_spear_of_justice_debuff", "items/item_spear_of_justice.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_spear_of_justice_debuff:OnCreated()
	self:OnRefresh()
end

function modifier_item_spear_of_justice_debuff:OnRefresh()
	self.movement_slow = -self:GetSpecialValueFor("movement_slow")
end

function modifier_item_spear_of_justice_debuff:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_item_spear_of_justice_debuff:GetModifierEvasion_Constant()
	return self.evasion
end

function modifier_item_spear_of_justice_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.movement_slow
end