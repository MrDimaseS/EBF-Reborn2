void_spirit_aether_remnant = class({})

function void_spirit_aether_remnant:IsVectorTargeting()
	return true
end

function void_spirit_aether_remnant:GetVectorTargetRange()
	return self:GetSpecialValueFor("remnant_watch_distance")
end

function void_spirit_aether_remnant:GetVectorTargetStartRadius()
	return self:GetSpecialValueFor("remnant_watch_radius") / 2
end

function void_spirit_aether_remnant:OnVectorCastStart()
	local caster = self:GetCaster()
	
	local velocity = self:GetSpecialValueFor("projectile_speed") * CalculateDirection( self:GetVectorPosition(), caster )
	local vision = self:GetSpecialValueFor("watch_path_vision_radius")
	local distance = CalculateDistance( self:GetVectorPosition(), caster )
	EmitSoundOn( "Hero_VoidSpirit.AetherRemnant.Cast", caster )
	local projectile = self:FireLinearProjectile("particles/units/heroes/hero_void_spirit/aether_remnant/void_spirit_aether_remnant_run.vpcf", velocity, distance, 0, {}, false, true, vision)
	
	self.projectiles = self.projectiles or {}
	self.projectiles[projectile] = {projectileReference = 0}
	
	
	local crossWatch = self:GetSpecialValueFor("aether_remnant_cross_watch") == 1
	if crossWatch then
		for i = 1, 3 do
			Timers:CreateTimer( 0.1*i, function()
				local newDirection = RotateVector2D( self:GetVectorDirection(), ToRadians( i*90 ) )
				local newPos = (self:GetVectorPosition() - self:GetVectorDirection() * 50) + newDirection * 50
				local newDist = CalculateDistance( newPos, caster )
				local newVel = self:GetSpecialValueFor("projectile_speed") * CalculateDirection(newPos, caster )
				local crossProj = self:FireLinearProjectile("particles/units/heroes/hero_void_spirit/aether_remnant/void_spirit_aether_remnant_run.vpcf", newVel, newDist, 0, {}, false, true, vision)
				self.projectiles[crossProj] = {projectileReference = i}
			end)
		end
	end
end

function void_spirit_aether_remnant:OnProjectileHitHandle( target, position, projectile )
	if not target then
		self:CreateAetherRemnant( position, RotateVector2D( self:GetVectorDirection(), ToRadians( self.projectiles[projectile].projectileReference * 90 ) ) )
	end
end

function void_spirit_aether_remnant:CreateAetherRemnant( position, direction )
	local caster = self:GetCaster()
	
	local duration = self:GetSpecialValueFor("duration")
	return CreateModifierThinker( caster, self, "modifier_void_spirit_aether_remnant_watch", {duration = duration, x = direction.x, y = direction.y}, GetGroundPosition( position, caster ), caster:GetTeam(), true )
end

modifier_void_spirit_aether_remnant_watch = class({})
LinkLuaModifier( "modifier_void_spirit_aether_remnant_watch", "heroes/hero_void_spirit/void_spirit_aether_remnant", LUA_MODIFIER_MOTION_NONE )

function modifier_void_spirit_aether_remnant_watch:OnCreated(kv)
	if IsServer() then
		local ability = self:GetAbility()
		local position = self:GetParent():GetAbsOrigin()
		local caster = self:GetCaster()
		
		self.duration = self:GetSpecialValueFor("pull_duration")
		self.vision = self:GetSpecialValueFor("watch_path_vision_radius")
		self.direction = Vector( kv.x, kv.y, 0 )
		self.range = ability:GetVectorTargetRange()
		self.width = ability:GetVectorTargetStartRadius()
		self.affectedUnits = {}
		
		self:CreateWatcher( position )
		
		EmitSoundOn( "Hero_VoidSpirit.AetherRemnant", self:GetParent() )
		EmitSoundOn( "Hero_VoidSpirit.AetherRemnant.Spawn_lp", self:GetParent() )
		
		self:StartIntervalThink(0.1)
		
		-- talents
		self.aether_remnant_dissimilate = self:GetSpecialValueFor("aether_remnant_dissimilate") == 1
		self.aether_remnant_reset_time = self:GetSpecialValueFor("aether_remnant_reset_time")
	end
end

function modifier_void_spirit_aether_remnant_watch:OnDestroy()
	if IsServer() then
		local parent = self:GetParent()
		EmitSoundOn( "Hero_VoidSpirit.AetherRemnant.Destroy", parent )
		StopSoundOn( "Hero_VoidSpirit.AetherRemnant.Spawn_lp", parent )
		ParticleManager:ClearParticle( self.currFX )
		
		if self.aether_remnant_dissimilate then
			local dissimilate = self:GetCaster():FindAbilityByName("void_spirit_dissimilate")
			if dissimilate and dissimilate:IsTrained() then
				dissimilate:PhaseIn( parent:GetAbsOrigin() + self.direction * 150, parent, false )
			end
		end
	end
end

