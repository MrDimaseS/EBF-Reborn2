item_sheepstick = class({})

function item_sheepstick:GetIntrinsicModifierName()
	return "modifier_modifier_item_sheepstick_passive"
end

function item_sheepstick:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	
	local unitsHexed = {}
	table.insert( unitsHexed, target )
	local maxUnitsHexed = self:GetSpecialValueFor("units_hexed") - 1
	local duration = self:GetSpecialValueFor("sheep_duration")
	local bonus_duration = self:GetSpecialValueFor("bonus_duration")
	
	local hex = target:AddNewModifier( caster, self, "modifier_sheepstick_debuff", {duration = duration} )
	while maxUnitsHexed > 0 do
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), self:GetTrueCastRange() ) ) do
			if not HasValInTable( unitsHexed, enemy ) then
				table.insert( unitsHexed, enemy )
				maxUnitsHexed = maxUnitsHexed - 1
				
				local hex = enemy:FindModifierByName("modifier_sheepstick_debuff")
				if hex then
					hex:SetDuration( hex:GetRemainingTime() + bonus_duration, true )
				else
					enemy:AddNewModifier( caster, self, "modifier_sheepstick_debuff", {duration = duration} )
				end
			end
			if maxUnitsHexed <= 0 then
				break
			end
		end
		if maxUnitsHexed > 0 then -- we've checked all possible enemies, reset bounces
			unitsHexed = {}
		end
	end
end

item_sheepstick_2 = class(item_sheepstick)
item_sheepstick_3 = class(item_sheepstick)
item_sheepstick_4 = class(item_sheepstick)
item_sheepstick_5 = class(item_sheepstick)

modifier_item_sheepstick_passive = class({})
LinkLuaModifier( "modifier_item_sheepstick_passive", "items/item_sheepstick.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_sheepstick_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_sheepstick_passive:OnRefresh()
	self.bonus_intellect = self:GetSpecialValueFor("bonus_intellect")
	self.bonus_mana_regen = self:GetSpecialValueFor("bonus_mana_regen")
end

function modifier_item_sheepstick_passive:DeclareFunctions()
	return { MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
			 MODIFIER_PROPERTY_STATS_INTELLECT_BONUS }
end

function modifier_item_sheepstick_passive:GetModifierConstantManaRegen()
	return self.bonus_mana_regen
end

function modifier_item_sheepstick_passive:GetModifierBonusStats_Intellect()
	return self.bonus_intellect
end

function modifier_item_sheepstick_passive:IsHidden()
	return true
end

function modifier_item_sheepstick_passive:IsPurgable()
	return false
end

function modifier_item_sheepstick_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end