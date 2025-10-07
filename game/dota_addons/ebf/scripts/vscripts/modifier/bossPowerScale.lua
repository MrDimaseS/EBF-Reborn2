bossPowerScale = class({})

MAX_STATUS_RESIST = 75
SECONDS_TO_COMBO_BREAK = 10

function bossPowerScale:OnCreated(keys)
	self:SetHasCustomTransmitterData( true )
	self:OnRefresh()
end

function bossPowerScale:OnRefresh(keys)
	local roundNumber = math.floor( self:GetStackCount() / 100 )
	local difficulty = math.floor( ( self:GetStackCount() % 100 ) / 10 )
	local playerNumber = ( self:GetStackCount() % 10 ) / 100
	
	self.roundNumber = roundNumber
	self.difficulty = difficulty
	self.playerNumber = playerNumber
	
	-- function to scale scaling down early on, ramping it up starting from round 17
	local logisticFunction = 0.1 + 1/ ( 1 + math.exp(-0.25*(roundNumber-13)) )
	
	-- remove some base armor and add it to bonus armor
	self.baseArmor = self.baseArmor or self:GetParent():GetPhysicalArmorBaseValue()
	self.bonusArmor = ( ( (1 + difficulty * 0.03) - 1 ) * 100 ) * logisticFunction + (self.baseArmor * 0.6) 
	self.bonusDamagePct = ( ( (1 + playerNumber * 4) - 1 ) * 100 ) * logisticFunction
	
	self.abilityValueIncrease = math.max(0, (-0.65 -19.5*(1 - math.exp(0.03*roundNumber))) )
	if GetMapName() == "strategy_gamemode" then
		self.abilityValueIncrease = self.abilityValueIncrease * 1.25
	end
	
	self.gameDamagePct = (self.difficulty-1) * 20
	if GetMapName() == "strategy_gamemode" then
		self.gameDamagePct = self.gameDamagePct * 1.1
	end
	
	self.treewalk = false
	self.dmgTakenSinceCheck = 0
	
	self.crit_damage = 200
	if self:GetParent():IsConsideredHero() then
		self.crit_chance = 20
		self.evasion = TernaryOperator( 8, self:GetParent():IsRangedAttacker(), 14 ) + 0.5 * playerNumber                                                                                                
		self.baseStatusResistance = 10 + 5 * difficulty
		self.statusResistIncreasePerTick = ( (MAX_STATUS_RESIST - self.baseStatusResistance) / SECONDS_TO_COMBO_BREAK ) * 0.25
		self.actualStatusResistance = self.baseStatusResistance
		self.baseEnrageTimer = (120 - (10*(self.difficulty-1)) )
		self.enrageTimer = self.baseEnrageTimer
	end
	self:StartIntervalThink( 0.25 )
	
	if IsServer() then 
		self:GetParent().bossOriginalModel = self:GetParent():GetModelName() 
		self:GetParent():SetPhysicalArmorBaseValue( self.baseArmor * 0.4 )
		self.bonusDamage = self:GetParent():GetAverageBaseDamage() * self.bonusDamagePct / 100
		self:SendBuffRefreshToClients()
	end
end