function modifier_void_spirit_aether_remnant_watch:OnIntervalThink()
	local parent = self:GetParent()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local startPos = parent:GetAbsOrigin()
	
	AddFOWViewer( parent:GetTeamNumber(), startPos, self.vision, 0.1, true ) 
	AddFOWViewer( parent:GetTeamNumber(), startPos + self.direction * self.range/2, self.vision, 0.1, true ) 
	AddFOWViewer( parent:GetTeamNumber(), startPos + self.direction * self.range, self.vision, 0.1, true )
	
	local units = parent:FindEnemyUnitsInLine( startPos, startPos + self.direction * self.range, self.width )
	local affectedUnits = 0
	for _, unit in ipairs( units ) do
		if not self.affectedUnits[unit:entindex()] or ( self.aether_remnant_reset_time > 0 and self.affectedUnits[unit:entindex()] <= GameRules:GetGameTime() ) then
			unit._aetherRemnantPosition = startPos + self.direction * 150
			unit:AddNewModifier( caster, ability, "modifier_void_spirit_aether_remnant_watched", {duration = self.duration} )
			self.affectedUnits[unit:entindex()] = GameRules:GetGameTime() + self.aether_remnant_reset_time
		end
		if unit:HasModifier("modifier_void_spirit_aether_remnant_watched") then
			affectedUnits = affectedUnits + 1
		end
	end
	if affectedUnits > 0 then
		if not self._isPulling then
			self:ClearPreviousState()
			self:CreatePuller( startPos )
			EmitSoundOn( "Hero_VoidSpirit.AetherRemnant.Target", parent )
		end
	elseif self._isPulling then
		self:ClearPreviousState()
		self:CreateWatcher( startPos )
	end
end

function modifier_void_spirit_aether_remnant_watch:ClearPreviousState()
	ParticleManager:ClearParticle( self.currFX )
	self._isPulling = false
end

function modifier_void_spirit_aether_remnant_watch:CreateWatcher( position )
	local caster = self:GetCaster()
	local parent = self:GetParent()
	
	self.currFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_void_spirit/aether_remnant/void_spirit_aether_remnant_watch.vpcf", PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( self.currFX, 0, position )
	ParticleManager:SetParticleControl( self.currFX, 1, parent:GetAbsOrigin() + self.direction * self.range )
	ParticleManager:SetParticleControl( self.currFX, 3, position )
	ParticleManager:SetParticleControlForward( self.currFX, 0, self.direction )
	ParticleManager:SetParticleControlForward( self.currFX, 2, self.direction )	

end

function modifier_void_spirit_aether_remnant_watch:CreatePuller( position )
	local caster = self:GetCaster()
	local parent = self:GetParent()
	-- Create Particle
	self.currFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_void_spirit/aether_remnant/void_spirit_aether_remnant_pull.vpcf", PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( self.currFX, 0, position )
	ParticleManager:SetParticleControl( self.currFX, 1, position + self.direction * self.range )
	ParticleManager:SetParticleControl( self.currFX, 2, position + self.direction * self.range )
	ParticleManager:SetParticleControl( self.currFX, 3, position )
	ParticleManager:SetParticleControlForward( self.currFX, 2, -self.direction )	
	self._isPulling = true
end

modifier_void_spirit_aether_remnant_watched = class({})
LinkLuaModifier( "modifier_void_spirit_aether_remnant_watched", "heroes/hero_void_spirit/void_spirit_aether_remnant", LUA_MODIFIER_MOTION_NONE )

function modifier_void_spirit_aether_remnant_watched:OnCreated()
	self.damage = self:GetSpecialValueFor("impact_damage")	
	self.think_interval = self:GetSpecialValueFor("think_interval")
	
	self.expire_damage = self:GetSpecialValueFor("expire_damage")
	self.expire_stun_duration = self:GetSpecialValueFor("expire_stun_duration") / 100
	
	self.attack_speed_factor = self:GetSpecialValueFor("think_interval")
	if IsServer() then
		self:GetParent():MoveToPosition( self:GetParent()._aetherRemnantPosition )
		self:OnIntervalThink( )
		self:StartIntervalThink(self.think_interval)
		
		
		self.aether_remnant_void_mark = self:GetSpecialValueFor("aether_remnant_void_mark") == 1
		if self.aether_remnant_void_mark then
			local astralStep = self:GetCaster():FindAbilityByName("void_spirit_astral_step")
			if astralStep and astralStep:IsTrained() then
				astralStep._preventInstantProc = self:GetAbility()
				astralStep:ApplyMark( self:GetParent() )
				astralStep._preventInstantProc = nil
			end
		end
	end
end

function modifier_void_spirit_aether_remnant_watched:OnIntervalThink()
	local parent = self:GetParent()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	
	ability:DealDamage( caster, parent, self.damage * self.think_interval )
	if self.attack_speed_factor > 0 then
		local damageFactor = (self.think_interval / caster:GetSecondsPerAttack( true ) - 1) * 100
		caster:PerformGenericAttack(parent, true, {suppressCleave = true, bonusDamagePct = damageFactor} )
	end
end

function modifier_void_spirit_aether_remnant_watched:OnDestroy()
	if IsClient() then return end
	
	local parent = self:GetParent()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	
	if self.expire_damage > 0 then
		ParticleManager:FireParticle("particles/units/heroes/hero_void_spirit/void_spirit_void_bubble_finish_explode.vpcf", PATTACH_POINT_FOLLOW, parent )
		ability:DealDamage( caster, parent, self.expire_damage )
	end
	if self.expire_stun_duration > 0 then
		ability:Stun( parent, self:GetElapsedTime() * self.expire_stun_duration )
	end
end

function modifier_void_spirit_aether_remnant_watched:CheckState()
	return {[MODIFIER_STATE_COMMAND_RESTRICTED] = true}
end

function modifier_void_spirit_aether_remnant_watched:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_void_spirit_aether_remnant_watched:GetModifierMoveSpeedBonus_Percentage()
	return -100
end