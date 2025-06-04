item_hurricane_pike = class({})

function item_hurricane_pike:GetIntrinsicModifierName()
	return "modifier_item_hurricane_pike"
end

function item_hurricane_pike:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	if caster:IsSameTeam( target ) then
		local push = target:ApplyKnockBack( target:GetAbsOrigin() - target:GetForwardVector() * 150, 0, 0.5, self:GetSpecialValueFor("push_length"), 0, caster, self ).knockback
		
		push:AddEffect( ParticleManager:CreateParticle( "particles/items_fx/force_staff.vpcf", PATTACH_POINT_FOLLOW, target ) )
	else
		local push_length = self:GetSpecialValueFor("enemy_length")
		local pushPosition = (caster:GetAbsOrigin() + target:GetAbsOrigin()) / 2
		local distance = push_length
		if not caster:IsRangedAttacker() then
			distance = -math.min( push_length, CalculateDistance( caster, target ) / 2 - caster:GetAttackRange( ) / 2 )
		end
		local push = caster:ApplyKnockBack( pushPosition, 0, 0.5, distance, 0, caster, self ).knockback
		local push2 = target:ApplyKnockBack( pushPosition, 0.5, 0.5, distance, 0, caster, self ).knockback
		
		push:AddEffect( ParticleManager:CreateParticle( "particles/items_fx/force_staff.vpcf", PATTACH_POINT_FOLLOW, target ) )
		push2:AddEffect( ParticleManager:CreateParticle( "particles/items_fx/force_staff.vpcf", PATTACH_POINT_FOLLOW, caster ) )

		caster:MoveToTargetToAttack( target )
	end
	
	caster:AddNewModifier( caster, self, "modifier_hurricane_pike_thrust", {duration = self:GetSpecialValueFor("range_duration")} )
	EmitSoundOn( "DOTA_Item.HurricanePike.Activate", caster )
end

modifier_hurricane_pike_thrust = class({})
LinkLuaModifier( "modifier_hurricane_pike_thrust", "items/item_hurricane_pike.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_hurricane_pike_thrust:OnCreated()
	self.bonus_attack_speed = self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
	self.base_attack_range = self:GetAbility():GetSpecialValueFor("base_attack_range")
end

function modifier_hurricane_pike_thrust:DeclareFunctions(params)
	local funcs = {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
    }
    return funcs
end

function modifier_hurricane_pike_thrust:CheckState()
	return {[MODIFIER_STATE_CANNOT_MISS ] = true}
end

function modifier_hurricane_pike_thrust:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

function modifier_hurricane_pike_thrust:GetModifierAttackRangeBonus(params)
	return self.base_attack_range * TernaryOperator( 1, self:GetParent():IsRangedAttacker(), 0.5 )
end

modifier_item_hurricane_pike = class(persistentModifier)
LinkLuaModifier( "modifier_item_hurricane_pike", "items/item_hurricane_pike.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_hurricane_pike:OnCreated()
	self.bonus_strength = self:GetAbility():GetSpecialValueFor("bonus_strength")
	self.bonus_agility = self:GetAbility():GetSpecialValueFor("bonus_agility")
	self.bonus_intellect = self:GetAbility():GetSpecialValueFor("bonus_intellect")
	
	self.bonus_health = self:GetAbility():GetSpecialValueFor("bonus_health")
	self.base_attack_range = self:GetAbility():GetSpecialValueFor("base_attack_range")
end

function modifier_item_hurricane_pike:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, 
			 MODIFIER_PROPERTY_STATS_AGILITY_BONUS, 
			 MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, 
			 MODIFIER_PROPERTY_HEALTH_BONUS, 
			 MODIFIER_PROPERTY_ATTACK_RANGE_BONUS
	}
end

function modifier_item_hurricane_pike:GetModifierBonusStats_Strength(params)
	return self.bonus_strength
end

function modifier_item_hurricane_pike:GetModifierBonusStats_Agility(params)
	return self.bonus_agility
end

function modifier_item_hurricane_pike:GetModifierBonusStats_Intellect(params)
	return self.bonus_intellect
end

function modifier_item_hurricane_pike:GetModifierHealthBonus(params)
	return self.bonus_health
end

function modifier_item_hurricane_pike:GetModifierAttackRangeBonus(params)
	return self.base_attack_range * TernaryOperator( 1, self:GetParent():IsRangedAttacker(), 0.5 )
end

function modifier_item_hurricane_pike:IsHidden()
	return true
end

function modifier_item_hurricane_pike:IsPurgable()
	return false
end

function modifier_item_hurricane_pike:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end