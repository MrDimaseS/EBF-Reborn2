earth_spirit_rolling_boulder = class({})

function earth_spirit_rolling_boulder:IsStealable()
	return true
end

function earth_spirit_rolling_boulder:IsHiddenWhenStolen()
	return false
end

function earth_spirit_rolling_boulder:OnSpellStart()
    local caster = self:GetCaster()
	
	local distance = self:GetSpecialValueFor("distance")
	local remnantDistance = self:GetSpecialValueFor("remnant_distance")
	local speed = self:GetSpecialValueFor("speed")
	local duration = ( remnantDistance / speed ) + 0.1
	
    caster:AddNewModifier( caster, self, "modifier_earth_spirit_boulder", {duration = 10})
	caster:StartGesture( ACT_DOTA_CAST_ABILITY_2_ES_ROLL_START )
    EmitSoundOn("Hero_EarthSpirit.RollingBoulder.Cast", caster)
end

modifier_earth_spirit_boulder = class({})
LinkLuaModifier( "modifier_earth_spirit_boulder", "heroes/hero_earth_spirit/earth_spirit_rolling_boulder.lua" ,LUA_MODIFIER_MOTION_NONE )


function modifier_earth_spirit_boulder:OnCreated(table)
	if IsServer() then
		local caster = self:GetCaster()
		local target = self:GetParent()
		self.delay = self:GetSpecialValueFor("delay")
		self.direction = CalculateDirection( self:GetAbility():GetCursorPosition(), caster )
		self.radius = self:GetSpecialValueFor("radius") + caster:GetHullRadius() + caster:GetCollisionPadding()
		
		self.baseDuration = self:GetSpecialValueFor("stun_duration")
		self.duration = self.baseDuration
		self.baseDamage = self:GetSpecialValueFor("damage")
		self.damage = self.baseDamage
		self.baseDistance = self:GetSpecialValueFor("distance")
		self.distance = self.baseDistance
		self.baseSpeed = self:GetSpecialValueFor("speed")
		self.speed = self.baseSpeed
		
		self.remnantBonus = self:GetSpecialValueFor("rock_bonus_value") / 100
		self.creep_multiplier = self:GetSpecialValueFor("creep_multiplier")
		
		self.nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_earth_spirit/espirit_geomagentic_target_sphere.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControlForward( self.nfx, 3, CalculateDirection(self:GetParent(), self:GetCaster() ) )
		self:AddEffect( self.nfx )
		self.hitTable = {}
		self.remnantHit = false
		if IsServer() then
			self:StartIntervalThink( self.delay )
		end
	end
end

function modifier_earth_spirit_boulder:OnIntervalThink( )
	self:StartMotionController()
	self:StartIntervalThink( -1 )
end

function modifier_earth_spirit_boulder:OnDestroy()
	if IsServer() then
		self:GetParent():StartGesture( ACT_DOTA_CAST_ABILITY_2_ES_ROLL_END )
	end
end

function modifier_earth_spirit_boulder:DoControlledMotion()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	
	local stones = caster:FindFriendlyUnitsInRadius(caster:GetAbsOrigin(), self.radius, {type = DOTA_UNIT_TARGET_ALL, flag = DOTA_UNIT_TARGET_FLAG_INVULNERABLE })
    for _,stone in ipairs(stones) do
    	if stone:GetName() == "npc_dota_earth_spirit_stone" then
			EmitSoundOn("Hero_EarthSpirit.RollingBoulder.Stone", stone)
			stone:ForceKill(false)
			self.distance = self.distance + self.baseDistance * self.remnantBonus
			self.speed = math.min( self.baseSpeed*2, self.speed + self.baseSpeed * self.remnantBonus )
			self.duration = self.duration + self.baseDuration * self.remnantBonus
			self.damage = self.damage + self.baseDamage * self.remnantBonus
    	end
    end
	
	local enemies = caster:FindEnemyUnitsInRadius(caster:GetAbsOrigin(), self.radius)
	for _,enemy in ipairs(enemies) do
		if not self.hitTable[enemy] then
			EmitSoundOn("Hero_EarthSpirit.RollingBoulder.Target", enemy)
			ability:Stun(enemy, self.duration)
			ability:DealDamage( caster, enemy, TernaryOperator( self.damage, enemy:IsConsideredHero(), self.damage * self.creep_multiplier ) )
			EmitSoundOn("Hero_EarthSpirit.RollingBoulder.Damage", enemy)
			self.hitTable[enemy] = true
			-- Magnetized effects
			for _, echo in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), -1 ) ) do
				if enemy ~= target and echo:HasModifier("modifier_earth_spirit_magnetize_effect") then
					ability:Stun(echo, self.duration)
					ability:DealDamage( caster, echo, TernaryOperator( self.damage, echo:IsConsideredHero(), self.damage * self.creep_multiplier ) )
					EmitSoundOn("Hero_EarthSpirit.RollingBoulder.Damage", echo)
					self.hitTable[echo] = true
				end
			end
		end
	end
	
	if caster:IsStunned() or caster:IsRooted() or self.distance <= 0 then
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		self:Destroy()
	else
		self.distance = self.distance - self.speed * FrameTime()
		caster:SetAbsOrigin( GetGroundPosition( caster:GetAbsOrigin() + self.direction * self.speed * FrameTime(), caster ) )
	end
end

function modifier_earth_spirit_boulder:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ORDER, MODIFIER_PROPERTY_OVERRIDE_ANIMATION, MODIFIER_PROPERTY_IGNORE_CAST_ANGLE}
end

function modifier_earth_spirit_boulder:CheckState()
	return {[MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS] = true}
end

function modifier_earth_spirit_boulder:OnOrder( params )
	if params.unit == self:GetParent() then
		if params.order_type == DOTA_UNIT_ORDER_STOP or params.order_type == DOTA_UNIT_ORDER_HOLD_POSITION then
			FindClearSpaceForUnit(params.unit, params.unit:GetAbsOrigin(), true)
			self:Destroy()
		end
	end
end

function modifier_earth_spirit_boulder:GetModifierIgnoreCastAngle()
	return 1
end

function modifier_earth_spirit_boulder:GetOverrideAnimation()
	return ACT_DOTA_CAST_ABILITY_2_ES_ROLL
end

function modifier_earth_spirit_boulder:GetEffectName()
	return "particles/units/heroes/hero_earth_spirit/espirit_rollingboulder.vpcf"
end