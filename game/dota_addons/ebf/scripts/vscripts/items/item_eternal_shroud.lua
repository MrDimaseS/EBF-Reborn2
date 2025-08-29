item_eternal_shroud = class({})

function item_eternal_shroud:GetIntrinsicModifierName()
	return "modifier_item_eternal_shroud_passive"
end

function item_eternal_shroud:OnSpellStart()
	local caster = self:GetCaster()
	
	local unitsToHit = {}
	local currentRadius = 150
	local endRadius = self:GetSpecialValueFor("blast_radius")
	local blastSpeed = self:GetSpecialValueFor("blast_speed")
	
	local radiusStep = blastSpeed * 0.1
	
	local damage = self:GetSpecialValueFor("blast_damage")
	local duration = self:GetSpecialValueFor("blast_debuff_duration")
	local amp_duration = self:GetSpecialValueFor("resist_debuff_duration")
	local dmg_to_mana = self:GetSpecialValueFor("dmg_to_mana") / 100
	
	EmitSoundOn( "DOTA_Item.ShivasGuard.Activate", caster )
	ParticleManager:FireParticle( "particles/items2_fx/shivas_guard_active.vpcf", PATTACH_POINT_FOLLOW, caster, {[1] = Vector( endRadius, endRadius / blastSpeed , blastSpeed )})
	Timers:CreateTimer( function()
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), currentRadius ) ) do
			if not unitsToHit[enemy:entindex()] then
				local damage = self:DealDamage( caster, enemy, damage, {damage_type = DAMAGE_TYPE_MAGICAL} )
				if dmg_to_mana > 0 then
					caster:GiveMana( damage * dmg_to_mana )
				end
				enemy:AddNewModifier( caster, self, "modifier_item_shivas_guard_blast", {duration = duration} )
				enemy:AddNewModifier( caster, self, "modifier_item_veil_of_discord_debuff", {duration = amp_duration} )
				unitsToHit[enemy:entindex()] = true
				ParticleManager:FireParticle( "particles/items2_fx/shivas_guard_impact.vpcf", PATTACH_POINT_FOLLOW, enemy )
			end
		end
		if currentRadius < endRadius then
			currentRadius = currentRadius + radiusStep
			return 0.1
		end
	end)
end

item_eternal_shroud_2 = class(item_eternal_shroud)
item_eternal_shroud_3 = class(item_eternal_shroud)
item_eternal_shroud_4 = class(item_eternal_shroud)
item_eternal_shroud_5 = class(item_eternal_shroud)

modifier_item_eternal_shroud_passive = class({})
LinkLuaModifier( "modifier_item_eternal_shroud_passive", "items/item_eternal_shroud.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_eternal_shroud_passive:OnCreated()
	self:OnRefresh()
	self.last_mana_restore_time = 0
end

function modifier_item_eternal_shroud_passive:OnRefresh()
	self.bonus_strength = self:GetSpecialValueFor("bonus_strength")
	self.bonus_other = self:GetSpecialValueFor("bonus_other")
	
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
	self.stack_armor = self:GetSpecialValueFor("stack_armor")
	self.bonus_spell_resist = self:GetSpecialValueFor("bonus_spell_resist")
	self.stack_resist = self:GetSpecialValueFor("stack_resist")
	self.bonus_health = self:GetSpecialValueFor("bonus_health")
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.bonus_mana = self:GetSpecialValueFor("bonus_mana")
	
	self.mana_restore_pct = self:GetSpecialValueFor("mana_restore_pct")
	
	self.aura_radius = self:GetSpecialValueFor("aura_radius")
	self.aura_damage = self:GetSpecialValueFor("aura_damage")
	self.aura_damage_illusions = self:GetSpecialValueFor("aura_damage_illusions")
	self.blast_aura_bonus = self:GetSpecialValueFor("blast_aura_bonus") / 100
	
	self.damage_taken = 0
	self.stack_threshold = self:GetSpecialValueFor("stack_threshold") / 100
	self.stack_duration = self:GetSpecialValueFor("stack_duration")
	self.max_stacks = self:GetSpecialValueFor("max_stacks")
	
	if IsServer() and self.aura_damage > 0 then
		if not self:GetCaster():IsIllusion() then
			local itemFX = ParticleManager:CreateParticle("particles/econ/events/fall_2021/radiance_owner_fall_2021.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster() )
			self:AddEffect( itemFX )
		end
		self:StartIntervalThink(1)
	end
end

function modifier_item_eternal_shroud_passive:OnIntervalThink()
	if not self:GetAbility() or self:GetAbility():IsNull() 
	or not self:GetCaster() or self:GetCaster():IsNull() 
	or not self:GetParent() or self:GetParent():IsNull() then 
		self:Destroy()
		return
	end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self.aura_radius ) ) do
		ability:DealDamage( caster, enemy, TernaryOperator( self.aura_damage_illusions, caster:IsIllusion(), self.aura_damage ) * (1 + TernaryOperator( self.blast_aura_bonus, enemy:HasModifier( "modifier_item_shivas_guard_blast" ), 0 )) )
	end
end

function modifier_item_eternal_shroud_passive:DeclareFunctions()
	return {
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_HEALTH_BONUS,
			MODIFIER_PROPERTY_MANA_BONUS,
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_EVENT_ON_TAKEDAMAGE
	}
end

