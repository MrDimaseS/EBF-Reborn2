nyx_assassin_nyxth_sense = class({})

function nyx_assassin_nyxth_sense:GetIntrinsicModifierName()
	return "modifier_nyx_assassin_nyxth_sense_handler"
end

modifier_nyx_assassin_nyxth_sense_handler = class({})
LinkLuaModifier( "modifier_nyx_assassin_nyxth_sense_handler", "heroes/hero_nyx_assassin/nyx_assassin_nyxth_sense.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_nyx_assassin_nyxth_sense_handler:OnCreated()
	self.radius = self:GetSpecialValueFor("radius")
	self.linger_duration = self:GetSpecialValueFor("linger_duration")
	self.damage_amp = self:GetSpecialValueFor("damage_amp")
	self.bonus_evasion = self:GetSpecialValueFor("bonus_evasion")
	self.bonus_magic_resist = self:GetSpecialValueFor("bonus_magic_resist")
	self.current_mana_drain = self:GetSpecialValueFor("current_mana_drain")
	if IsServer() then
		self:StartIntervalThink( 0.33 )
	end
end

function modifier_nyx_assassin_nyxth_sense_handler:OnIntervalThink()
	AddFOWViewer( self:GetParent():GetTeamNumber(), self:GetParent():GetAbsOrigin(), self:GetParent():GetCurrentVisionRange(), self.linger_duration, false )
end

function modifier_nyx_assassin_nyxth_sense_handler:DeclareFunctions()
	return {MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
			MODIFIER_PROPERTY_EVASION_CONSTANT,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_EVENT_ON_TAKEDAMAGE,
			MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL }
end

function modifier_nyx_assassin_nyxth_sense_handler:GetModifierTotalDamageOutgoing_Percentage( params )
	if self.damage_amp == 0 then return end
	if not params.target:HasModifier("modifier_nyx_assassin_nyxth_sense_effect") then return end
	return self.damage_amp
end

function modifier_nyx_assassin_nyxth_sense_handler:GetModifierEvasion_Constant( params )
	if IsClient() then return end
	if self.bonus_evasion == 0 then return end
	if not params.attacker:HasModifier("modifier_nyx_assassin_nyxth_sense_effect") then return end
	return self.bonus_evasion
end

function modifier_nyx_assassin_nyxth_sense_handler:GetModifierMagicalResistanceBonus( params )
	if IsClient() then return end
	if not self.activateMagicResistEffect then return end
	self.activateMagicResistEffect = false
	return self.bonus_magic_resist
end

function modifier_nyx_assassin_nyxth_sense_handler:OnTakeDamage( params )
	if self.current_mana_drain == 0 then return end
	if not params.unit:HasModifier("modifier_nyx_assassin_nyxth_sense_effect") then return end
	if params.target == self:GetParent() then return end
	local drain = params.unit:GetMana() * self.current_mana_drain / 100
	params.unit:ReduceMana( drain, self:GetAbility() )
	params.attacker:GiveMana( drain )
end

function modifier_nyx_assassin_nyxth_sense_handler:GetAbsoluteNoDamageMagical( params )
	if self.bonus_magic_resist == 0 then return end
	if not params.attacker:HasModifier("modifier_nyx_assassin_nyxth_sense_effect") then return end
	self.activateMagicResistEffect = true
end

function modifier_nyx_assassin_nyxth_sense_handler:IsAura()
	return true
end

function modifier_nyx_assassin_nyxth_sense_handler:GetModifierAura()
	return "modifier_nyx_assassin_nyxth_sense_effect"
end

function modifier_nyx_assassin_nyxth_sense_handler:GetAuraRadius()
	return self.radius
end

function modifier_nyx_assassin_nyxth_sense_handler:GetAuraDuration()
	return 0.5
end

function modifier_nyx_assassin_nyxth_sense_handler:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_nyx_assassin_nyxth_sense_handler:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_nyx_assassin_nyxth_sense_handler:IsHidden()    
	return true
end

modifier_nyx_assassin_nyxth_sense_effect = class({})
LinkLuaModifier( "modifier_nyx_assassin_nyxth_sense_effect", "heroes/hero_nyx_assassin/nyx_assassin_nyxth_sense.lua", LUA_MODIFIER_MOTION_NONE )