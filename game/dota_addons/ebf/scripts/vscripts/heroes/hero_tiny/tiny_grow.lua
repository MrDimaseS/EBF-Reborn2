tiny_grow = class({})

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
			self:GetCaster():SetModelScale(1.0)
			self:Grow(3)
		elseif level == 3 then
			self:GetCaster():SetModelScale(1.1)
			self:Grow(4)
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
	local model_path = "models/heroes/tiny_0"..level.."/tiny_0"..level
	self:GetCaster():SetOriginalModel(model_path..".vmdl")
	self:GetCaster():SetModel(model_path..".vmdl")
	-- Remove old wearables
	UTIL_Remove(self.head)
	UTIL_Remove(self.rarm)
	UTIL_Remove(self.larm)
	UTIL_Remove(self.body)
	-- Set new wearables
	self.head = SpawnEntityFromTableSynchronous("prop_dynamic", {model = model_path.."_head.vmdl"})
	self.rarm = SpawnEntityFromTableSynchronous("prop_dynamic", {model = model_path.."_right_arm.vmdl"})
	self.larm = SpawnEntityFromTableSynchronous("prop_dynamic", {model = model_path.."_left_arm.vmdl"})
	self.body = SpawnEntityFromTableSynchronous("prop_dynamic", {model = model_path.."_body.vmdl"})
	-- lock to bone
	self.head:FollowEntity(self:GetCaster(), true)
	self.rarm:FollowEntity(self:GetCaster(), true)
	self.larm:FollowEntity(self:GetCaster(), true)
	self.body:FollowEntity(self:GetCaster(), true)
end

modifier_tiny_grow_passive = class({})
LinkLuaModifier("modifier_tiny_grow_passive", "heroes/hero_tiny/tiny_grow", LUA_MODIFIER_MOTION_NONE)
function modifier_tiny_grow_passive:OnCreated(table)
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
	self.move_speed = self:GetSpecialValueFor("move_speed")
	self.bonus_damage_tree = 1 + self:GetSpecialValueFor("tree_bonus_damage_pct") / 100
	self.spell_bonus_damage = 1 + self:GetSpecialValueFor("spell_bonus_damage") / 100
	self.spell_bonus_range = 1 + self:GetSpecialValueFor("spell_bonus_range") / 100
	self.attack_speed_reduction = self:GetSpecialValueFor("attack_speed_reduction") / 100
	
	if IsServer() then
		self.bonus_strength = self:GetParent():GetBaseStrength( ) * self:GetSpecialValueFor("strength_pct") / 100
		self:SetHasCustomTransmitterData(true) 
	end
	self:StartIntervalThink(0.5)
end

function modifier_tiny_grow_passive:OnIntervalThink()
	self.bonus_damage_tree = self:GetSpecialValueFor("tree_bonus_damage_pct") / 100
	if IsServer() then 
		self.bonus_strength = self:GetParent():GetBaseStrength( ) * self:GetSpecialValueFor("strength_pct") / 100
		self:GetParent():CalculateStatBonus( true )
		self:SendBuffRefreshToClients()
	end
end

function modifier_tiny_grow_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
			MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE}
end

function modifier_tiny_grow_passive:GetModifierBaseAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_tiny_grow_passive:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_tiny_grow_passive:GetModifierBonusStats_Strength()
	return self.bonus_strength
end

function modifier_tiny_grow_passive:GetModifierMoveSpeedBonus_Constant()
	return self.move_speed
end

function modifier_tiny_grow_passive:GetModifierAttackSpeedBonus_Constant()
	if self.checkingForAttackSpeed then return end
	self.checkingForAttackSpeed = true
	local attackSpeed = (self:GetCaster():GetAttackSpeed(false) - 1)*100
	self.checkingForAttackSpeed = false
	return attackSpeed * self.attack_speed_reduction
end

function modifier_tiny_grow_passive:GetModifierOverrideAbilitySpecial(params)
	if params.ability:GetName() == "tiny_toss"
	or params.ability:GetName() == "tiny_avalanche"
	or params.ability:GetName() == "tiny_tree_grab" then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "avalanche_damage"
		or specialValue == "toss_damage"
		or specialValue == "radius"
		or specialValue == "grab_radius"
		or specialValue == "AbilityCastRange"
		or specialValue == "bonus_damage"
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
		elseif specialValue == "bonus_damage" then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( specialValue, params.ability_special_level )
			return flBaseValue * self.bonus_damage_tree
		end
	end
end

function modifier_tiny_grow_passive:AddCustomTransmitterData()
	return {bonus_strength = self.bonus_strength}
end

function modifier_tiny_grow_passive:HandleCustomTransmitterData(data)
	self.bonus_strength = data.bonus_strength
end

function modifier_tiny_grow_passive:IsHidden()
	return true
end
