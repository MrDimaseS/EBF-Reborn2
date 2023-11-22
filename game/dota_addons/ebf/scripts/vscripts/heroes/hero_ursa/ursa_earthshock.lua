ursa_earthshock = class({})

function ursa_earthshock:IsStealable()
	return true
end

function ursa_earthshock:IsHiddenWhenStolen()
	return false
end

function ursa_earthshock:GetCastRange(target, position)
	return self:GetSpecialValueFor("shock_radius")
end

function ursa_earthshock:GetCastPoint()
	return self:GetSpecialValueFor("hop_duration")
end

function ursa_earthshock:GetBehavior()
	local behavior = DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING + DOTA_ABILITY_BEHAVIOR_AUTOCAST
	if IsServer() and not self:GetAutoCastState() then
		behavior = behavior + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
	end
	return behavior
end

function ursa_earthshock:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	if self:GetAutoCastState() then
		caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_1, 0.33/self:GetSpecialValueFor("hop_duration"))
	end
	return true
end

function ursa_earthshock:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
	caster:FadeGesture(ACT_DOTA_CAST_ABILITY_1)
end

function ursa_earthshock:OnSpellStart()
	local caster = self:GetCaster()

	EmitSoundOn("Hero_LoneDruid.BattleCry.Bear", caster)
	if not self:GetAutoCastState() then
		caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_1, 1 )
		caster:AddNewModifier(caster, self, "modifier_ursa_earthshock_movement", {duration = self:GetSpecialValueFor("hop_duration")+0.1})
	else
		self:EarthShock()
	end
end

function ursa_earthshock:EarthShock()
	local caster = self:GetCaster()
	
	local radius = self:GetSpecialValueFor("shock_radius")

	EmitSoundOn("Hero_Ursa.Earthshock", caster)

	local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_ursa/ursa_earthshock.vpcf", PATTACH_POINT, caster)
				ParticleManager:SetParticleControl(nfx, 0, caster:GetAbsOrigin())
				--ParticleManager:SetParticleControl(nfx, 1, Vector(900, 450, 225))
				ParticleManager:SetParticleControl(nfx, 1, Vector(radius, radius, 225))
				ParticleManager:SetParticleControl(nfx, 2, Vector(radius, radius, 225))
				ParticleManager:ReleaseParticleIndex(nfx)

	GridNav:DestroyTreesAroundPoint(caster:GetAbsOrigin(), radius, false)
	local enemies = caster:FindEnemyUnitsInRadius(caster:GetAbsOrigin(), radius)
	local damage = self:GetAbilityDamage()
	local duration = self:GetSpecialValueFor("duration")
	local fury_swipe_stacks_on_hit = self:GetSpecialValueFor("fury_swipe_stacks_on_hit")
	local furySwipes = caster:FindAbilityByName("ursa_fury_swipes")
	
	local furySwipesDamage = 0 
	local furySwipesDuration = 0
	if furySwipes and furySwipes:IsTrained() then
		furySwipesDamage = furySwipes:GetSpecialValueFor("damage_per_stack")
		furySwipesDuration = furySwipes:GetSpecialValueFor("bonus_reset_time")
	end
	
	for _,enemy in pairs(enemies) do
		if not enemy:TriggerSpellAbsorb( self ) then
			enemy:AddNewModifier(caster, self, "modifier_ursa_earthshock", {Duration = duration})
			local totalDamage = damage
			if furySwipes and furySwipes:IsTrained() then
				if fury_swipe_stacks_on_hit > 0 then
					local modifier = enemy:AddNewModifier(caster, furySwipes, "modifier_ursa_fury_swipes_damage_increase", {duration = furySwipesDuration})
					modifier:SetStackCount( modifier:GetStackCount() + talent2Swipes )
				end
				if not caster:PassivesDisabled() then
					local furySwipesBonus = enemy:GetModifierStackCount( "modifier_ursa_fury_swipes_damage_increase", caster ) * furySwipesDamage
					totalDamage = totalDamage + furySwipesBonus
				end
			end
			self:DealDamage(caster, enemy, totalDamage)
		end
	end
end

modifier_ursa_earthshock_movement = class({})
LinkLuaModifier("modifier_ursa_earthshock_movement", "heroes/hero_ursa/ursa_earthshock", LUA_MODIFIER_MOTION_NONE)
if IsServer() then
	function modifier_ursa_earthshock_movement:OnCreated()
		local parent = self:GetParent()
		self.endPos = self:GetAbility():GetCursorPosition()
		self.distance = self:GetSpecialValueFor("hop_distance")
		self.direction = parent:GetForwardVector()
		self.speed = (self.distance / self:GetRemainingTime()) * FrameTime()
		self.maxHeight = self:GetSpecialValueFor("hop_height")
		self:StartMotionController()
	end
	
	function modifier_ursa_earthshock_movement:OnDestroy()
		local parent = self:GetParent()
		local parentPos = parent:GetAbsOrigin()
		FindClearSpaceForUnit(parent, parentPos, true)

		GridNav:DestroyTreesAroundPoint(parentPos, parent:GetAttackRange(), false)
		
		self:GetAbility():EarthShock()

		self:StopMotionController()
	end
	
	function modifier_ursa_earthshock_movement:DoControlledMotion()
		if self:GetParent():IsNull() then return end
		local parent = self:GetParent()
		self.distanceTraveled =  self.distanceTraveled or 0
		if parent:IsAlive() and self.distanceTraveled < self.distance then
			local newPos = GetGroundPosition(parent:GetAbsOrigin(), parent) + self.direction * self.speed
			local height = GetGroundHeight(parent:GetAbsOrigin(), parent)
			newPos.z = height + self.maxHeight * math.sin( (self.distanceTraveled/self.distance) * math.pi )
			parent:SetAbsOrigin( newPos )
			
			self.distanceTraveled = self.distanceTraveled + self.speed
		else
			FindClearSpaceForUnit(parent, parent:GetAbsOrigin(), true)
			self:Destroy()
			return nil
		end       
		
	end
end

function modifier_ursa_earthshock_movement:CheckState()
	return {[MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true}
end

function modifier_ursa_earthshock_movement:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ORDER}
end

function modifier_ursa_earthshock_movement:OnOrder( params )
	if params.unit == self:GetParent() then
		if params.order_type == DOTA_UNIT_ORDER_STOP or params.order_type == DOTA_UNIT_ORDER_HOLD_POSITION then
			self:Destroy()
			params.unit:RemoveGesture(ACT_DOTA_CAST_ABILITY_1)
			params.unit:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_1, 2)
		end
	end
end

function modifier_ursa_earthshock_movement:IsHidden()
	return true
end