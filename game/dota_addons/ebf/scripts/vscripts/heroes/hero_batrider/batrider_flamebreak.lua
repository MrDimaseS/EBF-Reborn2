batrider_flamebreak = class({})
LinkLuaModifier("modifier_batrider_flamebreak_debuff", "heroes/hero_batrider/batrider_flamebreak", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_batrider_flamebreak_pit", "heroes/hero_batrider/batrider_flamebreak", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_batrider_flamebreak_pit_damage", "heroes/hero_batrider/batrider_flamebreak", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_batrider_flamebreak_status_resist", "heroes/hero_batrider/batrider_flamebreak", LUA_MODIFIER_MOTION_NONE)

function batrider_flamebreak:IsStealable()
    return true
end

function batrider_flamebreak:IsHiddenWhenStolen()
    return false
end

function batrider_flamebreak:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function batrider_flamebreak:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	
	self:TossCocktail(point)
end

function batrider_flamebreak:TossCocktail(vLocation)
	local caster = self:GetCaster()
	local point = vLocation

	local distance = CalculateDistance(point, caster:GetAbsOrigin())
	local speed = self:GetSpecialValueFor("speed")
	local time = distance / speed

	local radius = self:GetSpecialValueFor("explosion_radius")
	local damage_duration = self:GetSpecialValueFor("damage_duration")
	local knockback_duration = self:GetSpecialValueFor("knockback_duration")
	local knockback_distance = self:GetSpecialValueFor("knockback_distance")
	local napalm_stacks = self:GetSpecialValueFor("napalm_stacks")
	local stun_duration = self:GetSpecialValueFor("stun_duration")

	EmitSoundOn("Hero_Batrider.Flamebreak", caster)
	
	local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_batrider/batrider_flamebreak.vpcf", PATTACH_POINT, caster)
				ParticleManager:SetParticleControlEnt(nfx, 0, caster, PATTACH_POINT, "attach_hitloc", caster:GetAbsOrigin(), true)
				ParticleManager:SetParticleControl(nfx, 1, Vector(speed, 0, 0))
				ParticleManager:SetParticleControl(nfx, 3, point)
				ParticleManager:SetParticleControl(nfx, 4, point)
				ParticleManager:SetParticleControl(nfx, 5, point)
	
	
	self.napalm = caster:FindAbilityByName("batrider_sticky_napalm")
	Timers:CreateTimer(time, function()
		EmitSoundOnLocationWithCaster(point, "Hero_Batrider.Flamebreak.Impact", caster)

		ParticleManager:ClearParticle(nfx)

		local enemies = caster:FindEnemyUnitsInRadius(point, radius)
		for _,enemy in pairs(enemies) do
			if not enemy:TriggerSpellAbsorb(self) then
				enemy:ApplyKnockBack(point, stun_duration, knockback_duration, knockback_distance, knockback_height, caster, self, true)
				enemy:AddNewModifier(caster, self, "modifier_flamebreak_damage", {Duration = damage_duration})
				if self.napalm and self.napalm:IsTrained() then
					for i = 1, napalm_stacks do
						enemy:AddNewModifier(caster, self.napalm, "modifier_batrider_sticky_napalm_debuff", {Duration = self.napalm:GetSpecialValueFor("duration")})
					end
				end
			end
		end
	end)
end