windrunner_windrun = class({})

function windrunner_windrun:IsStealable()
	return true
end

function windrunner_windrun:IsHiddenWhenStolen()
	return false
end

function windrunner_windrun:GetManaCost( iLvl )
	if self:GetCaster():HasModifier("modifier_windrunner_windrun_aura") then
		return 0
	else
		return self.BaseClass.GetManaCost( self, iLvl )
	end
end

function windrunner_windrun:OnSpellStart()
    local caster = self:GetCaster()
	
	if caster:HasModifier("modifier_windrunner_windrun_aura") then
		caster:RemoveModifierByName("modifier_windrunner_windrun_aura")
		caster:RemoveModifierByName("modifier_windrunner_windrun_invis")
	else
		EmitSoundOn("Ability.Windrun", caster)
		
		local duration = self:GetSpecialValueFor("duration")
		caster:AddNewModifier(caster, self, "modifier_windrunner_windrun_aura", {Duration = duration})
		if caster:HasScepter() then caster:AddNewModifier(caster, self, "modifier_windrunner_windrun_invis", {Duration = duration}) end
		self:SetCooldown(0.5)
	end
    
end

modifier_windrunner_windrun_aura = class({})
LinkLuaModifier("modifier_windrunner_windrun_aura", "heroes/hero_windrunner/windrunner_windrun", LUA_MODIFIER_MOTION_NONE)

function modifier_windrunner_windrun_aura:OnCreated(table)
	self:OnRefresh()
end

function modifier_windrunner_windrun_aura:OnRefresh()
	self.radius = self:GetSpecialValueFor("radius")
end

function modifier_windrunner_windrun_aura:OnDestroy()
	if IsServer() then
		self:GetAbility():SetCooldown()
	end
end

function modifier_windrunner_windrun_aura:IsAura()
    return true
end

function modifier_windrunner_windrun_aura:GetAuraDuration()
    return 0.5
end

function modifier_windrunner_windrun_aura:GetAuraRadius()
    return self.radius
end

function modifier_windrunner_windrun_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_windrunner_windrun_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_windrunner_windrun_aura:GetModifierAura()
    return "modifier_windrunner_windrun_windrun"
end

function modifier_windrunner_windrun_aura:IsHidden()
    return false
end

modifier_windrunner_windrun_windrun = class({})
LinkLuaModifier("modifier_windrunner_windrun_windrun", "heroes/hero_windrunner/windrunner_windrun", LUA_MODIFIER_MOTION_NONE)
function modifier_windrunner_windrun_windrun:OnCreated(table)
	self:OnRefresh()
end

function modifier_windrunner_windrun_windrun:OnRefresh()
	self.movespeed = self:GetSpecialValueFor("movespeed_bonus_pct") 
	self.evasion_pct_tooltip = self:GetSpecialValueFor("evasion_pct_tooltip")
	self.physical_damage_pct = self:GetSpecialValueFor("physical_damage_pct")
end

function modifier_windrunner_windrun_windrun:CheckState()
    local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true}
    return state
end

function modifier_windrunner_windrun_windrun:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_EVASION_CONSTANT,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
    return funcs
end

function modifier_windrunner_windrun_windrun:GetModifierMoveSpeedBonus_Percentage()
    return self.movespeed
end

function modifier_windrunner_windrun_windrun:GetModifierEvasion_Constant()
    return self.evasion_pct_tooltip
end

function modifier_windrunner_windrun_windrun:GetModifierIncomingDamage_Percentage( params )
	if params.damage_type == DAMAGE_TYPE_PHYSICAL then
		return self.evasion_pct_tooltip
	end
end

function modifier_windrunner_windrun_windrun:GetEffectName()
    return "particles/units/heroes/hero_windrunner/windrunner_windrun.vpcf"
end