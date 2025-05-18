item_specialists_array = class({})

function item_specialists_array:GetIntrinsicModifierName()
	return "modifier_item_specialists_array_passive"
end

modifier_item_specialists_array_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_specialists_array_passive", "items/item_specialists_array.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_specialists_array_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_specialists_array_passive:OnRefresh()
	self.all_stats = self:GetSpecialValueFor("all_stats")
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	
	self.count = self:GetSpecialValueFor("count")
	self.secondary_target_range_bonus = self:GetSpecialValueFor("secondary_target_range_bonus")
	self.melee_range_bonus = self:GetSpecialValueFor("melee_range_bonus")
	self.proc_bonus_damage = self:GetSpecialValueFor("proc_bonus_damage")
	self.proc_missing_damage = self:GetSpecialValueFor("proc_missing_damage") / 100
end

function modifier_item_specialists_array_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_EVENT_ON_ATTACK }
end

function modifier_item_specialists_array_passive:GetModifierBonusStats_Strength()
	return self.all_stats
end

function modifier_item_specialists_array_passive:GetModifierBonusStats_Agility()
	return self.all_stats
end

function modifier_item_specialists_array_passive:GetModifierBonusStats_Intellect()
	return self.all_stats
end

function modifier_item_specialists_array_passive:GetModifierPreAttack_BonusDamage( params )
	local bonusDamage = self.bonus_damage
	local parent = self:GetParent()
	if IsServer() and self:GetAbility():IsCooldownReady() and parent:IsAttacking() then 
		local procDamage = self.proc_bonus_damage
		local targets = self.count
		self.enemies = ( parent:FindEnemyUnitsInRadius( parent:GetAbsOrigin(), parent:GetAttackRange() + TernaryOperator( self.secondary_target_range_bonus, parent:IsRangedAttacker(), self.melee_range_bonus ) ) )
		for _, enemy in ipairs( self.enemies ) do
			if enemy ~= params.target then
				targets = targets - 1
				if targets <= 0 then
					break
				end
			end
		end
		self._bonusTargetDamage = (procDamage * targets) / (1+(self.count-targets))
		bonusDamage = bonusDamage + procDamage + self._bonusTargetDamage
	end
	return bonusDamage
end

function modifier_item_specialists_array_passive:OnAttack( params )
	local parent = self:GetParent()
	if params.attacker ~= parent then return end
	local ability = self:GetAbility()
	if not ability:IsCooldownReady() then return end
	ability:SetCooldown()
	local targets = self.count
	EmitSoundOn( TernaryOperator("DOTA_Item.MKB.ranged", parent:IsRangedAttacker(), "DOTA_Item.MKB.melee"), parent )
	for _, enemy in ipairs( self.enemies ) do
		if enemy ~= params.target then
			parent:PerformGenericAttack(enemy, false, {bonusDamage = self.proc_bonus_damage + (self._bonusTargetDamage or 0), procAttackEffects = false, ability = ability} )
			targets = targets - 1
			if targets <= 0 then
				break
			end
		end
	end
end