LinkLuaModifier( "modifier_item_ghost_form_ally", "items/item_ghost.lua" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_ghost_form_enemy", "items/item_ghost.lua" ,LUA_MODIFIER_MOTION_NONE )

item_veil_of_discord = class({})

function item_veil_of_discord:GetAOERadius()
	return self:GetSpecialValueFor("debuff_radius")
end

function item_veil_of_discord:GetIntrinsicModifierName()
	return "modifier_item_veil_of_discord_passive"
end

function item_veil_of_discord:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	
	local radius = self:GetSpecialValueFor("debuff_radius")
	local duration = self:GetSpecialValueFor("resist_debuff_duration")
	
	EmitSoundOn( "DOTA_Item.VeilofDiscord.Activate", self:GetCaster() )
	ParticleManager:FireParticle("particles/items2_fx/veil_of_discord.vpcf", PATTACH_WORLDORIGIN, nil, {[0] = point, [1] = Vector(radius,1,1)})
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( point, radius ) ) do
		enemy:AddNewModifier(caster, self, "modifier_item_veil_of_discord_spell_amp", {duration = duration})
	end
end

item_veil_of_discord2 = class(item_veil_of_discord)
item_veil_of_discord3 = class(item_veil_of_discord)
item_veil_of_discord4 = class(item_veil_of_discord)

function item_veil_of_discord4:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	
	local radius = self:GetSpecialValueFor("debuff_radius")
	local duration = self:GetSpecialValueFor("duration")
	local resist_debuff_duration = self:GetSpecialValueFor("resist_debuff_duration")
	local veil_to_allies = self:GetSpecialValueFor("veil_to_allies")
	
	for _, unit in ipairs( caster:FindAllUnitsInRadius( point, radius ) ) do
		if unit:IsSameTeam(caster) then
			unit:AddNewModifier(caster, self, "modifier_item_ghost_form_ally", {duration = duration})
			if veil_to_allies then
				unit:AddNewModifier(caster, self, "modifier_item_veil_of_discord_heal_amp", {duration = resist_debuff_duration})
			end
		else
			unit:AddNewModifier(caster, self, "modifier_item_ghost_form_enemy", {duration = duration})
			unit:AddNewModifier(caster, self, "modifier_item_veil_of_discord_spell_amp", {duration = resist_debuff_duration})
			
			self:DealDamage( caster, unit, caster:GetPrimaryStatValue() * self:GetSpecialValueFor("blast_agility_multiplier") + self:GetSpecialValueFor("blast_damage_base") )
		end
	end
	EmitSoundOn( "DOTA_Item.VeilofDiscord.Activate", caster )
	EmitSoundOnLocationWithCaster( point, "DOTA_Item.EtherealBlade.Activate", self:GetCaster() )
	
	ParticleManager:FireParticle("particles/items2_fx/ethereal_veil.vpcf", PATTACH_WORLDORIGIN, nil, {[0] = point, [1] = Vector(radius,1,1)})
end

item_veil_of_discord5 = class(item_veil_of_discord4)