function bossPowerScale:OnIntervalThink()
	if IsServer() then
		self.treewalk = not self:GetParent():IsLeashed()
		if self:GetParent():IsInvulnerable() or self:GetParent():IsInvulnerable() or self:GetParent():IsOutOfGame() then return end
		if self.enrageTimer then
			self.enrageTimer = self.enrageTimer - 0.25
			if self.enrageTimer <= 0 then
				self:GetParent():AddNewModifier( self:GetParent(), nil, "modifier_boss_enraged", {} )
				self.enrageTimer = self.baseEnrageTimer
			end
		end
		AddFOWViewer( DOTA_TEAM_BADGUYS, self:GetParent():GetAbsOrigin(), 128, 0.3, false )
	end
	
	if self.baseStatusResistance then
		if self:GetParent():HasModifier("status_immune") then return end
		if self:GetParent():IsStunned() or self:GetParent():IsHexed() or self:GetParent():IsFeared()
		or self:GetParent():IsSilenced() or self:GetParent():IsDisarmed() 
		or self:GetParent():IsRooted() or self:GetParent():PassivesDisabled() then
			if self.actualStatusResistance == MAX_STATUS_RESIST then -- make status immune for 5 seconds.
				if IsServer() then 
					EmitSoundOn( "DOTA_Item.BlackKingBar.Activate", self:GetParent() )
					self:GetParent():AddNewModifier( self:GetParent(), nil, "status_immune", {duration = 6} )
				end
				self.actualStatusResistance = self.baseStatusResistance
			else
				local statusResistIncrease = self.statusResistIncreasePerTick
				if self:GetParent():IsStunned() or self:GetParent():IsHexed() or self:GetParent():IsFeared() then
					statusResistIncrease = self.statusResistIncreasePerTick * 1.5
				elseif self:GetParent():IsSilenced() or self:GetParent():IsDisarmed() then
					statusResistIncrease = self.statusResistIncreasePerTick * 1.25
				end
				self.actualStatusResistance = math.min( self.actualStatusResistance + statusResistIncrease, MAX_STATUS_RESIST )
			end
		elseif self.baseStatusResistance < self.actualStatusResistance then
			self.actualStatusResistance = math.max( self.actualStatusResistance - self.statusResistIncreasePerTick, self.baseStatusResistance )
		end
	end
end

function bossPowerScale:CheckState()
	local states = {}
	if self.treewalk  then
		states[MODIFIER_STATE_ALLOW_PATHING_THROUGH_TREES] = true
	end
	if self:GetParent():IsConsideredHero() then
		states[MODIFIER_STATE_NO_HEALTH_BAR] = true
	end
	if self:GetParent():IsHexed() then
		states[MODIFIER_STATE_PASSIVES_DISABLED] = true
	end
	return states
end

function bossPowerScale:GetAttributes()
  return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE --+ MODIFIER_ATTRIBUTE_MULTIPLE
end

function bossPowerScale:AddCustomTransmitterData()
	return {
		bonusDamage = self.bonusDamage,
		bonusArmor = self.bonusArmor,
		bossOriginalModel = self.bossOriginalModel,
	}
end

function bossPowerScale:HandleCustomTransmitterData( data )
	self.bonusDamage = data.bonusDamage
	self.bonusArmor = data.bonusArmor
	self.bossOriginalModel = data.bossOriginalModel
end

function bossPowerScale:DeclareFunctions()
  local funcs = {
	MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
	MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
	MODIFIER_EVENT_ON_TAKEDAMAGE,
	MODIFIER_EVENT_ON_ABILITY_START,
	MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
	MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
	MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
	MODIFIER_PROPERTY_EVASION_CONSTANT,
	MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE
  }
  return funcs
end

function bossPowerScale:OnAbilityFullyCast(event)
	if event.ability and event.ability:GetAbilityKeyValues().AbilityGlobalSharedCooldown then
		local cooldown = tonumber(event.ability:GetAbilityKeyValues().AbilityGlobalSharedCooldown) or -1
		local abilityName = event.ability:GetAbilityName()
		if cooldown > 0 then
			for _, unit in ipairs( FindAllUnits() ) do
				local ability = unit:FindAbilityByName( abilityName )
				if ability and ability:GetCooldownTimeRemaining() < cooldown then
					ability:SetCooldown( cooldown )
				end
			end
		end
	end
end


