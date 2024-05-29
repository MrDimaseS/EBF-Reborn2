hoodwink_acorn_shot = class({})

function hoodwink_acorn_shot:GetCastRange()
	return self:GetCaster():GetAttackRange() - self:GetCaster():GetCastRangeBonus() + self:GetSpecialValueFor("bonus_range")
end

function hoodwink_acorn_shot:ShouldUseResources()
	return true
end

function hoodwink_acorn_shot:Spawn()
	self.projectileData = self.projectileData or {}
end

function hoodwink_acorn_shot:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget() or self:GetCursorPosition()
	if self:GetAutoCastState() then -- force position target
		target = self:GetCursorPosition()
	end
	self:FireAcorn( target )
end

function hoodwink_acorn_shot:FireAcorn( target, iBounces )
	local caster = self:GetCaster()
	local bounces = iBounces or self:GetSpecialValueFor("bounce_count")
	
	self.projectileData = self.projectileData or {}
	local direction = CalculateDirection( target, caster )
	local distance = CalculateDistance( target, caster )
	local projIndex
	if target.GetAbsOrigin then
		projIndex = self:FireTrackingProjectile("particles/units/heroes/hero_hoodwink/hoodwink_acorn_shot_tracking.vpcf", target, self:GetSpecialValueFor("projectile_speed"), {source = caster}, DOTA_PROJECTILE_ATTACHMENT_ATTACK_1, true, true, 200)
	else
		projIndex = self:FireLinearProjectile("particles/units/heroes/hero_hoodwink/hoodwink_acorn_shot_initial.vpcf", direction * self:GetSpecialValueFor("projectile_speed"), distance, 0, {source = caster})
	end
	self.projectileData[projIndex] = {}
	self.projectileData[projIndex].isGroundTargeted = target.GetAbsOrigin == nil
	self.projectileData[projIndex].bounces = bounces
end

function hoodwink_acorn_shot:OnProjectileHitHandle( target, position, projectile )
	local data = self.projectileData[projectile]
	local caster = self:GetCaster()
	if data.isGroundTargeted and target then return end
	if not data.isGroundTargeted and not target then return end
	if data then
		if data.isGroundTargeted then
			local treePos = position + CalculateDirection( position, caster ) * 250
			local dummy = caster:CreateDummy( position, 15 )
			dummy:AddNewModifier( caster, self, "hoodwink_acorn_shot_dummy", {} )
			AddFOWViewer( caster:GetTeam(), position, 200, 15, false )
			CreateTempTree( position, 15 )
			ResolveNPCPositions( position, 128 )
			target = dummy
		elseif not target:TriggerSpellAbsorb( self ) then
			caster:AddNewModifier( caster, self, "modifier_hoodwink_acorn_shot_damage", {} )
			self.processingAcornBounce = true
			caster:PerformGenericAttack( target, true )
			self.processingAcornBounce = false
			caster:RemoveModifierByName( "modifier_hoodwink_acorn_shot_damage" )
			
			target:AddNewModifier( caster, self, "modifier_hoodwink_acorn_shot_slow", { duration = self:GetSpecialValueFor("debuff_duration")} )
			EmitSoundOn( "Hero_Hoodwink.AcornShot.Slow", target )
		end
		
		EmitSoundOn( "Hero_Hoodwink.AcornShot.Target", target )
		
		local can_bounce_off_of_trees = self:GetSpecialValueFor("can_bounce_off_of_trees")
		if self.projectileData[projectile].bounces > 0 then
			for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( position, self:GetCastRange() ) ) do
				if enemy ~= target then
					EmitSoundOn( "Hero_Hoodwink.AcornShot.Bounce", caster )
					local projIndex = self:FireTrackingProjectile("particles/units/heroes/hero_hoodwink/hoodwink_acorn_shot_tracking.vpcf", enemy, self:GetSpecialValueFor("projectile_speed"), {source = target}, DOTA_PROJECTILE_ATTACHMENT_ATTACK_1, true, true, 200)
					self.projectileData[projIndex] = {}
					self.projectileData[projIndex].isGroundTargeted = false
					self.projectileData[projIndex].bounces = self.projectileData[projectile].bounces - 1
					self.projectileData[projectile] = nil
					return
				end
			end
			if not data.isGroundTargeted and can_bounce_off_of_trees then
				local newPos = position + RandomVector( self:GetSpecialValueFor("bonus_range") )
				local direction = CalculateDirection( newPos, position )
				local distance = CalculateDistance( newPos, position )
				projIndex = self:FireLinearProjectile("particles/units/heroes/hero_hoodwink/hoodwink_acorn_shot_initial.vpcf", direction * self:GetSpecialValueFor("projectile_speed"), distance, 0, {source = target, origin = target:GetAbsOrigin()})
				
				self.projectileData[projIndex] = {}
				self.projectileData[projIndex].isGroundTargeted = true
				self.projectileData[projIndex].bounces = self.projectileData[projectile].bounces - 1
				self.projectileData[projectile] = nil
			end
		end
	end
end

hoodwink_acorn_shot_dummy = class({})
LinkLuaModifier("hoodwink_acorn_shot_dummy", "heroes/hero_hoodwink/hoodwink_acorn_shot", LUA_MODIFIER_MOTION_NONE)

function hoodwink_acorn_shot_dummy:GetEffectName()
	return "particles/units/heroes/hero_hoodwink/hoodwink_acorn_shot_tree.vpcf"
end