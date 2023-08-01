primal_beast_uproar = class({})
LinkLuaModifier( "modifier_primal_beast_uproar_ebf", "heroes/hero_primal_beast/primal_beast_uproar", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_primal_beast_uproar_ebf_buff", "heroes/hero_primal_beast/primal_beast_uproar", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_primal_beast_uproar_ebf_debuff", "heroes/hero_primal_beast/primal_beast_uproar", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Init Abilities
function primal_beast_uproar:Precache( context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_primal_beast.vsndevts", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_primal_beast/primal_beast_uproar_magic_resist.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_primal_beast/primal_beast_status_effect_slow.vpcf", context )
end

function primal_beast_uproar:Spawn()
	if not IsServer() then return end
end

--------------------------------------------------------------------------------
-- Custom KV
function primal_beast_uproar:GetBehavior()
	if self:GetCaster():GetModifierStackCount( "modifier_primal_beast_uproar_ebf", self:GetCaster() ) < 1 then
		return DOTA_ABILITY_BEHAVIOR_PASSIVE
	end

	return DOTA_ABILITY_BEHAVIOR_NO_TARGET
end

function primal_beast_uproar:GetAbilityTextureName(  )
	local stack = self:GetCaster():GetModifierStackCount( "modifier_primal_beast_uproar_ebf", self:GetCaster() )
	if stack==0 then
		return "primal_beast_uproar_none"
	elseif stack== self:GetSpecialValueFor("stack_limit") then
		return "primal_beast_uproar_max"
	else
		return "primal_beast_uproar_mid"
	end
end

function primal_beast_uproar:IsRefreshable()
	return false
end

--------------------------------------------------------------------------------
-- Passive Modifier
function primal_beast_uproar:GetIntrinsicModifierName()
	return "modifier_primal_beast_uproar_ebf"
end

--------------------------------------------------------------------------------
-- Ability Cast Filter
function primal_beast_uproar:CastFilterResult()
	if self:GetCaster():GetModifierStackCount( "modifier_primal_beast_uproar_ebf", self:GetCaster() )<1 then
		return UF_FAIL_CUSTOM
	end

	return UF_SUCCESS
end

function primal_beast_uproar:GetCustomCastError( hTarget )
	if self:GetCaster():GetModifierStackCount( "modifier_primal_beast_uproar_ebf", self:GetCaster() )<1 then
		return "#dota_error_no_uproar_stack"
	end

	return ""
end

--------------------------------------------------------------------------------
-- Ability Start
function primal_beast_uproar:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()

	-- load data
	local duration = self:GetSpecialValueFor( "roar_duration" )
	local radius = self:GetSpecialValueFor( "radius" )
	local slow = self:GetSpecialValueFor( "slow_duration" )

	-- find modifier
	local stack = 0
	local modifier = caster:FindModifierByName( "modifier_primal_beast_uproar_ebf" )
	if modifier then
		stack = modifier:GetStackCount()
		modifier:ResetStack()
	end

	-- add buff
	caster:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_primal_beast_uproar_ebf_buff", -- modifier name
		{
			duration = duration,
			stack = stack,
		} -- kv
	)

	if caster:HasTalent("special_bonus_unique_primal_beast_roar_dispells") then
		caster:Dispel(caster, true)
		local magicImmune = caster:AddNewModifier( caster, self, "modifier_magic_immune", {duration = stack} )
		
		local FX = ParticleManager:CreateParticle( "particles/items_fx/black_king_bar_avatar.vpcf", PATTACH_POINT_FOLLOW, caster )
		magicImmune:AddEffect( FX )
	end
	
	-- find enemies
	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),	-- int, your team number
		caster:GetOrigin(),	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		0,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)

	for _,enemy in pairs(enemies) do
		enemy:AddNewModifier(
			caster, -- player source
			self, -- ability source
			"modifier_primal_beast_uproar_ebf_debuff", -- modifier name
			{
				duration = slow,
				stack = stack,
			} -- kv
		)
	end

	-- cooldown
	self:StartCooldown( duration )

	-- effects
	self:PlayEffects( radius )
	self:PlayEffects2()
	
	if caster:HasScepter() then
		local waves = self:GetTalentSpecialValueFor("projectile_waves")
		local projectiles = self:GetTalentSpecialValueFor("projectiles_per_stack") * stack
		local angle = 360 / projectiles
		local direction = caster:GetLeftVector()
		local interval = duration / waves
		
		Timers:CreateTimer( function()
			for i = 1, projectiles do
				local localDir = RotateVector2D( direction, ToRadians(angle)*(i-1) )
				self:FireUproarProjectile( localDir )
			end
			waves = waves - 1
			if waves > 0 then
				return interval
			end
		end)
	end
end

