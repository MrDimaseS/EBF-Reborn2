earth_spirit_geomagnetic_grip = class({})

function earth_spirit_geomagnetic_grip:IsStealable()
	return true
end

function earth_spirit_geomagnetic_grip:IsHiddenWhenStolen()
	return false
end

function earth_spirit_geomagnetic_grip:OnAbilityPhaseStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
	if target and not PlayerResource:IsDisableHelpSetForPlayerID( target:GetPlayerOwnerID(), caster:GetPlayerOwnerID() ) then
		self.target = target
		return true
	end
	
    local position = self:GetCursorPosition()
	local stones = caster:FindFriendlyUnitsInRadius(position, self:GetSpecialValueFor("remnant_grip_radius_tooltip"), {type = DOTA_UNIT_TARGET_ALL, flag = DOTA_UNIT_TARGET_FLAG_INVULNERABLE, order = FIND_CLOSEST})
    for _,stone in ipairs(stones) do
    	if stone:GetName() == "npc_dota_earth_spirit_stone" then
			self.target = stone
    		return true
    	end
    end
	local enemies = caster:FindAllUnitsInRadius(position, self:GetSpecialValueFor("remnant_grip_radius_tooltip"), {order = FIND_CLOSEST})
    for _,enemy in ipairs(enemies) do
		self.target = enemy
		return true
    end
	return false
end

function earth_spirit_geomagnetic_grip:OnSpellStart()
    local caster = self:GetCaster()
    local target = self.target
	
	if target:TriggerSpellAbsorb( caster ) then return end
	
	local remnantTarget = (target:GetName() == "npc_dota_earth_spirit_stone")
	
	local distance = self:GetSpecialValueFor("total_pull_distance")
	local speed = self:GetSpecialValueFor("pull_units_per_second_heroes")
	local rock_bonus_damage = self:GetSpecialValueFor("rock_bonus_damage") / 100
	local knockbackDuration = distance / TernaryOperator( speed, not remnantTarget, speed * (1+rock_bonus_damage) )
	
	target:AddNewModifier( caster, self, "modifier_earth_spirit_geomagnetic_grip_movement", {duration = knockbackDuration} )
	
    EmitSoundOn("Hero_EarthSpirit.GeomagneticGrip.Cast", caster)
	EmitSoundOn("Hero_EarthSpirit.GeomagneticGrip.Target", target)
	
	-- Magnetized effects
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), -1 ) ) do
		if enemy ~= target and enemy:HasModifier("modifier_earth_spirit_magnetize_effect") then
			enemy:AddNewModifier( caster, self, "modifier_earth_spirit_geomagnetic_grip_movement", {duration = distance / speed} )
		end
	end
end

modifier_earth_spirit_geomagnetic_grip_movement = class({})
LinkLuaModifier( "modifier_earth_spirit_geomagnetic_grip_movement", "heroes/hero_earth_spirit/earth_spirit_geomagnetic_grip.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_earth_spirit_geomagnetic_grip_movement:OnCreated(table)
	if IsServer() then
		caster = self:GetCaster()
		target = self:GetParent()
		self.silence = self:GetSpecialValueFor("duration")
		self.radius = self:GetSpecialValueFor("radius")
		self.damage = self:GetSpecialValueFor("rock_damage")
		self.creep_multiplier = self:GetSpecialValueFor("creep_multiplier")
		self.distance = self:GetSpecialValueFor("total_pull_distance")
		self.bonusDamage = self:GetSpecialValueFor("rock_bonus_damage") / 100
		self.isRemnant = (self:GetParent():GetName() == "npc_dota_earth_spirit_stone")
		self.speed = self:GetSpecialValueFor("pull_units_per_second_heroes")
		if self.isRemnant then
			self.speed = self.speed * (1+self.bonusDamage)
			self.damage = self.damage * (1+self.bonusDamage)
		end
		self.nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_earth_spirit/espirit_geomagentic_target_sphere.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControlForward( self.nfx, 3, CalculateDirection(self:GetParent(), self:GetCaster() ) )
		self:AddEffect( self.nfx )
		self.hitTable = {}
		self:StartMotionController()
	end
end

function modifier_earth_spirit_geomagnetic_grip_movement:DoControlledMotion()
	local caster = self:GetCaster()
	local target = self:GetParent()
	local ability = self:GetAbility()

	local direction = CalculateDirection(target, caster)
	local distance = CalculateDistance(target, caster)

	local enemies = caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), self.radius )
	for _,enemy in ipairs( enemies ) do
		if not self.hitTable[enemy] then
			EmitSoundOn("Hero_EarthSpirit.BoulderSmash.Silence", enemy)
			if self.isRemnant then ability:Silence(enemy, self.silence) end
			ability:DealDamage( caster, enemy, TernaryOperator( self.damage, enemy:IsConsideredHero(), self.damage * self.creep_multiplier ) )
			self.hitTable[enemy] = true
		end
	end
	if distance > 150 and self.distance > 0 then
		target:SetAbsOrigin( GetGroundPosition( target:GetAbsOrigin() - direction * self.speed * FrameTime(), target ) )
		ParticleManager:SetParticleControlForward( self.nfx, 3, direction )
		self.distance = self.distance - self.speed * FrameTime()
	else
		FindClearSpaceForUnit(target, target:GetAbsOrigin(), true)
		self:Destroy()
	end
end

function modifier_earth_spirit_geomagnetic_grip_movement:IsHidden()
	return true
end