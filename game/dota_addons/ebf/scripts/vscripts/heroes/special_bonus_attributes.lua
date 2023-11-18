special_bonus_attributes = class({})

function special_bonus_attributes:OnHeroLevelUp()
	local hero = self:GetCaster()
	local strGain = math.sum( 1, hero:GetLevel()-1, hero:GetStrengthGain()*0.5 )
	local agiGain = math.sum( 1, hero:GetLevel()-1, hero:GetAgilityGain()*0.5 ) 
	local intGain = math.sum( 1, hero:GetLevel()-1, hero:GetIntellectGain()*0.5 )
	
	local attribute_multiplier = self:GetSpecialValueFor("value") / 100
	
	print( strGain, agiGain, intGain, attribute_multiplier, "gained level" )
	
	strGain = strGain * (1+attribute_multiplier)
	agiGain = agiGain * (1+attribute_multiplier)
	intGain = intGain * (1+attribute_multiplier)
	
	
	if strGain > 0 then
		hero:ModifyStrength( strGain ) 
	end
	if agiGain > 0 then
		hero:ModifyAgility( agiGain ) 
	end
	if intGain > 0 then
		hero:ModifyIntellect( intGain )
	end
end

function special_bonus_attributes:OnUpgrade()
	local hero = self:GetCaster()
	
	local totalStrValue = self.originalBaseStr + math.sumT( 1, hero:GetLevel()-1, hero:GetStrengthGain() * 0.5 ) + (hero:GetLevel()-1 * hero:GetStrengthGain() )
	local totalAgiValue = self.originalBaseAgi + math.sumT( 1, hero:GetLevel()-1, hero:GetAgilityGain() * 0.5 ) + (hero:GetLevel()-1 * hero:GetAgilityGain() )
	local totalIntValue = self.originalBaseInt + math.sumT( 1, hero:GetLevel()-1, hero:GetIntellectGain() * 0.5 ) + (hero:GetLevel()-1 * hero:GetIntellectGain() )
	
	local attribute_multiplier = (self:GetSpecialValueFor( "value" ) - self:GetLevelSpecialValueFor( "value", self:GetLevel()-2 ) ) / 100
	print( self:GetSpecialValueFor( "value" ), self:GetLevelSpecialValueFor( "value", self:GetLevel()-2 ), self:GetLevelSpecialValueFor( "value", self:GetLevel()-1 ))
	if self:GetLevel() == 1 then -- no way to get 0 out of specialvalue and getlevel
		attribute_multiplier = self:GetSpecialValueFor( "value" ) / 100
	end
	
	print( totalStrValue, totalAgiValue, totalIntValue, attribute_multiplier, "leveled stats" )
	
	hero:ModifyStrength( totalStrValue * attribute_multiplier ) 
	hero:ModifyAgility( totalAgiValue * attribute_multiplier ) 
	hero:ModifyIntellect( totalIntValue * attribute_multiplier ) 
end

function special_bonus_attributes:Spawn()
	if not IsServer() then return end
	local hero = self:GetCaster()
	self.originalBaseStr = hero:GetBaseStrength()
	self.originalBaseAgi = hero:GetBaseAgility()
	self.originalBaseInt = hero:GetBaseIntellect()
	Timers:CreateTimer( 0.1, function() hero:AddNewModifier( hero, self, "modifier_special_bonus_attributes_stat_rescaling", {} ) end )
end

function special_bonus_attributes:OnHeroCalculateStatBonus()
	local modifier = self:GetCaster():FindModifierByName("modifier_special_bonus_attributes_stat_rescaling")
	if modifier then 
		modifier:SetStackCount( self:GetCaster():GetPrimaryAttribute() )
		modifier:ForceRefresh() 
	end
end

modifier_special_bonus_attributes_pct = class({})
LinkLuaModifier( "modifier_special_bonus_attributes_pct", "heroes/special_bonus_attributes", LUA_MODIFIER_MOTION_NONE )

function modifier_special_bonus_attributes_pct:OnCreated()
	if IsServer() then
		self.originalBaseStr = self:GetParent():GetBaseStrength()
		self.originalBaseAgi = self:GetParent():GetBaseAgility()
		self.originalBaseInt = self:GetParent():GetBaseIntellect()
		
		self:OnRefresh()
	end
end

