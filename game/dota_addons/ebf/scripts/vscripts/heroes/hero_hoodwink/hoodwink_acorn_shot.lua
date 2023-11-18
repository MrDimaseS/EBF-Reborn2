hoodwink_acorn_shot = class({})

function hoodwink_acorn_shot:GetCastRange()
	return self:GetCaster():GetAttackRange() - self:GetCaster():GetCastRangeBonus() + self:GetSpecialValueFor("bonus_range")
end

function hoodwink_acorn_shot:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	self.projectileData = self.projectileData or {}
	self:FireAcorn( target )
	
	EmitSoundOn( "Hero_Hoodwink.AcornShot.Cast", caster )
end

function hoodwink_acorn_shot:FireAcorn( target, iBounces )
	local caster = self:GetCaster()
	local bounces = iBounces or self:GetSpecialValueFor("bounce_count")
	if not target.GetAbsOrigin then -- vector
		local direction = CalculateDirection( target, caster )
		local distance = CalculateDistance( target, caster )
		local projIndex = self:FireLinearProjectile("particles/units/heroes/hero_hoodwink/hoodwink_acorn_shot_initial.vpcf", self:GetSpecialValueFor("projectile_speed") * direction, distance, 100, {}, DOTA_PROJECTILE_ATTACHMENT_ATTACK_1, true, true, 200)
		self.projectileData[projIndex] = {}
		self.projectileData[projIndex].isTracking = false
		self.projectileData[projIndex].bounces = bounces
	end
end

function hoodwink_acorn_shot:OnProjectileHitHandle( target, position, projectile )
	local data = self.projectileData[projectile]
	local caster = self:GetCaster()
	if data then
		if target then
			caster:PerformGenericAttack(target, true, self:GetSpecialValueFor("bonus_damage"))
			target:AddNewModifier( caster, self, "modifier_hoodwink_acorn_shot_slow", { duration = self:GetSpecialValueFor("debuff_duration")} )
			EmitSoundOn( "Hero_Hoodwink.AcornShot.Target", target )
			EmitSoundOn( "Hero_Hoodwink.AcornShot.Slow", target )
			
			if self.projectileData[projectile].bounces > 0 then
				for _, enemy in ipairs( caster:FindEnemyUnitsInRadius(position, self:GetSpecialValueFor("bounce_range")) ) do
					if enemy ~= target then
						EmitSoundOn( "Hero_Hoodwink.AcornShot.Bounce", caster )
						local projIndex = self:FireTrackingProjectile("particles/units/heroes/hero_hoodwink/hoodwink_acorn_shot_tracking.vpcf", enemy, self:GetSpecialValueFor("projectile_speed"), {source = target}, DOTA_PROJECTILE_ATTACHMENT_ATTACK_1, true, true, 200)
						self.projectileData[projIndex] = {}
						self.projectileData[projIndex].isTracking = true
						self.projectileData[projIndex].bounces = self.projectileData[projectile].bounces - 1
						self.projectileData[projectile] = nil
						break
					end
				end
			end
		end
		if not data.isTracking then -- initial target
			local dummy = caster:CreateDummy( position, 20 )
			dummy:AddNewModifier( caster, self, "hoodwink_acorn_shot_dummy", {} )
			AddFOWViewer( caster:GetTeam(), position, 200, 20, false )
			CreateTempTree( position, 20 )
			ResolveNPCPositions( position, 128 )
		end
	end
end

hoodwink_acorn_shot_dummy = class({})
LinkLuaModifier("hoodwink_acorn_shot_dummy", "heroes/hero_hoodwink/hoodwink_acorn_shot", LUA_MODIFIER_MOTION_NONE)

function hoodwink_acorn_shot_dummy:GetEffectName()
	return "particles/units/heroes/hero_hoodwink/hoodwink_acorn_shot_tree.vpcf"
end