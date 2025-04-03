item_radiance_2 = class({})

function item_radiance_2:GetIntrinsicModifierName()
	return "modifier_item_radiance_2_passive"
end

item_skeleton_king_radiance = class(item_radiance_2)
item_radiance = class(item_radiance_2)
item_radiance_3 = class(item_radiance_2)
item_radiance_4 = class(item_radiance_2)
item_radiance_5 = class(item_radiance_2)

modifier_item_radiance_2_passive = class({})
LinkLuaModifier( "modifier_item_radiance_2_passive", "items/item_radiance.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_radiance_2_passive:OnCreated()
	self:OnRefresh()
	if IsServer() then
		if not self:GetCaster():IsFakeHero() then
			local itemFX = ParticleManager:CreateParticle( "particles/items2_fx/radiance_owner.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster() )
			self:AddEffect( itemFX )
		end
		self:StartIntervalThink(1)
	end
end

function modifier_item_radiance_2_passive:OnRefresh()
	self.bonus_all = self:GetSpecialValueFor("bonus_all")
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.evasion = self:GetSpecialValueFor("evasion")
	
	self.aura_radius = self:GetSpecialValueFor("aura_radius")
	self.aura_damage = self:GetSpecialValueFor("aura_damage")
	self.aura_damage_illusions = self:GetSpecialValueFor("aura_damage_illusions")
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
		local enemies = caster:FindEnemyUnitsInRadius(caster:GetAbsOrigin(), self.aura_radius)
		for _, enemy in ipairs(enemies) do
			ability:DealDamage( caster, enemy, TernaryOperator( self.aura_damage_illusions, caster:IsIllusion(), self.aura_damage ) )
		end
	end
end

function modifier_item_radiance_2_passive:DeclareFunctions(params)
	local funcs = {
					MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
					MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
					MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
					MODIFIER_PROPERTY_HEALTH_BONUS,
					MODIFIER_PROPERTY_MANA_BONUS,
					MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
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

function modifier_item_radiance_2_passive:GetModifierHealthBonus()
	return self.bonus_health
end

function modifier_item_radiance_2_passive:GetModifierManaBonus()
	return self.bonus_mana
end

function modifier_item_radiance_2_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_radiance_2_passive:IsAura()
	if not IsServer() then return end
	if self:GetCaster():IsOutOfGame() then return end
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