slark_pounce = class({})

function slark_pounce:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_slark_pounce_movement", {duration = self:GetSpecialValueFor( "pounce_distance" ) / self:GetSpecialValueFor( "pounce_speed")})
	EmitSoundOn( "Hero_Slark.Pounce.Cast", caster )
end

modifier_slark_pounce_movement = class({})
LinkLuaModifier("modifier_slark_pounce_movement", "heroes/hero_slark/slark_pounce", LUA_MODIFIER_MOTION_NONE)
if IsServer() then
	function modifier_slark_pounce_movement:OnCreated()
		local parent = self:GetParent()
		self.endPos = self:GetAbility():GetCursorPosition()
		self.direction = parent:GetForwardVector()
		
		self.distance = self:GetTalentSpecialValueFor("pounce_distance")
		self.speed = self:GetTalentSpecialValueFor("pounce_speed") * FrameTime()
		self.initHeight = GetGroundHeight(parent:GetAbsOrigin(), parent)
		self.height = self.initHeight
		self.maxHeight = 125
		
		self.radius = self:GetTalentSpecialValueFor("pounce_radius")
		self.damage = self:GetTalentSpecialValueFor("pounce_damage")
		self.duration = self:GetTalentSpecialValueFor("leash_duration")
		
		self.enemiesHit = {}
		parent:StartGesture( ACT_DOTA_SLARK_POUNCE )
		self:StartMotionController()
	end
	
	
	function modifier_slark_pounce_movement:OnDestroy()
		local parent = self:GetParent()
		local parentPos = parent:GetAbsOrigin()
		ResolveNPCPositions(parentPos, parent:GetHullRadius() + parent:GetCollisionPadding())
		GridNav:DestroyTreesAroundPoint(parentPos, parent:GetHullRadius() + parent:GetCollisionPadding(), true)
		self:StopMotionController()
	end
	
	function modifier_slark_pounce_movement:DoControlledMotion()
		if self:GetParent():IsNull() then return end
		local parent = self:GetParent()
		self.distanceTraveled =  self.distanceTraveled or 0
		
		if parent:IsAlive() and self.distanceTraveled < self.distance then
			local newPos = GetGroundPosition(parent:GetAbsOrigin(), parent) + self.direction * self.speed
			newPos.z = self.height + self.maxHeight * math.sin( (self.distanceTraveled/self.distance) * math.pi )
			parent:SetAbsOrigin( newPos )
			
			self.distanceTraveled = self.distanceTraveled + self.speed
		else
			parent:SetAbsOrigin( GetGroundPosition(parent:GetAbsOrigin(), parent) + self.direction * self.speed )
			self:Destroy()
			return
		end
		local heroHit = false
		for _, enemy in ipairs( parent:FindEnemyUnitsInRadius( parent:GetAbsOrigin() + parent:GetForwardVector() * self.radius, self.radius ) ) do
			if not self.enemiesHit[enemy:entindex()] then
				self:Pounce(enemy)
				self.enemiesHit[enemy:entindex()] = true
				if enemy:IsConsideredHero() then heroHit = true end
			end
		end
		if heroHit then
			self:Destroy()
		end
	end
	
	function modifier_slark_pounce_movement:Pounce(target)
		local caster = self:GetParent()
		local ability = self:GetAbility()
		
		ability:DealDamage(caster, target, self.damage)
		target:AddNewModifier( caster, ability, "modifier_slark_pounce_debuff", {duration = self.duration} )
		caster:PerformGenericAttack( target, true )
		
		EmitSoundOn("Hero_Slark.Pounce.Impact", target)
	end
end

function modifier_slark_pounce_movement:GetEffectName()
	return "particles/units/heroes/hero_slark/slark_pounce_trail.vpcf"
end

function modifier_slark_pounce_movement:CheckState()
	return {[MODIFIER_STATE_STUNNED] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true}
end

function modifier_slark_pounce_movement:IsHidden()
	return true
end

modifier_slark_pounce_debuff = class({})
LinkLuaModifier( "modifier_slark_pounce_debuff", "heroes/hero_slark/slark_pounce", LUA_MODIFIER_MOTION_NONE )

function modifier_slark_pounce_debuff:OnCreated( kv )
	self:OnRefresh()
	if not IsServer() then return end
	-- play effects
	if self:GetParent():IsConsideredHero() then self:PlayEffects1() end
	self:PlayEffects2()
end

function modifier_slark_pounce_debuff:OnRefresh( kv )
	self.slow = self:GetSpecialValueFor("leash_slow")
end

function modifier_slark_pounce_debuff:OnDestroy()
	if not IsServer() then return end
	StopSoundOn( "Hero_Slark.Pounce.Leash", self:GetParent() )
	EmitSoundOn( "Hero_Slark.Pounce.End", self:GetParent() )
end

function modifier_slark_pounce_debuff:GetStatusEffectName()
	return "particles/status_fx/status_effect_frost.vpcf"
end

function modifier_slark_pounce_debuff:StatusEffectPriority()
	return MODIFIER_PRIORITY_NORMAL
end

function modifier_slark_pounce_debuff:PlayEffects1()
	local caster = self:GetCaster()
	local parent = self:GetParent()

	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_slark/slark_pounce_ground.vpcf", PATTACH_WORLDORIGIN, caster )
	ParticleManager:SetParticleControlEnt( effect_cast, 0, caster, PATTACH_WORLDORIGIN, "attach_hitloc", Vector(0,0,0), true)
	ParticleManager:SetParticleControl( effect_cast, 3, caster:GetOrigin() )
	ParticleManager:SetParticleControl( effect_cast, 4, Vector( 325, 0, 0 ) )
	self:AddEffect( effect_cast )
	
	EmitSoundOn( "Hero_Slark.Pounce.Leash", parent )
end

function modifier_slark_pounce_debuff:PlayEffects2()
	local caster = self:GetCaster()
	local parent = self:GetParent()

	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_slark/slark_pounce_leash.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
	ParticleManager:SetParticleControlEnt( effect_cast, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0,0,0), true )
	ParticleManager:SetParticleControl( effect_cast, 3, parent:GetOrigin() )

	self:AddEffect( effect_cast )
end

function modifier_slark_pounce_debuff:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_slark_pounce_debuff:GetModifierAttackSpeedBonus_Constant()
	return self.slow
end

function modifier_slark_pounce_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

function modifier_slark_pounce_debuff:IsHidden()
	return false
end

function modifier_slark_pounce_debuff:IsDebuff()
	return true
end

function modifier_slark_pounce_debuff:IsStunDebuff()
	return false
end

function modifier_slark_pounce_debuff:IsPurgable()
	return false
end

function modifier_slark_pounce_debuff:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end