item_serrated_shiv = class({})

function item_serrated_shiv:GetIntrinsicModifierName()
	return "modifier_item_serrated_shiv_passive"
end

function item_serrated_shiv:ShouldUseResources()
	return true
end

modifier_item_serrated_shiv_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_serrated_shiv_passive", "items/item_serrated_shiv.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_serrated_shiv_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_serrated_shiv_passive:OnRefresh()
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
	
	self.proc_chance = self:GetSpecialValueFor("proc_chance")
	self.hp_dmg = self:GetSpecialValueFor("hp_dmg") / 100
	
	self._criticalHits = {}
	if IsServer() then
		self:GetAbility():SetFrozenCooldown( false )
	end
end

function modifier_item_serrated_shiv_passive:ChecKState()
	if self:GetAbility():IsCooldownReady() then
		return {[MODIFIER_STATE_CANNOT_MISS] = true}
	end
end

function modifier_item_serrated_shiv_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
			MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY }
end

function modifier_item_serrated_shiv_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_serrated_shiv_passive:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attackspeed
end

function modifier_item_serrated_shiv_passive:GetModifierBonusStats_Agility()
	return self.bonus_agility
end

function modifier_item_serrated_shiv_passive:GetCritDamage()
	if not self:GetAbility():IsCooldownReady() then return end
	local parent = self:GetParent()
	local target = parent:GetAttackTarget()
	local attackDamage = parent:GetAverageTrueAttackDamage( target )
	local procDamage = math.ceil(target:GetHealth() * self.hp_dmg) * target:GetMaxHealthDamageResistance()
	self.crit_damage = procDamage / attackDamage
	return self.crit_damage
end

function modifier_item_serrated_shiv_passive:GetModifierPreAttack_CriticalStrike( params )
	if not self:GetAbility():IsCooldownReady() then return end
	if self:RollPRNG( self.proc_chance ) then
		self:GetAbility():SetCooldown()
		self:GetAbility():SetFrozenCooldown( true )
		self._criticalHits[params.record] = true
		return
	end
end

function modifier_item_serrated_shiv_passive:OnAttackRecordDestroy( params )
	if params.attacker == self:GetParent() then
		self._cannotMiss = false
		if self._criticalHits[params.record] then
			self._criticalHits[params.record] = nil
			local procDamage = math.ceil(params.target:GetHealth() * self.hp_dmg) * params.target:GetMaxHealthDamageResistance()
			self:GetAbility():DealDamage( params.attacker, params.target, procDamage, {damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_ATTACK_MODIFIER }, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE )
			self:GetAbility():SetFrozenCooldown( false )
		end
	end
end