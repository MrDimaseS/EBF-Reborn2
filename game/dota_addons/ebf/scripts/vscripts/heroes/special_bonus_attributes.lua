special_bonus_attributes = class({})

ABILITY_POWER_SCALING = 0.2

function special_bonus_attributes:OnHeroLevelUp()
	local hero = self:GetCaster()
	if hero:IsIllusion() then return end
	local heroLvl = hero:GetLevel()
	
	hero:ModifyStrength( hero._internalStrGain - hero:GetStrengthGain() ) 
	hero:ModifyAgility( hero._internalAgiGain - hero:GetAgilityGain() ) 
	hero:ModifyIntellect( hero._internalIntGain - hero:GetIntellectGain() )
	
	local heroPowerBonus = ABILITY_POWER_SCALING+self:GetSpecialValueFor("value") / 100
	-- calculate current level attributes
	local totalHeroPowerBonus = 1 + heroPowerBonus * (heroLvl - 1)
	local currentIntendedStr = (self.originalBaseStr + hero:GetStrengthGain() * (heroLvl-1) ) * totalHeroPowerBonus
	local currentIntendedAgi = (self.originalBaseAgi + hero:GetAgilityGain() * (heroLvl-1) ) * totalHeroPowerBonus
	local currentIntendedInt = (self.originalBaseInt + hero:GetIntellectGain() * (heroLvl-1) ) * totalHeroPowerBonus
	-- calculate next level attributes
	local totalHeroPowerBonusNext = 1 + heroPowerBonus * heroLvl
	local nextIntendedStr = (self.originalBaseStr + hero:GetStrengthGain() * heroLvl ) * totalHeroPowerBonusNext
	local nextIntendedAgi = (self.originalBaseAgi + hero:GetAgilityGain() * heroLvl ) * totalHeroPowerBonusNext
	local nextIntendedInt = (self.originalBaseInt + hero:GetIntellectGain() * heroLvl ) * totalHeroPowerBonusNext
	
	hero._internalStrGain = self.originalBaseStr * heroPowerBonus + 2 * hero:GetStrengthGain() * heroPowerBonus * heroLvl + hero:GetStrengthGain()
	hero._internalAgiGain = self.originalBaseAgi * heroPowerBonus + 2 * hero:GetAgilityGain() * heroPowerBonus * heroLvl + hero:GetAgilityGain()
	hero._internalIntGain = self.originalBaseInt * heroPowerBonus + 2 * hero:GetIntellectGain() * heroPowerBonus * heroLvl + hero:GetIntellectGain()
	
	self:SendUpdatedInventoryContents( info )
	self:UpdatePersistentModifiers( )
	CustomGameEventManager:Send_ServerToAllClients( "hero_leveled_up", {unit = self:GetCaster():entindex()} )
end

function special_bonus_attributes:OnUpgrade()
	local hero = self:GetCaster()
	if hero:IsIllusion() then return end
	local heroLvl = hero:GetLevel() - 1
		
	local heroPowerBonus = ABILITY_POWER_SCALING+self:GetSpecialValueFor("value") / 100
	local prevHeroPowerBonus = ABILITY_POWER_SCALING
	if self:GetLevel() > 1 then
		prevHeroPowerBonus = prevHeroPowerBonus + self:GetLevelSpecialValueFor( "value", self:GetLevel()-2 ) / 100
	end
	
	-- calculate current level attributes
	local totalHeroPowerBonus = 1 + prevHeroPowerBonus * heroLvl
	local currentIntendedStr = (self.originalBaseStr + hero:GetStrengthGain() * heroLvl ) * totalHeroPowerBonus
	local currentIntendedAgi = (self.originalBaseAgi + hero:GetAgilityGain() * heroLvl ) * totalHeroPowerBonus
	local currentIntendedInt = (self.originalBaseInt + hero:GetIntellectGain() * heroLvl ) * totalHeroPowerBonus
	-- calculate next level attributes
	local totalHeroPowerBonusNext = 1 + heroPowerBonus * heroLvl
	local nextIntendedStr = (self.originalBaseStr + hero:GetStrengthGain() * heroLvl ) * totalHeroPowerBonusNext
	local nextIntendedAgi = (self.originalBaseAgi + hero:GetAgilityGain() * heroLvl ) * totalHeroPowerBonusNext
	local nextIntendedInt = (self.originalBaseInt + hero:GetIntellectGain() * heroLvl ) * totalHeroPowerBonusNext
	
	hero:ModifyStrength( nextIntendedStr - currentIntendedStr ) 
	hero:ModifyAgility( nextIntendedAgi - currentIntendedAgi ) 
	hero:ModifyIntellect( nextIntendedInt - currentIntendedInt )
	
	self:SendUpdatedInventoryContents( info )
	self:UpdatePersistentModifiers( )
	CustomGameEventManager:Send_ServerToAllClients( "update_talent_pips", {unit = self:GetCaster():entindex()} )
end

