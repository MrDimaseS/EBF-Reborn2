hoodwink_sharpshooter = class({})

--------------------------------------------------------------------------------
-- Init Abilities
function hoodwink_sharpshooter:Precache( context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_hoodwink.vsndevts", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_hoodwink/hoodwink_sharpshooter.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_hoodwink/hoodwink_sharpshooter_projectile.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_hoodwink/hoodwink_sharpshooter_impact.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_hoodwink/hoodwink_sharpshooter_target.vpcf", context )
	PrecacheResource( "particle", "particles/items_fx/force_staff.vpcf", context )
end

function hoodwink_sharpshooter:GetAssociatedSecondaryAbilities()
	return "hoodwink_sharpshooter_release"
end

--------------------------------------------------------------------------------
-- Ability Start

function hoodwink_sharpshooter:OnUpgrade()
	local caster = self:GetCaster()
	local subAb = caster:FindAbilityByName("hoodwink_sharpshooter_release")
	if subAb and subAb:GetLevel() ~= 1 then
		subAb:SetLevel(1)
	end
end

function hoodwink_sharpshooter:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	-- load data
	local duration = self:GetSpecialValueFor( "misfire_time" )

	-- add modifier
	caster:AddNewModifier( caster, self, "modifier_hoodwink_sharpshooter_ebf", { duration = duration, x = point.x, y = point.y,} )
end

--------------------------------------------------------------------------------
-- Projectile
function hoodwink_sharpshooter:OnProjectileThinkHandle( projectile )
	local sound = EntIndexToHScript( self.projectiles[projectile].sound )
	if not sound or sound:IsNull() then return end
	sound:SetOrigin( ProjectileManager:GetLinearProjectileLocation( projectile ) )
end

function hoodwink_sharpshooter:OnProjectileHitHandle( target, location, projectile )
	local projectileData = self.projectiles[projectile]
	if not projectileData then return end
	
	if not target then
		local sound = EntIndexToHScript( projectileData.sound )
		if IsEntitySafe( sound ) then
			local sound_projectile = "Hero_Hoodwink.Sharpshooter.Projectile"
			StopSoundOn( sound_projectile, sound )
			UTIL_Remove( sound )
			self.projectiles[projectile] = nil
			return true
		end
	end

	local caster = self:GetCaster()

	if target:IsConsideredHero() then
		if projectileData.hitHero and not caster:HasScepter() then -- ignore heroes
			return false
		end
		projectileData.hitHero = true
	end
	self:DealDamage( caster, target, projectileData.damage )

	-- modifier
	target:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_hoodwink_sharpshooter_ebf_debuff", -- modifier name
		{
			duration = projectileData.duration,
			x = projectileData.direction.x,
			y = projectileData.direction.y
		} -- kv
	)

	-- overhead damage info
	SendOverheadEventMessage(
		nil,
		OVERHEAD_ALERT_BONUS_SPELL_DAMAGE,
		target,
		projectileData.damage,
		self:GetCaster():GetPlayerOwner()
	)

	-- Vision
	AddFOWViewer( self:GetCaster():GetTeamNumber(), target:GetOrigin(), 300, 4, false)

	-- play effects
	local direction = projectileData.direction:Normalized()
	self:PlayEffects( target, direction )
	
end

--------------------------------------------------------------------------------
-- Effects
function hoodwink_sharpshooter:PlayEffects( target, direction )
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_hoodwink/hoodwink_sharpshooter_impact.vpcf"
	local sound_cast = "Hero_Hoodwink.Sharpshooter.Target"

	-- Get Data

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:SetParticleControl( effect_cast, 0, target:GetOrigin() )
	ParticleManager:SetParticleControl( effect_cast, 1, target:GetOrigin() )
	ParticleManager:SetParticleControlForward( effect_cast, 1, direction )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOn( sound_cast, target )
end

