abyssal_underlord_raid_boss = class({})

function abyssal_underlord_raid_boss:GetIntrinsicModifierName()
	return "modifier_abyssal_underlord_raid_boss_innate"
end

modifier_abyssal_underlord_raid_boss_innate = class({})
LinkLuaModifier("modifier_abyssal_underlord_raid_boss_innate", "heroes/hero_underlord/abyssal_underlord_raid_boss", LUA_MODIFIER_MOTION_NONE)

function modifier_abyssal_underlord_raid_boss_innate:IsAura()
	return true
end

function modifier_abyssal_underlord_raid_boss_innate:GetModifierAura()
	return "modifier_abyssal_underlord_raid_boss_effect"
end

function modifier_abyssal_underlord_raid_boss_innate:GetAuraRadius()
	return 9999
end

function modifier_abyssal_underlord_raid_boss_innate:GetAuraDuration()
	return 0.5
end

function modifier_abyssal_underlord_raid_boss_innate:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_abyssal_underlord_raid_boss_innate:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_abyssal_underlord_raid_boss_innate:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_abyssal_underlord_raid_boss_innate:IsHidden()
	return true
end

function modifier_abyssal_underlord_raid_boss_innate:IsPurgable()
	return false
end

modifier_abyssal_underlord_raid_boss_effect = class({})
LinkLuaModifier("modifier_abyssal_underlord_raid_boss_effect", "heroes/hero_underlord/abyssal_underlord_raid_boss", LUA_MODIFIER_MOTION_NONE)

function modifier_abyssal_underlord_raid_boss_effect:OnCreated()
	self.damage_reduction = self:GetSpecialValueFor("damage_reduction")
	self.bonus_ms = self:GetSpecialValueFor("bonus_ms")
	self.dark_portal_multiplier = self:GetSpecialValueFor("dark_portal_multiplier")
	self.buff_duration = self:GetSpecialValueFor("buff_duration")
	
	if IsServer() then
		self._lastKnownPosition = self:GetParent():GetAbsOrigin()
		self:StartIntervalThink( 0 )
	end
end

function modifier_abyssal_underlord_raid_boss_effect:OnIntervalThink()
	local lastPos = self._lastKnownPosition
	self._lastKnownPosition = self:GetParent():GetAbsOrigin()
	if CalculateDistance( lastPos, self._lastKnownPosition ) > 50 then
		self:GetParent():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_abyssal_underlord_raid_boss_teleport", {duration = self.buff_duration} )
	end
end

function modifier_abyssal_underlord_raid_boss_effect:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_abyssal_underlord_raid_boss_effect:GetModifierIncomingDamage_Percentage()
	if self:GetParent():HasModifier("modifier_abyssal_underlord_raid_boss_teleport") then
		return self.damage_reduction * self.dark_portal_multiplier
	elseif self:GetParent():IsMoving() then
		return self.damage_reduction
	end
end

function modifier_abyssal_underlord_raid_boss_effect:GetModifierMoveSpeedBonus_Percentage()
	if self:GetParent():HasModifier("modifier_abyssal_underlord_raid_boss_teleport") then
		return self.bonus_ms * self.dark_portal_multiplier
	elseif self:GetParent():IsMoving() then
		return self.bonus_ms
	end
end

function modifier_abyssal_underlord_raid_boss_effect:IsHidden()
	return not self:GetParent():IsMoving()
end

modifier_abyssal_underlord_raid_boss_teleport = class({})
LinkLuaModifier("modifier_abyssal_underlord_raid_boss_teleport", "heroes/hero_underlord/abyssal_underlord_raid_boss", LUA_MODIFIER_MOTION_NONE)