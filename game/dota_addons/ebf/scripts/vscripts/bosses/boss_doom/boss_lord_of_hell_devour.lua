boss_lord_of_hell_devour = class({})

function boss_lord_of_hell_devour:IsStealable()
	return true
end

function boss_lord_of_hell_devour:IsHiddenWhenStolen()
	return false
end

function boss_lord_of_hell_devour:CastFilterResultTarget( target )
	if target ~= self:GetCaster() then
		return UnitFilter(target, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, self:GetCaster():GetTeamNumber() )
	else
		return UF_FAIL_HERO 
	end
end

function boss_lord_of_hell_devour:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	caster:AddNewModifier( caster, self, "modifier_boss_lord_of_hell_devour_eating", {duration = self:GetSpecialValueFor("duration")} )
	for i = 0, target:GetAbilityCount() - 1 do
		local ability = target:GetAbilityByIndex( i )
        if ability and ability:IsPassive() and not ability:IsAttributeBonus() and ability:GetAbilityName() ~= "neutral_upgrade" then
			if not caster:HasAbility( ability:GetAbilityName() ) then
				local addedAbility = caster:AddAbility( ability:GetAbilityName() )
				if addedAbility then
					addedAbility:SetLevel( self:GetLevel() )
				end
				break
			end
        end
    end
	
	local damage
	if target:IsConsideredHero() then
		damage = self:DealDamage( caster, target, self:GetSpecialValueFor("hero_damage"), {damage_type = DAMAGE_TYPE_PURE} )
	else
		damage = target:GetMaxHealth()
		target:AttemptKill(self, caster)
	end
	if damage > 0 then
		caster:HealEvent( damage * self:GetSpecialValueFor("instant_heal") / 100, self, caster )
	end
end

modifier_boss_lord_of_hell_devour_eating = class({})
LinkLuaModifier( "modifier_boss_lord_of_hell_devour_eating", "bosses/boss_doom/boss_lord_of_hell_devour", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_lord_of_hell_devour_eating:OnCreated()
	self:OnRefresh()
end

function modifier_boss_lord_of_hell_devour_eating:OnRefresh()
	self.armor = self:GetSpecialValueFor("armor")
	self.magic_resist = self:GetSpecialValueFor("magic_resist")
end

function modifier_boss_lord_of_hell_devour_eating:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
	}
end

function modifier_boss_lord_of_hell_devour_eating:GetModifierPhysicalArmorBonus()
	return self.armor
end

function modifier_boss_lord_of_hell_devour_eating:GetModifierMagicalResistanceBonus()
	return self.magic_resist
end