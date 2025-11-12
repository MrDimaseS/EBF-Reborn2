void_spirit_resonant_pulse = class({})

function void_spirit_resonant_pulse:GetIntrinsicModifierName()
	return "modifier_void_spirit_resonant_pulse_handler"
end

function void_spirit_resonant_pulse:GetCastRange( target, position )
	return self:GetSpecialValueFor("radius")
end

function void_spirit_resonant_pulse:OnAbilityPhaseStart()
	EmitSoundOn( "Hero_VoidSpirit.Pulse.Cast", self:GetCaster() )
	return true
end

function void_spirit_resonant_pulse:OnAbilityPhaseInterrupted()
	StopSoundOn( "Hero_VoidSpirit.Pulse.Cast", self:GetCaster() )
end

function void_spirit_resonant_pulse:OnSpellStart()
	local caster = self:GetCaster()
	
	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("buff_duration")
	local damage = self:GetSpecialValueFor("damage")
	local speed = self:GetSpecialValueFor("speed")
	local returnSpeed = self:GetSpecialValueFor("return_projectile_speed")
	
	local silenceDuration = self:GetSpecialValueFor("silence_duration")
	local resonantPulseAttacks = self:GetSpecialValueFor("resonant_pulse_attacks") == 1
	
	local unitsHit = {}
	local radiusGrowth = speed * 0.1
	local currentRadius = radiusGrowth
	
	local buff = caster:AddNewModifier( caster, self, "modifier_void_spirit_resonant_pulse_shield", {duration = duration} )
	self._buffProjectiles = self._buffProjectiles or {}
	Timers:CreateTimer( 0.1, function()
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), currentRadius ) ) do
			if not unitsHit[enemy:entindex()] then
				unitsHit[enemy:entindex()] = true
				self:DealDamage( caster, enemy, damage )
				EmitSoundOn( "Hero_VoidSpirit.Pulse.Target", caster )
				if enemy:IsConsideredHero() then
					local projectile = self:FireTrackingProjectile("", caster, returnSpeed)
					self._buffProjectiles[projectile] = buff
				end
				if silenceDuration > 0 then
					self:Silence(enemy, silenceDuration)
				end
				if resonantPulseAttacks then
					caster:PerformGenericAttack(enemy, true)
				end
			end
		end
		if currentRadius < radius then
			currentRadius = currentRadius + radiusGrowth
			return 0.1
		end
	end)
	
	
	ParticleManager:FireParticle( "particles/units/heroes/hero_void_spirit/pulse/void_spirit_pulse.vpcf", PATTACH_POINT_FOLLOW, caster, {[1] = Vector( radius * 2, speed, speed )} )
	EmitSoundOn( "Hero_VoidSpirit.Pulse", caster )
	
end

function void_spirit_resonant_pulse:OnProjectileHitHandle( target, position, projectileID )
	local caster = self:GetCaster()
	local buff = self._buffProjectiles[projectileID]
	if IsModifierSafe( buff ) then
		buff:ForceRefresh()
		self._buffProjectiles[projectileID] = nil
	end
end

modifier_void_spirit_resonant_pulse_handler = class(persistentModifier)
LinkLuaModifier( "modifier_void_spirit_resonant_pulse_handler", "heroes/hero_void_spirit/void_spirit_resonant_pulse", LUA_MODIFIER_MOTION_NONE )

function modifier_void_spirit_resonant_pulse_handler:OnCreated()
	self.cast_cdr = self:GetSpecialValueFor("cast_cdr")
end

function modifier_void_spirit_resonant_pulse_handler:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ABILITY_FULLY_CAST}
end

function modifier_void_spirit_resonant_pulse_handler:OnAbilityFullyCast( params )
	if self.cast_cdr <= 0 then return end
	if params.unit ~= self:GetParent() then return end
	if params.ability:IsItem() then return end
	local ability = self:GetAbility()
	if params.ability == ability then return end
	if ability:IsCooldownReady() then return end
	ability:ModifyCooldown( -self.cast_cdr )
end

modifier_void_spirit_resonant_pulse_shield = class({})
LinkLuaModifier( "modifier_void_spirit_resonant_pulse_shield", "heroes/hero_void_spirit/void_spirit_resonant_pulse", LUA_MODIFIER_MOTION_NONE )

function modifier_void_spirit_resonant_pulse_shield:OnCreated()
	self.damageBlock = self:GetSpecialValueFor("base_absorb_amount")
	self.is_all_barrier = self:GetSpecialValueFor("is_all_barrier") == 1
	self.bonus_attackspeed = self:GetSpecialValueFor("bonus_attackspeed")
	if IsServer() then
		local FX = ParticleManager:CreateParticle( "particles/units/heroes/hero_void_spirit/pulse/void_spirit_pulse_shield.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster() )
		ParticleManager:SetParticleControlEnt( FX, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetCaster():GetAbsOrigin(), true)
		ParticleManager:SetParticleControl( FX, 1, Vector( 128, 128, 128 ) )
		ParticleManager:SetParticleControl( FX, 4, Vector( 128, 128, 128 ) )
		self:AddEffect( FX )
		
		self:SetHasCustomTransmitterData(true)
		self:StartIntervalThink( 0 )
	end
end

function modifier_void_spirit_resonant_pulse_shield:OnIntervalThink()
	local parent = self:GetParent()
	if parent:IsInvulnerable() or parent:IsOutOfGame() then
		self:SetDuration( self:GetRemainingTime() + FrameTime(), true )
	end
end

function modifier_void_spirit_resonant_pulse_shield:OnRefresh()
	if not IsServer() then return end
	self.damageBlock = self.damageBlock + self:GetSpecialValueFor("absorb_per_hero_hit")
	self:SendBuffRefreshToClients()
end

function modifier_void_spirit_resonant_pulse_shield:OnDestroy()
	if IsServer() then
		local caster = self:GetCaster()
		EmitSoundOn( "Hero_VoidSpirit.Pulse.Destroy", caster )
	end
end

function modifier_void_spirit_resonant_pulse_shield:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
			MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_CONSTANT,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT}
end

function modifier_void_spirit_resonant_pulse_shield:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attackspeed
end

function modifier_void_spirit_resonant_pulse_shield:GetModifierIncomingPhysicalDamageConstant( params )
	if self.is_all_barrier then return end
	if IsServer() then
		local barrier = math.min( self.damageBlock, math.max( self.damageBlock, params.damage ) )
		self.damageBlock = self.damageBlock - params.damage
		self:SendBuffRefreshToClients()
		EmitSoundOn( "Hero_Antimage.Counterspell.Absorb", self:GetParent() )
		if self.damageBlock <= 0 then self:Destroy() end
		return -barrier
	else
		return self.damageBlock
	end
end

function modifier_void_spirit_resonant_pulse_shield:GetModifierIncomingDamageConstant( params )
	if not self.is_all_barrier then return end
	if IsServer() then
		local barrier = math.min( self.damageBlock, math.max( self.damageBlock, params.damage ) )
		self.damageBlock = self.damageBlock - params.damage
		self:SendBuffRefreshToClients()
		EmitSoundOn( "Hero_Antimage.Counterspell.Absorb", self:GetParent() )
		if self.damageBlock <= 0 then self:Destroy() end
		return -barrier
	else
		return self.damageBlock
	end
end

function modifier_void_spirit_resonant_pulse_shield:AddCustomTransmitterData()
	return {damageBlock = self.damageBlock}
end

function modifier_void_spirit_resonant_pulse_shield:HandleCustomTransmitterData(data)
	self.damageBlock = data.damageBlock
end

function modifier_void_spirit_resonant_pulse_shield:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE 
end