function primal_beast_uproar:OnProjectileHitHandle( target, position, projectile )
	local caster = self:GetCaster()
	if target then
		self:DealDamage( caster, target, self:GetSpecialValueFor("projectile_damage") )
		target:AddNewModifier( caster, self, "modifier_break", {duration = self:GetSpecialValueFor("projectile_break_duration")} )
	elseif not self.projectiles[projectile].secondProjectile then -- end of first projectile
		local waves = self:GetTalentSpecialValueFor("max_split_amount")
		local angle = self:GetTalentSpecialValueFor("splinter_angle")
		
		for i = 1, waves do
			local localDir = RotateVector2D( self.projectiles[projectile].direction, ToRadians( angle ) * (-1)^i * math.ceil( i / 2 ) )
			self:FireUproarProjectile( localDir, position )
		end
		
		-- clean table
		self.projectiles[projectile] = nil
	end
end

function primal_beast_uproar:FireUproarProjectile( direction, position )
	local caster = self:GetCaster() 
	
	local projectileSpeed = self:GetTalentSpecialValueFor("projectile_speed")
	local projectileWidth = self:GetTalentSpecialValueFor("projectile_width")
	local projectileDistance = self:GetTalentSpecialValueFor("projectile_distance")
		
	self.projectiles = self.projectiles or {}
	local projectile = self:FireLinearProjectile("", direction * projectileSpeed, projectileDistance, projectileWidth, {origin = position} )
	self.projectiles[projectile] = {secondProjectile = position ~= nil, direction = direction}
	
	ParticleManager:FireParticle("particles/units/heroes/hero_primal_beast/primal_beast_pulverize_tectonic_shift_projectile.vpcf", PATTACH_WORLDORIGIN, nil, {[0] = position or caster:GetAbsOrigin(), [1] = direction * projectileSpeed, [3] = Vector( 0, projectileDistance/ projectileSpeed, 0 )} )
end

--------------------------------------------------------------------------------
-- Effects
function primal_beast_uproar:PlayEffects( radius )
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_primal_beast/primal_beast_roar_aoe.vpcf"
	local sound_cast = "Hero_PrimalBeast.Uproar.Cast"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( radius, radius, radius ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOn( sound_cast, self:GetCaster() )
end

function primal_beast_uproar:PlayEffects2()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_primal_beast/primal_beast_roar.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, self:GetCaster() )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		self:GetCaster(),
		PATTACH_POINT_FOLLOW,
		"attach_jaw_fx",
		Vector(0,0,0), -- unknown
		true -- unknown, true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )
end

modifier_primal_beast_uproar_ebf = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_primal_beast_uproar_ebf:IsHidden()
	return self:GetStackCount()<1
end

function modifier_primal_beast_uproar_ebf:IsDebuff()
	return false
end

function modifier_primal_beast_uproar_ebf:IsPurgable()
	return false
end

-- Optional Classifications
function modifier_primal_beast_uproar_ebf:RemoveOnDeath()
	return false
end

function modifier_primal_beast_uproar_ebf:DestroyOnExpire()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_primal_beast_uproar_ebf:OnCreated( kv )
	self.parent = self:GetParent()

	-- references
	self.damage_limit = self:GetAbility():GetSpecialValueFor( "damage_limit" ) / 100
	self.stack_limit = self:GetAbility():GetSpecialValueFor( "stack_limit" )
	self.duration = self:GetAbility():GetSpecialValueFor( "stack_duration" )
	self.damage = self:GetAbility():GetSpecialValueFor( "bonus_damage" )

	if not IsServer() then return end
end

function modifier_primal_beast_uproar_ebf:OnRefresh( kv )
	-- references
	self.damage_limit = self:GetAbility():GetSpecialValueFor( "damage_limit" ) / 100
	self.stack_limit = self:GetAbility():GetSpecialValueFor( "stack_limit" )
	self.duration = self:GetAbility():GetSpecialValueFor( "stack_duration" )	
	self.damage = self:GetAbility():GetSpecialValueFor( "bonus_damage" )
end

function modifier_primal_beast_uproar_ebf:OnRemoved()
end

function modifier_primal_beast_uproar_ebf:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_primal_beast_uproar_ebf:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}

	return funcs
end

function modifier_primal_beast_uproar_ebf:OnTakeDamage( params )
	if self.parent:PassivesDisabled() then return end
	if self.parent:HasModifier( "modifier_primal_beast_uproar_ebf_buff" ) or not self:GetAbility():IsCooldownReady() then return end

	if params.unit~=self.parent then return end
	
	self.totalDamageTaken = (self.totalDamageTaken or 0) + params.damage
	if self.totalDamageTaken <= self:GetParent():GetMaxHealth() * self.damage_limit then return end
	self.totalDamageTaken = 0
	-- increment stack, refresh duration
	if self:GetStackCount()<self.stack_limit then
		self:IncrementStackCount()

		-- roar
		if self:GetStackCount()==self.stack_limit then
			EmitSoundOn( "Hero_PrimalBeast.Uproar.MaxStacks", self.parent )
		end
	end
	self:SetDuration( self.duration, true )
	self:StartIntervalThink(self.duration)