function modifier_item_eternal_shroud_passive:OnTakeDamage(params)
	if params.unit == self:GetParent() and not params.unit:IsIllusion() then
		if params.inflictor then 
            local current_time = GameRules:GetGameTime()
            if self.mana_restore_pct > 0 and (current_time - self.last_mana_restore_time) >= 0.3 then
                params.unit:GiveMana(self.mana_restore_pct)
                self.last_mana_restore_time = current_time
            end
			self.damage_taken = self.damage_taken + params.damage
			
		elseif self.stack_armor > 0 then
			self.damage_taken = self.damage_taken + params.damage
		end
		if self.damage_taken >= params.unit:GetHealth() * self.stack_threshold then
			self:AddIndependentStack( {duration = self.stack_duration, limit = self.max_stacks} )
			self.damage_taken = 0
		end
	end
end

function modifier_item_eternal_shroud_passive:GetModifierBonusStats_Strength()
	return self.bonus_strength
end

function modifier_item_eternal_shroud_passive:GetModifierBonusStats_Intellect()
	return self.bonus_other
end

function modifier_item_eternal_shroud_passive:GetModifierBonusStats_Agility()
	return self.bonus_other
end

function modifier_item_eternal_shroud_passive:GetModifierPhysicalArmorBonus()
	return self.bonus_armor + self.stack_armor * self:GetStackCount()
end

function modifier_item_eternal_shroud_passive:GetModifierMagicalResistanceBonus()
	return self.bonus_spell_resist + self.stack_resist * self:GetStackCount()
end

function modifier_item_eternal_shroud_passive:GetModifierHealthBonus()
	return self.bonus_health
end

function modifier_item_eternal_shroud_passive:GetModifierManaBonus()
	return self.bonus_mana
end

function modifier_item_eternal_shroud_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_eternal_shroud_passive:IsAura()
	if not IsServer() then return end
	if self.aura_radius == 0 then return end
	return self:GetCaster() and not self:GetCaster():IsNull() and self:GetCaster():IsAlive()
end

function modifier_item_eternal_shroud_passive:GetModifierAura()
	return "modifier_eternal_shroud_burn"
end

function modifier_item_eternal_shroud_passive:GetAuraRadius()
	return self.aura_radius
end

function modifier_item_eternal_shroud_passive:GetAuraDuration()
	return 0.5
end

function modifier_item_eternal_shroud_passive:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_item_eternal_shroud_passive:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_item_eternal_shroud_passive:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_item_eternal_shroud_passive:IsHidden()
	return self:GetStackCount() == 0
end

function modifier_item_eternal_shroud_passive:IsPurgable()
	return false
end

function modifier_item_eternal_shroud_passive:DestroyOnExpire()
	return false
end

function modifier_item_eternal_shroud_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

modifier_eternal_shroud_burn = class({})
LinkLuaModifier( "modifier_eternal_shroud_burn", "items/item_eternal_shroud.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_eternal_shroud_burn:OnCreated()
	self.aura_movespeed = self:GetAbility():GetSpecialValueFor("aura_movespeed")
	self.aura_attack_speed = self:GetAbility():GetSpecialValueFor("aura_attack_speed")
	self.hp_regen_degen_aura = -self:GetAbility():GetSpecialValueFor("hp_regen_degen_aura")
	self.aura_miss_pct = self:GetAbility():GetSpecialValueFor("aura_miss_pct")
	self.blast_aura_bonus = self:GetAbility():GetSpecialValueFor("blast_aura_bonus") / 100
	
	if IsServer() and self.aura_miss_pct > 0 then
		local FX = ParticleManager:CreateRopeParticle( "particles/econ/events/fall_2021/radiance_fall_2021.vpcf", PATTACH_POINT_FOLLOW, self:GetParent(), self:GetCaster() )
		self:AddEffect( FX )
	end
end

function modifier_eternal_shroud_burn:DeclareFunctions()
    return { MODIFIER_PROPERTY_MISS_PERCENTAGE,
			 MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			 MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			 MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
			 MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
			 MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
		}
end

function modifier_eternal_shroud_burn:GetModifierMiss_Percentage()
	return self.aura_miss_pct * (1 + TernaryOperator( self.blast_aura_bonus, self:GetParent():HasModifier( "modifier_item_shivas_guard_blast" ), 0 ))
end

function modifier_eternal_shroud_burn:GetModifierMoveSpeedBonus_Percentage()
	return self.aura_movespeed * (1 + TernaryOperator( self.blast_aura_bonus, self:GetParent():HasModifier( "modifier_item_shivas_guard_blast" ), 0 ))
end

function modifier_eternal_shroud_burn:GetModifierAttackSpeedBonus_Constant()
	return self.aura_attack_speed * (1 + TernaryOperator( self.blast_aura_bonus, self:GetParent():HasModifier( "modifier_item_shivas_guard_blast" ), 0 ))
end

function modifier_eternal_shroud_burn:GetModifierHealAmplify_PercentageSource()
	return self.hp_regen_degen_aura * (1 + TernaryOperator( self.blast_aura_bonus, self:GetParent():HasModifier( "modifier_item_shivas_guard_blast" ), 0 ))
end

function modifier_eternal_shroud_burn:GetModifierHPRegenAmplify_Percentage()
	return self.hp_regen_degen_aura * (1 + TernaryOperator( self.blast_aura_bonus, self:GetParent():HasModifier( "modifier_item_shivas_guard_blast" ), 0 ))
end

function modifier_eternal_shroud_burn:GetModifierLifestealRegenAmplify_Percentage()
	return self.hp_regen_degen_aura * (1 + TernaryOperator( self.blast_aura_bonus, self:GetParent():HasModifier( "modifier_item_shivas_guard_blast" ), 0 ))
end