vengefulspirit_nether_swap = class({})

function vengefulspirit_nether_swap:IsStealable()
	return true
end

function vengefulspirit_nether_swap:IsHiddenWhenStolen()
	return false
end

function vengefulspirit_nether_swap:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	EmitSoundOn("Hero_VengefulSpirit.NetherSwap", caster)

	local startPos = caster:GetAbsOrigin()
	local endPos = target:GetAbsOrigin()

	ParticleManager:FireRopeParticle("particles/units/heroes/hero_vengeful/vengeful_nether_swap.vpcf", PATTACH_POINT, caster, target, {})
	ParticleManager:FireRopeParticle("particles/units/heroes/hero_vengeful/vengeful_nether_swap_target.vpcf", PATTACH_POINT, target, caster, {})

	if target:GetTeam() ~= caster:GetTeam() then
		if not target:TriggerSpellAbsorb( self ) then
			FindClearSpaceForUnit(caster, endPos, true)
			caster:AddNewModifier(caster, self, "modifier_vengefulspirit_nether_swap", {Duration = self:GetSpecialValueFor("damage_reduction_duration")})
			FindClearSpaceForUnit(target, startPos, true)
			self:DealDamage( caster, target, self:GetSpecialValueFor("damage") )

		end
	else
		caster:AddNewModifier(caster, self, "modifier_vengefulspirit_nether_swap", {Duration = self:GetSpecialValueFor("damage_reduction_duration")})
		target:AddNewModifier(caster, self, "modifier_vengefulspirit_nether_swap", {Duration = self:GetSpecialValueFor("damage_reduction_duration")})
		FindClearSpaceForUnit(caster, endPos, true)
		FindClearSpaceForUnit(target, startPos, true)
	end

	caster:StartGesture(ACT_DOTA_CHANNEL_END_ABILITY_4)
end

modifier_vengefulspirit_nether_swap = class({})
LinkLuaModifier( "modifier_vengefulspirit_nether_swap", "heroes/hero_vengefulspirit/vengefulspirit_nether_swap.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_vengefulspirit_nether_swap:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
    }
    return funcs
end

function modifier_vengefulspirit_nether_swap:GetModifierIncomingDamage_Percentage()
    return -self:GetSpecialValueFor("damage_reduction")
end