LinkLuaModifier( "modifier_hoodwink_sharpshooter_ebf", "heroes/hero_hoodwink/hoodwink_sharpshooter", LUA_MODIFIER_MOTION_NONE )
modifier_hoodwink_sharpshooter_ebf = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_hoodwink_sharpshooter_ebf:IsHidden()
	return false
end

function modifier_hoodwink_sharpshooter_ebf:IsDebuff()
	return false
end

function modifier_hoodwink_sharpshooter_ebf:IsStunDebuff()
	return false
end

function modifier_hoodwink_sharpshooter_ebf:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_hoodwink_sharpshooter_ebf:OnCreated( kv )
	-- references
	self.caster = self:GetCaster()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self.team = self.parent:GetTeamNumber()

	self.charge = self:GetAbility():GetSpecialValueFor( "max_charge_time" )
	self.damage = self:GetAbility():GetSpecialValueFor( "max_damage" )
	self.duration = self:GetAbility():GetSpecialValueFor( "max_slow_debuff_duration" )
	self.turn_rate = self:GetAbility():GetSpecialValueFor( "turn_rate" )

	self.recoil_distance = self:GetAbility():GetSpecialValueFor( "recoil_distance" )
	self.recoil_duration = self:GetAbility():GetSpecialValueFor( "recoil_duration" )
	self.recoil_height = self:GetAbility():GetSpecialValueFor( "recoil_height" )

	-- set interval on both cl and sv
	self.interval = 0.03 
	self:StartIntervalThink( self.interval )

	if not IsServer() then return end

	-- references
	self.projectile_speed = self:GetAbility():GetSpecialValueFor( "arrow_speed" )
	self.projectile_range = self:GetAbility():GetSpecialValueFor( "arrow_range" )
	self.projectile_width = self:GetAbility():GetSpecialValueFor( "arrow_width" )
	local projectile_vision = self:GetAbility():GetSpecialValueFor( "arrow_vision" )
	local projectile_name = "particles/units/heroes/hero_hoodwink/hoodwink_sharpshooter_projectile.vpcf"

	-- init turn logic
	local vec = Vector( kv.x, kv.y, 0 )
	self:SetDirection( vec )
	self.current_dir = self.target_dir
	self.face_target = true
	self.parent:SetForwardVector( self.current_dir )
	self.turn_speed = self.interval*self.turn_rate

	-- precache projectile
	self.info = {
		Source = self.parent,
		Ability = self:GetAbility(),
		-- vSpawnOrigin = caster:GetAbsOrigin(),
		
	    bDeleteOnHit = false,
	    
	    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
	    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
	    iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,

	    EffectName = projectile_name,
	    fDistance = self.projectile_range,
	    fStartRadius = self.projectile_width,
	    fEndRadius = self.projectile_width,
		-- vVelocity = projectile_direction * projectile_speed,
	
		bHasFrontalCone = false,
		bReplaceExisting = false,
		
		bProvidesVision = true,
		iVisionRadius = projectile_vision,
		iVisionTeamNumber = self.caster:GetTeamNumber()
	}

	-- swap abilities
	self.caster:SwapAbilities( "hoodwink_sharpshooter", "hoodwink_sharpshooter_release", false, true )

	-- play effects
	self:PlayEffects1()
	self:PlayEffects2()
end

function modifier_hoodwink_sharpshooter_ebf:OnRefresh( kv )
	
end

function modifier_hoodwink_sharpshooter_ebf:OnRemoved()
end

