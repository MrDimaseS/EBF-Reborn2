void_spirit_resonant_pulse = class({})

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
	
	caster:RemoveModifierByName("modifier_void_spirit_resonant_pulse_shield")
	
	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("buff_duration")
	local damage = self:GetSpecialValueFor("damage")
	local speed = self:GetSpecialValueFor("speed")
	local returnSpeed = self:GetSpecialValueFor("return_projectile_speed")
	
	local scepter = caster:HasScepter()
	local scepterDuration = self:GetSpecialValueFor("silence_duration_scepter")
	
	local talent = caster:HasTalent("special_bonus_unique_void_spirit_3")
	
	local unitsHit = {}
	local radiusGrowth = speed * 0.1
	local currentRadius = radiusGrowth
	Timers:CreateTimer( 0.1, function()
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), radius ) ) do
			if not unitsHit[enemy:entindex()] then
				unitsHit[enemy:entindex()] = true
				self:DealDamage( caster, enemy, damage )
				EmitSoundOn( "Hero_VoidSpirit.Pulse.Target", caster )
				if enemy:IsConsideredHero() then
					self:FireTrackingProjectile("", caster, returnSpeed)
				end
				if scepter then
					self:Silence(enemy, scepterDuration)
				end
				if talent then
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
	
	local buff = caster:AddNewModifier( caster, self, "modifier_void_spirit_resonant_pulse_shield", {duration = duration} )
end

function void_spirit_resonant_pulse:OnProjectileHit()
	local caster = self:GetCaster()
	local buff = caster:FindModifierByName("modifier_void_spirit_resonant_pulse_shield")
	buff:ForceRefresh()
end

modifier_void_spirit_resonant_pulse_shield = class({})
LinkLuaModifier( "modifier_void_spirit_resonant_pulse_shield", "heroes/hero_void_spirit/void_spirit_resonant_pulse", LUA_MODIFIER_MOTION_NONE )

function modifier_void_spirit_resonant_pulse_shield:OnCreated()
	self.damageBlock = self:GetSpecialValueFor("base_absorb_amount")
	if IsServer() then
		local FX = ParticleManager:CreateParticle( "particles/units/heroes/hero_void_spirit/pulse/void_spirit_pulse_shield.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster() )
		ParticleManager:SetParticleControlEnt( FX, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetCaster():GetAbsOrigin(), true)
		ParticleManager:SetParticleControl( FX, 1, Vector( 128, 128, 128 ) )
		ParticleManager:SetParticleControl( FX, 4, Vector( 128, 128, 128 ) )
		self:AddEffect( FX )
		
		self:SetHasCustomTransmitterData(true)
	end
end

function modifier_void_spirit_resonant_pulse_shield:OnRefresh()
	if not IsServer() then return end
	self.damageBlock = self.damageBlock + self:GetSpecialValueFor("absorb_per_hero_hit")
	self:SendBuffRefreshToClients()
	print("refreshing")
end

function modifier_void_spirit_resonant_pulse_shield:OnDestroy()
	if IsServer() then
		local caster = self:GetCaster()
		EmitSoundOn( "Hero_VoidSpirit.Pulse.Destroy", caster )
	end
end

function modifier_void_spirit_resonant_pulse_shield:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_CONSTANT}
end


function modifier_void_spirit_resonant_pulse_shield:GetModifierIncomingPhysicalDamageConstant( params )
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