item_blink_treads = class({})

function item_blink_treads:GetIntrinsicModifierName()
	return "modifier_blink_treads_passive"
end

function item_blink_treads:GetCastRange( position, target )
	if IsClient() then
		return self:GetSpecialValueFor("blink_range")
	else
		return 0
	end
end

function item_blink_treads:GetAbilityTextureName( iLvl )
	if self.chosenAttribute == DOTA_ATTRIBUTE_STRENGTH then
		return "blink/blink_treads_str"
	elseif self.chosenAttribute == DOTA_ATTRIBUTE_INTELLECT then
		return "blink/blink_treads_int"
	else
		return "blink/blink_treads_agi"
	end
end

function item_blink_treads:GetCooldown( iLvl )
	if self.chosenAttribute == DOTA_ATTRIBUTE_INTELLECT then
		return self:GetSpecialValueFor("arcane_blink_cd")
	else
		return self.BaseClass.GetCooldown( self, iLvl )
	end
end

function item_blink_treads:OnSpellStart()
	local caster = self:GetCaster()
	local position = self:GetCursorPosition()
	
	if self:GetCursorTarget() == caster then
		if self.chosenAttribute == DOTA_ATTRIBUTE_STRENGTH then
			self.passiveModifier:SetStackCount(DOTA_ATTRIBUTE_INTELLECT)
		elseif self.chosenAttribute == DOTA_ATTRIBUTE_INTELLECT then
			self.passiveModifier:SetStackCount(DOTA_ATTRIBUTE_AGILITY)
		else
			self.passiveModifier:SetStackCount(DOTA_ATTRIBUTE_STRENGTH)
		end
		caster:CalculateStatBonus( false )
		self:EndCooldown()
		return
	end
	
	if self.chosenAttribute == DOTA_ATTRIBUTE_AGILITY then
		ParticleManager:FireParticle( "particles/items3_fx/blink_swift_start.vpcf", PATTACH_ABSORIGIN, caster, {[0] = caster:GetAbsOrigin()})
	elseif self.chosenAttribute == DOTA_ATTRIBUTE_INTELLECT then
		ParticleManager:FireParticle( "particles/items3_fx/blink_arcane_start.vpcf", PATTACH_ABSORIGIN, caster, {[0] = caster:GetAbsOrigin()})
	else
		ParticleManager:FireParticle( "particles/items3_fx/blink_overwhelming_start.vpcf", PATTACH_ABSORIGIN, caster, {[0] = caster:GetAbsOrigin()})
	end
	
	local duration = self:GetSpecialValueFor("duration")
	caster:Blink( position, {distance = self:GetSpecialValueFor("blink_range") + caster:GetCastRangeBonus(), clamp = self:GetSpecialValueFor("blink_range_clamp") + caster:GetCastRangeBonus(), FX = false } )
	
	if self.chosenAttribute == DOTA_ATTRIBUTE_AGILITY then
		ParticleManager:FireParticle( "particles/items3_fx/blink_swift_end.vpcf", PATTACH_POINT, caster )
		EmitSoundOn( "Blink_Layer.Swift", caster )
		
		caster:AddNewModifier( caster, self, "modifier_item_swift_blink_buff", {duration = duration} )
	elseif self.chosenAttribute == DOTA_ATTRIBUTE_INTELLECT then
		ParticleManager:FireParticle( "particles/items3_fx/blink_arcane_end.vpcf", PATTACH_POINT, caster )
		EmitSoundOn( "Blink_Layer.Arcane", caster )
		
		caster:HealEvent(self:GetSpecialValueFor("heal_amount"), self, caster)
		caster:GiveMana(self:GetSpecialValueFor("mana_amount"))
	else
		ParticleManager:FireParticle( "particles/items3_fx/blink_overwhelming_end.vpcf", PATTACH_POINT, caster )
		EmitSoundOn( "Blink_Layer.Overwhelming", caster )
		
		local radius = self:GetSpecialValueFor("radius")
		local damage = self:GetSpecialValueFor("base_damage") + caster:GetStrength() * self:GetSpecialValueFor("damage_pct") / 100
		
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), radius ) ) do
			self:DealDamage( caster, enemy, damage, {damage_type = DAMAGE_TYPE_MAGICAL} )
			enemy:AddNewModifier( caster, self, "modifier_item_overwhelming_blink_debuff", {duration = duration} )
		end
		
		ParticleManager:FireParticle( "particles/items3_fx/blink_overwhelming_burst.vpcf", PATTACH_POINT, caster, {[1] = Vector( radius, radius, radius )} )
	end
end

item_blink_treads2 = class(item_blink_treads)

