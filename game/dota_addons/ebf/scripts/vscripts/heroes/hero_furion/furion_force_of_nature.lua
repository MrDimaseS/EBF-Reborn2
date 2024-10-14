furion_force_of_nature = class({})

function furion_force_of_nature:IsStealable()
	return false
end

function furion_force_of_nature:IsHiddenWhenStolen()
	return false
end

function furion_force_of_nature:GetAOERadius()
	return self:GetSpecialValueFor("area_of_effect")
end

TREANT_ATTACH = {
 [1] = "thigh_R",
 [2] = "thigh_L",
 [3] = "elbow_L",
 [4] = "elbow_R",
 [5] = "Spine_0",
 [6] = "Spine_1",
 [7] = "Spine_3",
 [8] = "Head_0"
}

TREANT_QANGLE = {
 [1] = Vector( -90, 0, 0),
 [2] = Vector( 90, 0, 0),
 [3] = Vector( 90, 0, 0),
 [4] = Vector( -90, 0, 0),
 [5] = Vector( 0, 0, 0),
 [6] = Vector( 45, 0, 0),
 [7] = Vector( -90, 0, 0),
 [8] = Vector( 90, 0, 0)
}

function furion_force_of_nature:OnSpellStart()
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    local treants = caster:FindFriendlyUnitsInRadius(caster:GetAbsOrigin(), FIND_UNITS_EVERYWHERE, {})

    local radius = self:GetSpecialValueFor("area_of_effect")
    local max_hp_per_treants = self:GetSpecialValueFor("max_hp_per_treants") > 0
	local duration = self:GetSpecialValueFor("treant_duration")

    local trees = GridNav:GetAllTreesAroundPoint(point, radius, true)
	
    if #trees > 1 then
    	GridNav:DestroyTreesAroundPoint(point, radius, true)
		local treants = math.min(#trees, self:GetSpecialValueFor("max_treants"))
		local treeTable = {}
	    for i=1, treants do
	    	local randoVect = Vector(RandomInt(-radius,radius), RandomInt(-radius,radius), 0)
			local pointRando = point + randoVect

	    	local treant = self:SpawnTreant(pointRando)
			
			if max_hp_per_treants then
				table.insert( treeTable, treant:entindex() )
				treant:FollowEntityMerge(caster, TREANT_ATTACH[i])
				treant:SetLocalAngles( TREANT_QANGLE[i].x, TREANT_QANGLE[i].y, TREANT_QANGLE[i].z )
				treant:AddNewModifier( caster, self, "modifier_furion_force_of_nature_phytomercenary_treant", {duration = duration })
			end
	    end
		if max_hp_per_treants then
			caster:RemoveModifierByName("modifier_furion_force_of_nature_phytomercenary")
			local buff = caster:AddNewModifier( caster, self, "modifier_furion_force_of_nature_phytomercenary", {duration = duration})
			buff:SetStackCount( treants )
			buff.treantTable = treeTable
			caster:CalculateStatBonus( true )
		end
	end
end

function furion_force_of_nature:OnProjectileHit( target, position )
	if target then
		local caster = self:GetCaster()
		local healPerPulse = self:GetSpecialValueFor("heal_per_pulse")
		target:HealEvent( healPerPulse, self, caster )
	end
end

function furion_force_of_nature:SpawnTreant(position)
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("treant_duration")
	local tree = caster:CreateSummon( "npc_dota_furion_treant", position, duration )
	
	FindClearSpaceForUnit(tree, position, true)
	local maxHP = self:GetSpecialValueFor("treant_health")
	
	tree:SetBaseMaxHealth(maxHP)
	tree:SetMaxHealth(maxHP)
	tree:SetHealth(maxHP)
	
	local adMax = self:GetSpecialValueFor("treant_damage_max")
	tree:SetAverageBaseDamage(adMax, 5)
	
	if self:GetSpecialValueFor("uncontrollable") == 1 then
		local secPerPulse = self:GetSpecialValueFor("sec_per_pulse")
		local currDelay = secPerPulse
		tree:SetControllableByPlayer(-1, true)
		tree:SetFollowRange(tree:GetAttackRange() + 50)
		
		local heroBeingHealed
		
		Timers:CreateTimer( function()
			if not IsEntitySafe( tree ) or not tree:IsAlive() then
				return
			end
			if IsEntitySafe( heroBeingHealed ) and heroBeingHealed:IsAlive() then
				if CalculateDistance( tree, heroBeingHealed ) <= tree:GetAttackRange()*2 and currDelay <= 0 then
					currDelay = secPerPulse
					self:FireTrackingProjectile("particles/units/heroes/hero_treant/treant_leech_seed_projectile.vpcf", heroBeingHealed, 900, {source = tree})
				end
			else
				for _, hero in ipairs( caster:FindFriendlyUnitsInRadius( caster:GetAbsOrigin(), -1, {type = DOTA_UNIT_TARGET_HERO} ) ) do
					if hero:IsAlive() then
						if not (IsEntitySafe( hero._healedByTreant ) and hero._healedByTreant:IsAlive() ) -- previous treant died
						or (IsEntitySafe( hero._healedByTreant ) and hero._healedByTreant._currentlyHealingPlayer ~= hero)then -- previous treant retargeted
							hero._healedByTreant = tree
							heroBeingHealed = hero
							tree._currentlyHealingPlayer = heroBeingHealed
							break
						end
					end
				end
			end
			if IsEntitySafe( heroBeingHealed ) then
				tree:MoveToNPC( heroBeingHealed )
			elseif not (tree:IsAttacking() or tree:IsMoving()) then
				local enemy = tree:FindRandomEnemyInRadius( tree:GetAbsOrigin(), -1 )
				tree:MoveToPositionAggressive( enemy:GetAbsOrigin() )
			end
			if currDelay > 0 then
				currDelay = currDelay - 0.1
			end
			return 0.25
		end)
	else
		tree:MoveToPositionAggressive(position)
	end
	return tree
end


modifier_furion_force_of_nature_phytomercenary_treant = class({})
LinkLuaModifier( "modifier_furion_force_of_nature_phytomercenary_treant", "heroes/hero_furion/furion_force_of_nature.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_furion_force_of_nature_phytomercenary_treant:CheckState()
	return {[MODIFIER_STATE_INVULNERABLE] = true,
			[MODIFIER_STATE_UNTARGETABLE] = true,
			[MODIFIER_STATE_NO_HEALTH_BAR] = true,
			[MODIFIER_STATE_STUNNED] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			}
end

modifier_furion_force_of_nature_phytomercenary = class({})
LinkLuaModifier( "modifier_furion_force_of_nature_phytomercenary", "heroes/hero_furion/furion_force_of_nature.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_furion_force_of_nature_phytomercenary:OnCreated()
	self.treant_damage_max = self:GetSpecialValueFor("treant_damage_max")
	self.treant_health = self:GetSpecialValueFor("treant_health")
	self.max_hp_per_treants = self:GetSpecialValueFor("max_hp_per_treants") / 100
end

function modifier_furion_force_of_nature_phytomercenary:OnDestroy()
	if not IsServer() then return end
	for _, treantID in ipairs( self.treantTable ) do
		local treant = EntIndexToHScript( treantID )
		if IsEntitySafe( treant ) then
			treant:ForceKill( false )
		end
	end
	self:GetParent():CalculateStatBonus( true )
end

function modifier_furion_force_of_nature_phytomercenary:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_HEALTH_BONUS,
			MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_furion_force_of_nature_phytomercenary:GetModifierPreAttack_BonusDamage()
	return self.treant_damage_max * self:GetStackCount()
end

function modifier_furion_force_of_nature_phytomercenary:GetModifierHealthBonus()
	return self.treant_health * self:GetStackCount()
end

function modifier_furion_force_of_nature_phytomercenary:OnTakeDamage( params )
	if params.unit == self:GetCaster() then
		local hpCheck = params.unit:GetMaxHealth() * self.max_hp_per_treants
		self._damageTaken = (self._damageTaken or 0) + params.damage
		if hpCheck <= self._damageTaken then
			self._damageTaken = 0
			self:DecrementStackCount()
			
			local id = RandomInt( 1, #self.treantTable )
			local treant = EntIndexToHScript( self.treantTable[id] )
			table.remove( self.treantTable, id )
			if IsEntitySafe( treant ) then
				treant:ForceKill( false )
				treant:FollowEntityMerge( nil, "" )
			end
			if self:GetStackCount() == 0 then
				self:Destroy()
			end
		end
	end
end