function bossPowerScale:GetModifierOverrideAbilitySpecial(params)
	if self._lockForProcessing then return end
	if GameRules._processValuesForScaling == nil then
		GameRules._processValuesForScaling = {}
	end
	if GameRules._processValuesForScaling[params.ability:GetAbilityName()] == nil then
		GameRules._processValuesForScaling[params.ability:GetAbilityName()] = {}
	end
	local special_value = params.ability_special_value:gsub("%#", "")
	if special_value == "AbilityCooldown" or special_value == "AbilityCharges" or special_value == "AbilityManaCost" or special_value == "AbilityCastRange" or special_value == "AbilityDuration" then
		return
	end
	if GameRules._processValuesForScaling[params.ability:GetAbilityName()][special_value] == nil then
		local abilityValues = GetAbilityKeyValuesByName(params.ability:GetAbilityName()).AbilityValues
		if abilityValues then
			for specialValue, valueData in pairs( abilityValues ) do
				GameRules._processValuesForScaling[params.ability:GetAbilityName()][specialValue] = {}
				GameRules._processValuesForScaling[params.ability:GetAbilityName()][specialValue].affected_by_lvl_increase = false
				if type(valueData) == "table" then -- check for adjustments
					if toboolean(valueData.CalculateSpellDamageTooltip)
					or toboolean(valueData.CalculateSpellHealTooltip)
					or toboolean(valueData.CalculateAttackDamageTooltip)
					or toboolean(valueData.CalculateAttributeTooltip) then
						GameRules._processValuesForScaling[params.ability:GetAbilityName()][specialValue].affected_by_lvl_increase = true
					end
				elseif specialValue == "AbilityDamage" then
					GameRules._processValuesForScaling[params.ability:GetAbilityName()][specialValue].affected_by_lvl_increase = true
				end
			end
		end
	end
	if GameRules._processValuesForScaling[params.ability:GetAbilityName()][special_value] == nil then
		GameRules._processValuesForScaling[params.ability:GetAbilityName()][special_value] = false -- not found
	end
	if GameRules._processValuesForScaling[params.ability:GetAbilityName()][special_value]
	and GameRules._processValuesForScaling[params.ability:GetAbilityName()][special_value].affected_by_lvl_increase then
		return 1
	end
end

function bossPowerScale:GetModifierOverrideAbilitySpecialValue(params)
	self._lockForProcessing = true
	local special_value = params.ability_special_value:gsub("%#", "")
	local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( special_value, -1 )
	self._lockForProcessing = false
	if flBaseValue <= 0 then
		return
	end
	if GameRules._processValuesForScaling[params.ability:GetAbilityName()][special_value].affected_by_lvl_increase then
		local flNewValue = flBaseValue * self.abilityValueIncrease
		return flNewValue
	end
end

function bossPowerScale:OnAbilityStart(event)
	if event.unit ~= self:GetParent() then return end
	local radius = 64
	local position
	if event.ability:GetCursorTarget() then
		position = event.ability:GetCursorTarget():GetAbsOrigin()
		radius = event.ability:GetCursorTarget():GetPaddedCollisionRadius() + 120
	elseif event.ability:GetCursorTargetingNothing() then
		position = event.unit:GetAbsOrigin()
		radius = event.ability:GetTrueCastRange( ) - event.unit:GetCastRangeBonus()
	else
		position = event.ability:GetCursorPosition()
		radius = event.ability:GetAOERadius( )
	end
	ParticleManager:FireWarningParticle(position, radius)
	event.unit:MakeVisibleToTeam(DOTA_TEAM_GOODGUYS, 1.5)
end

function bossPowerScale:OnTakeDamage(event)
	local parent = self:GetParent()
	if event.unit == parent then
		if not event.attacker:CanBeSeenByAnyOpposingTeam() then
			parent:MakeVisibleToTeam(DOTA_TEAM_BADGUYS, 1.5)
		end
	elseif event.attacker == parent and not parent:CanBeSeenByAnyOpposingTeam() then
		parent:MakeVisibleToTeam(DOTA_TEAM_GOODGUYS, 1.5)
	end
end

function bossPowerScale:GetModifierBaseDamageOutgoing_Percentage(event)
	return self.gameDamagePct
end

function bossPowerScale:GetModifierPhysicalArmorBonus(event)
	return self.bonusArmor
end

function bossPowerScale:GetModifierPreAttack_BonusDamage(event)
	return self.bonusDamage
end

function bossPowerScale:GetModifierStatusResistanceStacking(event)
	return self.baseStatusResistance
end


function bossPowerScale:GetModifierEvasion_Constant(event)
	return self.evasion
end

function bossPowerScale:GetModifierPreAttack_CriticalStrike()
	if not IsServer() then return end
	if self:RollPRNG( self.crit_chance ) then
		return self.crit_damage
	end
end

function bossPowerScale:GetCritDamage()
	return self.crit_damage / 100
end

function bossPowerScale:IsHidden()
  return true
end

function bossPowerScale:IsDebuff()
  return false
end

function bossPowerScale:IsPurgable()
  return false
end

function bossPowerScale:RemoveOnDeath()
	return true
end