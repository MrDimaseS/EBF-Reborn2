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
    local targets = {}

	local duration = self:GetSpecialValueFor("duration")
	local grabRadius = self:GetSpecialValueFor("grab_radius")
	local unitsGrabbed = self:GetSpecialValueFor("units_grabbed")
	
    EmitSoundOn("Ability.TossThrow", caster)
	if self:GetSpecialValueFor("throw_tiny") == 1 and self:GetAutoCastState() and not caster:HasModifier("modifier_tiny_toss") then
		table.insert( targets, caster )
	else
		local enemies = caster:FindAllUnitsInRadius(caster:GetAbsOrigin(), grabRadius, {order = FIND_CLOSEST})
		for _,enemy in pairs(enemies) do
			if not enemy:HasModifier("modifier_tiny_toss") and not PlayerResource:IsDisableHelpSetForPlayerID( enemy:GetPlayerOwnerID(), caster:GetPlayerOwnerID() ) and enemy ~= caster then
				table.insert( targets, enemy )
				if unitsGrabbed > 0 then
					unitsGrabbed = unitsGrabbed - 1
					if unitsGrabbed <= 0 then
						break
					end
				end
			end
		end
	end
	if #targets == 0 then
		local dummy = caster:CreateDummy(caster:GetAbsOrigin(), duration+0.1)
		ParticleManager:FireParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_impale_burrow_soil.vpcf", PATTACH_POINT, dummy, {})
		dummy:SetForwardVector( CalculateDirection( position, caster ) )
		table.insert( targets, dummy )
		dummy:SetOriginalModel("models/particle/cracked_boulder.vmdl")
		dummy:SetModel("models/particle/cracked_boulder.vmdl")
		dummy:SetModelScale(0.25)
	end
	
	if #targets > 0 then
		caster:StartGesture( ACT_TINY_TOSS )
		for _, target in ipairs( targets ) do
			EmitSoundOn("Hero_Tiny.Toss.Target", target)
			local modifierKnockback = {
				x = position.x,
				y = position.y,
				z = position.z,
				should_stun = true,
				duration = duration,
				ignoreStatusResist = true,
				knockback_duration = duration,
				knockback_distance = CalculateDistance( target, position ),
				knockback_height = 160,
			}
			target:AddNewModifier( caster, self, "modifier_tiny_toss", modifierKnockback )
		end
	end
end