function modifier_hoodwink_sharpshooter_ebf:OnDestroy()
	if not IsServer() then return end

	-- calculate direction
	local direction = self.current_dir

	-- calculate percentage
	local pct = math.min( self:GetElapsedTime(), self.charge )/self.charge

	-- Create thinker for sound
	local sound = CreateModifierThinker(
		self.caster, -- player source
		self, -- ability source
		"", -- modifier name
		{}, -- kv
		self.caster:GetOrigin(),
		self.team,
		false
	)
	local sound_cast = "Hero_Hoodwink.Sharpshooter.Projectile"
	EmitSoundOn( sound_cast, sound )

	self:GetAbility().projectiles = self:GetAbility().projectiles or {}
	local projectile = self:GetAbility():FireLinearProjectile("particles/units/heroes/hero_hoodwink/hoodwink_sharpshooter_projectile.vpcf", direction * self.projectile_speed, self.projectile_range, self.projectile_width)
	self:GetAbility().projectiles[projectile] = {
		damage = self.damage * pct,
		duration = self.duration * pct,
		direction = direction,
		sound = sound:entindex(),
	}
	print( projectile, "projectile ID creation" )

	-- knockback
	local mod = self.caster:ApplyKnockBack( self.caster:GetAbsOrigin() + self.caster:GetForwardVector() * self.recoil_distance, 0, self.recoil_duration, self.recoil_distance, self.recoil_height, self.caster, self:GetAbility() )

	-- swap abilities
	self.caster:SwapAbilities( "hoodwink_sharpshooter", "hoodwink_sharpshooter_release", true, false )

	-- play effects
	self:PlayEffects4( mod )
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_hoodwink_sharpshooter_ebf:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ORDER,
		
		MODIFIER_PROPERTY_DISABLE_TURNING,
		MODIFIER_PROPERTY_MOVESPEED_LIMIT,
		-- MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
	}

	return funcs
end

function modifier_hoodwink_sharpshooter_ebf:OnOrder( params )
	if params.unit~=self:GetParent() then return end

	-- point right click
	if 	params.order_type==DOTA_UNIT_ORDER_MOVE_TO_POSITION or
		params.order_type==DOTA_UNIT_ORDER_MOVE_TO_DIRECTION
	then
		-- set facing
		self:SetDirection( params.new_pos )

	-- targetted right click
	elseif 
		params.order_type==DOTA_UNIT_ORDER_MOVE_TO_TARGET or
		params.order_type==DOTA_UNIT_ORDER_ATTACK_TARGET
	then
		-- set facing
		self:SetDirection( params.target:GetOrigin() )
	end
end

function modifier_hoodwink_sharpshooter_ebf:GetModifierMoveSpeed_Limit()
	return 0.1
end

function modifier_hoodwink_sharpshooter_ebf:GetModifierTurnRate_Percentage()
	return -self.turn_rate
end

function modifier_hoodwink_sharpshooter_ebf:GetModifierDisableTurning()
	return 1
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_hoodwink_sharpshooter_ebf:CheckState()
	local state = {
		[MODIFIER_STATE_DISARMED] = true,
	}

	return state
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_hoodwink_sharpshooter_ebf:OnIntervalThink()
	if not IsServer() then
		-- client only code
		self:UpdateStack()
		return
	end

	-- turning logic
	self:TurnLogic()

	-- vision
	-- NOTE: Can be optimized if there's a way to move vision provider dynamically
	local startpos = self.parent:GetOrigin()
	local visions = self.projectile_range/self.projectile_width
	local delta = self.parent:GetForwardVector() * self.projectile_width
	for i=1,visions do
		AddFOWViewer( self.team, startpos, self.projectile_width, 0.1, false )
		startpos = startpos + delta
	end

	-- max charge sound
	if not self.charged and self:GetElapsedTime()>self.charge then
		self.charged = true

		-- play effects
		local sound_cast = "Hero_Hoodwink.Sharpshooter.MaxCharge"
		EmitSoundOnClient( sound_cast, self.parent:GetPlayerOwner() )
	end

	-- timer particle
	local remaining = self:GetRemainingTime()
	local seconds = math.ceil( remaining )
	local isHalf = (seconds-remaining)>0.5
	if isHalf then seconds = seconds-1 end

	if self.half~=isHalf then
		self.half = isHalf

		-- play effects
		self:PlayEffects3( seconds, isHalf )
	end

	-- update paticle
	self:UpdateEffect()
