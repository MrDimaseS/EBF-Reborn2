mars_dauntless = class({})

function mars_dauntless:GetIntrinsicModifierName()
	return "modifier_mars_dauntless_passive"
end

modifier_mars_dauntless_passive = class({})
LinkLuaModifier( "modifier_mars_dauntless_passive", "heroes/hero_mars/mars_dauntless.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_mars_dauntless_passive:OnCreated()
	self:OnRefresh()
	if self.lifesteal > 0 then
		self:GetParent()._spellLifestealModifiersList = self:GetParent()._spellLifestealModifiersList or {}
		self:GetParent()._spellLifestealModifiersList[self] = true
		
		self:GetParent()._attackLifestealModifiersList = self:GetParent()._attackLifestealModifiersList or {}
		self:GetParent()._attackLifestealModifiersList[self] = true
	end
	if IsServer() then
		self:GetParent()._dauntlessModifier = self
		self:StartIntervalThink( 0.5 )
	end
end

function modifier_mars_dauntless_passive:OnRefresh()
	self.health_regen_per_enemy = self:GetSpecialValueFor("health_regen_per_enemy")
	self.health_regen_per_creep = self:GetSpecialValueFor("health_regen_per_creep")
	self.hero_stacks = self.health_regen_per_enemy / self.health_regen_per_creep
	self.radius = self:GetSpecialValueFor("radius")
	
	self.lifesteal = self:GetSpecialValueFor("lifesteal")
	self.ally_benefit = self:GetSpecialValueFor("ally_benefit") / 100
	self.armor_per_enemy = self:GetSpecialValueFor("armor_per_enemy")
	self.armor_per_creep = self:GetSpecialValueFor("armor_per_creep")
	self.magic_resist_per_enemy = self:GetSpecialValueFor("magic_resist_per_enemy")
	self.magic_resist_per_creep = self:GetSpecialValueFor("magic_resist_per_creep")
	self.amp_to_damage = self:GetSpecialValueFor("amp_to_damage") / 100
end

function modifier_mars_dauntless_passive:OnIntervalThink()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	if caster == parent then
		local stacks = 0
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self.radius ) ) do
			if enemy:IsConsideredHero() then
				stacks = stacks + self.hero_stacks
			else
				stacks = stacks + 1
			end
		end
		self:SetStackCount( stacks )
	elseif IsModifierSafe( caster._dauntlessModifier ) then
		self:SetStackCount( caster._dauntlessModifier:GetStackCount() )
	end
end

function modifier_mars_dauntless_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
			MODIFIER_PROPERTY_TOOLTIP }
end

function modifier_mars_dauntless_passive:GetModifierPropertyRestorationAmplification( params )
	return self.health_regen_per_creep * self:GetStackCount() * TernaryOperator( 1, self:GetParent() == self:GetCaster(), self.ally_benefit )
end

function modifier_mars_dauntless_passive:OnTooltip( params )
	return self:GetModifierPropertyRestorationAmplification( params )
end

function modifier_mars_dauntless_passive:GetModifierPhysicalArmorBonus( params )
	return self.armor_per_creep * self:GetStackCount() * TernaryOperator( 1, self:GetParent() == self:GetCaster(), self.ally_benefit )
end

function modifier_mars_dauntless_passive:GetModifierMagicalResistanceBonus( params )
	return self.magic_resist_per_creep * self:GetStackCount() * TernaryOperator( 1, self:GetParent() == self:GetCaster(), self.ally_benefit )
end

function modifier_mars_dauntless_passive:GetModifierBaseDamageOutgoing_Percentage( params )
	return self:GetModifierPropertyRestorationAmplification( params ) * self.amp_to_damage
end

function modifier_mars_dauntless_passive:GetModifierProperty_MagicalLifesteal( params )
	return self.lifesteal * TernaryOperator( 1, self:GetParent() == self:GetCaster(), self.ally_benefit )
end

function modifier_mars_dauntless_passive:GetModifierProperty_PhysicalLifesteal( params )
	return self.lifesteal * TernaryOperator( 1, self:GetParent() == self:GetCaster(), self.ally_benefit )
end

function modifier_mars_dauntless_passive:IsAura()
	return self.ally_benefit > 0 and self:GetCaster() == self:GetParent()
end

function modifier_mars_dauntless_passive:GetModifierAura()
	return "modifier_mars_dauntless_passive"
end

function modifier_mars_dauntless_passive:GetAuraRadius()
	return self.radius
end

function modifier_mars_dauntless_passive:GetAuraDuration()
	return 0.5
end

function modifier_mars_dauntless_passive:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_mars_dauntless_passive:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_HERO
end

function modifier_mars_dauntless_passive:GetAuraEntityReject( unit )
	return unit == self:GetCaster()
end

function modifier_mars_dauntless_passive:IsHidden()
	return self:GetStackCount() == 0
end

function modifier_mars_dauntless_passive:IsPurgable()
	return false
end

function modifier_mars_dauntless_passive:IsPurgeException()
	return false
end

function modifier_mars_dauntless_passive:IsDebuff()
	return false
end