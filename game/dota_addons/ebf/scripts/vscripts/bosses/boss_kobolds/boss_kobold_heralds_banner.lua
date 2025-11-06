boss_kobold_heralds_banner = class({})

function boss_kobold_heralds_banner:OnSpellStart()
	local caster = self:GetCaster()
	local position = self:GetCursorPosition()
	
	local banner = CreateUnitByName( "npc_dota_unit_roshans_banner", position, true, nil, nil, caster:GetTeam() )
	banner:SetCoreHealth( self:GetSpecialValueFor("health_per_hero") * HeroList:GetActiveHeroCount() )
	banner:AddNewModifier( caster, self, "modifier_kill", {duration = self:GetSpecialValueFor("duration")} )
	banner:AddNewModifier( caster, self, "modifier_boss_kobold_heralds_banner", {duration = self:GetSpecialValueFor("duration")} )
end

modifier_boss_kobold_heralds_banner = class({})
LinkLuaModifier( "modifier_boss_kobold_heralds_banner", "bosses/boss_kobolds/boss_kobold_heralds_banner", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_kobold_heralds_banner:IsAura()
	return true
end

function modifier_boss_kobold_heralds_banner:GetModifierAura()
	return "modifier_boss_kobold_heralds_banner_aura"
end

function modifier_boss_kobold_heralds_banner:GetAuraRadius()
	return 9999
end

function modifier_boss_kobold_heralds_banner:GetAuraDuration()
	return 0.5
end

function modifier_boss_kobold_heralds_banner:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_boss_kobold_heralds_banner:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

modifier_boss_kobold_heralds_banner_aura = class({})
LinkLuaModifier( "modifier_boss_kobold_heralds_banner_aura", "bosses/boss_kobolds/boss_kobold_heralds_banner", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_kobold_heralds_banner_aura:OnCreated()
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
	self.bonus_magic_resist = self:GetSpecialValueFor("bonus_magic_resist")
end

function modifier_boss_kobold_heralds_banner_aura:DeclareFunctions()
	return {MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }
end

function modifier_boss_kobold_heralds_banner_aura:GetModifierDamageOutgoing_Percentage()
	return self.bonus_damage
end

function modifier_boss_kobold_heralds_banner_aura:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_boss_kobold_heralds_banner_aura:GetModifierMagicalResistanceBonus()
	return self.bonus_magic_resist
end