item_signet_of_destiny = class({})

function item_signet_of_destiny:GetIntrinsicModifierName()
	return "modifier_signet_of_destiny_passive"
end

function item_signet_of_destiny:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	local burst = self:GetSpecialValueFor("hp_per_charge") * self:GetCurrentCharges()
	local mana = self:GetSpecialValueFor("mp_per_charge") * self:GetCurrentCharges()
	local duration = self:GetSpecialValueFor("duration")
	if caster:IsSameTeam( target ) then
		target:AddNewModifier( caster, self, "modifier_signet_of_destiny_buff", {duration = duration} )
		local heal = target:HealEvent( burst, self, caster )
		target:GiveMana( mana )
	else
		target:AddNewModifier( caster, self, "modifier_signet_of_destiny_debuff", {duration = duration} )
		local damage = self:DealDamage( caster, target, burst )
		target:ReduceMana( mana )
	end
	
	ParticleManager:FireRopeParticle("particles/items2_fx/holy_locket_cast.vpcf", PATTACH_POINT_FOLLOW, caster, target )
	ParticleManager:FireRopeParticle("particles/items4_fx/spirit_vessel_cast.vpcf", PATTACH_POINT_FOLLOW, caster, target )
	EmitSoundOn("DOTA_Item.MagicWand.Activate", caster )
	EmitSoundOn("DOTA_Item.SpiritVessel.Cast", caster )
	EmitSoundOn("DOTA_Item.Dagon5.Target", target )
	
	self:SetCurrentCharges( 0 )
end

item_signet_of_destiny_2 = class(item_signet_of_destiny)
item_signet_of_destiny_3 = class(item_signet_of_destiny)
item_signet_of_destiny_4 = class(item_signet_of_destiny)
item_signet_of_destiny_5 = class(item_signet_of_destiny)

modifier_signet_of_destiny_buff = class({})
LinkLuaModifier( "modifier_signet_of_destiny_buff", "items/item_signet_of_destiny.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_signet_of_destiny_buff:OnCreated()
	self:OnRefresh()
	if IsServer() then
		if  self:GetCaster():IsSameTeam( self:GetParent() ) then
			EmitSoundOn( "DOTA_Item.SpiritVessel.Target.Ally", self:GetParent() )
		else
			EmitSoundOn( "DOTA_Item.SpiritVessel.Target.Enemy", self:GetParent() )
		end
	end
end

function modifier_signet_of_destiny_buff:OnRefresh()
	self.soul_damage_amount = self:GetSpecialValueFor("soul_damage_amount")
	self.hp_regen_reduction_enemy = self:GetSpecialValueFor("hp_regen_reduction_enemy")
	self.enemy_hp_drain = self:GetSpecialValueFor("enemy_hp_drain") / 100
	if IsServer() then
		self:StartIntervalThink( 1 )
	end
end

function modifier_signet_of_destiny_buff:OnDestroy()
	if IsServer() then
		StopSoundOn( "DOTA_Item.SpiritVessel.Target.Ally", self:GetParent() )
		StopSoundOn( "DOTA_Item.SpiritVessel.Target.Enemy", self:GetParent() )
	end
end

function modifier_signet_of_destiny_buff:OnIntervalThink()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local parent = self:GetParent()
	
	parent:HealEvent( self.soul_damage_amount + self.enemy_hp_drain * parent:GetHealthDeficit(), ability, caster )
end

function modifier_signet_of_destiny_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
			MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE}
end

function modifier_signet_of_destiny_buff:GetModifierHealAmplify_PercentageTarget( )
	return -self.hp_regen_reduction_enemy
end

function modifier_signet_of_destiny_buff:GetModifierHPRegenAmplify_Percentage( )
	return -self.hp_regen_reduction_enemy
end

function modifier_signet_of_destiny_buff:GetModifierLifestealRegenAmplify_Percentage( )
	return -self.hp_regen_reduction_enemy
end

function modifier_signet_of_destiny_buff:GetModifierSpellLifestealRegenAmplify_Percentage( )
	return -self.hp_regen_reduction_enemy
end

function modifier_signet_of_destiny_buff:GetEffectName()
	return "particles/items4_fx/spirit_vessel_heal.vpcf"
end

