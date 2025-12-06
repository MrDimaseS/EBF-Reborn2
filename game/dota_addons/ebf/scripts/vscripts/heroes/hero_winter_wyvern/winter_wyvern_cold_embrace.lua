winter_wyvern_cold_embrace = class({})

function winter_wyvern_cold_embrace:GetAbilityTargetTeam()
    if self:GetSpecialValueFor("damage") > 0 then
        return DOTA_UNIT_TARGET_TEAM_BOTH
    else
        return DOTA_UNIT_TARGET_TEAM_FRIENDLY
    end
end

function winter_wyvern_cold_embrace:CastFilterResultTarget(target)
    if self:GetSpecialValueFor("stuns") == 0 then
		return UF_SUCCESS
	elseif target:HasModifier("modifier_winter_wyvern_cold_embrace_effect") then
		return UF_FAIL_CUSTOM
    end
	return UnitFilter( target, self:GetAbilityTargetTeam(), DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, self:GetCaster():GetTeamNumber() )
end

function winter_wyvern_cold_embrace:GetCustomCastErrorTarget(target)
    return "Already in a Cold Embrace"
end

function winter_wyvern_cold_embrace:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
	
	self:ColdEmbrace( target )
    EmitSoundOn("Hero_Winter_Wyvern.ColdEmbrace.Cast", caster)
end

function winter_wyvern_cold_embrace:ColdEmbrace( target, duration )
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
	
	local fDur = duration or TernaryOperator( self:GetSpecialValueFor("duration"), target:GetTeam() == caster:GetTeam(), self:GetSpecialValueFor("enemy_duration") )
	target:AddNewModifierStacking(caster, self, "modifier_winter_wyvern_cold_embrace_effect", {duration = fDur})
end

modifier_winter_wyvern_cold_embrace_effect = class({})
LinkLuaModifier("modifier_winter_wyvern_cold_embrace_effect", "heroes/hero_winter_wyvern/winter_wyvern_cold_embrace", LUA_MODIFIER_MOTION_NONE)

function modifier_winter_wyvern_cold_embrace_effect:IsPurgable()
    return false
end

function modifier_winter_wyvern_cold_embrace_effect:IsBuff()
    return true
end

function modifier_winter_wyvern_cold_embrace_effect:OnCreated()
    self:OnRefresh()
    EmitSoundOn("Hero_Winter_Wyvern.ColdEmbrace", self:GetParent())
end

function modifier_winter_wyvern_cold_embrace_effect:OnRefresh()
    self.stuns = self:GetSpecialValueFor("stuns") == 1 or not self:GetParent():IsSameTeam( self:GetCaster() )
    self.damage_immunity = self:GetParent():IsSameTeam( self:GetCaster() )

    self.heal_interval = self:GetSpecialValueFor("heal_interval")
    self.heal_additive = self:GetSpecialValueFor("heal_additive")
    self.heal_percentage = self:GetSpecialValueFor("heal_percentage") / 100
    self.damage = self:GetSpecialValueFor("damage") / 100
    self.splits = self:GetSpecialValueFor("splits") == 1

    if IsServer() then self:StartIntervalThink(self.heal_interval) end
end

function modifier_winter_wyvern_cold_embrace_effect:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

	local maxHealthValue = parent:GetMaxHealth() * self.heal_percentage
	if parent:GetTeam() == caster:GetTeam() then
		parent:HealEvent( ( maxHealthValue + self.heal_additive ) * self.heal_interval, ability, caster)
	elseif self.damage > 0 then
		ability:DealDamage(caster, parent, ( maxHealthValue * parent:GetMaxHealthDamageResistance() + self.heal_additive * caster:GetSpellAmplification( false ) ) * self.heal_interval, {damage_type = DAMAGE_TYPE_MAGICAL, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION } )
	end
end

function modifier_winter_wyvern_cold_embrace_effect:OnDestroy()
	if IsClient() then return end
	if not self.splits then return end
	local caster = self:GetCaster()
	local splinterBlast = caster:FindAbilityByName("winter_wyvern_splinter_blast")
	if splinterBlast and splinterBlast:IsTrained() then
		caster:SetCursorCastTarget( parent )
		splinterBlast:OnSpellStart()
	end
end

function modifier_winter_wyvern_cold_embrace_effect:CheckState()
	local state = {[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true}
	if self.stuns then
		state[MODIFIER_STATE_STUNNED] = self.stuns
		state[MODIFIER_STATE_FROZEN] = self.stuns
		state[MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE] = self.stuns
	end
	if self.damage_immunity then
		state[MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL] = self.damage_immunity
	end
    return state
end

function modifier_winter_wyvern_cold_embrace_effect:GetEffectName()
    return "particles/units/heroes/hero_winter_wyvern/wyvern_cold_embrace_buff.vpcf"
end