end

function modifier_primal_beast_uproar_ebf:GetModifierPreAttack_BonusDamage()
	return self.damage
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_primal_beast_uproar_ebf:OnIntervalThink()
	self:ResetStack()
end

--------------------------------------------------------------------------------
-- Helper
function modifier_primal_beast_uproar_ebf:ResetStack()
	self:SetStackCount(0)
end

modifier_primal_beast_uproar_ebf_buff = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_primal_beast_uproar_ebf_buff:IsHidden()
	return false
end

function modifier_primal_beast_uproar_ebf_buff:IsDebuff()
	return false
end

function modifier_primal_beast_uproar_ebf_buff:IsPurgable()
	return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_primal_beast_uproar_ebf_buff:OnCreated( kv )
	-- references
	self.damage = self:GetAbility():GetSpecialValueFor( "bonus_damage_per_stack" )
	self.armor = self:GetAbility():GetSpecialValueFor( "roared_bonus_armor" )

	if not IsServer() then return end
	self.stack = kv.stack

	-- send init data from server to client
	self:SetHasCustomTransmitterData( true )

	self:PlayEffects()
end

function modifier_primal_beast_uproar_ebf_buff:OnRefresh( kv )
	-- references
	self.damage = self:GetAbility():GetSpecialValueFor( "bonus_damage_per_stack" )
	self.armor = self:GetAbility():GetSpecialValueFor( "roared_bonus_armor" )

	if not IsServer() then return end
	self.stack = kv.stack	
end

function modifier_primal_beast_uproar_ebf_buff:OnRemoved()
end

function modifier_primal_beast_uproar_ebf_buff:OnDestroy()
end

--------------------------------------------------------------------------------
-- Transmitter data
function modifier_primal_beast_uproar_ebf_buff:AddCustomTransmitterData()
	-- on server
	local data = {
		stack = self.stack
	}

	return data
end

function modifier_primal_beast_uproar_ebf_buff:HandleCustomTransmitterData( data )
	-- on client
	self.stack = data.stack
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_primal_beast_uproar_ebf_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}

	return funcs
end

function modifier_primal_beast_uproar_ebf_buff:GetModifierPreAttack_BonusDamage()
	return self.damage * self.stack
end
function modifier_primal_beast_uproar_ebf_buff:GetModifierPhysicalArmorBonus()
	return self.armor * self.stack
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_primal_beast_uproar_ebf_buff:PlayEffects()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_primal_beast/primal_beast_uproar_magic_resist.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_OVERHEAD_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		2,
		self:GetParent(),
		PATTACH_OVERHEAD_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0), -- unknown
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
end	

modifier_primal_beast_uproar_ebf_debuff = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_primal_beast_uproar_ebf_debuff:IsHidden()
	return false
end

function modifier_primal_beast_uproar_ebf_debuff:IsDebuff()
	return true
end

function modifier_primal_beast_uproar_ebf_debuff:IsPurgable()
	return true
end

function modifier_primal_beast_uproar_ebf_debuff:GetTexture()
	return "primal_beast_uproar"
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_primal_beast_uproar_ebf_debuff:OnCreated( kv )
	-- references
	self.slow = -self:GetAbility():GetSpecialValueFor( "move_slow_per_stack" )

	if not IsServer() then return end
	self.stack = kv.stack
	self:SetStackCount(self.stack)

	-- send init data from server to client
	self:SetHasCustomTransmitterData( true )
end

function modifier_primal_beast_uproar_ebf_debuff:OnRefresh( kv )
	-- references
	self.slow = -self:GetAbility():GetSpecialValueFor( "move_slow_per_stack" )

	if not IsServer() then return end
	self.stack = kv.stack	
end

function modifier_primal_beast_uproar_ebf_debuff:OnRemoved()
end

function modifier_primal_beast_uproar_ebf_debuff:OnDestroy()
end

--------------------------------------------------------------------------------
-- Transmitter data
function modifier_primal_beast_uproar_ebf_debuff:AddCustomTransmitterData()
	-- on server
	local data = {
		stack = self.stack
	}

	return data
end

function modifier_primal_beast_uproar_ebf_debuff:HandleCustomTransmitterData( data )
	-- on client
	self.stack = data.stack
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_primal_beast_uproar_ebf_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}

	return funcs
end

function modifier_primal_beast_uproar_ebf_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.slow * self.stack
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_primal_beast_uproar_ebf_debuff:GetStatusEffectName()
	return "particles/units/heroes/hero_primal_beast/primal_beast_status_effect_slow.vpcf"
end

function modifier_primal_beast_uproar_ebf_debuff:StatusEffectPriority()
	return MODIFIER_PRIORITY_NORMAL
end