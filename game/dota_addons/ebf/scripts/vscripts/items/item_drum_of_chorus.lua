item_drum_of_chorus = class({})

function item_drum_of_chorus:GetIntrinsicModifierName()
	return "modifier_item_drum_of_chorus_passive"
end

modifier_item_drum_of_chorus_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_drum_of_chorus_passive", "items/item_drum_of_chorus.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_drum_of_chorus_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_drum_of_chorus_passive:OnRefresh()
	self.bonus_primary = self:GetSpecialValueFor("bonus_primary")
	self.trigger_radius = self:GetSpecialValueFor("trigger_radius")
	self.buff_duration = self:GetSpecialValueFor("buff_duration")
end

function modifier_item_drum_of_chorus_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_EVENT_ON_ABILITY_FULLY_CAST }
end

function modifier_item_drum_of_chorus_passive:GetModifierBonusStats_Strength()
	if self:GetParent():GetPrimaryAttribute() == DOTA_ATTRIBUTE_ALL then
		return self.bonus_primary / 3
	elseif self:GetParent():GetPrimaryAttribute() == DOTA_ATTRIBUTE_STRENGTH then
		return self.bonus_primary
	end
end

function modifier_item_drum_of_chorus_passive:GetModifierBonusStats_Agility()
	if self:GetParent():GetPrimaryAttribute() == DOTA_ATTRIBUTE_ALL then
		return self.bonus_primary / 3
	elseif self:GetParent():GetPrimaryAttribute() == DOTA_ATTRIBUTE_AGILITY then
		return self.bonus_primary
	end
end

function modifier_item_drum_of_chorus_passive:GetModifierBonusStats_Intellect()
	if self:GetParent():GetPrimaryAttribute() == DOTA_ATTRIBUTE_ALL then
		return self.bonus_primary / 3
	elseif self:GetParent():GetPrimaryAttribute() == DOTA_ATTRIBUTE_INTELLECT then
		return self.bonus_primary
	end
end

function modifier_item_drum_of_chorus_passive:OnAbilityFullyCast( params )
	local parent = self:GetParent()
	if not params.unit:IsSameTeam( parent ) then return end
	if CalculateDistance( params.unit, parent ) > self.trigger_radius then return end
	local allies = parent:FindFriendlyUnitsInRadius( parent:GetAbsOrigin(), self.trigger_radius )
	if params.unit == parent and #allies > 1 then return end
	local target = parent
	if target:HasModifier("modifier_item_drum_of_chorus_buff") then
		for _, ally in ipairs( allies ) do
			if ally:IsRealHero() and not ally:HasModifier("modifier_item_drum_of_chorus_buff") then
				target = ally
				break
			end
		end
	end
	target:AddNewModifier( parent, self:GetAbility(), "modifier_item_drum_of_chorus_buff", {duration = self.buff_duration} )
	ParticleManager:FireParticle("particles/items_fx/drum_of_chorus_buff.vpcf", PATTACH_POINT_FOLLOW, target )
	EmitSoundOn( "TI9_ConsumableInstrument.Drum.Hit", target )
end

modifier_item_drum_of_chorus_buff = class({})
LinkLuaModifier( "modifier_item_drum_of_chorus_buff", "items/item_drum_of_chorus.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_drum_of_chorus_buff:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink( 0.1 )
	end
end

function modifier_item_drum_of_chorus_buff:OnRefresh()
	self.bonus_movespeed = self:GetSpecialValueFor("bonus_movespeed")
	self.bonus_cdr = self:GetSpecialValueFor("bonus_cdr")
end

function modifier_item_drum_of_chorus_buff:OnIntervalThink()
	local parent = self:GetParent()
	for i = 0, parent:GetAbilityCount()-1 do
		local ability = parent:GetAbilityByIndex( i )
		if ability and ability:GetCooldownTimeRemaining() > 0 then
			ability:ModifyCooldown( -0.1 * (self.bonus_cdr / 100) )
		end
	end
end

function modifier_item_drum_of_chorus_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_TOOLTIP }
end

function modifier_item_drum_of_chorus_buff:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_movespeed
end

function modifier_item_drum_of_chorus_buff:OnTooltip()
	return self.bonus_cdr
end
