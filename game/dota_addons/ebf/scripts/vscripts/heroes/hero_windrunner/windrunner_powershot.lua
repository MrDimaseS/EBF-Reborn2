windrunner_powershot = class({})

function windrunner_powershot:IsStealable()
	return true
end

function windrunner_powershot:IsHiddenWhenStolen()
	return false
end

function windrunner_powershot:OnSpellStart()
	self.current_power = FrameTime() / self:GetChannelTime()
	
	self:GetCaster():StartGesture( ACT_DOTA_OVERRIDE_ABILITY_2 )
end

function windrunner_powershot:OnChannelThink( dt )
	self.current_power = math.min( 1, self.current_power + dt / self:GetChannelTime() )
end

function windrunner_powershot:OnChannelFinish( bInterrupt )
	self:LaunchPowerShot( self:GetCursorPosition() )
end

function windrunner_powershot:LaunchPowerShot(target)
	local caster = self:GetCaster()
	local pos = self:GetCursorPosition()
	local direction = CalculateDirection( pos, caster:GetAbsOrigin() )
	
	EmitSoundOn("Ability.Powershot", caster)
	
	local projectile = self:FireLinearProjectile("particles/units/heroes/hero_windrunner/windrunner_spell_powershot.vpcf", CalculateDirection( target, caster ) * self:GetSpecialValueFor("arrow_speed"), self:GetTrueCastRange(), self:GetSpecialValueFor("arrow_width"), {}, false, true, self:GetSpecialValueFor("vision_radius"))
	self.projectiles = self.projectiles or {}
	self.projectiles[projectile] = { power = self.current_power * 100, origin = caster:GetAbsOrigin() }
end

function windrunner_powershot:OnProjectileHitHandle(target, position, projectile)
	if target and not target:TriggerSpellAbsorb( self ) then
		local caster = self:GetCaster()
		local power = self.projectiles[projectile].power / 100
		EmitSoundOn("Ability.PowershotDamage", target)
		target:AddNewModifier( caster, self, "modifier_windrunner_powershot_on_hit_effect", {duration = self:GetSpecialValueFor("slow_duration")} ):SetStackCount( self.projectiles[projectile].power )
		self:DealDamage( caster, target, self:GetSpecialValueFor("powershot_damage") * power, {}, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE )
		
		local maxHPThreshold = self:GetSpecialValueFor("max_execute_threshold")
		if maxHPThreshold > 0 then
			local minHPThreshold = self:GetSpecialValueFor("min_execute_threshold")
			local hpThreshold = minHPThreshold + ( maxHPThreshold - minHPThreshold ) * power * target:GetMaxHealthDamageResistance()
			if target:GetHealthPercent() <= hpThreshold then
				target:AttemptKill(self, caster)
			end
		end
		if target:IsConsideredHero() then
			local reduction = 1 - self:GetSpecialValueFor("damage_reduction") / 100
			self.projectiles[projectile].power = math.floor( self.projectiles[projectile].power * reduction )
			return self.projectiles[projectile].power <= 0
		end
	end
end

function windrunner_powershot:OnProjectileThink(vLocation)
	GridNav:DestroyTreesAroundPoint(vLocation, self:GetSpecialValueFor("arrow_width"), true)
end

modifier_windrunner_powershot_on_hit_effect = class({})
LinkLuaModifier("modifier_windrunner_powershot_on_hit_effect", "heroes/hero_windrunner/windrunner_powershot", LUA_MODIFIER_MOTION_NONE)

function modifier_windrunner_powershot_on_hit_effect:OnCreated()
	self:OnRefresh()
end

function modifier_windrunner_powershot_on_hit_effect:OnRefresh()
	self.slow = self:GetSpecialValueFor("slow")
end

function modifier_windrunner_powershot_on_hit_effect:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_windrunner_powershot_on_hit_effect:GetModifierMoveSpeedBonus_Percentage()
	return -self.slow * self:GetStackCount() / 100
end