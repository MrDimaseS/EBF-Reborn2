boss_troll_warlord_meteor_strike = class({})

function boss_troll_warlord_meteor_strike:OnAbilityPhaseStart()
	ParticleManager:FireWarningParticle( self.pos, self:GetSpecialValueFor("radius"))
	return true
end

function boss_troll_warlord_meteor_strike:OnSpellStart()
	local caster = self:GetCaster()
	EmitSoundOn("Ability.Leap", caster)
	caster:AddNewModifier( caster, self, "modifier_boss_troll_warlord_meteor_strike_movement", {duration = self:GetSpecialValueFor("leap_duration") + 0.5})
end

modifier_boss_troll_warlord_meteor_strike_movement = class({})
LinkLuaModifier("modifier_boss_troll_warlord_meteor_strike_movement", "bosses/boss_troll_warlord/boss_troll_warlord_meteor_strike", LUA_MODIFIER_MOTION_NONE)

if IsServer() then
	function modifier_boss_troll_warlord_meteor_strike_movement:OnCreated()
		local parent = self:GetParent()
		self.endPos = self:GetAbility():GetCursorPosition()
		self.distance = CalculateDistance( self.endPos, parent )
		self.direction = CalculateDirection( self.endPos, parent )
		self.speed = ( self.distance / self:GetSpecialValueFor("leap_duration") ) * FrameTime()
		self.initHeight = GetGroundHeight(parent:GetAbsOrigin(), parent)
		self.height = self.initHeight
		self.maxHeight = 350
		self:StartMotionController()
	end
	
	
	function modifier_boss_troll_warlord_meteor_strike_movement:OnDestroy()
		local parent = self:GetParent()

		FindClearSpaceForUnit(parent, parent:GetAbsOrigin(), true)
		if parent:IsFrozen() then return end
		self:StopMotionController()
	end
	
	function modifier_boss_troll_warlord_meteor_strike_movement:DoControlledMotion()
		if not IsModifierSafe( self ) then return end
		local parent = self:GetParent()
		if not IsEntitySafe( parent ) then return end
		self.distanceTraveled =  self.distanceTraveled or 0
		if parent:IsAlive() and self.distanceTraveled < self.distance and not parent:IsFrozen() then
			local newPos = GetGroundPosition(parent:GetAbsOrigin(), parent) + self.direction * self.speed
			newPos.z = self.height + self.maxHeight * math.sin( (self.distanceTraveled/self.distance) * math.pi )
			parent:SetAbsOrigin( newPos )
			
			self.distanceTraveled = self.distanceTraveled + self.speed
		else
			local ability = self:GetAbility()
			local radius = self:GetSpecialValueFor("radius")
			
			ParticleManager:FireParticle("particles/units/heroes/hero_centaur/centaur_warstomp.vpcf", PATTACH_ABSORIGIN, parent, {[1] = Vector(radius, 1, 1)})
			local critBuff = parent:AddNewModifier( parent, ability, "modifier_boss_troll_warlord_meteor_strike_crit", {} )
			for _, enemy in ipairs( parent:FindEnemyUnitsInRadius( parent:GetAbsOrigin(), radius ) ) do
				parent:PerformGenericAttack( enemy, true, {ability = ability, neverMiss = true} )
			end
			critBuff:Destroy()
			EmitSoundOn("Ability.TossImpact", parent)
			self:Destroy()
			return nil
		end       
		
	end
end

function modifier_boss_troll_warlord_meteor_strike_movement:GetEffectName()
	return "particles/units/heroes/hero_tiny/tiny_toss_blur.vpcf"
end

function modifier_boss_troll_warlord_meteor_strike_movement:CheckState()
	return {[MODIFIER_STATE_STUNNED] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true}
end

function modifier_boss_troll_warlord_meteor_strike_movement:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}
end

function modifier_boss_troll_warlord_meteor_strike_movement:GetOverrideAnimation()
	return ACT_DOTA_CAST_ABILITY_3
end

modifier_boss_troll_warlord_meteor_strike_crit = class({})
LinkLuaModifier("modifier_boss_troll_warlord_meteor_strike_crit", "bosses/boss_troll_warlord/boss_troll_warlord_meteor_strike", LUA_MODIFIER_MOTION_NONE)

function modifier_boss_troll_warlord_meteor_strike_crit:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE }
end

function modifier_boss_troll_warlord_meteor_strike_crit:GetModifierPreAttack_CriticalStrike()
	return self:GetSpecialValueFor("crit_damage")
end