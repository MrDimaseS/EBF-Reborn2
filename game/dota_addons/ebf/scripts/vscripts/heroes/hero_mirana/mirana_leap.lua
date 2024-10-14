mirana_leap = class({})

function mirana_leap:IsStealable()
	return true
end

function mirana_leap:IsHiddenWhenStolen()
	return false
end

function mirana_leap:GetCastRange(target, position)
	return self:GetSpecialValueFor("leap_distance")
end

function mirana_leap:GetVectorTargetRange()
	return math.max( self:GetSpecialValueFor("leap_distance"), self:GetSpecialValueFor("blast_projectile_distance") )
end

function mirana_leap:GetBehavior()
	local baseBehavior = tonumber(tostring(self.BaseClass.GetBehavior( self )))
	if self:GetAltCastState() then
		return baseBehavior + DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_VECTOR_TARGETING
	else
		return baseBehavior + DOTA_ABILITY_BEHAVIOR_NO_TARGET
	end
end

function mirana_leap:OnVectorCastStart( vPos, vDir )
	local caster = self:GetCaster()
	local direction = self:GetForwardVector()
	
	local distance = self:GetSpecialValueFor("leap_distance")
	if self:GetAltCastState() then
		direction = CalculateDirection( self:GetCursorPosition(), caster )
		distance = CalculateDistance( self:GetCursorPosition(), caster )
		caster:SetForwardVector( self:GetVectorDirection() )
	end
	
	EmitSoundOn("Ability.Leap", caster)
	caster:AddNewModifier(caster, self, "modifier_mirana_leap_movement", {duration = distance/self:GetSpecialValueFor("leap_speed")+0.1, distance = distance, x = direction.x, y = direction.y})
end

function mirana_leap:OnSpellStart()
	self:OnVectorCastStart()
end

function mirana_leap:OnProjectileHit( target, position )
	local caster = self:GetCaster()
	if target then
		local damage = self:GetSpecialValueFor("blast_damage")
		local blast_slow_duration = self:GetSpecialValueFor("blast_slow_duration")
		self:DealDamage( caster, target, damage, {damage_type = DAMAGE_TYPE_MAGICAL} )
		target:AddNewModifier( caster, self, "modifier_mirana_leap_debuff", {duration = blast_slow_duration} )
	end
end

modifier_mirana_leap_movement = class({})
LinkLuaModifier("modifier_mirana_leap_movement", "heroes/hero_mirana/mirana_leap", LUA_MODIFIER_MOTION_NONE)

if IsServer() then
	function modifier_mirana_leap_movement:OnCreated( params )
		local parent = self:GetParent()
		self.distance = params.distance
		self.speed = self:GetSpecialValueFor("leap_speed") * FrameTime()
		self.direction = Vector( params.x, params.y, 0 )
		self.initHeight = GetGroundHeight(parent:GetAbsOrigin(), parent)
		self.height = self.initHeight
		self.maxHeight = 250
		self:StartMotionController()
	end
	
	function modifier_mirana_leap_movement:OnDestroy()
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local parentPos = parent:GetAbsOrigin()
		FindClearSpaceForUnit(parent, parentPos, true)
		self:StopMotionController()

		parent:AddNewModifier(parent, ability, "modifier_mirana_leap_buff", {Duration = self:GetSpecialValueFor("leap_bonus_duration")})
		parent:FaceTowards( parent:GetAbsOrigin() + parent:GetForwardVector() + 150 )
		
		local blast_radius = self:GetSpecialValueFor("blast_radius")
		if blast_radius > 0 then
			local blast_radius_end = self:GetSpecialValueFor("blast_radius_end")
			local blast_projectile_distance = self:GetSpecialValueFor("blast_projectile_distance")
			local blast_projectile_speed = self:GetSpecialValueFor("blast_projectile_speed")
			
			ability:FireLinearProjectile("particles/units/heroes/hero_mirana/mirana_shard_leap_cone.vpcf", parent:GetForwardVector() * blast_projectile_speed, blast_projectile_distance, blast_radius, {width_end = blast_radius_end})
		end
	end
	
	function modifier_mirana_leap_movement:DoControlledMotion()
		if self:GetParent():IsNull() then return end
		local parent = self:GetParent()
		self.distanceTraveled =  self.distanceTraveled or 0
		if parent:IsAlive() and self.distanceTraveled < self.distance then
			local newPos = GetGroundPosition(parent:GetAbsOrigin(), parent) + self.direction * self.speed
			newPos.z = self.height + self.maxHeight * math.sin( (self.distanceTraveled/self.distance) * math.pi )
			parent:SetAbsOrigin( newPos )
			
			self.distanceTraveled = self.distanceTraveled + self.speed
		else
			FindClearSpaceForUnit(parent, parent:GetAbsOrigin(), true)
			self:Destroy()
			return nil
		end       
	end
end

function modifier_mirana_leap_movement:CheckState()
	return {[MODIFIER_STATE_ROOTED] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true}
end

function modifier_mirana_leap_movement:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION, MODIFIER_PROPERTY_DISABLE_TURNING }
end

function modifier_mirana_leap_movement:GetOverrideAnimation()
	return ACT_DOTA_FLAIL
end

function modifier_mirana_leap_movement:GetModifierDisableTurning()
	return 1
end

function modifier_mirana_leap_movement:GetEffectName()
	return "particles/units/heroes/hero_mirana/mirana_leap_trail.vpcf"
end

function modifier_mirana_leap_movement:IsHidden()
	return true
end

modifier_mirana_leap_buff = class({})
LinkLuaModifier("modifier_mirana_leap_buff", "heroes/hero_mirana/mirana_leap", LUA_MODIFIER_MOTION_NONE)

function modifier_mirana_leap_buff:OnCreated(table)
	self:OnRefresh()
end

function modifier_mirana_leap_buff:OnRefresh(table)
	self.leap_speedbonus_as = self:GetSpecialValueFor("leap_speedbonus_as")
	self.leap_speedbonus = self:GetSpecialValueFor("leap_speedbonus")
end

function modifier_mirana_leap_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_mirana_leap_buff:GetModifierAttackSpeedBonus_Constant()
	return self.leap_speedbonus_as
end

function modifier_mirana_leap_buff:GetModifierMoveSpeedBonus_Percentage()
	return self.leap_speedbonus
end

modifier_mirana_leap_debuff = class({})
LinkLuaModifier("modifier_mirana_leap_debuff", "heroes/hero_mirana/mirana_leap", LUA_MODIFIER_MOTION_NONE)
function modifier_mirana_leap_debuff:OnCreated(table)
	self:OnRefresh()
end

function modifier_mirana_leap_debuff:OnRefresh(table)
	self.blast_slow_pct = self:GetSpecialValueFor("blast_slow_pct")
end

function modifier_mirana_leap_debuff:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_mirana_leap_debuff:GetModifierMoveSpeedBonus_Percentage()
	return -self.blast_slow_pct
end