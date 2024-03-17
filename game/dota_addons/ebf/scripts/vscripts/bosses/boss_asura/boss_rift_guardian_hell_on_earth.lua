boss_rift_guardian_hell_on_earth = class({})

function boss_rift_guardian_hell_on_earth:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier( caster, self, "modifier_boss_rift_guardian_hell_on_earth", {duration = self:GetChannelTime()} )
end

function boss_rift_guardian_hell_on_earth:OnChannelFinish( bInterrupt )
	local caster = self:GetCaster()
	local channel = caster:FindModifierByName("modifier_boss_rift_guardian_hell_on_earth")
	if bInterrupt then
		channel:SetDuration( self:GetSpecialValueFor("persist_duration"), true )
	else
		channel:Destroy()
	end
end

function boss_rift_guardian_hell_on_earth:CreateTimedRaze( position )
	local caster = self:GetCaster()
	
	local razeFX = ParticleManager:CreateParticle("particles/doom_ring.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(razeFX, 0, position)
	ParticleManager:SetParticleControl(razeFX, 1, position)
	
	local damage = self:GetSpecialValueFor("raze_damage")
	local break_duration = self:GetSpecialValueFor("break_duration")
	local radius = self:GetSpecialValueFor("radius")
	Timers:CreateTimer(1.5, function()
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( position, radius ) ) do
			self:DealDamage( caster, enemy, damage )
			enemy:AddNewModifier( caster, self, "modifier_doom_bringer_doom_break", {duration = break_duration} )
		end
		EmitSoundOnLocationWithCaster( position, "Hero_EmberSpirit.Attack.TI9", caster )
        ParticleManager:DestroyParticle(razeFX, false)
	end)
end

modifier_boss_rift_guardian_hell_on_earth = class({})
LinkLuaModifier( "modifier_boss_rift_guardian_hell_on_earth", "bosses/boss_asura/boss_rift_guardian_hell_on_earth", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_rift_guardian_hell_on_earth:OnCreated()
	if not IsServer() then return end
	self.razeType = RandomInt( 1, 4 )
	self.radius = self:GetSpecialValueFor("radius")
	self:StartRazeSequence( razeType )
end

function modifier_boss_rift_guardian_hell_on_earth:StartRazeSequence( razeType )
	self.created_projectiles = 0
	self.total_projectiles = 40
	self.shift = self:GetAbility():GetTrueCastRange() / self.total_projectiles
	self.origin = self:GetCaster():GetAbsOrigin()
	self.direction = self:GetCaster():GetForwardVector()
	self.grow = TernaryOperator( -1, RollPercentage(50), 1 )
	if self.grow == -1 then
		self.distance = 0
	else
		self.distance = self:GetAbility():GetTrueCastRange()
	end
	self:StartIntervalThink( 0.08 )
end

function modifier_boss_rift_guardian_hell_on_earth:OnIntervalThink()
	if self.razeType == 1 then -- straight
		self:ContinueSwirlSequence( )
	elseif self.razeType == 2 then -- swirl
		self:ContinueSpokesSequence( )
	elseif self.razeType == 3 then -- kill players
		self:ContinueTargetedSequence( )
	elseif self.razeType == 4 then -- chaos
		self:ContinueChaosSequence( )
	end
	if self.created_projectiles >= self.total_projectiles then -- reset to random sequence
		self:OnCreated()
	end
end

function modifier_boss_rift_guardian_hell_on_earth:ContinueSpokesSequence( )
	self.created_projectiles = self.created_projectiles + 1
	for i = 1, 5 do
		local angle = 0 + 360*(i-1)/5
		local position = GetGroundPosition(RotatePosition(Vector(0,0,0), QAngle(0,angle,0), self.direction) * (self.distance-self.grow*self.shift*self.created_projectiles) + self.origin,nil)
		self:GetAbility():CreateTimedRaze( position )
	end
end

function modifier_boss_rift_guardian_hell_on_earth:ContinueSwirlSequence( )
	self.created_projectiles = self.created_projectiles + 1
	for i = 1, 2 do
		local angle = ((self.created_projectiles*1200)/(self.total_projectiles*2))*(-1)^i
		local position = GetGroundPosition(RotatePosition(Vector(0,0,0), QAngle(0,angle,0), self.direction) * (self.distance-self.grow*self.shift*self.created_projectiles) + self.origin,nil)
		self:GetAbility():CreateTimedRaze( position )
	end
end

function modifier_boss_rift_guardian_hell_on_earth:ContinueTargetedSequence( )
	local caster = self:GetCaster()
	self.created_projectiles = self.created_projectiles + 1
	for _, hero in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self:GetAbility():GetTrueCastRange(), {type = DOTA_UNIT_TARGET_HERO} ) ) do
		if hero:IsRealHero() then
			local position = GetGroundPosition(hero:GetAbsOrigin() + ActualRandomVector( self.radius * 2 ), nil)
			self:GetAbility():CreateTimedRaze( position )
		end
	end
end

function modifier_boss_rift_guardian_hell_on_earth:ContinueChaosSequence( )
	self.created_projectiles = self.created_projectiles + 1
	for i = 1, 5 do
		local position = GetGroundPosition(self.origin + ActualRandomVector( math.max( 128, (self.distance-self.grow*self.shift*self.created_projectiles*2) ), 64 ), nil)
		self:GetAbility():CreateTimedRaze( position )
	end
end

function modifier_boss_rift_guardian_hell_on_earth:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION, MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE  }
end

function modifier_boss_rift_guardian_hell_on_earth:GetOverrideAnimation()
	return ACT_DOTA_FLAIL
end

function modifier_boss_rift_guardian_hell_on_earth:GetOverrideAnimationRate()
	return 0.2
end