
item_orb_of_shadows = class({})

function item_orb_of_shadows:OnSpellStart()
	local caster = self:GetCaster()
	
	local level = self:GetSpecialValueFor("level")
	local itemToUpgrade
	
	for i = DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
		local item = caster:GetItemInSlot( i )
		if item then
			local baseLevel = 5 - item:GetMaxLevel()
			local effectiveLevel = item:GetLevel() + baseLevel
			if effectiveLevel < level then
				itemToUpgrade = item
				itemToUpgrade.effectiveLevel = effectiveLevel
			end
		end
	end	
	
	if itemToUpgrade then
		local reimbursement = itemToUpgrade:GetCost() * 2 ^ (itemToUpgrade:GetLevel() - 1) - 1000
		local GPM = caster:GetGold() + math.floor(reimbursement)
		caster:SetGold( 0, false )
		caster:SetGold( GPM, true )
		
		local newLevel = level + (itemToUpgrade:GetMaxLevel() - 5)
		itemToUpgrade:SetLevel( newLevel )
		
		if itemToUpgrade:GetItemSlot() > DOTA_ITEM_SLOT_6 then
			local intrinsic = caster:FindModifierByNameAndAbility( itemToUpgrade:GetIntrinsicModifierName(), itemToUpgrade )
			if intrinsic then
				intrinsic:Destroy()
			end
		end
		
		UTIL_Remove( self )
		Timers:CreateTimer( function() caster:FindAbilityByName("special_bonus_attributes"):SendUpdatedInventoryContents({unit = caster:entindex()}) end )
	end
end

item_orb_of_demons = class(item_orb_of_shadows)
item_orb_of_angels = class(item_orb_of_shadows)
item_orb_of_horrors = class(item_orb_of_shadows)