function item_blink_treads2:GetAbilityTextureName( iLvl )
	if self.chosenAttribute == DOTA_ATTRIBUTE_STRENGTH then
		return "blink/blink_treads2_str"
	elseif self.chosenAttribute == DOTA_ATTRIBUTE_INTELLECT then
		return "blink/blink_treads2_int"
	else
		return "blink/blink_treads2_agi"
	end
end

item_blink_treads3 = class(item_blink_treads)

function item_blink_treads3:GetAbilityTextureName( iLvl )
	if self.chosenAttribute == DOTA_ATTRIBUTE_STRENGTH then
		return "blink/blink_treads3_str"
	elseif self.chosenAttribute == DOTA_ATTRIBUTE_INTELLECT then
		return "blink/blink_treads3_int"
	else
		return "blink/blink_treads3_agi"
	end
end

item_blink_treads4 = class(item_blink_treads)

function item_blink_treads4:GetAbilityTextureName( iLvl )
	if self.chosenAttribute == DOTA_ATTRIBUTE_STRENGTH then
		return "blink/blink_treads4_str"
	elseif self.chosenAttribute == DOTA_ATTRIBUTE_INTELLECT then
		return "blink/blink_treads4_int"
	else
		return "blink/blink_treads4_agi"
	end
end
item_blink_treads5 = class(item_blink_treads)

function item_blink_treads5:GetAbilityTextureName( iLvl )
	if self.chosenAttribute == DOTA_ATTRIBUTE_STRENGTH then
		return "blink/blink_treads5_str"
	elseif self.chosenAttribute == DOTA_ATTRIBUTE_INTELLECT then
		return "blink/blink_treads5_int"
	else
		return "blink/blink_treads5_agi"
	end
end

modifier_blink_treads_passive = class({})
LinkLuaModifier( "modifier_blink_treads_passive", "items/item_blink_treads.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_blink_treads_passive:OnCreated()
	self.bonus_movement_speed_ranged = self:GetAbility():GetSpecialValueFor("bonus_movement_speed_ranged")
	self.bonus_movement_speed_melee = self:GetAbility():GetSpecialValueFor("bonus_movement_speed_melee")
	self.bonus_stat = self:GetAbility():GetSpecialValueFor("bonus_stat")
	self.bonus_other = self:GetSpecialValueFor("bonus_other")
	self.bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
	
	self.damage_cd = self:GetSpecialValueFor("blink_damage_cooldown")
	self.arcane_blink_dmg_cd = self:GetSpecialValueFor("arcane_blink_dmg_cd")
	
	self:GetAbility().passiveModifier = self
	if self:GetAbility().chosenAttribute then
		self:SetStackCount( self:GetAbility().chosenAttribute )
	else
		self:GetAbility().chosenAttribute = self:GetStackCount()
	end
end

function modifier_blink_treads_passive:OnStackCountChanged( stacks )
	self:GetAbility().chosenAttribute = self:GetStackCount()
end

function modifier_blink_treads_passive:DeclareFunctions(params)
	local funcs = {
				MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
				MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
				MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
				MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE,
				MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,				
				MODIFIER_EVENT_ON_TAKEDAMAGE,
			}
    return funcs
end

function modifier_blink_treads_passive:OnTakeDamage(params)
	if params.unit == self:GetParent() and params.attacker:IsConsideredHero() and self:GetAbility():GetCooldownTimeRemaining() < self.damage_cd and params.damage > 25 then
		self:GetAbility():SetCooldown( TernaryOperator( self.damage_cd, self:GetStackCount() == DOTA_ATTRIBUTE_INTELLECT, self.arcane_blink_dmg_cd ) )
	end
end

function modifier_blink_treads_passive:GetModifierMoveSpeedBonus_Special_Boots()
	return TernaryOperator( self.bonus_movement_speed_ranged, self:GetParent():IsRangedAttacker(), self.bonus_movement_speed_melee )
end

function modifier_blink_treads_passive:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

function modifier_blink_treads_passive:GetModifierBonusStats_Strength()
	return TernaryOperator( self.bonus_stat, self:GetStackCount() == DOTA_ATTRIBUTE_STRENGTH, self.bonus_other )
end

function modifier_blink_treads_passive:GetModifierBonusStats_Intellect()
	return TernaryOperator( self.bonus_stat, self:GetStackCount() == DOTA_ATTRIBUTE_INTELLECT, self.bonus_other )
end

function modifier_blink_treads_passive:GetModifierBonusStats_Agility()
	return TernaryOperator( self.bonus_stat, self:GetStackCount() == DOTA_ATTRIBUTE_AGILITY, self.bonus_other )
end

function modifier_blink_treads_passive:IsHidden()
	return true
end

function modifier_blink_treads_passive:IsPurgable()
	return false
end

function modifier_blink_treads_passive:RemoveOnDeath()
	return false
end

function modifier_blink_treads_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end