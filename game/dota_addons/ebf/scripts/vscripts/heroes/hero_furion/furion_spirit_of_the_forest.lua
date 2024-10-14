furion_spirit_of_the_forest = class({})

function furion_spirit_of_the_forest:PiercesDisableResistance()
    return true
end

function furion_spirit_of_the_forest:GetIntrinsicModifierName()
	return "modifier_furion_spirit_of_the_forest_handler"
end

modifier_furion_spirit_of_the_forest_handler = class({})
LinkLuaModifier( "modifier_furion_spirit_of_the_forest_handler", "heroes/hero_furion/furion_spirit_of_the_forest.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_furion_spirit_of_the_forest_handler:OnCreated()
	self:OnRefresh()
end

function modifier_furion_spirit_of_the_forest_handler:OnRefresh()
	self.damage_per_tree_pct = self:GetSpecialValueFor("damage_per_tree_pct")
	self.heal_amp_per_tree = self:GetSpecialValueFor("heal_amp_per_tree")
	self.armor_per_tree = self:GetSpecialValueFor("armor_per_tree")
	self.damage_per_tree = self:GetSpecialValueFor("damage_per_tree")
	
	self.radius_treant = self:GetSpecialValueFor("radius_treant")
	self.radius = self:GetSpecialValueFor("radius")
	
	if IsServer() then
		self:StartIntervalThink(0.33)
	end
end

function modifier_furion_spirit_of_the_forest_handler:OnIntervalThink()
	local caster = self:GetCaster()
	local trees = #GridNav:GetAllTreesAroundPoint( caster:GetAbsOrigin(), self.radius, true )
	local treants = 0
	for _, treant in ipairs( caster:FindFriendlyUnitsInRadius( caster:GetAbsOrigin(), self.radius_treant, {flag = DOTA_UNIT_TARGET_FLAG_INVULNERABLE} ) ) do
		if treant:GetUnitLabel() == 'treants' or treant == caster then
			treants = treants + 1
		end
	end
	self:SetStackCount( trees + treants )
end

function modifier_furion_spirit_of_the_forest_handler:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
	}
	return funcs
end

function modifier_furion_spirit_of_the_forest_handler:GetModifierPhysicalArmorBonus(params)
	return self.armor_per_tree * self:GetStackCount()
end

function modifier_furion_spirit_of_the_forest_handler:GetModifierBaseDamageOutgoing_Percentage(params)
	return self.damage_per_tree_pct * self:GetStackCount()
end

function modifier_furion_spirit_of_the_forest_handler:GetModifierHealAmplify_PercentageTarget(params)
	return self.heal_amp_per_tree * self:GetStackCount()
end

function modifier_furion_spirit_of_the_forest_handler:IsAura()
	return self.damage_per_tree > 0
end

function modifier_furion_spirit_of_the_forest_handler:GetModifierAura()
	return "modifier_furion_spirit_of_the_forest_debuff"
end

function modifier_furion_spirit_of_the_forest_handler:GetAuraRadius()
	return self.radius_treant
end

function modifier_furion_spirit_of_the_forest_handler:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_furion_spirit_of_the_forest_handler:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_HEROES_AND_CREEPS
end

function modifier_furion_spirit_of_the_forest_handler:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_furion_spirit_of_the_forest_handler:GetAuraDuration()
	return 0.5
end

function modifier_furion_spirit_of_the_forest_handler:IsHidden()
	return false
end

modifier_furion_spirit_of_the_forest_debuff = class({})
LinkLuaModifier( "modifier_furion_spirit_of_the_forest_debuff", "heroes/hero_furion/furion_spirit_of_the_forest.lua",LUA_MODIFIER_MOTION_NONE )
function modifier_furion_spirit_of_the_forest_debuff:OnCreated()
	self.radius = self:GetSpecialValueFor("radius")
	self.damage_per_tree = self:GetSpecialValueFor("damage_per_tree")
	if IsServer() then
		self:StartIntervalThink(1)
	end
end

function modifier_furion_spirit_of_the_forest_debuff:OnIntervalThink()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	local trees = #GridNav:GetAllTreesAroundPoint( parent:GetAbsOrigin(), self.radius, true )
	local treants = 0
	for _, treant in ipairs( caster:FindFriendlyUnitsInRadius( parent:GetAbsOrigin(), self.radius ) ) do
		if treant:GetUnitLabel() == 'treants' or treant == caster then
			treants = treants + 1
		end
	end
	if treants + trees > 0 then
		self:GetAbility():DealDamage( caster, parent, self.damage_per_tree * (treants+trees), {damage_type = DAMAGE_FLAG_MAGICAL} )
	end
end

function modifier_furion_spirit_of_the_forest_debuff:GetEffectName()
	return "particles/units/heroes/hero_furion/furion_curse_of_forest_debuff.vpcf"
end