function special_bonus_attributes:UpdatePersistentModifiers()
	local hero = self:GetCaster()
	local shields = hero:FindModifierByName("modifier_item_artifact_of_shields_buff")
	if shields then
		shields:OnStackCountChanged()
	end
	local blades = hero:FindModifierByName("modifier_item_artifact_of_blades_buff")
	if blades then
		blades:OnStackCountChanged()
	end
	local wands = hero:FindModifierByName("modifier_item_artifact_of_wands_buff")
	if wands then
		wands:OnStackCountChanged()
	end
	local balance = hero:FindModifierByName("modifier_item_artifact_of_balance_buff")
	if balance then
		balance:OnStackCountChanged()
	end
end

function special_bonus_attributes:Spawn()
	if not IsServer() then return end
	local hero = self:GetCaster()
	
	local heroName = hero:GetUnitName()
	local originalHero
	for _, ogHero in ipairs( HeroList:GetRealHeroes() ) do
		if heroName == ogHero:GetUnitName() then
			originalHero = ogHero
		end
	end
	
	-- security check
	self.originalBaseStr = hero:GetBaseStrength()
	self.originalBaseAgi = hero:GetBaseAgility()
	self.originalBaseInt = hero:GetBaseIntellect()
	
	hero._internalStrGain = hero:GetStrengthGain() + (self.originalBaseStr + hero:GetStrengthGain()) * ABILITY_POWER_SCALING
	hero._internalAgiGain = hero:GetAgilityGain() + (self.originalBaseAgi + hero:GetAgilityGain()) * ABILITY_POWER_SCALING
	hero._internalIntGain = hero:GetIntellectGain() + (self.originalBaseInt + hero:GetIntellectGain()) * ABILITY_POWER_SCALING
	
	hero._originalPrimaryValue = hero:GetPrimaryAttribute()
	
	Timers:CreateTimer(function()
		-- delay for KV overrides
		self.originalBaseStr = hero:GetBaseStrength()
		self.originalBaseAgi = hero:GetBaseAgility()
		self.originalBaseInt = hero:GetBaseIntellect()
		
		hero._internalStrGain = hero:GetStrengthGain() + (self.originalBaseStr + hero:GetStrengthGain()) * ABILITY_POWER_SCALING
		hero._internalAgiGain = hero:GetAgilityGain() + (self.originalBaseAgi + hero:GetAgilityGain()) * ABILITY_POWER_SCALING
		hero._internalIntGain = hero:GetIntellectGain() + (self.originalBaseInt + hero:GetIntellectGain()) * ABILITY_POWER_SCALING
		
		hero._originalPrimaryValue = hero:GetPrimaryAttribute()
	end)
	
	hero._attributesAbility = self

	Timers:CreateTimer( 0.1, function()
		hero:AddNewModifier( originalHero or hero, self, "modifier_special_bonus_attributes_stat_rescaling", {} )
		if originalHero then
			hero:ModifyStrength( originalHero:GetBaseStrength() - hero:GetBaseStrength() )
			hero:ModifyAgility( originalHero:GetBaseAgility() - hero:GetBaseAgility() )
			hero:ModifyIntellect( originalHero:GetBaseIntellect() - hero:GetBaseIntellect() )
		end
	end )
end

function special_bonus_attributes:OnHeroCalculateStatBonus()
	if not IsEntitySafe( self ) then return end
	local hero = self:GetCaster() 
	local modifier = self:GetCaster():FindModifierByName("modifier_special_bonus_attributes_stat_rescaling")
	
	if modifier then 
		modifier:SetStackCount( self:GetCaster():GetPrimaryAttribute() )
		modifier:ForceRefresh()
	end
end

function special_bonus_attributes:OnInventoryContentsChanged()
	local itemsMerged = false
	if not IsEntitySafe( self ) then return end
	if not IsEntitySafe( self:GetCaster() ) then return end
	if self:GetCaster():IsIllusion( ) then return end
	local parent = self:GetCaster()
	for i=0, DOTA_STASH_SLOT_6 do
		local item = parent:GetItemInSlot( i )
		if IsEntitySafe( item )
		and item:GetLevel() < item:GetMaxLevel()
		and not item:IsCombineLocked() 
		and item:GetPurchaser():GetPlayerOwnerID() == parent:GetPlayerOwnerID() then -- item can be upgraded at all
			local itemType = (item:GetAbilityName():gsub('%W','')):gsub('_','')
			for j=0, DOTA_STASH_SLOT_6 do
				local itemToCheck = parent:GetItemInSlot( j )
				if IsEntitySafe( itemToCheck )
				and item ~= itemToCheck
				and not itemToCheck:IsCombineLocked() then
					local itemToCheckType = (itemToCheck:GetAbilityName():gsub('%W','')):gsub('_','')
					if itemToCheckType == itemType
					and item:GetLevel() == itemToCheck:GetLevel()
					and itemToCheck:GetPurchaser():GetPlayerOwnerID() == parent:GetPlayerOwnerID() then
						itemToCheck:Destroy()
						-- update innate
						local passive = parent:FindModifierByNameAndAbility( item:GetIntrinsicModifierName(), item )
						if passive then
							passive:Destroy()
						end
						item:UpgradeAbility( false )
						if i > DOTA_ITEM_SLOT_6 then
							local intrinsic = parent:FindModifierByNameAndAbility( item:GetIntrinsicModifierName(), item )
							if intrinsic then
								intrinsic:Destroy()
							end
						end
						itemsMerged = true
						EmitSoundOnClient("General.Combine", parent:GetPlayerOwner() )
						-- item:RefreshIntrinsicModifier()
					end
				end
			end
		end
	end
	if itemsMerged then
		-- see if combined item needs to be merged again
		self:OnInventoryContentsChanged()
	else
		Timers:CreateTimer( function() self:SendUpdatedInventoryContents({unit = self:GetCaster():entindex()}) end )
	end
