tiny_toss = class({})

function tiny_toss:IsStealable()
    return true
end

function tiny_toss:IsHiddenWhenStolen()
    return false
end

function tiny_toss:GetBehavior()
	if self:GetSpecialValueFor("throw_tiny") == 1 then
		return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_AUTOCAST
	else
		return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE
	end
end

function tiny_toss:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function tiny_toss:OnSpellStart()
    local caster = self:GetCaster()
    local position = self:GetCursorPosition()
    local target = nil

	local duration = self:GetSpecialValueFor("duration")
	local grabRadius = self:GetSpecialValueFor("grab_radius")
	
    EmitSoundOn("Ability.TossThrow", caster)
	
	local enemies = caster:FindAllUnitsInRadius(caster:GetAbsOrigin(), grabRadius, {order = FIND_CLOSEST})
	for _,enemy in pairs(enemies) do
		if not enemy:HasModifier("modifier_tiny_toss") and not PlayerResource:IsDisableHelpSetForPlayerID( caster:GetPlayerOwnerID(), enemy:GetPlayerOwnerID() ) and enemy ~= caster then
			target = enemy
	  		break
	  	end
	end
	
	if self:GetSpecialValueFor("throw_tiny") == 1 and self:GetAutoCastState() and not caster:HasModifier("modifier_tiny_toss") then
		target = caster
	elseif target == nil then
		local dummy = caster:CreateDummy(caster:GetAbsOrigin(), duration+0.1)
		ParticleManager:FireParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_impale_burrow_soil.vpcf", PATTACH_POINT, dummy, {})
		dummy:SetForwardVector( CalculateDirection( position, caster ) )
		target = dummy
		dummy:SetOriginalModel("models/particle/cracked_boulder.vmdl")
		dummy:SetModel("models/particle/cracked_boulder.vmdl")
		dummy:SetModelScale(0.25)
	end
	
	if target then
		EmitSoundOn("Hero_Tiny.Toss.Target", target)
		local modifierKnockback = {
			x = position.x,
			y = position.y,
			z = position.z,
			should_stun = true,
			duration = duration,
			knockback_duration = duration,
			knockback_distance = CalculateDistance( target, position ),
			knockback_height = 160,
		}
		target:AddNewModifier(caster, self, "modifier_tiny_toss", modifierKnockback)
		
		caster:StartGesture( ACT_TINY_TOSS )
	end
end