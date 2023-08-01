tiny_grow = class({})
LinkLuaModifier("modifier_tiny_grow_passive", "heroes/hero_tiny/tiny_grow", LUA_MODIFIER_MOTION_NONE)

function tiny_grow:IsStealable()
    return false
end

function tiny_grow:GetIntrinsicModifierName()
	return "modifier_tiny_grow_passive"
end

function tiny_grow:OnUpgrade()
	if IsServer() then
		local level = self:GetLevel()
		if level == 1 then -- model bullshit
			self:Grow(2)
		elseif level == 2 then
			self:GetCaster():SetModelScale(1.1)
		elseif level == 3 then
			self:GetCaster():SetModelScale(1.0)
			self:Grow(3)
		elseif level == 4 then
			self:GetCaster():SetModelScale(1.2)
		elseif level == 5 then
			self:GetCaster():SetModelScale(1.1)
			self:Grow(4)
		elseif level == 6 then
			self:GetCaster():SetModelScale(1.3)
		end
		-- Effects
		self:GetCaster():StartGesture(ACT_TINY_GROWL)
		EmitSoundOn("Tiny.Grow", self:GetCaster())
		
		local grow = ParticleManager:CreateParticle("particles/units/heroes/hero_tiny/tiny_transform.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster()) 
		ParticleManager:SetParticleControl(grow, 0, self:GetCaster():GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(grow)
	end
end

function tiny_grow:Grow(level)
	self:GetCaster():SetOriginalModel("models/heroes/tiny_0"..level.."/tiny_0"..level..".vmdl")
	self:GetCaster():SetModel("models/heroes/tiny_0"..level.."/tiny_0"..level..".vmdl")
	-- Remove old wearables
	UTIL_Remove(self.head)
	UTIL_Remove(self.rarm)
	UTIL_Remove(self.larm)
	UTIL_Remove(self.body)
	-- Set new wearables
	self.head = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_0"..level.."/tiny_0"..level.."_head.vmdl"})
	self.rarm = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_0"..level.."/tiny_0"..level.."_right_arm.vmdl"})
	self.larm = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_0"..level.."/tiny_0"..level.."_left_arm.vmdl"})
	self.body = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_0"..level.."/tiny_0"..level.."_body.vmdl"})
	-- lock to bone
	self.head:FollowEntity(self:GetCaster(), true)
	self.rarm:FollowEntity(self:GetCaster(), true)
	self.larm:FollowEntity(self:GetCaster(), true)
	self.body:FollowEntity(self:GetCaster(), true)
end

modifier_tiny_grow_passive = class({})
function modifier_tiny_grow_passive:OnCreated(table)
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
	self.attack_speed_reduction = self:GetSpecialValueFor("attack_speed_reduction")
	if self:GetCaster():HasTalent("special_bonus_unique_tiny_grow_1") then
		self.attack_speed_reduction = 0
	end
	self.bonus_attack_range = self:GetSpecialValueFor("bonus_attack_range")

	self.magic_resist = 0
	if self:GetCaster():HasTalent("special_bonus_unique_tiny_grow_2") then
		self.magic_resist = self:GetCaster():FindTalentValue("special_bonus_unique_tiny_grow_2")
	end

	self:StartIntervalThink(0.5)
end

function modifier_tiny_grow_passive:OnIntervalThink()
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.bonus_damage_tree = self:GetSpecialValueFor("tree_bonus_damage_pct") / 100
	self.spell_bonus_damage = 1 + self:GetSpecialValueFor("spell_bonus_damage") / 100
	self.spell_bonus_range = 1 + self:GetSpecialValueFor("spell_bonus_range") / 100
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
	self.attack_speed_reduction = self:GetSpecialValueFor("attack_speed_reduction") / 100

	if IsServer() then self:GetParent():CalculateStatBonus( true ) end
end

function modifier_tiny_grow_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
			MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE}
end

function modifier_tiny_grow_passive:GetModifierBaseAttack_BonusDamage()
	if self:GetParent():HasModifier("modifier_tiny_tree_grab") then
		return self.bonus_damage * (1+self.bonus_damage_tree)
	else
		return self.bonus_damage
	end
end

function modifier_tiny_grow_passive:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_tiny_grow_passive:GetModifierAttackSpeedBonus_Constant()
	if self.checkingForAttackSpeed then return end
	self.checkingForAttackSpeed = true
	local attackSpeed = (self:GetCaster():GetAttackSpeed() - 1)*100
	self.checkingForAttackSpeed = false
	return attackSpeed * self.attack_speed_reduction
end

function modifier_tiny_grow_passive:GetModifierOverrideAbilitySpecial(params)
	if params.ability:GetName() == "tiny_toss"
	or params.ability:GetName() == "tiny_avalanche" then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "avalanche_damage"
		or specialValue == "toss_damage"
		or specialValue == "radius"
		or specialValue == "grab_radius"
		or specialValue == "AbilityCastRange"
		then
			return 1
		end
	end
end

function modifier_tiny_grow_passive:GetModifierOverrideAbilitySpecialValue(params)
	if params.ability:GetName() == "tiny_toss"
	or params.ability:GetName() == "tiny_avalanche" then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if (specialValue == "avalanche_damage" or specialValue == "toss_damage") then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( specialValue, params.ability_special_level )
			return flBaseValue * self.spell_bonus_damage
		elseif ( specialValue == "radius" or specialValue == "grab_radius" or specialValue == "AbilityCastRange" ) then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( specialValue, params.ability_special_level )
			return flBaseValue * self.spell_bonus_range
		end
	end
end

function modifier_tiny_grow_passive:IsHidden()
	return true
end