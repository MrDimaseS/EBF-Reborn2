spirit_breaker_herd_mentality = class({})

function spirit_breaker_herd_mentality:GetIntrinsicModifierName()
	return "modifier_spirit_breaker_herd_mentality_innate"
end

modifier_spirit_breaker_herd_mentality_innate = class({})
LinkLuaModifier("modifier_spirit_breaker_herd_mentality_innate", "heroes/hero_spirit_breaker/spirit_breaker_herd_mentality", LUA_MODIFIER_MOTION_NONE)

function modifier_spirit_breaker_herd_mentality_innate:OnCreated()
	self:OnRefresh()
end

function modifier_spirit_breaker_herd_mentality_innate:OnRefresh()
	self.search_radius = self:GetSpecialValueFor("search_radius")
	self.damage_per_second = self:GetSpecialValueFor("damage_per_second")
	if IsServer() then
		self:StartIntervalThink( 0.25 )
	end
end

function modifier_spirit_breaker_herd_mentality_innate:OnIntervalThink()
	local caster = self:GetCaster()
	local count = #caster:FindFriendlyUnitsInRadius( caster:GetAbsOrigin(), self.search_radius, {type = DOTA_UNIT_TARGET_HERO} )
	self:SetStackCount( count )
end

function modifier_spirit_breaker_herd_mentality_innate:IsAura()
	return true
end

function modifier_spirit_breaker_herd_mentality_innate:GetModifierAura()
	return "modifier_spirit_breaker_herd_mentality_ms"
end

function modifier_spirit_breaker_herd_mentality_innate:GetAuraRadius()
	return self.search_radius
end

function modifier_spirit_breaker_herd_mentality_innate:GetAuraDuration()
	return 0.5
end

function modifier_spirit_breaker_herd_mentality_innate:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_spirit_breaker_herd_mentality_innate:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_HERO
end

function modifier_spirit_breaker_herd_mentality_innate:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_spirit_breaker_herd_mentality_innate:IsHidden()
	return true
end

modifier_spirit_breaker_herd_mentality_ms = class({})
LinkLuaModifier("modifier_spirit_breaker_herd_mentality_ms", "heroes/hero_spirit_breaker/spirit_breaker_herd_mentality", LUA_MODIFIER_MOTION_NONE)

function modifier_spirit_breaker_herd_mentality_ms:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink( 0.25 )
	end
end

function modifier_spirit_breaker_herd_mentality_ms:OnRefresh()
	self.bonus_ms_per_unit = self:GetSpecialValueFor("bonus_ms_per_unit")
end

function modifier_spirit_breaker_herd_mentality_ms:OnIntervalThink()
	local innate = self:GetCaster():FindModifierByName("modifier_spirit_breaker_herd_mentality_innate")
	if innate then
		self:SetStackCount( innate:GetStackCount() )
	end
end

function modifier_spirit_breaker_herd_mentality_ms:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end
function modifier_spirit_breaker_herd_mentality_ms:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_ms_per_unit * self:GetStackCount()
end

function modifier_spirit_breaker_herd_mentality_ms:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
		MODIFIER_PROPERTY_MOVESPEED_LIMIT
	}
end

function modifier_spirit_breaker_herd_mentality_ms:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_ms_per_unit * self:GetStackCount()
end

function modifier_spirit_breaker_herd_mentality_ms:GetModifierIgnoreMovespeedLimit()
	return 1
end

function modifier_spirit_breaker_herd_mentality_ms:GetModifierMoveSpeed_Limit()
	return 3500
end