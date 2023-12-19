item_assault = class({})

function item_assault:GetIntrinsicModifierName()
	return "modifier_item_assault_cuirass_passive"
end

item_cuirass_2 = class(item_assault)
item_cuirass_3 = class(item_assault)

function item_cuirass_3:OnSpellStart()
	local caster = self:GetCaster()
	
	local unitsToHit = {}
	local currentRadius = 150
	local endRadius = self:GetSpecialValueFor("blast_radius")
	local blastSpeed = self:GetSpecialValueFor("blast_speed")
	
	local radiusStep = blastSpeed * 0.1
	
	local damage = self:GetSpecialValueFor("blast_damage")
	local duration = self:GetSpecialValueFor("blast_debuff_duration")
	local amp_duration = self:GetSpecialValueFor("resist_debuff_duration")
	local bkb_duration = self:GetSpecialValueFor("duration")
	local magic_resist = self:GetSpecialValueFor("magic_resist")
	local affects_allies = tonumber(self:GetSpecialValueFor("affects_allies")) == 1
	
	EmitSoundOn( "DOTA_Item.ShivasGuard.Activate", caster )
	
	local particleFX = TernaryOperator( "particles/econ/events/ti10/shivas_guard_ti10_active.vpcf", affects_allies, "particles/items2_fx/shivas_guard_active.vpcf" )
	if magic_resist > 0 then
		caster:AddNewModifier( caster, self, "modifier_black_king_bar_immune", {duration = bkb_duration} )
	end
	
	ParticleManager:FireParticle( particleFX, PATTACH_POINT_FOLLOW, caster, {[1] = Vector( endRadius, endRadius / blastSpeed , blastSpeed )})
	Timers:CreateTimer( function()
		for _, unit in ipairs( caster:FindAllUnitsInRadius( caster:GetAbsOrigin(), currentRadius ) ) do
			if not unitsToHit[unit:entindex()] and unit ~= caster then
				if not unit:IsSameTeam( caster ) then
					local damage = self:DealDamage( caster, unit, damage, {damage_type = DAMAGE_TYPE_MAGICAL} )
					unit:AddNewModifier( caster, self, "modifier_item_shivas_guard_blast", {duration = duration} )
					unit:AddNewModifier( caster, self, "modifier_item_veil_of_discord_debuff", {duration = amp_duration} )
					ParticleManager:FireParticle( "particles/items2_fx/shivas_guard_impact.vpcf", PATTACH_POINT_FOLLOW, unit )	
				elseif affects_allies then
					unit:AddNewModifier( caster, self, "modifier_black_king_bar_immune", {duration = bkb_duration} )
					ParticleManager:FireParticle( "particles/items2_fx/shivas_guard_impact.vpcf", PATTACH_POINT_FOLLOW, unit )	
				end
				unitsToHit[unit:entindex()] = true
			end
		end
		if currentRadius < endRadius then
			currentRadius = currentRadius + radiusStep
			return 0.1
		end
	end)
end

item_cuirass_4 = class(item_cuirass_3)
item_cuirass_5 = class(item_cuirass_3)
item_asura_plate = class(item_cuirass_3)

modifier_item_assault_cuirass_passive = class({})
LinkLuaModifier( "modifier_item_assault_cuirass_passive", "items/item_cuirass.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_assault_cuirass_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_assault_cuirass_passive:OnRefresh()
	self.health_regen = self:GetSpecialValueFor("health_regen")
	self.bonus_all = self:GetSpecialValueFor("bonus_all")
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
	self.bonus_attackspeed = self:GetSpecialValueFor("bonus_attackspeed")
	
	self.radius = self:GetSpecialValueFor("radius")
	
	self.bonus_armor_pr = self:GetSpecialValueFor("bonus_armor_pr")
	
	if self.bonus_armor_pr > 0 and IsServer() then
		self:StartIntervalThink(0.25)
	end
end

function modifier_item_assault_cuirass_passive:OnIntervalThink()
	local stack = GameRules._roundnumber
	if stack ~= self:GetStackCount() then
		self:SetStackCount( stack )
	end
end

function modifier_item_assault_cuirass_passive:DeclareFunctions()
	return {
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function modifier_item_assault_cuirass_passive:GetModifierBonusStats_Strength()
	return self.bonus_all
end

function modifier_item_assault_cuirass_passive:GetModifierBonusStats_Intellect()
	return self.bonus_all
end

function modifier_item_assault_cuirass_passive:GetModifierBonusStats_Agility()
	return self.bonus_all
end

function modifier_item_assault_cuirass_passive:GetModifierPhysicalArmorBonus()
	return self.bonus_armor + self:GetStackCount() * self.bonus_armor_pr
end

function modifier_item_assault_cuirass_passive:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attackspeed
end

function modifier_item_assault_cuirass_passive:GetModifierConstantHealthRegen()
	return self.health_regen
end

function modifier_item_assault_cuirass_passive:IsAura()
	if not IsServer() then return end
	if self.radius == 0 then return end
	return self:GetCaster() and not self:GetCaster():IsNull() and self:GetCaster():IsAlive()
end

function modifier_item_assault_cuirass_passive:GetModifierAura()
	return "modifier_item_assault_cuirass_aura"
end

function modifier_item_assault_cuirass_passive:GetAuraRadius()
	return self.radius
end

function modifier_item_assault_cuirass_passive:GetAuraDuration()
	return 0.5
end

function modifier_item_assault_cuirass_passive:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_item_assault_cuirass_passive:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_item_assault_cuirass_passive:IsHidden()
	return true
end

function modifier_item_assault_cuirass_passive:IsPurgable()
	return false
end

function modifier_item_assault_cuirass_passive:DestroyOnExpire()
	return false
end

function modifier_item_assault_cuirass_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

modifier_item_assault_cuirass_aura = class({})
LinkLuaModifier( "modifier_item_assault_cuirass_aura", "items/item_cuirass.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_assault_cuirass_aura:OnCreated()
	if self:GetCaster():IsSameTeam( self:GetParent() ) then
		self.bonus_attackspeed_aura = self:GetSpecialValueFor("bonus_attackspeed_aura")
		self.bonus_armor_aura = self:GetSpecialValueFor("bonus_armor_aura")
		self.health_regen_aura = self:GetSpecialValueFor("health_regen_aura")
	else
		self.bonus_armor_aura = self:GetSpecialValueFor("bonus_armor_debuff")
		self.bonus_attackspeed_aura = self:GetSpecialValueFor("bonus_attackspeed_debuff")
		self.bonus_hp_regen_debuff = self:GetSpecialValueFor("bonus_hp_regen_debuff")
	end
end

function modifier_item_assault_cuirass_aura:DeclareFunctions()
    return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
             MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
			 MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			 MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
			 MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
			 MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
		}
end

function modifier_item_assault_cuirass_aura:GetModifierConstantHealthRegen()
	return self.health_regen_aura
end

function modifier_item_assault_cuirass_aura:GetModifierPhysicalArmorBonus()
	return self.bonus_armor_aura
end

function modifier_item_assault_cuirass_aura:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attackspeed_aura
end

function modifier_item_assault_cuirass_aura:GetModifierHealAmplify_PercentageSource()
	return self.bonus_hp_regen_debuff
end

function modifier_item_assault_cuirass_aura:GetModifierHPRegenAmplify_Percentage()
	return self.bonus_hp_regen_debuff
end

function modifier_item_assault_cuirass_aura:GetModifierLifestealRegenAmplify_Percentage()
	return self.bonus_hp_regen_debuff
end