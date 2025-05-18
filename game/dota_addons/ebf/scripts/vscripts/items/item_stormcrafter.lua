item_stormcrafter = class({})

function item_stormcrafter:ShouldUseResources()
	return true
end

function item_stormcrafter:GetIntrinsicModifierName()
	return "modifier_item_stormcrafter_passive"
end

modifier_item_stormcrafter_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_stormcrafter_passive", "items/item_stormcrafter.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_stormcrafter_passive:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink( 0.25 )
	end
end

function modifier_item_stormcrafter_passive:OnRefresh()
	self.passive_movement_bonus = self:GetSpecialValueFor("passive_movement_bonus")
	self.bonus_mana_regen = self:GetSpecialValueFor("bonus_mana_regen")
	self.bonus_all = self:GetSpecialValueFor("bonus_all")
	
	self.range = self:GetSpecialValueFor("range")
	self.damage = self:GetSpecialValueFor("damage")
	self.interval = self:GetSpecialValueFor("interval")
	self.slow_duration = self:GetSpecialValueFor("slow_duration")
	self.max_targets = self:GetSpecialValueFor("max_targets")
end

function modifier_item_stormcrafter_passive:OnIntervalThink()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	
	if ability:IsCooldownReady() then
		local targets = self.max_targets
		local enemies = caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self.range )
		if #enemies > 0 then
			for _, enemy in ipairs( enemies ) do
				ability:DealDamage( caster, enemy, self.damage )
				EmitSoundOn("soundevents/game_sounds_items.vsndevts", enemy )
				ParticleManager:FireRopeParticle( "particles/neutral_fx/harpy_chain_lightning.vpcf", PATTACH_POINT_FOLLOW, caster, enemy )
				targets = targets - 1
				if targets == 0 then
					break
				end
			end
			ability:SetCooldown()
		end
	end
end

function modifier_item_stormcrafter_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS}
end

function modifier_item_stormcrafter_passive:GetModifierMoveSpeedBonus_Constant()
	return self.passive_movement_bonus
end

function modifier_item_stormcrafter_passive:GetModifierConstantManaRegen( params )
	return self.bonus_mana_regen
end

function modifier_item_stormcrafter_passive:GetModifierBonusStats_Strength( params )
	return self.bonus_all
end

function modifier_item_stormcrafter_passive:GetModifierBonusStats_Agility( params )
	return self.bonus_all
end

function modifier_item_stormcrafter_passive:GetModifierBonusStats_Intellect( params )
	return self.bonus_all
end