end

--------------------------------------------------------------------------------
-- Helper
function modifier_hoodwink_sharpshooter_ebf:SetDirection( vec )
	self.target_dir = ((vec-self.parent:GetOrigin())*Vector(1,1,0)):Normalized()
	self.face_target = false
end

function modifier_hoodwink_sharpshooter_ebf:TurnLogic()
	-- only rotate when target changed
	if self.face_target then return end

	local current_angle = VectorToAngles( self.current_dir ).y
	local target_angle = VectorToAngles( self.target_dir ).y
	local angle_diff = AngleDiff( current_angle, target_angle )

	local sign = -1
	if angle_diff<0 then sign = 1 end

	if math.abs( angle_diff )<1.1*self.turn_speed then
		-- end rotating
		self.current_dir = self.target_dir
		self.face_target = true
	else
		-- rotate
		self.current_dir = RotatePosition( Vector(0,0,0), QAngle(0, sign*self.turn_speed, 0), self.current_dir )
	end

	-- set facing when not motion controlled
	local a = self.parent:IsCurrentlyHorizontalMotionControlled()
	local b = self.parent:IsCurrentlyVerticalMotionControlled()
	if not (a or b) then
		self.parent:SetForwardVector( self.current_dir )
	end
end

function modifier_hoodwink_sharpshooter_ebf:UpdateStack()
	-- only update stack percentage on client to reduce traffic
	local pct = math.min( self:GetElapsedTime(), self.charge )/self.charge
	pct = math.floor( pct*100 )
	self:SetStackCount( pct )
end

--------------------------------------------------------------------------------
-- Filter
function modifier_hoodwink_sharpshooter_ebf:OrderFilter( data )
	if #data.units>1 then return true end

	local unit
	for _,id in pairs(data.units) do
		unit = EntIndexToHScript( id )
	end
	if unit~=self.parent then return true end

	if data.order_type==DOTA_UNIT_ORDER_MOVE_TO_POSITION then
		data.order_type = DOTA_UNIT_ORDER_MOVE_TO_DIRECTION
	elseif data.order_type==DOTA_UNIT_ORDER_ATTACK_TARGET or data.order_type==DOTA_UNIT_ORDER_MOVE_TO_TARGET then
		local pos = EntIndexToHScript( data.entindex_target ):GetOrigin()

		data.order_type = DOTA_UNIT_ORDER_MOVE_TO_DIRECTION
		data.position_x = pos.x
		data.position_y = pos.y
		data.position_z = pos.z
	end

	return true
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_hoodwink_sharpshooter_ebf:PlayEffects1()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_hoodwink/hoodwink_sharpshooter.vpcf"
	local sound_cast = "Hero_Hoodwink.Sharpshooter.Channel"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self.parent )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		self.parent,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		self.parent:GetOrigin(), -- unknown
		true -- unknown, true
	)

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

function modifier_hoodwink_sharpshooter_ebf:PlayEffects2()
	--NOTE: This could be a client-only code to reduce traffic, if only GetForwardVector is available on client. (Why GetAbsOrigin is available but not GetForwardVector?)

	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_hoodwink/hoodwink_sharpshooter_range_finder.vpcf"

	-- Get Data
	local startpos = self.parent:GetAbsOrigin()
	local endpos = startpos + self.parent:GetForwardVector() * self.projectile_range

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticleForPlayer( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self.parent, self.parent:GetPlayerOwner() )
	ParticleManager:SetParticleControl( effect_cast, 0, startpos )
	ParticleManager:SetParticleControl( effect_cast, 1, endpos )

	-- buff particle
	self:AddParticle(
		effect_cast,
		false, -- bDestroyImmediately
		false, -- bStatusEffect
		-1, -- iPriority
		false, -- bHeroEffect
		false -- bOverheadEffect
	)
	self.effect_cast = effect_cast
