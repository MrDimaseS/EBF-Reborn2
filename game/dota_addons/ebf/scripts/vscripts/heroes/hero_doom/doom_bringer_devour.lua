doom_bringer_devour = class({})

function doom_bringer_devour:IsStealable()
	return true
end

function doom_bringer_devour:IsHiddenWhenStolen()
	return false
end

function doom_bringer_devour:OnUpgrade()
	if IsServer() then
		if self:GetLevel() == 1 then
			self:ToggleAutoCast()
		elseif self.currentlyDevouredAbilities then
			for _, ability in ipairs( self.currentlyDevouredAbilities  ) do
				ability:SetLevel( self:GetLevel() )
			end
		end
	end
end

function doom_bringer_devour:CastFilterResultTarget( target )
	return UnitFilter(target, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, TernaryOperator( DOTA_UNIT_TARGET_FLAG_NONE, self:GetSpecialValueFor("targets_ancients") > 0, DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS ), self:GetCaster():GetTeamNumber() )
end

function doom_bringer_devour:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	caster:RemoveModifierByName( "modifier_doom_bringer_devour_eating" )
	caster:AddNewModifier( caster, self, "modifier_doom_bringer_devour_eating", {duration = self:GetSpecialValueFor("duration")} )
	if target:IsNeutralUnitType() and self:GetAutoCastState() then
		self.currentlyDevouredAbilities = {}
		local abilitiesToAdd = {}
		for i = 1, 10 do
			local neutralAbility = target:GetAbilityByIndex( i-1 )
			if neutralAbility and neutralAbility:IsStealable() and neutralAbility:GetAbilityName() ~= "neutral_upgrade" then
				if #abilitiesToAdd < 2 then
					table.insert( abilitiesToAdd, neutralAbility:GetAbilityName() )
				end
			else
				table.insert( abilitiesToAdd, "doom_bringer_empty"..i )
			end
		end
		for index, abilityName in ipairs( abilitiesToAdd ) do
			local currentAbility = caster:GetAbilityByIndex( index+2 )
			if currentAbility and currentAbility:GetAbilityName() ~= abilityName then
				local newAbility = caster:AddAbility( abilityName )
				if newAbility then
					caster:SwapAbilities( currentAbility:GetAbilityName(), abilityName, false, true )
					for _, modifier in ipairs( caster:FindAllModifiers() ) do
						if modifier:GetAbility() == currentAbility then
							modifier:Destroy()
						end
					end
					caster:RemoveAbilityByHandle(currentAbility)
					
					newAbility:SetLevel( self:GetLevel() )
					newAbility:SetStolen( true )
					table.insert( self.currentlyDevouredAbilities, newAbility )
				end
			end
		end
	end
	
	if target:IsConsideredHero() then
		self:DealDamage( caster, target, caster:GetStrength() * self:GetSpecialValueFor("hero_damage") / 100, {damage_type = DAMAGE_TYPE_PURE} )
	else
		self:DealDamage( caster, target, target:GetMaxHealth() + 1, {damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS} )
	end
end

modifier_doom_bringer_devour_eating = class({})
LinkLuaModifier( "modifier_doom_bringer_devour_eating", "heroes/hero_doom/doom_bringer_devour", LUA_MODIFIER_MOTION_NONE )

function modifier_doom_bringer_devour_eating:OnCreated()
	self:OnRefresh()
end

function modifier_doom_bringer_devour_eating:OnRefresh()
	self.bonus_gold = self:GetSpecialValueFor("bonus_gold")
	self.armor = self:GetSpecialValueFor("armor")
	self.magic_resist = self:GetSpecialValueFor("magic_resist")
end

function modifier_doom_bringer_devour_eating:OnDestroy()
	if IsServer() and self:GetParent():IsAlive() then
		self:GetCaster():AddGold( self.bonus_gold )
	end
end

function modifier_doom_bringer_devour_eating:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
	}
end

function modifier_doom_bringer_devour_eating:GetModifierPhysicalArmorBonus()
	return self.armor
end

function modifier_doom_bringer_devour_eating:GetModifierMagicalResistanceBonus()
	return self.magic_resist
end