function modifier_special_bonus_attributes_pct:OnRefresh()
	self.attribute_multiplier = self:GetSpecialValueFor("value") / 100
	if IsServer() and self.attribute_multiplier > 0 then
		local hero = self:GetParent()
		
		local intendedStr = self.originalBaseStr + (hero:GetLevel() - 1) * hero:GetStrengthGain()
		local intendedAgi = self.originalBaseStr + (hero:GetLevel() - 1) * hero:GetAgilityGain()
		local intendedInt = self.originalBaseStr + (hero:GetLevel() - 1) * hero:GetIntellectGain()
		
		local currentStrBonus = intendedStr * self.attribute_multiplier
		local currentAgiBonus = intendedStr * self.attribute_multiplier
		local currentIntBonus = intendedStr * self.attribute_multiplier
		
		local currStr = hero:GetBaseStrength()
		local currAgi = hero:GetBaseAgility()
		local currInt = hero:GetBaseIntellect()
		
		local actualStr = currStr - (self.lastStrBonus or 0) + currentStrBonus
		local actualAgi = currAgi - (self.lastAgiBonus or 0) + currentAgiBonus
		local actualInt = currInt - (self.lastIntBonus or 0) + currentIntBonus
		
		if actualStr ~= currStr then
			hero:SetBaseStrength( math.max( 0, actualStr ) )
		end
		if actualAgi ~= currAgi then
			hero:SetBaseAgility(  math.max( 0, actualAgi ) )
		end
		if actualInt ~= currInt then
			hero:SetBaseIntellect(  math.max( 0, actualInt ) )
		end
		
		self.lastStrBonus = currentStrBonus
		self.lastAgiBonus = currentAgiBonus
		self.lastIntBonus = currentIntBonus
	end
end

function modifier_special_bonus_attributes_pct:IsHidden()
	return true
end

function modifier_special_bonus_attributes_pct:IsPurgable()
	return false
end

function modifier_special_bonus_attributes_pct:RemoveOnDeath()
	return false
end

function modifier_special_bonus_attributes_pct:IsPermanent()
	return true
end

modifier_special_bonus_attributes_stat_rescaling = class({})
LinkLuaModifier( "modifier_special_bonus_attributes_stat_rescaling", "heroes/special_bonus_attributes", LUA_MODIFIER_MOTION_NONE )

function modifier_special_bonus_attributes_stat_rescaling:GetAttributes()
  return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE --+ MODIFIER_ATTRIBUTE_MULTIPLE
end


function modifier_special_bonus_attributes_stat_rescaling:OnCreated()
	self.baseMana = self:GetParent():GetIntellect() * 11
	self.baseManaRegen = self:GetParent():GetIntellect() * 0.04

	self.bonusSpellAmp = 0.04
	self.bonusDamage = 1.5
	self.baseMR = 25
	
	self:GetParent().cooldownModifiers = {}
	if self:GetParent():IsIllusion() then
		self.baseArmor = self:GetParent():GetPhysicalArmorBaseValue() + ( self:GetParent():GetAgility() / 6 - 0.065 * self:GetParent():GetAgility() )
	else
		self.baseArmor = self:GetCaster():GetPhysicalArmorBaseValue()
	end
	
	self:OnRefresh()
	if IsServer() then
		self:SetStackCount( self:GetParent():GetPrimaryAttribute() )
	end
end

function modifier_special_bonus_attributes_stat_rescaling:OnRefresh()
	self.attackspeed = 30 + math.floor( math.min( 0.75 * self:GetParent():GetAgility(), 10.32*self:GetParent():GetAgility()^(math.log(2)/math.log(5)) ) )
	if IsServer() then
		if self.baseArmor then
			local agilityArmor = math.min( 0.065 * self:GetParent():GetAgility(), 0.9*self:GetParent():GetAgility()^(math.log(2)/math.log(5)) )
			if self:GetParent():IsIllusion() then
				agilityArmor = 0
			end
			self:GetParent():SetPhysicalArmorBaseValue( self.baseArmor + agilityArmor )
		end
		if self.baseMR then
			local intArmor =  math.min( 0.04 * self:GetParent():GetIntellect(), 0.55*self:GetParent():GetIntellect()^(math.log(2)/math.log(5)) )
			if self:GetParent():IsIllusion() then
				intArmor = 0
			end
			self:GetParent():SetBaseMagicalResistanceValue( -self:GetParent():GetIntellect() * 0.1 + self.baseMR + intArmor )
		end
	end
end

-- function modifier_special_bonus_attributes_stat_rescaling:CheckState()
	-- return {[MODIFIER_STATE_NO_HEALTH_BAR] = true}
