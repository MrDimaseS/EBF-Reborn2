boss_axe_battle_hunger = class({})

function boss_axe_battle_hunger:IsStealable()
	return true
end

function boss_axe_battle_hunger:IsHiddenWhenStolen()
	return false
end

function boss_axe_battle_hunger:GetIntrinsicModifierName()
	return "modifier_boss_axe_battle_hunger_handler"
end

function boss_axe_battle_hunger:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	EmitSoundOn("Hero_Axe.Battle_Hunger", target)
	target:AddNewModifier(caster, self, "modifier_boss_axe_battle_hunger", {Duration = self:GetTalentSpecialValueFor("duration")})
end

modifier_boss_axe_battle_hunger_handler = class({})
LinkLuaModifier( "modifier_boss_axe_battle_hunger_handler", "bosses/boss_axes/boss_axe_battle_hunger.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_boss_axe_battle_hunger_handler:OnCreated()
	self:OnRefresh()
	
	if IsServer() then 
		self:StartIntervalThink(0.25)
	end
end

function modifier_boss_axe_battle_hunger_handler:OnRefresh()
	self.movespeed = self:GetTalentSpecialValueFor("speed_bonus")
	self.armor = self:GetTalentSpecialValueFor("scepter_armor_change")
end

function modifier_boss_axe_battle_hunger_handler:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
	return funcs
end

function modifier_boss_axe_battle_hunger_handler:GetModifierMoveSpeedBonus_Percentage()
	return math.max( 0, self.movespeed * self:GetStackCount() )
end

function modifier_boss_axe_battle_hunger_handler:GetModifierPhysicalArmorBonus()
	return math.max( 0, self.armor * self:GetStackCount() )
end

function modifier_boss_axe_battle_hunger_handler:IsHidden()
	return self:GetStackCount() <= 0
end

modifier_boss_axe_battle_hunger = class({})
LinkLuaModifier( "modifier_boss_axe_battle_hunger", "bosses/boss_axes/boss_axe_battle_hunger.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_boss_axe_battle_hunger:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink(1)
		local modifier = self:GetCaster():FindModifierByName("modifier_boss_axe_battle_hunger_handler")
		modifier:SetStackCount( math.max( modifier:GetStackCount() + 1, 0 ) )
		modifier:ForceRefresh()
	end
end

function modifier_boss_axe_battle_hunger:OnRefresh()
	self.movespeed = -self:GetTalentSpecialValueFor("speed_bonus")
	self.armor = -self:GetTalentSpecialValueFor("scepter_armor_change")
	self.damage = self:GetTalentSpecialValueFor("damage_per_second")
	self.armor_multiplier = self:GetTalentSpecialValueFor("armor_multiplier")
end

function modifier_boss_axe_battle_hunger:OnDestroy()
	if IsServer() then
		if not self:GetCaster() or self:GetCaster():IsNull() or not self:GetCaster():IsAlive() then return end
		local modifier = self:GetCaster():FindModifierByName("modifier_boss_axe_battle_hunger_handler")
		if not modifier then return end
		modifier:SetStackCount( math.max( 0, modifier:GetStackCount() - 1 ) )
		modifier:ForceRefresh()
	end
end

function modifier_boss_axe_battle_hunger:OnIntervalThink()
	if not self or self:IsNull() then return end
	local caster = self:GetCaster()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	if not caster or caster:IsNull() then self:Destroy() return end
	if not parent or parent:IsNull() then self:Destroy() return end
	if not ability or ability:IsNull() then self:Destroy() return end
	ability:DealDamage(caster, parent, self.damage + caster:GetPhysicalArmorValue( false ) * self.armor_multiplier, {damage_type = DAMAGE_TYPE_PHYSICAL}, OVERHEAD_ALERT_BONUS_POISON_DAMAGE)
end

function modifier_boss_axe_battle_hunger:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
	return funcs
end

function modifier_boss_axe_battle_hunger:GetModifierMoveSpeedBonus_Percentage()
	return self.movespeed
end

function modifier_boss_axe_battle_hunger:GetModifierPhysicalArmorBonus()
	return self.armor
end

function modifier_boss_axe_battle_hunger:GetEffectName()
	return "particles/units/heroes/hero_axe/axe_battle_hunger.vpcf"
end

function modifier_boss_axe_battle_hunger:GetStatusEffectName()
	return "particles/status_fx/status_effect_battle_hunger.vpcf"
end

function modifier_boss_axe_battle_hunger:StatusEffectPriority()
	return 12
end

function modifier_boss_axe_battle_hunger:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_boss_axe_battle_hunger:IsDebuff()
	return true
end