end

ITEM_LEVELS = {"COMMON", "SHADOW", "DEMONIC", "DIVINE", "OTHERWORLDLY"}

function special_bonus_attributes:SendUpdatedInventoryContents( info )
	if IsEntitySafe( self ) and not self.stopUnnecessaryUpdates and IsEntitySafe( self:GetCaster() ) then
		self.stopUnnecessaryUpdates = true
		local inventory = {}
		for i = 0, 8 do
			local item = self:GetCaster():GetItemInSlot(i)
			if IsEntitySafe(item) then
				inventory[i] = item:GetAbilityKeyValues()
				inventory[i].AbilityTier = (#ITEM_LEVELS - item:GetMaxLevel()) + item:GetLevel()
				inventory[i].AbilityTierDescription = ITEM_LEVELS[inventory[i].AbilityTier]
				inventory[i].AbilityName = item:GetAbilityName()
				inventory[i].IsCombineLocked = item:IsCombineLocked()
			else
				inventory[i] = -1
			end
		end
		local artifact = self:GetCaster():GetItemInSlot(DOTA_ITEM_NEUTRAL_ACTIVE_SLOT)
		if IsEntitySafe(artifact) then
			inventory[9] = artifact:GetAbilityKeyValues()
		else
			inventory[9] = -1
		end
		local enchantment = self:GetCaster():GetItemInSlot(DOTA_ITEM_NEUTRAL_PASSIVE_SLOT)
		if IsEntitySafe(enchantment) then
			inventory[10] = enchantment:GetAbilityKeyValues()
		else
			inventory[10] = -1
		end
		CustomGameEventManager:Send_ServerToAllClients( "client_update_ability_kvs", {unit = self:GetCaster():entindex(), inventory = inventory} )
		CustomGameEventManager:Send_ServerToAllClients( "hero_leveled_up", {unit = self:GetCaster():entindex()} )
		Timers:CreateTimer( function() self.stopUnnecessaryUpdates = false end )
	end
end

modifier_special_bonus_attributes_stat_rescaling = class({})
LinkLuaModifier( "modifier_special_bonus_attributes_stat_rescaling", "heroes/special_bonus_attributes", LUA_MODIFIER_MOTION_NONE )

function modifier_special_bonus_attributes_stat_rescaling:GetAttributes()
  return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE --+ MODIFIER_ATTRIBUTE_MULTIPLE
end

HP_AMP_PER_STR = 0.8
MP_AMP_PER_INT = 0.8

function modifier_special_bonus_attributes_stat_rescaling:OnCreated()
	self:GetParent()._heroManaType = (CustomNetTables:GetTableValue("hero_attributes", tostring(self:GetParent():entindex())) or {}).mana_type or "Mana"
	
	local UNITKV =  GetUnitKeyValuesByName(self:GetParent():GetUnitName())
	
	self.baseManaRegen = 5
	if self:GetParent()._heroManaType ~= "Mana" then
		self.baseMana = 0
		self.baseManaRegen = 0
	end

	self.bonusSpellAmp = 0.02
	self.bonusDamage = 1.5
	self.baseArmor = tonumber(UNITKV.ArmorPhysical) + 0.10 * tonumber(UNITKV.AttributeBaseAgility)
	self.baseMR = 0
	self.baseAttackSpeed = self:GetParent():GetAgility() * 0.8
	self.baseDamage = ( tonumber(UNITKV.AttackDamageMin) + tonumber(UNITKV.AttackDamageMax) ) / 2
	self:GetParent()._baseArmorForIllusions = self.baseArmor
	self:GetParent()._primaryAttribute = self:GetParent():GetPrimaryAttribute()
	
	self.internal_ability_scaling = ABILITY_POWER_SCALING + self:GetSpecialValueFor("value") / 100
	
	self:GetParent().cooldownModifiers = {}
	self:GetParent()._aoeModifiersList = {}
	self:GetParent()._critModifiersList = {}
	self:GetParent()._chanceModifiersList = {}
	self:GetParent()._pureLifestealModifiersList = {}
	self:GetParent()._spellLifestealModifiersList = {}
	self:GetParent()._attackLifestealModifiersList = {}
	self:GetParent()._pureLifestealTargetModifiersList = {}
	self:GetParent()._spellLifestealTargetModifiersList = {}
	self:GetParent()._attackLifestealTargetModifiersList = {}
	self:GetParent()._onLifestealModifiersList = {}
	
	self:OnRefresh()
	if IsServer() then
		self:SetStackCount( self:GetParent():GetPrimaryAttribute() )
		
		if self:GetParent()._heroManaType == "Rage" then
			Timers:CreateTimer( 0.1, function() self:GetParent():AddNewModifier( self:GetParent(), self:GetAbility(), "modifier_hero_rage_system", {} ) end )
		elseif self:GetParent()._heroManaType == "Stamina" then
			Timers:CreateTimer( 0.1, function() self:GetParent():AddNewModifier( self:GetParent(), self:GetAbility(), "modifier_hero_stamina_system", {} ) end )
		end
		if not self:GetParent():IsFakeHero() then
			self:StartIntervalThink( 0.3 )
		end
		self:SetHasCustomTransmitterData(true)
	end
end

function modifier_special_bonus_attributes_stat_rescaling:OnRefresh()
	if not IsEntitySafe( self:GetParent() ) then return end
	-- self.attackspeed = self.baseAttackSpeed + math.floor( 0.1 * self:GetParent():GetAgility() )
	-- self:GetParent()._internalBaseAttackSpeedBonus = self.attackspeed
	self.total_ability_scaling = 1 + (self:GetCaster():GetLevel() - 1) * self.internal_ability_scaling
	if IsServer() then
		-- if self.baseArmor then
			-- local agilityArmor = 0.015 * self:GetParent():GetAgility()
			-- self:GetParent():SetPhysicalArmorBaseValue( self.baseArmor + agilityArmor )
			-- Timers:CreateTimer( function() -- illusion fix, idk why the fuck it needs a frame delay for them
				-- if not IsEntitySafe( self:GetParent() ) then return end
				-- self:GetParent():SetPhysicalArmorBaseValue( self.baseArmor + agilityArmor )
			-- end)
		-- end
		-- if self.baseMR then
			-- local intArmor =  1-(1-0.003)^(math.floor(self:GetParent():GetIntellect(false)/10)) + 0.003 * (self:GetParent():GetIntellect(false)%10)
			-- local totalVal = -self:GetParent():GetIntellect(false) * 0.1 + self.baseMR + intArmor*100
			-- self:GetParent():SetBaseMagicalResistanceValue( totalVal )
			-- Timers:CreateTimer( function() -- illusion fix, idk why the fuck it needs a frame delay for them
				-- if not IsEntitySafe( self:GetParent() ) then return end
				-- self:GetParent():SetBaseMagicalResistanceValue( totalVal )
			-- end)
		-- end
	end
end	

function modifier_special_bonus_attributes_stat_rescaling:OnIntervalThink()
	CustomNetTables:SetTableValue("hero_attributes", tostring( self:GetCaster():entindex() ), {mana_type = self:GetCaster()._heroManaType, strength = self:GetCaster():GetStrength(), agility = self:GetCaster():GetAgility(), intellect = self:GetCaster():GetIntellect(false), str_gain = self:GetCaster()._internalStrGain, agi_gain = self:GetCaster()._internalAgiGain, int_gain = self:GetCaster()._internalIntGain, spell_amp = self:GetCaster():GetSpellAmplification( false ), innate = self:GetCaster()._innateAbilityName, facetID = self:GetCaster():GetHeroFacetID(), primaryStat = self:GetCaster()._originalPrimaryValue})
end

function modifier_special_bonus_attributes_stat_rescaling:CheckState()
	return {[MODIFIER_STATE_ALLOW_PATHING_THROUGH_TREES] = true}
end

function modifier_special_bonus_attributes_stat_rescaling:DeclareFunctions()
  local funcs = {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
		MODIFIER_PROPERTY_CASTTIME_PERCENTAGE,
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
		MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
		MODIFIER_PROPERTY_EVASION_CONSTANT,
		MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_ON_ABILITY_START,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DIRECT_MODIFICATION 
  }
  return funcs
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierMagicalResistanceDirectModification(params)
	local intArmor =  1-(1-0.002)^(math.floor(self:GetParent():GetIntellect(false)/10)) + 0.002 * (self:GetParent():GetIntellect(false)%10)
	return -self:GetParent():GetIntellect(false) * 0.1 + intArmor * 100 - 25
end

function modifier_special_bonus_attributes_stat_rescaling:OnAbilityStart(params)
	if params.unit ~= self:GetParent() then return end
	params.unit:MakeVisibleToTeam(DOTA_TEAM_BADGUYS, 1.5)
end

function modifier_special_bonus_attributes_stat_rescaling:OnTakeDamage(params)
	if params.attacker ~= self:GetParent() then return end
	params.attacker:MakeVisibleToTeam(DOTA_TEAM_BADGUYS, 1.5)
	
	
	local lifestealParams = {unit = params.attacker, heal = 0, excess = 0, damage_category = params.damage_category, damage = params.damage}
	
	if params.damage_type == DAMAGE_TYPE_PURE then
		local pureLifestealPct = 0
		for modifier, active in pairs( params.unit._pureLifestealTargetModifiersList or {} ) do
			if IsModifierSafe( modifier ) then
				if modifier.GetModifierProperty_PureLifestealTarget and (modifier:GetModifierProperty_PureLifestealTarget( params ) or 0) > 0 then
					attackLifestealPct = attackLifestealPct + modifier:GetModifierProperty_PureLifestealTarget( params )
				end
			else
				self:GetCaster()._pureLifestealTargetModifiersList[modifier] = nil
			end
		end
		for modifier, active in pairs( params.attacker._pureLifestealModifiersList or {} ) do
			if IsModifierSafe( modifier ) then
				if modifier.GetModifierProperty_PureLifesteal and (modifier:GetModifierProperty_PureLifesteal( params ) or 0) > 0 then
					attackLifestealPct = attackLifestealPct + modifier:GetModifierProperty_PureLifesteal( params )
				end
			else
				self:GetCaster()._pureLifestealModifiersList[modifier] = nil
			end
		end
		if not params.unit:IsConsideredHero() then
			attackLifestealPct =  attackLifestealPct * (100 - 40)/100
		end
		local heal = params.damage * attackLifestealPct / 100
		self.lifeToGive = (self.lifeToGive or 0) + heal
	elseif params.damage_category == DOTA_DAMAGE_CATEGORY_SPELL then
		if HasBit( params.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL ) or HasBit( params.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS ) or HasBit( params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION ) then return end
		local spellLifestealPct = 0
		for modifier, active in pairs( params.unit._spellLifestealTargetModifiersList or {} ) do
			if IsModifierSafe( modifier ) then
				if modifier.GetModifierProperty_MagicalLifestealTarget and (modifier:GetModifierProperty_MagicalLifestealTarget( params ) or 0) > 0 then
					spellLifestealPct = spellLifestealPct + modifier:GetModifierProperty_MagicalLifestealTarget( params )
				end
			else
				self:GetCaster()._spellLifestealTargetModifiersList[modifier] = nil
			end
		end
		
		for modifier, active in pairs( params.attacker._spellLifestealModifiersList or {} ) do
			if IsModifierSafe( modifier ) then
				if modifier.GetModifierProperty_MagicalLifesteal and (modifier:GetModifierProperty_MagicalLifesteal( params ) or 0) > 0 then
					spellLifestealPct = spellLifestealPct + modifier:GetModifierProperty_MagicalLifesteal( params )
				end
			else
				self:GetCaster()._spellLifestealModifiersList[modifier] = nil
			end
		end
		
		if not params.unit:IsConsideredHero() then
			spellLifestealPct =  spellLifestealPct * (100 - 80)/100
		end
		local heal = params.damage * spellLifestealPct / 100
		self.lifeToGive = (self.lifeToGive or 0) + heal
	elseif params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
		local attackLifestealPct = 0
		for modifier, active in pairs( params.unit._attackLifestealTargetModifiersList or {} ) do
			if IsModifierSafe( modifier ) then
				if modifier.GetModifierProperty_PhysicalLifestealTarget and (modifier:GetModifierProperty_PhysicalLifestealTarget( params ) or 0) > 0 then
					attackLifestealPct = attackLifestealPct + modifier:GetModifierProperty_PhysicalLifestealTarget( params )
				end
			else
				self:GetCaster()._attackLifestealTargetModifiersList[modifier] = nil
			end
		end
		for modifier, active in pairs( params.attacker._attackLifestealModifiersList or {} ) do
			if IsModifierSafe( modifier ) then
				if modifier.GetModifierProperty_PhysicalLifesteal and (modifier:GetModifierProperty_PhysicalLifesteal( params ) or 0) > 0 then
					attackLifestealPct = attackLifestealPct + modifier:GetModifierProperty_PhysicalLifesteal( params )
				end
			else
				self:GetCaster()._attackLifestealModifiersList[modifier] = nil
			end
		end
		if not params.unit:IsConsideredHero() then
			attackLifestealPct =  attackLifestealPct * (100 - 40)/100
		end
		local heal = params.damage * attackLifestealPct / 100
		self.lifeToGive = (self.lifeToGive or 0) + heal
	end
	if (self.lifeToGive or 0) > 1 then
		local preHP = params.attacker:GetHealth()
		params.attacker:HealWithParams( self.lifeToGive, params.inflictor, false, true, self, true )
		local postHP = params.attacker:GetHealth()
		local realHeal = postHP - preHP
		lifestealParams.heal = lifestealParams.heal + realHeal
		lifestealParams.excess = lifestealParams.excess + math.max( 0, self.lifeToGive - realHeal )
		self.lifeToGive = self.lifeToGive - math.floor(self.lifeToGive)
	end
	if lifestealParams.heal + lifestealParams.excess > 0 then
		if lifestealParams.heal > 0 then
			if lifestealParams.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
				ParticleManager:FireParticle( "particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_POINT_FOLLOW, params.attacker )
			elseif lifestealParams.damage_category == DOTA_DAMAGE_CATEGORY_SPELL then
				ParticleManager:FireParticle( "particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_POINT_FOLLOW, params.attacker )
			end
			SendOverheadEventMessage( params.attacker:GetPlayerOwner(), OVERHEAD_ALERT_HEAL, params.attacker, lifestealParams.heal, params.attacker:GetPlayerOwner() )
		end
		for modifier, active in pairs( self:GetCaster()._onLifestealModifiersList or {} ) do
			if IsModifierSafe( modifier ) and modifier.OnLifesteal then
				modifier:OnLifesteal( lifestealParams )
			else
				self:GetCaster()._onLifestealModifiersList[modifier] = nil
			end
		end
	end
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierEvasion_Constant()
	if self:GetParent():IsStunned() or self:GetParent():IsHexed() or self:GetParent():IsRooted() then
		return -999
	end
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierPropertyRestorationAmplification()
	return HP_AMP_PER_STR * (self:GetParent():GetStrength() / 100)
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierMPRegenAmplify_Percentage()
	return MP_AMP_PER_INT * (self:GetParent():GetIntellect(false) / 100)
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierOverrideAbilitySpecial(params)
	if self._lockForProcessing then return end
	if params.ability._processValuesForScaling == nil then
		params.ability._processValuesForScaling = {}
	end
	local special_value = params.ability_special_value:gsub("%#", "")
	if params.ability._processValuesForScaling[special_value] == nil then
		local abilityValues = GetAbilityKeyValuesByName(params.ability:GetAbilityName()).AbilityValues
		params.ability._processValuesForScaling[special_value] = {}
		params.ability._processValuesForScaling[special_value].affected_by_aoe_increase = false
		params.ability._processValuesForScaling[special_value].affected_by_crit_increase = false
		params.ability._processValuesForScaling[special_value].affected_by_chance_increase = false
		params.ability._processValuesForScaling[special_value].affected_by_lvl_increase = false
		if abilityValues and abilityValues[special_value] then
			if type(abilityValues[special_value]) == "table" then -- check for adjustments
				if toboolean(abilityValues[special_value].affected_by_aoe_increase) then
					params.ability._processValuesForScaling[special_value].affected_by_aoe_increase = true
				end
				if toboolean(abilityValues[special_value].affected_by_chance_increase) then
					params.ability._processValuesForScaling[special_value].affected_by_chance_increase = true
				end
				if toboolean(abilityValues[special_value].affected_by_crit_increase) then
					params.ability._processValuesForScaling[special_value].affected_by_crit_increase = true
				end
				if toboolean(abilityValues[special_value].CalculateSpellDamageTooltip)
				or toboolean(abilityValues[special_value].CalculateSpellHealTooltip)
				or toboolean(abilityValues[special_value].CalculateAttackDamageTooltip)
				or toboolean(abilityValues[special_value].CalculateAttributeTooltip) then
					params.ability._processValuesForScaling[special_value].affected_by_lvl_increase = true
					params.ability._processValuesForScaling[special_value].lvl_increase_spell_damage_type = toboolean(abilityValues[special_value].CalculateSpellDamageTooltip)
				end
				if abilityValues[special_value].ForceCalculateLevelBonus then
					params.ability._processValuesForScaling[special_value].affected_by_lvl_increase = toboolean(abilityValues.ForceCalculateLevelBonus)
				end
			elseif special_value == "AbilityDamage" then
				params.ability._processValuesForScaling[special_value].affected_by_lvl_increase = true
			end
		end
	end
	if params.ability._processValuesForScaling[special_value]
	and (params.ability._processValuesForScaling[special_value].affected_by_aoe_increase
	or params.ability._processValuesForScaling[special_value].affected_by_crit_increase
	or params.ability._processValuesForScaling[special_value].affected_by_chance_increase
	or params.ability._processValuesForScaling[special_value].affected_by_lvl_increase) then
		return 1
	end
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierOverrideAbilitySpecialValue(params)
	self._lockForProcessing = true
	local special_value = params.ability_special_value:gsub("%#", "")
	local flBaseValue = params.ability:GetLevelSpecialValueFor( special_value, params.ability_special_level )
	self._lockForProcessing = false
	if flBaseValue <= 0 then
		return
	end
	if params.ability._processValuesForScaling[special_value].affected_by_aoe_increase  then
		local aoe_bonus_positive = 0
		local aoe_bonus_positive_pct = 0
		local aoe_bonus_negative = 0
		local aoe_bonus_negative_pct = 0
		for modifier, active in pairs( self:GetCaster()._aoeModifiersList ) do
			if IsModifierSafe( modifier ) then
				if modifier.GetModifierAoEBonusConstant and modifier:GetModifierAoEBonusConstant() then
					if modifier:GetModifierAoEBonusConstant() > 0 then
						aoe_bonus_positive = math.max( aoe_bonus_positive, modifier:GetModifierAoEBonusConstant() )
					else
						aoe_bonus_negative = math.min( aoe_bonus_negative, modifier:GetModifierAoEBonusConstant() )
					end
				end
				if modifier.GetModifierAoEBonusConstantStacking and modifier:GetModifierAoEBonusConstantStacking() then
					if modifier:GetModifierAoEBonusConstantStacking() > 0 then
						aoe_bonus_positive = aoe_bonus_positive + modifier:GetModifierAoEBonusConstantStacking()
					else
						aoe_bonus_negative = aoe_bonus_negative - modifier:GetModifierAoEBonusConstantStacking()
					end
				end
				if modifier.GetModifierAoEBonusPercentage and modifier:GetModifierAoEBonusPercentage() then
					if modifier:GetModifierAoEBonusPercentage() > 0 then
						aoe_bonus_positive_pct = math.max( aoe_bonus_positive_pct, modifier:GetModifierAoEBonusPercentage() )
					else
						aoe_bonus_negative_pct = math.min( aoe_bonus_negative_pct, modifier:GetModifierAoEBonusPercentage() )
					end
				end
			else
				self:GetCaster()._aoeModifiersList[modifier] = nil
			end
		end
		local flNewValue = flBaseValue * (1+(aoe_bonus_positive_pct/100 + aoe_bonus_negative_pct/100)) + aoe_bonus_positive + aoe_bonus_negative
		return math.floor(flNewValue+0.5)
	end
	if params.ability._processValuesForScaling[special_value].affected_by_crit_increase then
		local aoe_bonus_positive = 0
		local aoe_bonus_negative = 0
		for modifier, active in pairs( self:GetCaster()._critModifiersList ) do
			if IsModifierSafe( modifier ) then
				if modifier.GetModifierCriticalStrike_BonusDamage and modifier:GetModifierCriticalStrike_BonusDamage() then
					if modifier:GetModifierCriticalStrike_BonusDamage() > 0 then
						aoe_bonus_positive = math.max( aoe_bonus_positive, modifier:GetModifierCriticalStrike_BonusDamage() )
					else
						aoe_bonus_negative = math.min( aoe_bonus_negative, modifier:GetModifierCriticalStrike_BonusDamage() )
					end
				end
			else
				self:GetCaster()._critModifiersList[modifier] = nil
			end
		end
		local flNewValue = flBaseValue + aoe_bonus_positive + aoe_bonus_negative
		return math.floor(flNewValue+0.5)
	end
	if params.ability._processValuesForScaling[special_value].affected_by_chance_increase then
		local chance_bonus = 0
		for modifier, active in pairs( self:GetCaster()._chanceModifiersList ) do
			if IsModifierSafe( modifier ) then
				if modifier.GetModifierChanceBonusConstant and modifier:GetModifierChanceBonusConstant() then
					chance_bonus = chance_bonus + modifier:GetModifierChanceBonusConstant()/100
				end
			else
				self:GetCaster()._chanceModifiersList[modifier] = nil
			end
		end
		if chance_bonus == 0 then
			return flBaseValue
		end
		local flNewValue = flBaseValue/100
		if chance_bonus > 0 then
			flNewValue = math.min( 1-(1-flNewValue)/(1+chance_bonus), flNewValue * (1+chance_bonus) )
		else
			flNewValue = flNewValue/(1+chance_bonus)
		end
		return math.floor(flNewValue * 10000)/100
	end
	if params.ability._processValuesForScaling[special_value].affected_by_lvl_increase then
		local flNewValue = flBaseValue * self.total_ability_scaling
		if params.ability._processValuesForScaling[special_value].lvl_increase_spell_damage_type then
			local SPELL_AMP_PRIMARY = 0.025
			local SPELL_AMP_INT = 0.025
			local SPELL_AMP_UNIVERSAL = 0.0133
			local bonusBaseSpellDamagePct = 0
			if self:GetStackCount() == DOTA_ATTRIBUTE_STRENGTH then
				bonusBaseSpellDamagePct =  self:GetParent():GetStrength() * SPELL_AMP_PRIMARY
			elseif self:GetStackCount() == DOTA_ATTRIBUTE_AGILITY then
				bonusBaseSpellDamagePct =  self:GetParent():GetAgility() * SPELL_AMP_PRIMARY
			elseif self:GetStackCount() == DOTA_ATTRIBUTE_INTELLECT then
				bonusBaseSpellDamagePct =  self:GetParent():GetIntellect(false) * SPELL_AMP_PRIMARY
			else -- universal hero
				bonusBaseSpellDamagePct =  ( self:GetParent():GetStrength() + self:GetParent():GetAgility() + self:GetParent():GetIntellect(false) ) * SPELL_AMP_UNIVERSAL
			end
			flNewValue = math.floor( flNewValue * ( 1 + bonusBaseSpellDamagePct/100 ) ) + SPELL_AMP_INT * self:GetParent():GetIntellect(false)
		end
		return flNewValue
	end
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierPercentageCooldown( params )
  local castSpeed = 0
  for modifier,_ in pairs( self:GetParent().cooldownModifiers or {} ) do
	if IsModifierSafe( modifier ) and modifier.GetModifierCastSpeed then
		castSpeed = castSpeed + (modifier:GetModifierCastSpeed( params ) or 0)
	else
		self:GetParent().cooldownModifiers[modifier] = nil
	end
  end
  local cdr = (1 - ( 1 / (( 100 + castSpeed ) / 100 ) ))*100
  return cdr
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierPercentageCasttime( params )
  return self:GetModifierPercentageCooldown( params )
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierPhysicalArmorBonus()
	if not self:GetParent():IsRangedAttacker() then
		return 4
	end
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierStatusResistanceStacking()
	if not self:GetParent():IsRangedAttacker() then
		return 15
	end
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierExtraHealthPercentage()
	if not self:GetParent():IsRangedAttacker() then
		return 1.25
	end
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierHealthBonus()
	local BASE_HP_PRIMARY = 11
	local BASE_HP_UNIVERSAL = 4
	local bonusBaseHP = 0
	if self:GetStackCount() == DOTA_ATTRIBUTE_STRENGTH then
		bonusBaseHP = self:GetParent():GetStrength() * BASE_HP_PRIMARY
	elseif self:GetStackCount() == DOTA_ATTRIBUTE_AGILITY then
		bonusBaseHP = self:GetParent():GetAgility() * BASE_HP_PRIMARY
	elseif self:GetStackCount() == DOTA_ATTRIBUTE_INTELLECT then
		bonusBaseHP = self:GetParent():GetIntellect(false) * BASE_HP_PRIMARY
	else -- universal hero
		bonusBaseHP = ( self:GetParent():GetStrength() + self:GetParent():GetAgility() + self:GetParent():GetIntellect(false) ) * BASE_HP_UNIVERSAL
	end
	return 600*(self.total_ability_scaling-1) + bonusBaseHP
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierManaBonus()
	-- local mana = self.baseMana
	-- if self:GetParent()._heroManaType ~= "Mana" then
		-- mana = mana - self:GetParent():GetIntellect(false) * 2
	-- end
  -- return mana
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierConstantManaRegen()
	return self.baseManaRegen - self:GetParent():GetIntellect(false) * 0.05
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierBaseAttack_BonusDamage()
	local BASE_DAMAGE_PRIMARY = 0.5
	local BASE_DAMAGE_UNIVERSAL = 0.55
	local bonusBaseDamage = 0
	if self:GetStackCount() == DOTA_ATTRIBUTE_STRENGTH then
		bonusBaseDamage = self:GetParent():GetStrength() * BASE_DAMAGE_PRIMARY
	elseif self:GetStackCount() == DOTA_ATTRIBUTE_AGILITY then
		bonusBaseDamage = self:GetParent():GetAgility() * BASE_DAMAGE_PRIMARY
	elseif self:GetStackCount() == DOTA_ATTRIBUTE_INTELLECT then
		bonusBaseDamage = self:GetParent():GetIntellect(false) * BASE_DAMAGE_PRIMARY
	else -- universal hero
		bonusBaseDamage = ( self:GetParent():GetStrength() + self:GetParent():GetAgility() + self:GetParent():GetIntellect(false) ) * BASE_DAMAGE_UNIVERSAL
	end
	return self:GetParent():GetAgility() * self.bonusDamage + bonusBaseDamage + (4*self.baseDamage + 120) * self.total_ability_scaling
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierMagicalResistanceBonus()
	if not self:GetParent():IsRangedAttacker() then 
		return 12
	end
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierMoveSpeedBonus_Percentage()
	if not self:GetParent():IsRangedAttacker() then 
		return 12
	end
end

function modifier_special_bonus_attributes_stat_rescaling:AddCustomTransmitterData()
	return {lastUpdatedAbility = self.lastUpdatedAbility,
			lastUpdatedAbilityState = self.lastUpdatedAbilityState}
end

function modifier_special_bonus_attributes_stat_rescaling:HandleCustomTransmitterData(data)
	if not data.lastUpdatedAbility then return end
	local ability = EntIndexToHScript(data.lastUpdatedAbility)
	if ability then
		ability._getAltCastState = toboolean(data.lastUpdatedAbilityState)
	end
end

function modifier_special_bonus_attributes_stat_rescaling:IsHidden()
  return true
end

function modifier_special_bonus_attributes_stat_rescaling:IsDebuff()
  return false
end

function modifier_special_bonus_attributes_stat_rescaling:IsPurgable()
  return false
end

function modifier_special_bonus_attributes_stat_rescaling:AllowIllusionDuplicate()
  return true
end
