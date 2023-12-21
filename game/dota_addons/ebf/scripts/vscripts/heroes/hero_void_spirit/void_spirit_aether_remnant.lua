void_spirit_aether_remnant = class({})

function void_spirit_aether_remnant:IsVectorTargeting()
	return true
end

function void_spirit_aether_remnant:GetVectorTargetRange()
	return self:GetTalentSpecialValueFor("remnant_watch_distance")
end

function void_spirit_aether_remnant:GetVectorTargetStartRadius()
	return self:GetTalentSpecialValueFor("remnant_watch_radius") / 2
end

function void_spirit_aether_remnant:OnVectorCastStart()
	local caster = self:GetCaster()
	
	local velocity = self:GetTalentSpecialValueFor("projectile_speed") * CalculateDirection( self:GetVectorPosition(), caster )
	local vision = self:GetTalentSpecialValueFor("watch_path_vision_radius")
	local distance = CalculateDistance( self:GetVectorPosition(), caster )
	local width = 125
	EmitSoundOn( "Hero_VoidSpirit.AetherRemnant.Cast", caster )
	self:FireLinearProjectile("particles/units/heroes/hero_void_spirit/aether_remnant/void_spirit_aether_remnant_run.vpcf", velocity, distance, width, {}, false, true, vision)
end

function void_spirit_aether_remnant:OnProjectileHit( target, position )
	if not target then
		local caster = self:GetCaster()
		
		local duration = self:GetTalentSpecialValueFor("duration")
		CreateModifierThinker( caster, self, "modifier_void_spirit_aether_remnant_watch", {duration = duration}, GetGroundPosition( position, caster ), caster:GetTeam(), true )
	end
end

modifier_void_spirit_aether_remnant_watch = class({})
LinkLuaModifier( "modifier_void_spirit_aether_remnant_watch", "heroes/hero_void_spirit/void_spirit_aether_remnant", LUA_MODIFIER_MOTION_NONE )

function modifier_void_spirit_aether_remnant_watch:OnCreated()
	if IsServer() then
		local ability = self:GetAbility()
		local position = self:GetParent():GetAbsOrigin()
		local caster = self:GetCaster()
		
		self.duration = self:GetTalentSpecialValueFor("pull_duration")
		self.damage = self:GetTalentSpecialValueFor("impact_damage")
		self.vision = self:GetTalentSpecialValueFor("watch_path_vision_radius")
		self.direction = ability:GetVectorDirection()
		self.range = ability:GetVectorTargetRange()
		self.width = ability:GetVectorTargetStartRadius()
		self.affectedUnits = {}
		
		self.hasShard = caster:HasShard()
		self.shard = caster:GetSecondsPerAttack(false) * self:GetTalentSpecialValueFor("shard_attack_rate_multiplier")
		self.shardTick = 0
		
		self:CreateWatcher( position )
		
		EmitSoundOn( "Hero_VoidSpirit.AetherRemnant", self:GetParent() )
		EmitSoundOn( "Hero_VoidSpirit.AetherRemnant.Spawn_lp", self:GetParent() )
		
		self:StartIntervalThink(0)
	end
end

function modifier_void_spirit_aether_remnant_watch:OnDestroy()
	if IsServer() then
		EmitSoundOn( "Hero_VoidSpirit.AetherRemnant.Destroy", self:GetParent() )
		StopSoundOn( "Hero_VoidSpirit.AetherRemnant.Spawn_lp", self:GetParent() )
		ParticleManager:ClearParticle( self.currFX )
	end
end

function modifier_void_spirit_aether_remnant_watch:OnIntervalThink()
	local parent = self:GetParent()
	local startPos = parent:GetAbsOrigin()
	
	AddFOWViewer( parent:GetTeamNumber(), startPos, self.vision, 0.1, true ) 
	AddFOWViewer( parent:GetTeamNumber(), startPos + self.direction * self.range/2, self.vision, 0.1, true ) 
	AddFOWViewer( parent:GetTeamNumber(), startPos + self.direction * self.range, self.vision, 0.1, true ) 
	if not parent.currentPullTarget or parent.currentPullTarget:IsNull() then
		for _, unit in ipairs( parent:FindEnemyUnitsInLine( startPos, startPos + self.direction * self.range, self.width ) ) do
			if not self.affectedUnits[unit:entindex()] then
				parent.currentPullTarget = unit
				self:GetAbility():Stun(unit, self.duration)
				
				parent.timeToPull = self.duration + 0.1
				parent.distanceToPull = CalculateDistance(parent, unit)
				parent.pullSpeed = ( parent.distanceToPull / parent.timeToPull ) * 0.35
				self:ClearPreviousState()
				self:CreatePuller( startPos, unit )
				EmitSoundOn( "Hero_VoidSpirit.AetherRemnant.Triggered", unit )
				self.affectedUnits[unit:entindex()] = true
				break
			end
		end
	elseif parent.currentPullTarget then
		if parent.timeToPull >= 0 then
			parent.timeToPull = parent.timeToPull - FrameTime()
			local pullDirection = CalculateDirection( parent, parent.currentPullTarget )
			parent.currentPullTarget:SetAbsOrigin( parent.currentPullTarget:GetAbsOrigin() + pullDirection * parent.pullSpeed * FrameTime() )
			parent.currentPullTarget:SetForwardVector( pullDirection )
			
			if self.hasShard then
				self.shardTick = self.shardTick - FrameTime()
				if self.shardTick <= 0 then
					self:GetCaster():PerformAbilityAttack( parent.currentPullTarget, true, self:GetAbility() )
					self.shardTick = self.shard
				end
			end
		else
			ResolveNPCPositions( parent.currentPullTarget:GetAbsOrigin(), 128 )
			self:ClearPreviousState()
			self:CreateWatcher( startPos )
			EmitSoundOn( "Hero_VoidSpirit.AetherRemnant.Target", parent.currentPullTarget )
			self:GetAbility():DealDamage( self:GetCaster(), parent.currentPullTarget, self.damage )
			parent.currentPullTarget = nil
		end
	end
end

function modifier_void_spirit_aether_remnant_watch:ClearPreviousState()
	ParticleManager:ClearParticle( self.currFX )
end

function modifier_void_spirit_aether_remnant_watch:CreateWatcher( position )
	local caster = self:GetCaster()
	self.currFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_void_spirit/aether_remnant/void_spirit_aether_remnant_watch.vpcf", PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl( self.currFX, 0, position )
	ParticleManager:SetParticleControlOrientation( self.currFX, 0, self.direction, self.direction, self.direction )
	ParticleManager:SetParticleControl( self.currFX, 1, position + self.direction * self.range )
	ParticleManager:SetParticleControlOrientation( self.currFX, 2, self.direction, self.direction, self.direction )
	ParticleManager:SetParticleControlEnt( self.currFX, 3, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
end

function modifier_void_spirit_aether_remnant_watch:CreatePuller( position, target )
	local caster = self:GetCaster()
	-- get data
	local direction = target:GetOrigin()-position
	direction.z = 0
	direction = -direction:Normalized()

	-- Create Particle
	self.currFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_void_spirit/aether_remnant/void_spirit_aether_remnant_pull.vpcf", PATTACH_CUSTOMORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControl( self.currFX, 0, position )
	ParticleManager:SetParticleControlEnt(self.currFX, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0,0,0), true)
	ParticleManager:SetParticleControlForward( self.currFX, 2, direction )
	ParticleManager:SetParticleControl( self.currFX, 3, position )
end