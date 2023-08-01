boss_zombie_tombstone = class({})

function boss_zombie_tombstone:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	local duration = self:GetSpecialValueFor("duration")
	local tombstone = self:GetCaster():CreateSummon( "npc_dota_unit_tombstone4", caster:GetAbsOrigin() - caster:GetForwardVector() * 128, duration, false )
	
	tombstone:AddNewModifier(caster, self, "modifier_boss_zombie_tombstone", {duration = duration})
	tombstone:SetBaseMaxHealth( self:GetSpecialValueFor("tombstone_health") * HeroList:GetActiveHeroCount() )
	tombstone:SetMaxHealth( self:GetSpecialValueFor("tombstone_health") * HeroList:GetActiveHeroCount() )
	tombstone:SetHealth( tombstone:GetMaxHealth() )
	
	tombstone:SetMaximumGoldBounty( 0 )
	tombstone:SetMinimumGoldBounty( 0 )
	tombstone:SetDeathXP( 0 )
end


modifier_boss_zombie_tombstone = class({})
LinkLuaModifier( "modifier_boss_zombie_tombstone", "bosses/boss_zombies/boss_zombie_tombstone", LUA_MODIFIER_MOTION_NONE)

if IsServer() then
	function modifier_boss_zombie_tombstone:OnCreated( )
		self.spawnInterval = self:GetTalentSpecialValueFor("zombie_interval")
		self.zombieCost = self:GetTalentSpecialValueFor("zombie_cost")
		self.zombiesSpawned = 0
		self.spawnRadius = self:GetTalentSpecialValueFor("radius")
		
		self:StartIntervalThink( self.spawnInterval )
		self:OnIntervalThink( )
	end
	
	function modifier_boss_zombie_tombstone:OnIntervalThink()
		local caster = self:GetCaster()
		local tombstone = self:GetParent()
		local ability = self:GetAbility()
		
		for _, enemy in ipairs( tombstone:FindEnemyUnitsInRadius( tombstone:GetAbsOrigin(), self.spawnRadius, {type = DOTA_UNIT_TARGET_HERO} ) ) do
			if enemy:IsRealHero() and RollPercentage( 50 ) then
				local zombie = CreateUnitByName( "npc_dota_boss_zombie_minion", enemy:GetAbsOrigin() + RandomVector( 250 ), true, nil, nil, tombstone:GetTeam() )
				self.zombiesSpawned = self.zombiesSpawned + 1
				local hp = tombstone:GetHealth()
				if self.zombiesSpawned >= self.zombieCost then
					if hp > 1 then
						tombstone:SetHealth( hp - 1 )
					else
						tombstone:StartGesture(ACT_DOTA_DIE)
						tombstone:Kill(ability, caster)
					end
					self.zombiesSpawned = 0
				end
			end
		end
	end
end

function modifier_boss_zombie_tombstone:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE}
end

function modifier_boss_zombie_tombstone:GetModifierIncomingDamage_Percentage(params)
	local parent = self:GetParent()
	if params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
		local hp = parent:GetHealth()
		if hp > 1 then
			parent:SetHealth( hp - 1 )
		else
			self:GetParent():StartGesture(ACT_DOTA_DIE)
			parent:Kill(params.inflictor, params.attacker)
		end
	end
	return -999
end

function modifier_boss_zombie_tombstone:GetDisableHealing( params )
	return 1
end

function modifier_boss_zombie_tombstone:IsHidden()
	return true
end

function modifier_boss_zombie_tombstone:IsPurgable()
	return false
end
