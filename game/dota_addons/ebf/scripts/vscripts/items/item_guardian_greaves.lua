item_guardian_greaves = class({})

function item_guardian_greaves:GetIntrinsicModifierName()
	return "modifier_guardian_greaves_passive"
end

function item_guardian_greaves:OnSpellStart()
	local caster = self:GetCaster()
	
	local radius = self:GetSpecialValueFor("replenish_radius")
	local heal = self:GetSpecialValueFor("replenish_health") + self:GetSpecialValueFor("hp_per_charge") * self:GetCurrentCharges()
	local mana = self:GetSpecialValueFor("replenish_mana") + self:GetSpecialValueFor("mp_per_charge") * self:GetCurrentCharges()
	
	for _, unit in ipairs( caster:FindFriendlyUnitsInRadius( caster:GetAbsOrigin(), radius ) ) do
		unit:HealEvent( heal, self, caster )
		unit:GiveMana( mana )
		
		ParticleManager:FireParticle( "particles/items2_fx/mekanism_recipient.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
		ParticleManager:FireParticle( "particles/items_fx/arcane_boots_recipient.vpcf", PATTACH_POINT_FOLLOW, caster )
		EmitSoundOn( "Item.GuardianGreaves.Target", unit )
	end
	caster:Dispel( caster, false )
	if self:GetSpecialValueFor("magic_immunity") == 1 then
		caster:AddNewModifier( caster, self, "modifier_black_king_bar_immune", {duration = self:GetSpecialValueFor("duration")} )
	end
	self:SetCurrentCharges( 0 )
	
	ParticleManager:FireParticle( "particles/items_fx/arcane_boots.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:FireParticle( "particles/items2_fx/mekanism.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	EmitSoundOn( "Item.GuardianGreaves.Activate", caster )
end

item_guardian_greaves_2 = class(item_guardian_greaves)
item_guardian_greaves_3 = class(item_guardian_greaves)
item_guardian_greaves_4 = class(item_guardian_greaves)
item_guardian_greaves_5 = class(item_guardian_greaves)

modifier_guardian_greaves_passive = class({})
LinkLuaModifier( "modifier_guardian_greaves_passive", "items/item_guardian_greaves.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_guardian_greaves_passive:OnCreated()
	self:OnRefresh()
end

function modifier_guardian_greaves_passive:OnRefresh()
	self.bonus_movement = self:GetSpecialValueFor("bonus_movement")
	self.bonus_health = self:GetSpecialValueFor("bonus_health")
	self.bonus_mana = self:GetSpecialValueFor("bonus_mana")
	self.mana_regen = self:GetSpecialValueFor("mana_regen")
	self.bonus_all_stats = self:GetSpecialValueFor("bonus_all_stats")
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
	self.heal_increase = self:GetSpecialValueFor("heal_increase")
	
	self.max_charges = self:GetSpecialValueFor("max_charges")
	self.charge_gain_timer = self:GetSpecialValueFor("charge_gain_timer")
	
	self.aura_radius = self:GetSpecialValueFor("aura_radius")
	
	if IsServer() and self.charge_gain_timer > 0 then
		self:StartIntervalThink( self.charge_gain_timer )
	end
end

function modifier_guardian_greaves_passive:OnIntervalThink()
	local currentCharges = self:GetAbility():GetCurrentCharges()
	if currentCharges == self.max_charges then
		return
	else
		self:GetAbility():SetCurrentCharges( currentCharges + 1 )
	end
end

function modifier_guardian_greaves_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE,
			MODIFIER_PROPERTY_HEALTH_BONUS,
			MODIFIER_PROPERTY_MANA_BONUS,
			MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
			MODIFIER_EVENT_ON_ABILITY_FULLY_CAST
			}
end

function modifier_guardian_greaves_passive:OnAbilityFullyCast( params )
	if not params.unit:IsSameTeam( self:GetParent() ) and CalculateDistance( params.unit, self:GetParent() ) < self.aura_radius then
		self:OnIntervalThink()
	end
end

function modifier_guardian_greaves_passive:GetModifierMoveSpeedBonus_Special_Boots()
	return self.bonus_movement
end

function modifier_guardian_greaves_passive:GetModifierHealthBonus()
	return self.bonus_health
end

function modifier_guardian_greaves_passive:GetModifierConstantManaRegen()
	return self.mana_regen
end


function modifier_guardian_greaves_passive:GetModifierManaBonus()
	return self.bonus_mana
end

function modifier_guardian_greaves_passive:GetModifierBonusStats_Strength()
	return self.bonus_all_stats
end

function modifier_guardian_greaves_passive:GetModifierBonusStats_Agility()
	return self.bonus_all_stats
end

function modifier_guardian_greaves_passive:GetModifierBonusStats_Intellect()
	return self.bonus_all_stats
end

function modifier_guardian_greaves_passive:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_guardian_greaves_passive:GetModifierHealAmplify_PercentageSource()
	return self.heal_increase
end

function modifier_guardian_greaves_passive:IsAura()
	return true
end

function modifier_guardian_greaves_passive:GetModifierAura()
	return "modifier_guardian_greaves_regen"
end

function modifier_guardian_greaves_passive:GetAuraRadius()
	return self.aura_radius
end

function modifier_guardian_greaves_passive:GetAuraDuration()
	return 0.5
end

function modifier_guardian_greaves_passive:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_guardian_greaves_passive:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_guardian_greaves_passive:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_guardian_greaves_passive:IsHidden()
	return true
end

function modifier_guardian_greaves_passive:IsPurgable()
	return false
end

function modifier_guardian_greaves_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

modifier_guardian_greaves_regen = class({})
LinkLuaModifier( "modifier_guardian_greaves_regen", "items/item_guardian_greaves.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_guardian_greaves_regen:OnCreated()
	self.aura_health_regen = self:GetSpecialValueFor("aura_health_regen")
	self.aura_mana_regen = self:GetSpecialValueFor("aura_mana_regen")
	self.aura_armor = self:GetSpecialValueFor("aura_armor")
	self.aura_health_regen_bonus = self:GetSpecialValueFor("aura_health_regen_bonus")
	self.aura_mana_regen_bonus = self:GetSpecialValueFor("aura_mana_regen_bonus")
	self.aura_armor_bonus = self:GetSpecialValueFor("aura_armor_bonus")
	self.aura_bonus_threshold = self:GetSpecialValueFor("aura_bonus_threshold")
end


function modifier_guardian_greaves_regen:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
			MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS}
end

function modifier_guardian_greaves_regen:GetModifierConstantHealthRegen()
	return TernaryOperator( self.aura_health_regen_bonus, self:GetParent():GetHealthPercent() < self.aura_bonus_threshold, self.aura_health_regen )
end

function modifier_guardian_greaves_regen:GetModifierConstantManaRegen()
	return TernaryOperator( self.aura_mana_regen_bonus, self:GetParent():GetHealthPercent() < self.aura_bonus_threshold, self.aura_mana_regen )
end

function modifier_guardian_greaves_regen:GetModifierPhysicalArmorBonus()
	return TernaryOperator( self.aura_armor_bonus, self:GetParent():GetHealthPercent() < self.aura_bonus_threshold, self.aura_armor )
end