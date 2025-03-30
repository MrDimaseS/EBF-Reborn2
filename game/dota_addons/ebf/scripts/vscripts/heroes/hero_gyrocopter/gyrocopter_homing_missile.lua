gyrocopter_homing_missile = class({})

function gyrocopter_homing_missile:GetBehavior()
	if self:GetCaster():HasModifier("modifier_gyrocopter_flight_of_the_valkyrie_active") then
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET
	else
		return self.BaseClass.GetBehavior( self )
	end
end

function gyrocopter_homing_missile:OnSpellStart()
	local caster = self:GetCaster()
	
	
	if not caster:HasModifier("modifier_gyrocopter_flight_of_the_valkyrie_active") then
		local target = self:GetCursorTarget() 
		self:LaunchHomingMissile( target )
	else
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self:GetTrueCastRange() ) ) do
			self:LaunchHomingMissile( enemy )
		end
	end
end


function gyrocopter_homing_missile:LaunchHomingMissile( target )
	local caster = self:GetCaster()
	local homingMissile = CreateUnitByName("npc_dota_gyrocopter_homing_missile",caster:GetAbsOrigin() + caster:GetForwardVector() * 150 + RandomVector(32),true,caster,caster:GetOwnerEntity(),caster:GetTeam())
	homingMissile.target = target
	homingMissile:SetCoreHealth( self:GetSpecialValueFor("tower_hits_to_kill_tooltip") )
	EmitSoundOn("hero_gyrocopter.HomingMissile",homingMissile)
	homingMissile:AddNewModifier(caster, self, "modifier_gyrocopter_homing_missile_behavior", {})
end

