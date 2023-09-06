earth_spirit_boulder_smash = class({})

function earth_spirit_boulder_smash:IsStealable()
	return true
end

function earth_spirit_boulder_smash:IsHiddenWhenStolen()
	return false
end

function earth_spirit_boulder_smash:OnAbilityPhaseStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
	if target then 
		self.target = target
		return true
	end
	
    local position = self:GetCursorPosition()
	local stones = caster:FindFriendlyUnitsInRadius(position, self:GetSpecialValueFor("rock_search_aoe"), {type = DOTA_UNIT_TARGET_ALL, flag = DOTA_UNIT_TARGET_FLAG_INVULNERABLE, order = FIND_CLOSEST})
    for _,stone in ipairs(stones) do
    	if stone:GetName() == "npc_dota_earth_spirit_stone" then
			self.target = stone
    		return true
    	end
    end
	local enemies = caster:FindEnemyUnitsInRadius(position, self:GetSpecialValueFor("rock_search_aoe"), {order = FIND_CLOSEST})
    for _,enemy in ipairs(enemies) do
		self.target = enemy
		return true
    end
	return false
end

function earth_spirit_boulder_smash:OnSpellStart()
    local caster = self:GetCaster()
	local target = self.target
	
	if target:TriggerSpellAbsorb( caster ) then return end
	
	local remnantTarget = (target:GetName() == "npc_dota_earth_spirit_stone")
	local remnantDistance = self:GetSpecialValueFor("rock_distance") 
	local distance = self:GetSpecialValueFor("unit_distance")
	local speed = self:GetSpecialValueFor("speed")
	local damage = self:GetSpecialValueFor("rock_damage")
	
	local knockbackDistance = TernaryOperator( remnantDistance, remnantTarget, distance )
	local knockbackDuration = knockbackDistance / speed
	target:ApplyKnockBack(caster:GetAbsOrigin(), knockbackDuration, knockbackDuration, knockbackDistance, 0, caster, self, not caster:IsSameTeam(target) )
	target:AddNewModifier( caster, self, "modifier_earth_spirit_boulder_smash_movement", {duration = knockbackDuration} )
	
	if not target:IsSameTeam( caster ) then
		self:DealDamage( caster, target, TernaryOperator( damage, target:IsConsideredHero(), damage * self:GetSpecialValueFor("creep_multiplier") ) )
	end
	
	EmitSoundOn( "Hero_EarthSpirit.BoulderSmash.Cast", caster )
	EmitSoundOn( "Hero_EarthSpirit.BoulderSmash.Target", target )
	
	-- Magnetized effects
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), -1 ) ) do
		if enemy ~= target and enemy:HasModifier("modifier_earth_spirit_magnetize_effect") then
			enemy:ApplyKnockBack(caster:GetAbsOrigin(), distance/speed, distance/speed, distance, 0, caster, self )
			enemy:AddNewModifier( caster, self, "modifier_earth_spirit_boulder_smash_movement", {duration = distance/speed} )
			self:DealDamage( caster, enemy, TernaryOperator( damage, enemy:IsConsideredHero(), damage * self:GetSpecialValueFor("creep_multiplier") ) )
			EmitSoundOn( "Hero_EarthSpirit.BoulderSmash.Target", enemy )
		end
	end
end

modifier_earth_spirit_boulder_smash_movement = class({})
LinkLuaModifier( "modifier_earth_spirit_boulder_smash_movement", "heroes/hero_earth_spirit/earth_spirit_boulder_smash", LUA_MODIFIER_MOTION_NONE )
function modifier_earth_spirit_boulder_smash_movement:OnCreated(table)
	if IsServer() then
		self.radius = self:GetSpecialValueFor("radius")
		self.damage = self:GetSpecialValueFor("rock_damage")
		self.duration = self:GetSpecialValueFor("slow_duration")
		self.creep_multiplier = self:GetSpecialValueFor("creep_multiplier")
		
		local remnantTarget = (self:GetParent():GetName() == "npc_dota_earth_spirit_stone")
		if remnantTarget then
			self.damage = self.damage * (1+self:GetSpecialValueFor("rock_bonus_damage")/100)
		else
			self.duration = 0
		end
		
		self.nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_earth_spirit/espirit_geomagentic_target_sphere.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControlForward( self.nfx, 3, CalculateDirection(self:GetParent(), self:GetCaster() ) )
		self:AddEffect( self.nfx )
		
		self.hitTable = {}
		self.hitTable[self:GetParent()] = true
		
		self:StartIntervalThink(0)
	end
end

function modifier_earth_spirit_boulder_smash_movement:OnIntervalThink()
	caster = self:GetCaster()
	target = self:GetParent()
	ability = self:GetAbility()

	local direction = CalculateDirection(target, caster)
	local distance = CalculateDistance(target, caster)
	
	local enemies = caster:FindEnemyUnitsInRadius(target:GetAbsOrigin(), self.radius)
	for _,enemy in pairs(enemies) do
		if not self.hitTable[enemy] then
			EmitSoundOn("Hero_EarthSpirit.BoulderSmash.Damage", enemy)
			enemy:AddNewModifier( caster, self:GetAbility(), "modifier_earth_spirit_boulder_smash_debuff", {duration = self.duration} )
			ability:DealDamage( caster, enemy, TernaryOperator( self.damage, enemy:IsConsideredHero(), self.damage * self.creep_multiplier ) )
			self.hitTable[enemy] = true
		end
	end
end

function modifier_earth_spirit_boulder_smash_movement:IsHidden()
	return true
end