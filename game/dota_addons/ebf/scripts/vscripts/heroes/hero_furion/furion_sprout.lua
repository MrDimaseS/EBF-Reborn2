furion_sprout = class({})

function furion_sprout:IsStealable()
	return true
end

function furion_sprout:IsHiddenWhenStolen()
	return false
end

function furion_sprout:GetAOERadius()
	return self:GetSpecialValueFor("tree_radius")
end

function furion_sprout:PiercesDisableResistance()
    return true
end

function furion_sprout:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	if self:GetCursorTarget() then
		local point = self:GetCursorTarget():GetAbsOrigin()
	end
	local duration = self:GetSpecialValueFor("duration")
	local vision_range = self:GetSpecialValueFor("vision_range")
	local trees = 8
	local sprout_treants = self:GetSpecialValueFor("sprout_treants")
	local sprout_damage_radius = self:GetSpecialValueFor("sprout_damage_radius")
	local sprout_damage = self:GetSpecialValueFor("sprout_damage")
	local radius = 150 or self:GetSpecialValueFor("tree_radius")
	local angle = math.pi/(trees/2)
	
	local treants = caster:FindAbilityByName("furion_force_of_nature")
	-- Creates 16 temporary trees at each 45 degree interval around the clicked point
	for i=trees,1, -1 do
		local position = Vector(point.x+radius*math.sin(angle * (i-1)), point.y+radius*math.cos(angle * (i-1)), point.z)
		if IsEntitySafe( treants ) and sprout_treants > 0 and RollPercentage( (sprout_treants/i)*100 ) then
			treants:SpawnTreant( position )
			sprout_treants = sprout_treants - 1
		else
			local tree = CreateTempTree(position, duration)
		end
	end
	local dummy = caster:CreateDummy(point)
	dummy:AddNewModifier(caster, self, "modifier_furion_sprout_leash_thinker", {duration = duration-0.1})
	-- Gives vision to the caster's team in a radius around the clicked point for the duration
	AddFOWViewer(caster:GetTeam(), point, vision_range, duration, false)
	ParticleManager:FireParticle("particles/units/heroes/hero_furion/furion_sprout.vpcf", PATTACH_ABSORIGIN, dummy)
	EmitSoundOn("Hero_Furion.Sprout", dummy)
	
	ResolveNPCPositions( point, vision_range + radius ) 
	
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( point, sprout_damage_radius ) ) do
		self:DealDamage( caster, enemy, sprout_damage, {damage_type = DAMAGE_TYPE_MAGICAL} )
	end
end


modifier_furion_sprout_leash_thinker = class({})
LinkLuaModifier( "modifier_furion_sprout_leash_thinker", "heroes/hero_furion/furion_sprout.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_furion_sprout_leash_thinker:OnCreated( kv )
	self.sprout_damage_radius = self:GetSpecialValueFor( "sprout_damage_radius" )
	
	self.sprout_heal_interval = self:GetSpecialValueFor("sprout_heal_interval")
	self.sprout_current_interval = self.sprout_heal_interval
	self.sprout_heal_per_second = self:GetSpecialValueFor("sprout_heal_per_second") * self.sprout_heal_interval
	
	self.sprout_damage_radius = self:GetSpecialValueFor("sprout_damage_radius")
	
	if IsServer() then
		self.treants = self:GetCaster():FindAbilityByName("furion_force_of_nature")
		self:StartIntervalThink( 0.1 )
	end
end

function modifier_furion_sprout_leash_thinker:OnDestroy( kv )
	if IsServer() then
		self:GetParent():RemoveSelf()
	end
end

function modifier_furion_sprout_leash_thinker:OnIntervalThink()
	if self.sprout_heal_interval <= 0 then return end
	
	self.sprout_current_interval = self.sprout_current_interval - 0.1
	if self.sprout_current_interval <= 0 then
		local caster = self:GetCaster()
		local parent = self:GetParent()
		local ability = self:GetAbility()
		self.sprout_current_interval = self.sprout_heal_interval
		for _, ally in ipairs( caster:FindFriendlyUnitsInRadius( parent:GetAbsOrigin(), self.sprout_damage_radius ) ) do
			ally:HealEvent( self.sprout_heal_per_second, ability, caster )
		end
	end
end

function modifier_furion_sprout_leash_thinker:IsHidden()
	return true
end

function modifier_furion_sprout_leash_thinker:IsAura()
	return true
end

function modifier_furion_sprout_leash_thinker:GetModifierAura()
	return "modifier_furion_sprout_leash_aura"
end

function modifier_furion_sprout_leash_thinker:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_furion_sprout_leash_thinker:GetAuraSearchType()
	return DOTA_UNIT_TARGET_ALL
end

function modifier_furion_sprout_leash_thinker:GetAuraRadius()
	return self.sprout_damage_radius
end

function modifier_furion_sprout_leash_thinker:IsPurgable()
    return false
end

function modifier_furion_sprout_leash_thinker:CheckState()
    local state = {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true
	}
	return state
end

function modifier_furion_sprout_leash_thinker:GetEffectName()
	return "particles/furion_sprout_sleep.vpcf"
end

modifier_furion_sprout_leash_aura = class({})
LinkLuaModifier( "modifier_furion_sprout_leash_aura", "heroes/hero_furion/furion_sprout.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_furion_sprout_leash_aura:OnCreated()
	self.sprout_miss_chance = self:GetSpecialValueFor("sprout_miss_chance")
end

function modifier_furion_sprout_leash_aura:CheckState()
    local state = {
		[MODIFIER_STATE_TETHERED] = true,
	}
	return state
end

function modifier_furion_sprout_leash_aura:DeclareFunctions()
	return {MODIFIER_PROPERTY_MISS_PERCENTAGE}
end

function modifier_furion_sprout_leash_aura:GetModifierMiss_Percentage()
	return self.sprout_miss_chance
end

function modifier_furion_sprout_leash_aura:IsHidden()
	return true
end