modifier_item_veil_of_discord_passive = class({})
LinkLuaModifier( "modifier_item_veil_of_discord_passive", "items/item_veil.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_veil_of_discord_passive:OnCreated()
	self.bonus_all_stats = self:GetSpecialValueFor("bonus_all_stats")
	
	self.bonus_evasion = self:GetSpecialValueFor("bonus_evasion")
	self.spell_amp = self:GetSpecialValueFor("spell_amp")
	self.status_resistance = self:GetSpecialValueFor("status_resistance")
	self.regen_amp = self:GetSpecialValueFor("hp_regen_amp")
	
	self.aura_radius = self:GetSpecialValueFor("aura_radius")
end

function modifier_item_veil_of_discord_passive:DeclareFunctions()
	return {
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_EVASION_CONSTANT,
			MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
			MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE
	}
end

function modifier_item_veil_of_discord_passive:GetModifierBonusStats_Agility()
	return self.bonus_all_stats
end

function modifier_item_veil_of_discord_passive:GetModifierBonusStats_Strength()
	return self.bonus_all_stats
end

function modifier_item_veil_of_discord_passive:GetModifierBonusStats_Intellect()
	return self.bonus_all_stats
end

function modifier_item_veil_of_discord_passive:GetModifierSpellAmplify_Percentage()
	return self.spell_amp
end

function modifier_item_veil_of_discord_passive:GetModifierEvasion_Constant()
	return self.bonus_evasion
end

function modifier_item_veil_of_discord_passive:GetModifierStatusResistanceStacking()
	return self.status_resistance
end

function modifier_item_veil_of_discord_passive:GetModifierHealAmplify_PercentageSource()
	return self.regen_amp
end

function modifier_item_veil_of_discord_passive:GetModifierHPRegenAmplify_Percentage()
	return self.regen_amp
end

function modifier_item_veil_of_discord_passive:GetModifierLifestealRegenAmplify_Percentage()
	return self.regen_amp
end

function modifier_item_veil_of_discord_passive:GetModifierSpellLifestealRegenAmplify_Percentage()
	return self.regen_amp
end

function modifier_item_veil_of_discord_passive:GetModifierMPRegenAmplify_Percentage()
	return self.regen_amp
end

function modifier_item_veil_of_discord_passive:IsAura()
	return true
end

function modifier_item_veil_of_discord_passive:GetModifierAura()
	return "modifier_item_veil_of_discord_passive_basilius"
end

function modifier_item_veil_of_discord_passive:GetAuraRadius()
	return self.aura_radius
end

function modifier_item_veil_of_discord_passive:GetAuraDuration()
	return 0.5
end

function modifier_item_veil_of_discord_passive:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_veil_of_discord_passive:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_item_veil_of_discord_passive:IsHidden()
	return true
end

function modifier_item_veil_of_discord_passive:IsPurgable()
	return false
end

modifier_item_veil_of_discord_passive_basilius = class({})
LinkLuaModifier( "modifier_item_veil_of_discord_passive_basilius", "items/item_veil.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_veil_of_discord_passive_basilius:OnCreated()
	self.aura_mana_regen = self:GetSpecialValueFor("aura_mana_regen")
end

function modifier_item_veil_of_discord_passive_basilius:DeclareFunctions()
	return {MODIFIER_PROPERTY_MANA_REGEN_CONSTANT}
end

function modifier_item_veil_of_discord_passive_basilius:GetModifierConstantManaRegen()
	return self.aura_mana_regen
end

modifier_item_veil_of_discord_spell_amp = class({})
LinkLuaModifier( "modifier_item_veil_of_discord_spell_amp", "items/item_veil.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_veil_of_discord_spell_amp:OnCreated()
	self.debuff_spell_amp = self:GetSpecialValueFor("debuff_spell_amp")
end

function modifier_item_veil_of_discord_spell_amp:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE}
end

function modifier_item_veil_of_discord_spell_amp:GetModifierIncomingDamage_Percentage(params)
	if IsServer() then
		if params.damage_category == DOTA_DAMAGE_CATEGORY_SPELL then
			local dmgAmp = self.debuff_spell_amp * ( 1 / ( self:GetParent().EHP_MULT or 1) )
			return dmgAmp
		end
	else
		return self.debuff_spell_amp
	end
end

modifier_item_veil_of_discord_heal_amp = class({})
LinkLuaModifier( "modifier_item_veil_of_discord_heal_amp", "items/item_veil.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_veil_of_discord_heal_amp:OnCreated()
	self.debuff_spell_amp = self:GetSpecialValueFor("debuff_spell_amp")
end

function modifier_item_veil_of_discord_heal_amp:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE}
end

function modifier_item_veil_of_discord_heal_amp:GetModifierHealAmplify_PercentageSource(params)
	return self.debuff_spell_amp
end