end

function modifier_hoodwink_sharpshooter_ebf:PlayEffects3( seconds, half )
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_hoodwink/hoodwink_sharpshooter_timer.vpcf"

	-- calculate data
	local mid = 1
	if half then mid = 8 end

	local len = 2
	if seconds<1 then
		len = 1
		if not half then return end
	end

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_OVERHEAD_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( 1, seconds, mid ) )
	ParticleManager:SetParticleControl( effect_cast, 2, Vector( len, 0, 0 ) )
end

function modifier_hoodwink_sharpshooter_ebf:PlayEffects4( modifier )
	-- Get Resources
	local particle_cast = "particles/items_fx/force_staff.vpcf"
	local sound_channel = "Hero_Hoodwink.Sharpshooter.Channel"
	local sound_cast = "Hero_Hoodwink.Sharpshooter.Cast"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self.parent )

	-- buff particle
	modifier:AddParticle(
		effect_cast,
		false, -- bDestroyImmediately
		false, -- bStatusEffect
		-1, -- iPriority
		false, -- bHeroEffect
		false -- bOverheadEffect
	)

	-- sound
	StopSoundOn( sound_channel, self.caster )
	EmitSoundOn( sound_cast, self.caster )
end

function modifier_hoodwink_sharpshooter_ebf:UpdateEffect()
	local startpos = self.parent:GetAbsOrigin()
	local endpos = startpos + self.current_dir * self.projectile_range

	ParticleManager:SetParticleControl( self.effect_cast, 0, startpos )
	ParticleManager:SetParticleControl( self.effect_cast, 1, endpos )
end

LinkLuaModifier( "modifier_hoodwink_sharpshooter_ebf_debuff", "heroes/hero_hoodwink/hoodwink_sharpshooter", LUA_MODIFIER_MOTION_NONE )
modifier_hoodwink_sharpshooter_ebf_debuff = class({})

function modifier_hoodwink_sharpshooter_ebf_debuff:IsHidden()
	return false
end

function modifier_hoodwink_sharpshooter_ebf_debuff:IsDebuff()
	return true
end

function modifier_hoodwink_sharpshooter_ebf_debuff:IsStunDebuff()
	return false
end

function modifier_hoodwink_sharpshooter_ebf_debuff:IsPurgable()
	return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_hoodwink_sharpshooter_ebf_debuff:OnCreated( kv )
	-- references
	self.parent = self:GetParent()

	self.slow = -self:GetAbility():GetSpecialValueFor( "slow_move_pct" )

	if not IsServer() then return end
	
	-- play effects
	local direction = Vector( kv.x, kv.y, 0 ):Normalized()
	self:PlayEffects( direction )
end

function modifier_hoodwink_sharpshooter_ebf_debuff:OnRefresh( kv )
end

function modifier_hoodwink_sharpshooter_ebf_debuff:OnRemoved()
end

function modifier_hoodwink_sharpshooter_ebf_debuff:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_hoodwink_sharpshooter_ebf_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}

	return funcs
end

function modifier_hoodwink_sharpshooter_ebf_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_hoodwink_sharpshooter_ebf_debuff:CheckState()
	local state = {
		[MODIFIER_STATE_PASSIVES_DISABLED] = true,
	}

	return state
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_hoodwink_sharpshooter_ebf_debuff:PlayEffects( direction )
	-- NOTE: Particle doesn't appear, don't know why

	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_hoodwink/hoodwink_sharpshooter_debuff.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, self.parent )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		self.parent,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		self.parent:GetOrigin(), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControlForward( effect_cast, 1, direction )

	-- buff particle
	self:AddParticle(
		effect_cast,
		false, -- bDestroyImmediately
		false, -- bStatusEffect
		-1, -- iPriority
		false, -- bHeroEffect
		false -- bOverheadEffect
	)
end