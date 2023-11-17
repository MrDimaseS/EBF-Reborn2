dawnbreaker_fire_wreath = class({})

dawnbreaker_fire_wreath = class({})
LinkLuaModifier( "modifier_starbreaker_fire_wreath_activity", "heroes/hero_dawnbreaker/dawnbreaker_fire_wreath", LUA_MODIFIER_MOTION_HORIZONTAL )

--------------------------------------------------------------------------------
-- Init Abilities
function dawnbreaker_fire_wreath:Precache( context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_dawnbreaker.vsndevts", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_dawnbreaker/hero_dawnbreaker_combo_strike_range_finder_aoe.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_dawnbreaker/dawnbreaker_fire_wreath_sweep.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_dawnbreaker/dawnbreaker_fire_wreath_smash.vpcf", context )
end

--------------------------------------------------------------------------------
-- Ability Cast Filter
function dawnbreaker_fire_wreath:CastFilterResultLocation( vLoc )
	-- check nohammer
	if self:GetCaster():HasModifier( "modifier_dawnbreaker_celestial_hammer_caster" ) then
		return UF_FAIL_CUSTOM
	end

	if not IsServer() then return end

	return UF_SUCCESS
end

function dawnbreaker_fire_wreath:GetCustomCastErrorLocation( vLoc )
	-- check nohammer
	if self:GetCaster():HasModifier( "modifier_dawnbreaker_celestial_hammer_caster" ) then
		return "#dota_hud_error_nohammer"
	end

	return ""
end

--------------------------------------------------------------------------------
-- Ability Start
function dawnbreaker_fire_wreath:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local point = self:GetCursorPosition()

	-- load data
	local duration = self:GetSpecialValueFor( "duration" )

	-- get direction
	local direction = point-caster:GetOrigin()
	if direction:Length2D()<1 then
		direction = caster:GetForwardVector()
	else
		direction.z = 0
		direction = direction:Normalized()
	end

	-- add modifier
	caster:AddNewModifier( caster, self, "modifier_starbreaker_fire_wreath_activity", {})
end

modifier_starbreaker_fire_wreath_activity = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_starbreaker_fire_wreath_activity:IsHidden()
	return false
end

function modifier_starbreaker_fire_wreath_activity:IsDebuff()
	return false
end

function modifier_starbreaker_fire_wreath_activity:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_starbreaker_fire_wreath_activity:OnCreated( kv )
	self.parent = self:GetParent()

	-- references
	self.swipe_radius = self:GetAbility():GetSpecialValueFor( "swipe_radius" )
	self.swipe_damage = self:GetAbility():GetSpecialValueFor( "swipe_damage" )
	self.swipe_duration = self:GetAbility():GetSpecialValueFor( "sweep_stun_duration" )

	self.smash_radius = self:GetAbility():GetSpecialValueFor( "smash_radius" )
	self.smash_damage = self:GetAbility():GetSpecialValueFor( "smash_damage" )
	self.smash_duration = self:GetAbility():GetSpecialValueFor( "smash_stun_duration" )
	self.smash_distance = self:GetAbility():GetSpecialValueFor( "smash_distance_from_hero" )

	self.selfstun = self:GetAbility():GetSpecialValueFor( "self_stun_duration" )
	self.attacks = self:GetAbility():GetSpecialValueFor( "total_attacks" )
	self.speed = self:GetAbility():GetSpecialValueFor( "movement_speed" )
	self.duration = self:GetAbility():GetSpecialValueFor( "duration" )

	self.shard_movement_penalty = self:GetAbility():GetSpecialValueFor( "shard_movement_penalty" )
	
	if not IsServer() then return end

	self.forward = CalculateDirection( self:GetAbility():GetCursorPosition(), self.parent )
	self.bonus = 0
	self.ctr = 0
	local interval = self.duration/(self.attacks-1)

	-- apply forward motion
	if not self:GetCaster():HasShard() then
		self:ApplyHorizontalMotionController()
		self.movementControllerActive = true
	end
	self.parent:StartGestureWithPlaybackRate( ACT_DOTA_OVERRIDE_ABILITY_1, 1.1 / self.duration )
	-- Start interval
	self:StartIntervalThink( interval )
	self:OnIntervalThink()
end

function modifier_starbreaker_fire_wreath_activity:OnRefresh( kv )
end

function modifier_starbreaker_fire_wreath_activity:OnRemoved()
	
end

function modifier_starbreaker_fire_wreath_activity:OnDestroy()
	if not IsServer() then return end
	if self.movementControllerActive then self:GetParent():RemoveHorizontalMotionController( self ) end
	self.parent:StartGestureWithPlaybackRate( ACT_DOTA_CAST_ABILITY_1_END, 1 )
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_starbreaker_fire_wreath_activity:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_SUPPRESS_CLEAVE,
		MODIFIER_PROPERTY_DISABLE_TURNING,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE_MIN,
		MODIFIER_PROPERTY_DISABLE_TURNING,
	}

	return funcs
end

function modifier_starbreaker_fire_wreath_activity:GetModifierPreAttack_BonusDamage()
	if not IsServer() then return 0 end

	return self.bonus
end

function modifier_starbreaker_fire_wreath_activity:GetSuppressCleave()
	return 1
end

function modifier_starbreaker_fire_wreath_activity:GetModifierDisableTurning()
	return 1
end