modifier_signet_of_destiny_debuff = class(modifier_signet_of_destiny_buff)
LinkLuaModifier( "modifier_signet_of_destiny_debuff", "items/item_signet_of_destiny.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_signet_of_destiny_debuff:OnIntervalThink()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local parent = self:GetParent()
	
	ability:DealDamage( caster, parent, self.soul_damage_amount )
	ability:DealDamage( caster, parent, self.enemy_hp_drain * parent:GetHealth(), {damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS } )
end

function modifier_signet_of_destiny_debuff:GetModifierHealAmplify_PercentageTarget( )
	return self.hp_regen_reduction_enemy
end

function modifier_signet_of_destiny_debuff:GetModifierHPRegenAmplify_Percentage( )
	return self.hp_regen_reduction_enemy
end

function modifier_signet_of_destiny_debuff:GetModifierLifestealRegenAmplify_Percentage( )
	return self.hp_regen_reduction_enemy
end

function modifier_signet_of_destiny_debuff:GetModifierSpellLifestealRegenAmplify_Percentage( )
	return self.hp_regen_reduction_enemy
end

function modifier_signet_of_destiny_debuff:GetEffectName()
	return "particles/items4_fx/spirit_vessel_damage.vpcf"
end

modifier_signet_of_destiny_passive = class({})
LinkLuaModifier( "modifier_signet_of_destiny_passive", "items/item_signet_of_destiny.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_signet_of_destiny_passive:OnCreated()
	self:OnRefresh()
end

function modifier_signet_of_destiny_passive:OnRefresh()
	self.bonus_intellect = self:GetSpecialValueFor("bonus_intellect")
	self.bonus_other = self:GetSpecialValueFor("bonus_other")
	self.bonus_health = self:GetSpecialValueFor("bonus_health")
	self.bonus_mana = self:GetSpecialValueFor("bonus_mana")
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.bonus_mana_regen = self:GetSpecialValueFor("bonus_mana_regen")
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
	self.heal_increase = self:GetSpecialValueFor("heal_increase")
	self.spell_amp = self:GetSpecialValueFor("spell_amp")
	
	self.max_charges = self:GetSpecialValueFor("max_charges")
	self.charge_gain_timer = self:GetSpecialValueFor("charge_gain_timer")
	self.charge_gain_kill = self:GetSpecialValueFor("charge_gain_kill")
	self.charge_gain_hero = self:GetSpecialValueFor("charge_gain_hero")
	
	self.charge_radius = self:GetSpecialValueFor("charge_radius")
	
	if IsServer() and self.charge_gain_timer > 0 then
		self:StartIntervalThink( self.charge_gain_timer )
	end
end

function modifier_signet_of_destiny_passive:OnIntervalThink()
	local currentCharges = self:GetAbility():GetCurrentCharges()
	if currentCharges == self.max_charges then
		return
	else
		self:GetAbility():SetCurrentCharges( currentCharges + 1 )
	end
end

function modifier_signet_of_destiny_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_HEALTH_BONUS,
			MODIFIER_PROPERTY_MANA_BONUS,
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
			MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
			MODIFIER_EVENT_ON_ABILITY_FULLY_CAST
			}
end

function modifier_signet_of_destiny_passive:OnAbilityFullyCast( params )
	if not params.unit:IsSameTeam( self:GetParent() ) and CalculateDistance( params.unit, self:GetParent() ) < self.charge_radius then
		self:OnIntervalThink()
	end
end

function modifier_signet_of_destiny_passive:GetModifierHealthBonus()
	return self.bonus_health
end

function modifier_signet_of_destiny_passive:GetModifierManaBonus()
	return self.bonus_mana
end

function modifier_signet_of_destiny_passive:GetModifierBonusStats_Strength()
	return self.bonus_other
end

function modifier_signet_of_destiny_passive:GetModifierBonusStats_Agility()
	return self.bonus_other
end

function modifier_signet_of_destiny_passive:GetModifierBonusStats_Intellect()
	return self.bonus_intellect
end

function modifier_signet_of_destiny_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_signet_of_destiny_passive:GetModifierConstantManaRegen()
	return self.bonus_mana_regen
end

function modifier_signet_of_destiny_passive:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_signet_of_destiny_passive:GetModifierHealAmplify_PercentageSource()
	return self.heal_increase
end

function modifier_signet_of_destiny_passive:GetModifierSpellAmplify_Percentage()
	return self.spell_amp
end

function modifier_signet_of_destiny_passive:GetModifierSpellLifestealRegenAmplify_Percentage()
	return self.spell_amp
end

function modifier_signet_of_destiny_passive:GetModifierMPRegenAmplify_Percentage()
	return self.spell_amp
end

function modifier_signet_of_destiny_passive:IsHidden()
	return true
end

function modifier_signet_of_destiny_passive:IsPurgable()
	return false
end

function modifier_signet_of_destiny_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end