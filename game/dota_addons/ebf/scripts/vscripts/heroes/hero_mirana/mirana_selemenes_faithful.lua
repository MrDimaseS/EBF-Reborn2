mirana_selemenes_faithful = class({})

function mirana_selemenes_faithful:GetIntrinsicModifierName()
    return "modifier_mirana_selemenes_faithful_handler"
end

function mirana_selemenes_faithful:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_PASSIVE
end

modifier_mirana_selemenes_faithful_handler = class({})
LinkLuaModifier( "modifier_mirana_selemenes_faithful_handler", "heroes/hero_mirana/mirana_selemenes_faithful.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_mirana_selemenes_faithful_handler:OnCreated()
	self:OnRefresh()
end

function modifier_mirana_selemenes_faithful_handler:OnRefresh()
	self.bonus_duration = self:GetSpecialValueFor("bonus_duration")
	self.bonus_aoe = self:GetSpecialValueFor("bonus_aoe")
end

function modifier_mirana_selemenes_faithful_handler:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST 
    }
    return funcs
end

function modifier_mirana_selemenes_faithful_handler:OnAbilityFullyCast(params)
    if params.unit == self:GetCaster() then
		self:AddIndependentStack( self.bonus_duration )
		self:SetDuration( self.bonus_duration, true )
	end
end

function modifier_mirana_selemenes_faithful_handler:IsAura()
	return true
end

function modifier_mirana_selemenes_faithful_handler:GetModifierAura()
	return "modifier_mirana_selemenes_faithful_buff"
end

function modifier_mirana_selemenes_faithful_handler:GetAuraRadius()
	return self.bonus_aoe
end

function modifier_mirana_selemenes_faithful_handler:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_mirana_selemenes_faithful_handler:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_HERO
end

function modifier_mirana_selemenes_faithful_handler:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_mirana_selemenes_faithful_handler:GetAuraDuration()
	return 0.5
end

function modifier_mirana_selemenes_faithful_handler:IsHidden()
    return true
end

function modifier_mirana_selemenes_faithful_handler:DestroyOnExpire()
    return false
end

function modifier_mirana_selemenes_faithful_handler:IsPurgable()
    return false
end

function modifier_mirana_selemenes_faithful_handler:IsPermanent()
    return true
end

modifier_mirana_selemenes_faithful_buff = class({})
LinkLuaModifier( "modifier_mirana_selemenes_faithful_buff", "heroes/hero_mirana/mirana_selemenes_faithful.lua" ,LUA_MODIFIER_MOTION_NONE )
function modifier_mirana_selemenes_faithful_buff:OnCreated()
	self:OnRefresh()
end

function modifier_mirana_selemenes_faithful_buff:OnRefresh()
	self.bonus_stats = self:GetSpecialValueFor("bonus_stats") / 100
	self.bonus_attackspeed = self:GetSpecialValueFor("bonus_attackspeed") / 100
	if IsServer() then
		self._parentModifier = self:GetCaster():FindModifierByName("modifier_mirana_selemenes_faithful_handler")
		self:OnIntervalThink()
		self:StartIntervalThink( 0.1 )
	end
end

function modifier_mirana_selemenes_faithful_buff:OnIntervalThink()
	if not IsModifierSafe( self._parentModifier ) then
		self._parentModifier = self:GetCaster():FindModifierByName("modifier_mirana_selemenes_faithful_handler")
	end
	if self._parentModifier and self:GetStackCount() ~= self._parentModifier:GetStackCount() then
		self:SetStackCount( self._parentModifier:GetStackCount() )
		self:GetParent():CalculateStatBonus( true )
	end
end

function modifier_mirana_selemenes_faithful_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    }
end

function modifier_mirana_selemenes_faithful_buff:GetModifierBonusStats_Strength(params)
	if self._lockedStr then return end
	self._lockedStr = true
	local str = self:GetCaster():GetStrength()
	self._lockedStr = false
    return math.ceil(self.bonus_stats * str * self:GetStackCount())
end

function modifier_mirana_selemenes_faithful_buff:GetModifierBonusStats_Agility(params)
	if self._lockedAgi then return end
	self._lockedAgi = true
	local agi = self:GetCaster():GetAgility()
	self._lockedAgi = false
    return math.ceil(self.bonus_stats * agi * self:GetStackCount())
end

function modifier_mirana_selemenes_faithful_buff:GetModifierBonusStats_Intellect(params)
	if self._lockedInt then return end
	self._lockedInt = true
	local int = self:GetCaster():GetIntellect(false)
	self._lockedInt = false
    return math.ceil(self.bonus_stats * int * self:GetStackCount())
end

function modifier_mirana_selemenes_faithful_buff:GetModifierAttackSpeedBonus_Constant(params)
    return math.ceil(self.bonus_attackspeed * self:GetCaster():GetBaseAttackSpeed() * self:GetStackCount())
end

function modifier_mirana_selemenes_faithful_buff:IsHidden()
    return self:GetStackCount() <= 0
end