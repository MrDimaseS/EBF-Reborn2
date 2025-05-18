item_assassins_dagger = class({})

function item_assassins_dagger:GetIntrinsicModifierName()
	return "modifier_item_assassins_dagger_passive"
end

function item_assassins_dagger:OnSpellStart()
	local caster = self:GetCaster()
	local position = self:GetCursorPosition()
	
	local blinkDistance = TernaryOperator( 0, caster:IsRooted() or caster:IsLeashed() or caster:HasModifier("modifier_item_assassins_dagger_broken"), self:GetSpecialValueFor("blink_distance") )
	local buffDuration = self:GetSpecialValueFor("buff_duration")
	caster:Blink( position, {FX = "particles/items3_fx/blink_swift_start.vpcf", distance = blinkDistance})
	caster:AddNewModifier( caster, self, "modifier_item_assassins_dagger_active", {duration = buffDuration} )
end

modifier_item_assassins_dagger_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_assassins_dagger_passive", "items/item_assassins_dagger.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_assassins_dagger_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_assassins_dagger_passive:OnRefresh()
	self.bonus_attackspeed = self:GetSpecialValueFor("bonus_attackspeed")
	self.bonus_agility = self:GetSpecialValueFor("bonus_agility")
	self.buff_duration = self:GetSpecialValueFor("buff_duration")
	self.blink_disable = self:GetSpecialValueFor("blink_disable")
	
	self._noCritEvaluations = {}
end

function modifier_item_assassins_dagger_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,				
			MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,				
			MODIFIER_EVENT_ON_TAKEDAMAGE,
			MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_item_assassins_dagger_passive:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attackspeed
end

function modifier_item_assassins_dagger_passive:GetModifierBonusStats_Agility()
	return self.bonus_agility
end

function modifier_item_assassins_dagger_passive:GetCritDamage()
	return 1
end

function modifier_item_assassins_dagger_passive:GetModifierPreAttack_CriticalStrike( params )
	self._noCritEvaluations[params.record] = true
	return 
end

function modifier_item_assassins_dagger_passive:OnTakeDamage(params)
	if params.unit == self:GetParent() and params.attacker:IsConsideredHero() and params.damage > 25 then
		self:GetParent():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_item_assassins_dagger_broken", {duration = self.blink_disable} )
	end
end

function modifier_item_assassins_dagger_passive:OnAttackLanded( params )
	local parent = self:GetParent()
	if params.attacker ~= parent then return end
	if self._noCritEvaluations[params.record] then -- no crits
		self._noCritEvaluations[params.record] = nil
		return
	end
	parent:AddNewModifier( parent, self:GetAbility(), "modifier_item_assassins_dagger_buff", {duration = self.buff_duration} )
end

modifier_item_assassins_dagger_broken = class({})
LinkLuaModifier( "modifier_item_assassins_dagger_broken", "items/item_assassins_dagger.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_assassins_dagger_broken:IsDebuff()
	return true
end

function modifier_item_assassins_dagger_broken:IsPurgable()
	return false
end

modifier_item_assassins_dagger_active = class({})
LinkLuaModifier( "modifier_item_assassins_dagger_active", "items/item_assassins_dagger.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_assassins_dagger_active:OnCreated()
	self:OnRefresh()
end

function modifier_item_assassins_dagger_active:OnRefresh()
	self.critical_damage = self:GetSpecialValueFor("critical_damage")
end

function modifier_item_assassins_dagger_active:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE}
end

function modifier_item_assassins_dagger_active:GetCritDamage()
	return self.critical_damage / 100
end

function modifier_item_assassins_dagger_active:GetModifierPreAttack_CriticalStrike()
	if IsServer() and self._critEvaluated then return end
	self._critEvaluated = true
	return self.critical_damage
end

modifier_item_assassins_dagger_buff = class({})
LinkLuaModifier( "modifier_item_assassins_dagger_buff", "items/item_assassins_dagger.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_assassins_dagger_buff:OnCreated()
	self:OnRefresh()
end

function modifier_item_assassins_dagger_buff:OnRefresh()
	self.crit_attackspeed = self:GetSpecialValueFor("crit_attackspeed")
	self.crit_lifesteal = self:GetSpecialValueFor("crit_lifesteal")
	
	self:GetParent()._attackLifestealModifiersList = self:GetParent()._attackLifestealModifiersList or {}
	self:GetParent()._attackLifestealModifiersList[self] = true
end

function modifier_item_assassins_dagger_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_TOOLTIP,
			MODIFIER_PROPERTY_PHYSICAL_LIFESTEAL }
end

function modifier_item_assassins_dagger_buff:GetModifierAttackSpeedBonus_Constant()
	return self.crit_attackspeed
end

function modifier_item_assassins_dagger_buff:OnTooltip()
	return self.crit_lifesteal
end

function modifier_item_assassins_dagger_buff:GetModifierProperty_PhysicalLifesteal()
	return self.crit_lifesteal
end
