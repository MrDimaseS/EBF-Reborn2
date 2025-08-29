item_avianas_feather = class({})

function item_avianas_feather:GetIntrinsicModifierName()
	return "modifier_item_avianas_feather_passive"
end

modifier_item_avianas_feather_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_avianas_feather_passive", "items/item_avianas_feather.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_avianas_feather_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_avianas_feather_passive:OnRefresh()
	self.bonus_spell_amp = self:GetSpecialValueFor("bonus_spell_amp")
	self.bonus_heal_amp = self:GetSpecialValueFor("bonus_heal_amp")
	self.move_speed = self:GetSpecialValueFor("move_speed")
	
	self.flight_threshold = self:GetSpecialValueFor("flight_threshold")
	self.linger_duration = self:GetSpecialValueFor("linger_duration")
	if IsServer() then
		self:StartIntervalThink( 0.25 )
	end
end

function modifier_item_avianas_feather_passive:OnDestroy()
	if IsClient() then return end
	if self._selfFlightBuff then self._selfFlightBuff:Destroy() end
end

function modifier_item_avianas_feather_passive:OnIntervalThink()
	local parent = self:GetParent()
	if self:GetParent():GetHealthPercent() <= self.flight_threshold then
		if not IsModifierSafe( self._selfFlightBuff ) then
			self._selfFlightBuff = parent:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_item_avianas_feather_free_bird", {} )
		elseif self._selfFlightBuff:GetRemainingTime() > 0 then
			self._selfFlightBuff:SetDuration( -1, true )
		end
	elseif IsModifierSafe( self._selfFlightBuff ) and self._selfFlightBuff:GetRemainingTime() < 0 then
			self._selfFlightBuff:SetDuration( self.linger_duration, true )
	end
end

function modifier_item_avianas_feather_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
			}
end

function modifier_item_avianas_feather_passive:GetModifierHealAmplify_PercentageSource()
	return self.bonus_heal_amp
end

function modifier_item_avianas_feather_passive:GetModifierSpellAmplify_Percentage()
	return self.bonus_spell_amp
end

function modifier_item_avianas_feather_passive:GetModifierMoveSpeedBonus_Constant()
	return self.move_speed
end

modifier_item_avianas_feather_free_bird = class({})
LinkLuaModifier( "modifier_item_avianas_feather_free_bird", "items/item_avianas_feather.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_avianas_feather_free_bird:OnCreated()
	self:OnRefresh()
end

function modifier_item_avianas_feather_free_bird:OnRefresh()
	self.flight_evasion = self:GetSpecialValueFor("flight_evasion")
	self.flight_threshold = self:GetSpecialValueFor("flight_threshold")
end

function modifier_item_avianas_feather_free_bird:CheckState()
	return {[MODIFIER_STATE_FLYING] = true}
end

function modifier_item_avianas_feather_free_bird:DeclareFunctions()
	return {MODIFIER_PROPERTY_EVASION_CONSTANT}
end

function modifier_item_avianas_feather_free_bird:GetModifierEvasion_Constant()
	return self.flight_evasion * (1 - self:GetParent():GetHealthPercent()/self.flight_threshold)
end

function modifier_item_avianas_feather_free_bird:GetEffectName()
	return "particles/items_fx/avianas_feather.vpcf"
end