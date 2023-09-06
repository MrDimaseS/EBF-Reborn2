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
	local trees = self:GetSpecialValueFor("tree_count")
	local radius = self:GetSpecialValueFor("tree_radius")
	local angle = math.pi/(trees/2)
	
	-- Creates 16 temporary trees at each 45 degree interval around the clicked point
	local treeList = {}
	for i=1,trees do
		local position = Vector(point.x+radius*math.sin(angle * (i-1)), point.y+radius*math.cos(angle * (i-1)), point.z)
		local tree = CreateTempTree(position, duration)
		treeList[tree] = position
	end
	local dummy = caster:CreateDummy(point)
	dummy:AddNewModifier(caster, self, "modifier_furion_sprout_leash_thinker", {duration = duration-0.1})
	dummy.treeList = treeList
	-- Gives vision to the caster's team in a radius around the clicked point for the duration
	AddFOWViewer(caster:GetTeam(), point, vision_range, duration, false)
	local sprout = ParticleManager:CreateParticle("particles/units/heroes/hero_furion/furion_sprout.vpcf", PATTACH_ABSORIGIN, dummy)
		ParticleManager:SetParticleControl( sprout, 0, dummy:GetOrigin() )
	ParticleManager:ReleaseParticleIndex(sprout)
	EmitSoundOn("Hero_Furion.Sprout", dummy)
	
	ResolveNPCPositions( point, vision_range + radius ) 
end


modifier_furion_sprout_leash_thinker = class({})
LinkLuaModifier( "modifier_furion_sprout_leash_thinker", "heroes/hero_furion/furion_sprout.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_furion_sprout_leash_thinker:OnCreated( kv )
	self.aura_radius = self:GetSpecialValueFor( "tree_radius" )
	self.max_greater_treants = self:GetSpecialValueFor("max_greater_treants")
	
	
	self.sprout_damage_inteval = self:GetSpecialValueFor("sprout_damage_inteval")
	self.sprout_current_inteval = self:GetSpecialValueFor("sprout_damage_inteval")
	self.sprout_damage = self:GetSpecialValueFor("sprout_damage") * self.sprout_damage_inteval
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
	if self.treants:GetLevel() > 0 then
		if self.max_greater_treants <= 0 then
			self:StartIntervalThink(-1)
			return
		end
		
		for tree, position in pairs( self:GetParent().treeList ) do
			if tree:IsNull() and self.max_greater_treants > 0 then
				self.treants:SpawnTreant( position, true )
				self.max_greater_treants = self.max_greater_treants - 1
				self:GetParent().treeList[tree] = nil
			end
		end
	end
	
	self.sprout_current_inteval = self.sprout_current_inteval - 1
	if self.sprout_current_inteval <= 0 then
		local caster = self:GetCaster()
		local parent = self:GetParent()
		local ability = self:GetAbility()
		self.sprout_current_inteval = self.sprout_damage_inteval
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( parent:GetAbsOrigin(), self.sprout_damage_radius ) ) do
			ability:DealDamage( caster, enemy, self.sprout_damage, {damage_type = DAMAGE_TYPE_MAGICAL} )
		end
	end
end

function modifier_furion_sprout_leash_thinker:IsHidden()
	return true
end

--------------------------------------------------------------------------------

function modifier_furion_sprout_leash_thinker:IsAura()
	return true
end

--------------------------------------------------------------------------------

function modifier_furion_sprout_leash_thinker:GetModifierAura()
	return "modifier_furion_sprout_leash_aura"
end

--------------------------------------------------------------------------------

function modifier_furion_sprout_leash_thinker:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

--------------------------------------------------------------------------------

function modifier_furion_sprout_leash_thinker:GetAuraSearchType()
	return DOTA_UNIT_TARGET_ALL
end

--------------------------------------------------------------------------------

function modifier_furion_sprout_leash_thinker:GetAuraRadius()
	return self.aura_radius
end


--------------------------------------------------------------------------------
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
	self.miss = self:GetSpecialValueFor("miss_chance")
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
	return self.miss
end

function modifier_furion_sprout_leash_aura:IsHidden()
	return true
end