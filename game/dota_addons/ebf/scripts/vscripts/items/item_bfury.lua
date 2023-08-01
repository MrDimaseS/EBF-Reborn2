item_bfury = class({})

function item_bfury:GetIntrinsicModifierName()
	return "item_bfury_passive"
end

item_bfury2 = class(item_bfury)

item_bfury_passive = class({})
LinkLuaModifier( "item_bfury_passive", "items/item_bfury.lua", LUA_MODIFIER_MOTION_NONE )

function item_bfury_passive:OnCreated()
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.bonus_health_regen = self:GetSpecialValueFor("bonus_health_regen")
	self.bonus_mana_regen = self:GetSpecialValueFor("bonus_mana_regen")
	
	self.splash_damage = self:GetSpecialValueFor("splash_damage") / 100
	self.splash_damage_ranged = self:GetSpecialValueFor("splash_damage_ranged") / 100
	self.cleave_starting_width = self:GetSpecialValueFor("cleave_starting_width")
	self.cleave_ending_width = self:GetSpecialValueFor("cleave_ending_width")
	self.cleave_distance = self:GetSpecialValueFor("cleave_distance")
end

function item_bfury_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
			MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
			MODIFIER_EVENT_ON_ATTACK_LANDED,
			}
end

function item_bfury_passive:GetModifierConstantManaRegen()
	return self.bonus_mana_regen
end

function item_bfury_passive:GetModifierConstantHealthRegen()
	return self.bonus_health_regen
end

function item_bfury_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function item_bfury_passive:OnAttackLanded( params )
	if params.attacker == self:GetParent() and not params.attacker:IsIllusion() then
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

function item_bfury_passive:IsHidden()
	return true
end

function item_bfury_passive:IsPurgable()
	return false
end

function item_bfury_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end