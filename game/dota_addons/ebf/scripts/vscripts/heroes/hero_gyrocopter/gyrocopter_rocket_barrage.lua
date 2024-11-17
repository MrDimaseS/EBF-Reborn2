gyrocopter_rocket_barrage = class({})

function gyrocopter_rocket_barrage:IsStealable()
	return true
end

function gyrocopter_rocket_barrage:IsHiddenWhenStolen()
	return false
end

function gyrocopter_rocket_barrage:OnSpellStart()
	local caster = self:GetCaster()
	
	caster:AddNewModifier( caster, self, "modifier_gyrocopter_rocket_barrage_active", {duration = self:GetSpecialValueFor("AbilityDuration")} )
	EmitSoundOn( "Hero_Gyrocopter.Rocket_Barrage", caster )
end


function gyrocopter_rocket_barrage:OnProjectileHit(hTarget, vLocation)
	local caster = self:GetCaster()
	if hTarget then
		EmitSoundOn("Hero_Gyrocopter.Rocket_Barrage.Impact", hTarget)
		local attackDamage = self:GetSpecialValueFor("attack_damage_penalty")
		local rocketDamage = self:GetSpecialValueFor("rocket_damage")
		if attackDamage > 0 then
			caster:PerformGenericAttack( hTarget, true, {ability = self, bonusDamage = rocketDamage, bonusDamagePct = attackDamage} )
		else
			self:DealDamage( caster, hTarget, rocketDamage )
		end
	end
end

modifier_gyrocopter_rocket_barrage_active = class({})
LinkLuaModifier( "modifier_gyrocopter_rocket_barrage_active", "heroes/hero_gyrocopter/gyrocopter_rocket_barrage.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_gyrocopter_rocket_barrage_active:OnCreated()
	self:OnRefresh()
end

function modifier_gyrocopter_rocket_barrage_active:OnRefresh()
	self.seconds_per_rocket = 1 / self:GetSpecialValueFor("rockets_per_second")
	self.radius = self:GetSpecialValueFor("radius")
	self.bonus_movement_speed = self:GetSpecialValueFor("bonus_movement_speed")
	self.bonus_movespeed_duration = self:GetSpecialValueFor("bonus_movespeed_duration")
	if IsServer() then
		self:StartIntervalThink( self.seconds_per_rocket )
	end
end

function modifier_gyrocopter_rocket_barrage_active:OnRemoved()
	if IsServer() then
		self:GetCaster():RemoveGesture(ACT_DOTA_OVERRIDE_ABILITY_1)
	end
end

function modifier_gyrocopter_rocket_barrage_active:OnIntervalThink()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	local ability = self:GetAbility()

	caster:StartGesture( ACT_DOTA_OVERRIDE_ABILITY_1 )
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( parent:GetAbsOrigin(), self.radius ) ) do
		EmitSoundOn("Hero_Gyrocopter.Rocket_Barrage.Launch", parent)
		local attachment = TernaryOperator( DOTA_PROJECTILE_ATTACHMENT_ATTACK_1, RollPercentage( 50 ), DOTA_PROJECTILE_ATTACHMENT_ATTACK_2 )
		ability:FireTrackingProjectile("particles/units/heroes/hero_gyrocopter/gyro_rocket_barrage.vpcf", enemy, 2000, {source = parent}, attachment)
		if not parent:HasModifier("modifier_gyrocopter_flight_of_the_valkyrie_active") or caster ~= parent then
			break
		end
	end
end

function modifier_gyrocopter_rocket_barrage_active:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_gyrocopter_rocket_barrage_active:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_movement_speed
end

function modifier_gyrocopter_rocket_barrage_active:OnAttackLanded( params )
	if params.attacker ~= self:GetParent() then return end
	if self.bonus_movespeed_duration > 0 then
		params.attacker:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_gyrocopter_rocket_barrage_afterburner", {duration = self.bonus_movespeed_duration} )
	end
end

modifier_gyrocopter_rocket_barrage_afterburner = class({})
LinkLuaModifier( "modifier_gyrocopter_rocket_barrage_afterburner", "heroes/hero_gyrocopter/gyrocopter_rocket_barrage.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_gyrocopter_rocket_barrage_afterburner:OnCreated()
	self:OnRefresh()
end

function modifier_gyrocopter_rocket_barrage_afterburner:OnRefresh()
	self.bonus_movement_speed_per_hit = self:GetSpecialValueFor("bonus_movement_speed_per_hit")
	if IsServer() then
		self:IncrementStackCount()
	end
end

function modifier_gyrocopter_rocket_barrage_afterburner:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_gyrocopter_rocket_barrage_afterburner:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_movement_speed_per_hit * self:GetStackCount()
end