modifier_gyrocopter_homing_missile_behavior = class({})
LinkLuaModifier( "modifier_gyrocopter_homing_missile_behavior", "heroes/hero_gyrocopter/gyrocopter_homing_missile.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_gyrocopter_homing_missile_behavior:OnCreated(kv)
	self.hits_to_kill_tooltip = self:GetSpecialValueFor("hits_to_kill_tooltip")
	self.tower_hits_to_kill_tooltip = self:GetSpecialValueFor("tower_hits_to_kill_tooltip")
	self.hero_damage = self:GetSpecialValueFor("tower_hits_to_kill_tooltip") / self.hits_to_kill_tooltip
	self.stun_duration = self:GetSpecialValueFor("stun_duration")
	self.hit_damage = self:GetSpecialValueFor("hit_damage")
	self.max_distance = self:GetSpecialValueFor("max_distance")
	self.speed = self:GetSpecialValueFor("speed")
	self.acceleration = self:GetSpecialValueFor("acceleration")
	self.pre_flight_time = self:GetSpecialValueFor("pre_flight_time")
	self.barrage_delay = self:GetSpecialValueFor("barrage_delay")
	self.reduction_duration = self:GetSpecialValueFor("reduction_duration")
	
	
	self:StartIntervalThink( 0 )
	
	if IsServer() then
		self.target = self:GetParent().target
		local parent = self:GetParent()
		self.fuse = ParticleManager:CreateParticle("particles/units/heroes/hero_gyrocopter/gyro_homing_missile_fuse.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent) 
		ParticleManager:SetParticleControlEnt(self.fuse, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(self.fuse, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
		
		local marker = ParticleManager:CreateParticle("particles/units/heroes/hero_gyrocopter/gyro_guided_missile_target.vpcf", PATTACH_OVERHEAD_FOLLOW, self.target)
		self:AddEffect( marker )
	end
end

function modifier_gyrocopter_homing_missile_behavior:OnIntervalThink()
	local homingMissile = self:GetParent()
	local caster = self:GetCaster()
	if IsServer() then
		if self.barrage_delay > 0 and not self.activatedBarrage and self:GetElapsedTime() > self.barrage_delay then
			local rocket_barrage = caster:FindAbilityByName("gyrocopter_rocket_barrage")
			self.activatedBarrage = homingMissile:AddNewModifier( caster, rocket_barrage, "modifier_gyrocopter_rocket_barrage_active", {} )
		end
	end
	if self:GetElapsedTime() < self.pre_flight_time then return end
	self.speed = self.speed + self.acceleration * FrameTime()
	if IsServer() then
		if self.fuse then -- one time cosmetic changes
			ParticleManager:ClearParticle( self.fuse )
			self.fuse = nil
			
			local fire = ParticleManager:CreateParticle("particles/units/heroes/hero_gyrocopter/gyro_guided_missile.vpcf", PATTACH_ABSORIGIN_FOLLOW, homingMissile) 
			ParticleManager:SetParticleControlEnt(fire, 0, homingMissile, PATTACH_POINT_FOLLOW, "attach_hitloc", homingMissile:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(fire, 1, homingMissile, PATTACH_POINT_FOLLOW, "attach_hitloc", homingMissile:GetAbsOrigin(), true)
			self:AddEffect( fire )
			ParticleManager:ReleaseParticleIndex( fire )
			
			homingMissile:RemoveGesture( ACT_DOTA_SPAWN )
			homingMissile:StartGesture( ACT_DOTA_RUN )
			homingMissile:StartGesture( ACT_DOTA_ATTACK_EVENT )
		end
		if IsEntitySafe( self.target ) and self.target:IsAlive() then
			homingMissile:MoveToPosition( self.target:GetAbsOrigin() )
			if CalculateDistance(homingMissile, self.target ) <= self.target :GetPaddedCollisionRadius() + homingMissile:GetCollisionPadding() + 5 and homingMissile:IsAlive() then
				local ability = self:GetAbility()
				local explosion = ParticleManager:CreateParticle("particles/units/heroes/hero_gyrocopter/gyro_guided_missile_explosion.vpcf", PATTACH_POINT_FOLLOW, self.target ) 
				ParticleManager:SetParticleControlEnt(explosion, 1, self.target , PATTACH_POINT_FOLLOW, "attach_hitloc", self.target :GetAbsOrigin(), true)
				
				EmitSoundOn( "Hero_Gyrocopter.HomingMissile.Target", self.target )
				homingMissile:EmitSound( "Hero_Gyrocopter.HomingMissile.Destroy" )
				if self.reduction_duration > 0 then
					self.target:AddNewModifier( caster, ability, "modifier_gyrocopter_homing_missile_afterburner", {duration = self.reduction_duration} )
				end
				ability:Stun(self.target, self.stun_duration)
				ability:DealDamage(caster, self.target, self.hit_damage, {damage_type = DAMAGE_TYPE_MAGICAL}, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE)
				self:Destroy()
			end
		else
			self.target = caster:FindRandomEnemyInRadius(homingMissile:GetAbsOrigin(), -1, {order = FIND_CLOSEST})
			local marker = ParticleManager:CreateParticle("particles/units/heroes/hero_gyrocopter/gyro_guided_missile_target.vpcf", PATTACH_OVERHEAD_FOLLOW, self.target)
			self:AddEffect( marker )
		end
	end
end

function modifier_gyrocopter_homing_missile_behavior:OnRemoved()
	if IsServer() then
		local parent = self:GetParent()
		parent:StopSound("hero_gyrocopter.HomingMissile")
		parent:ForceKill(false)
		parent:AddNoDraw()
	end
end

function modifier_gyrocopter_homing_missile_behavior:CheckState()
	local state = { [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
					[MODIFIER_STATE_MAGIC_IMMUNE] = true,
					[MODIFIER_STATE_UNSELECTABLE] = true,
					[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
					[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
				}
	if not self.pre_flight_time or self:GetElapsedTime() < self.pre_flight_time then
		state[MODIFIER_STATE_ROOTED] = true
	end
	return state
end

function modifier_gyrocopter_homing_missile_behavior:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, MODIFIER_PROPERTY_HEALTHBAR_PIPS, MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE }
end

function modifier_gyrocopter_homing_missile_behavior:GetModifierMoveSpeed_Absolute()
	return self.speed
end

function modifier_gyrocopter_homing_missile_behavior:GetModifierIncomingDamage_Percentage(params)
	local parent = self:GetParent()
	if params.inflictor then
		return -999
	else
		local hp = parent:GetHealth()
		local damage = TernaryOperator( self.hero_damage, params.attacker:IsConsideredHero(), 1 )
		if damage < hp then
			parent:SetHealth( hp - damage )
			return -999
		elseif hp <= damage then
			self:GetParent():StartGesture(ACT_DOTA_DIE)
			parent:Kill(params.inflictor, params.attacker)
		end
	end
end

function modifier_gyrocopter_homing_missile_behavior:GetModifierHealthBarPips(params)
	return self.hits_to_kill_tooltip
end

modifier_gyrocopter_homing_missile_afterburner = class({})
LinkLuaModifier( "modifier_gyrocopter_homing_missile_afterburner", "heroes/hero_gyrocopter/gyrocopter_homing_missile.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_gyrocopter_homing_missile_afterburner:OnCreated()
	self.armor_reduction = self:GetSpecialValueFor("armor_reduction")
end

function modifier_gyrocopter_homing_missile_afterburner:DeclareFunctions()
	return {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end

function modifier_gyrocopter_homing_missile_afterburner:GetModifierPhysicalArmorBonus()
	return -self.armor_reduction
end
