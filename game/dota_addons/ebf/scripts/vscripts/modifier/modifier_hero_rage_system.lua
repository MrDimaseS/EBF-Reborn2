modifier_hero_rage_system = class({})

function modifier_hero_rage_system:OnCreated()
	self:GetParent()._baseMaxRage = self:GetParent():GetMaxMana()
	self:GetParent()._currentRage = 0
	self.lastTimeInCombat = 0
	if IsServer() then
		self:StartIntervalThink(0)
		
		self:GetParent().GetRage = function( self ) return self._currentRage end
		self:GetParent().GetMaxRage = function( self ) return self._baseMaxRage end
		self:GetParent().ModifyRage = function( self, val) self._currentRage = math.max(0,math.min( self:GetMaxRage(), self._currentRage + val )) end
		self:GetParent().SetRage = function( self, val) self._currentRage = val end
	end
end

function modifier_hero_rage_system:OnIntervalThink()
	if self.lastTimeInCombat + 5 <= GameRules:GetGameTime() and self:GetParent():GetRage() > 0 then
		self:GetParent():ModifyRage( -5 * FrameTime() )
	end
	self:GetParent():SetMana( self:GetParent()._currentRage )
end

function modifier_hero_rage_system:DeclareFunctions()
	return { MODIFIER_PROPERTY_EXTRA_MANA_BONUS, 
			 MODIFIER_EVENT_ON_ABILITY_EXECUTED,
			 MODIFIER_EVENT_ON_TAKEDAMAGE,
			 MODIFIER_PROPERTY_MANACOST_PERCENTAGE_STACKING }
end

function modifier_hero_rage_system:GetModifierExtraManaBonus()
	if not self._checkingGlobalMana then
		self._checkingGlobalMana = true
		if IsServer() then
			self:GetParent():CalculateStatBonus( true )
		end
		local maxmana = self:GetParent():GetMaxMana() - self:GetParent()._baseMaxRage
		self._checkingGlobalMana = false
		return -maxmana
	end
end

function modifier_hero_rage_system:OnAbilityExecuted( params )
	if params.unit == self:GetParent() then
		params.unit:ModifyRage( -params.ability:GetEffectiveManaCost( -1 ) )
		self.lastTimeInCombat = GameRules:GetGameTime()
	end
end

function modifier_hero_rage_system:GetModifierPercentageManacostStacking( params )
	if params.ability and params.ability:IsItem() then
		return 80
	end
end

function modifier_hero_rage_system:OnTakeDamage( params )
	if params.attacker == self:GetParent() or params.unit == self:GetParent() then
		local amt = (( params.original_damage / params.unit:GetMaxHealth() ) * 100)
		if params.attacker == self:GetParent() then
			amt = amt * TernaryOperator( 1, params.unit:IsConsideredHero(), 0.15 )
			amt = amt * TernaryOperator( 0.2, params.inflictor, 1 )
		else
			amt = amt * 1
		end
		self:GetParent():ModifyRage( amt )
		self.lastTimeInCombat = GameRules:GetGameTime()
	end
end

function modifier_hero_rage_system:IsPurgable()
	return false
end

function modifier_hero_rage_system:DestroyOnExpire()
	return false
end

function modifier_hero_rage_system:RemoveOnDeath()
	return false
end

function modifier_hero_rage_system:IsPermanent()
	return true
end

function modifier_hero_rage_system:GetPriority()
	return MODIFIER_PRIORITY_HIGH
end

function modifier_hero_rage_system:IsHidden()
	return true
end