-- end

function modifier_special_bonus_attributes_stat_rescaling:DeclareFunctions()
  local funcs = {
		-- MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		-- MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		-- MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK_UNAVOIDABLE_PRE_ARMOR,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
		MODIFIER_PROPERTY_CASTTIME_PERCENTAGE,
  }
  return funcs
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierPercentageCooldown( params )
  local castSpeed = 0
  for modifier,_ in pairs( self:GetParent().cooldownModifiers ) do
	if IsModifierSafe( modifier ) then
		castSpeed = castSpeed + modifier:GetModifierCastSpeed( params )
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

function modifier_special_bonus_attributes_stat_rescaling:GetModifierAttackSpeedBonus_Constant()
  return self.attackspeed
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
		bonusBaseHP = self:GetParent():GetIntellect() * BASE_HP_PRIMARY
	else -- universal hero
		bonusBaseHP = ( self:GetParent():GetStrength() + self:GetParent():GetAgility() + self:GetParent():GetIntellect() ) * BASE_HP_UNIVERSAL
	end
	return 75 + bonusBaseHP
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierManaBonus()
  return self.baseMana + 5 * (self:GetParent():GetLevel() - 1)^2
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierConstantManaRegen()
  return self.baseManaRegen - self:GetParent():GetIntellect() * 0.04
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierBaseAttack_BonusDamage()
	local BASE_DAMAGE_PRIMARY = 0.5
	local BASE_DAMAGE_UNIVERSAL = 0.3
	local bonusBaseDamage = 0
	if self:GetStackCount() == DOTA_ATTRIBUTE_STRENGTH then
		bonusBaseDamage = self:GetParent():GetStrength() * BASE_DAMAGE_PRIMARY
	elseif self:GetStackCount() == DOTA_ATTRIBUTE_AGILITY then
		bonusBaseDamage = self:GetParent():GetAgility() * BASE_DAMAGE_PRIMARY
	elseif self:GetStackCount() == DOTA_ATTRIBUTE_INTELLECT then
		bonusBaseDamage = self:GetParent():GetIntellect() * BASE_DAMAGE_PRIMARY
	else -- universal hero
		bonusBaseDamage = ( self:GetParent():GetStrength() + self:GetParent():GetAgility() + self:GetParent():GetIntellect() ) * BASE_DAMAGE_UNIVERSAL
	end
	return self:GetParent():GetAgility() * self.bonusDamage + 30 + bonusBaseDamage
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierSpellAmplify_Percentage()
	local SPELL_AMP_PRIMARY = 0.08
	local SPELL_AMP_UNIVERSAL = 0.03
	local bonusSpellAmp = 0
	if self:GetStackCount() == DOTA_ATTRIBUTE_STRENGTH then
		bonusSpellAmp =  self:GetParent():GetStrength() * SPELL_AMP_PRIMARY
	elseif self:GetStackCount() == DOTA_ATTRIBUTE_AGILITY then
		bonusSpellAmp =  self:GetParent():GetAgility() * SPELL_AMP_PRIMARY
	elseif self:GetStackCount() == DOTA_ATTRIBUTE_INTELLECT then
		bonusSpellAmp =  self:GetParent():GetIntellect() * SPELL_AMP_PRIMARY
	else -- universal hero
		bonusSpellAmp =  ( self:GetParent():GetStrength() + self:GetParent():GetAgility() + self:GetParent():GetIntellect() ) * SPELL_AMP_UNIVERSAL
	end
	return self:GetParent():GetIntellect() * self.bonusSpellAmp + bonusSpellAmp
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierMagicalResistanceBonus()
	if not self:GetParent():IsRangedAttacker() then 
		return 20
	end
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierMoveSpeedBonus_Percentage()
	if not self:GetParent():IsRangedAttacker() then 
		return 12
	end
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierPhysical_ConstantBlockUnavoidablePreArmor( params )
	if not self:GetParent():IsRangedAttacker() and params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK and params.damage > 0 then
		local roll = RollPercentage( 80 )
		local isHero = params.attacker:IsConsideredHero()
		if roll or not isHero then
			local block = params.damage * TernaryOperator( 0.35, isHero, TernaryOperator( 0.5, roll, 0.85 ) )
			SendOverheadEventMessage( nil, OVERHEAD_ALERT_BLOCK, self:GetParent(), block, nil )
			return block
		end
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