function modifier_starbreaker_fire_wreath_activity:GetModifierMoveSpeedBonus_Percentage()
	return -self.shard_movement_penalty
end

function modifier_starbreaker_fire_wreath_activity:GetModifierMoveSpeed_AbsoluteMin()
	return self.speed
end
--------------------------------------------------------------------------------
-- Status Effects
function modifier_starbreaker_fire_wreath_activity:CheckState()
	local state = {
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_CANNOT_MISS] = true
	}
	if not self:GetCaster():HasShard() then
		state[MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS] = true
	else
		state[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
		state[MODIFIER_STATE_DEBUFF_IMMUNE] = true
	end

	return state
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_starbreaker_fire_wreath_activity:OnIntervalThink()
	-- if stunned, destroy
	if self.parent:IsStunned() then
		self:Destroy()
		return
	end

	self.ctr = self.ctr + 1
	if self.ctr>=self.attacks then
		self:Smash()
	else
		self:Swipe()
	end
	
end

function modifier_starbreaker_fire_wreath_activity:Swipe()
	-- find enemies
	local enemies = self.parent:FindEnemyUnitsInRadius( self.parent:GetAbsOrigin(), self.swipe_radius )

	for _,enemy in pairs(enemies) do
		-- attack
		self.bonus = self.swipe_damage
		self.parent:PerformAttack( enemy, true, true, true, true, false, false, true )

		-- slow
		if IsEntitySafe( enemy ) then
			enemy:AddNewModifier(self.parent, self:GetAbility(), "modifier_starbreaker_fire_wreath_slow", { duration = self.swipe_duration })
		end
	end

	-- increment luminosity stack
	if #enemies>0 then
		local mod1 = self.parent:FindModifierByName( "modifier_dawnbreaker_luminosity_lua" )
		local mod2 = self.parent:FindModifierByName( "modifier_dawnbreaker_luminosity_lua_buff" )

		if mod2 then
			mod2:Destroy()
		elseif mod1 then
			mod1:Increment()
		end
	end

	-- play effects
	self:PlayEffects1()
	self:PlayEffects2()
end

function modifier_starbreaker_fire_wreath_activity:Smash()
	local center = self.parent:GetOrigin() + self.forward * self.smash_distance
	local ability = self:GetAbility()

	-- find enemies
	local enemies = self.parent:FindEnemyUnitsInRadius( center, self.smash_radius )

	for _,enemy in pairs(enemies) do
		-- attack
		self.bonus = self.smash_damage
		self.parent:PerformAttack( enemy, true, true, true, true, false, false, true )

		-- stun
		if IsEntitySafe( enemy ) then
			enemy:ApplyKnockBack(center, self.smash_duration, 0.2, 0, 90, self.parent, ability)
		end
	end

	-- self stun
	ability:Stun( target, self.selfstun )

	-- increment luminosity stack
	if #enemies>0 then
		local mod1 = self.parent:FindModifierByName( "modifier_dawnbreaker_luminosity_lua" )
		local mod2 = self.parent:FindModifierByName( "modifier_dawnbreaker_luminosity_lua_buff" )

		if mod2 then
			mod2:Destroy()
		elseif mod1 then
			mod1:Increment()
		end
	end

	-- play effects
	self:PlayEffects3( center )
	
	self:Destroy()
end

--------------------------------------------------------------------------------
-- Motion Effects
function modifier_starbreaker_fire_wreath_activity:UpdateHorizontalMotion( me, dt )
	-- get forward pos
	local pos = me:GetOrigin() + self.forward * self.speed * dt

	-- if not traversable, stop
	if not GridNav:IsTraversable( pos ) then return end

	-- destroy trees
	GridNav:DestroyTreesAroundPoint( me:GetOrigin(), 100, true )

	pos = GetGroundPosition( pos, me )
	me:SetOrigin( pos )
end

function modifier_starbreaker_fire_wreath_activity:OnHorizontalMotionInterrupted()
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_starbreaker_fire_wreath_activity:PlayEffects1()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_dawnbreaker/dawnbreaker_fire_wreath_sweep_cast.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self.parent )
	ParticleManager:ReleaseParticleIndex( effect_cast )
end

function modifier_starbreaker_fire_wreath_activity:PlayEffects2()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_dawnbreaker/dawnbreaker_fire_wreath_sweep.vpcf"
	local sound_cast = "Hero_Dawnbreaker.Fire_Wreath.Sweep"

	-- Get Data
	local forward = RotatePosition( Vector(0,0,0), QAngle( 0, -120, 0 ), self.forward )

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self.parent )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		self.parent,
		PATTACH_POINT_FOLLOW,
		"attach_attack1",
		Vector(0,0,0), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControlForward( effect_cast, 0, forward )

	-- buff particle
	self:AddParticle(
		effect_cast,
		false, -- bDestroyImmediately
		false, -- bStatusEffect
		-1, -- iPriority
		false, -- bHeroEffect
		false -- bOverheadEffect
	)

	-- Create Sound
	EmitSoundOn( sound_cast, self.parent )
end

function modifier_starbreaker_fire_wreath_activity:PlayEffects3( center )
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_dawnbreaker/dawnbreaker_fire_wreath_smash.vpcf"
	local sound_cast = "Hero_Dawnbreaker.Fire_Wreath.Smash"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self.parent )
	ParticleManager:SetParticleControl( effect_cast, 0, center )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOn( sound_cast, self.parent )
end