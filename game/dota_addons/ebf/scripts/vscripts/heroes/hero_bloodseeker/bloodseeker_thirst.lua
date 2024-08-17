bloodseeker_thirst = class({})

function bloodseeker_thirst:GetIntrinsicModifierName()
	return "modifier_bloodseeker_thirst_buff"
end

modifier_bloodseeker_thirst_buff = class({})
LinkLuaModifier( "modifier_bloodseeker_thirst_buff", "heroes/hero_bloodseeker/bloodseeker_thirst", LUA_MODIFIER_MOTION_NONE )

function modifier_bloodseeker_thirst_buff:OnCreated()
	self:OnRefresh()
end

function modifier_bloodseeker_thirst_buff:OnRefresh()
	self.min_bonus_pct = self:GetSpecialValueFor("min_bonus_pct")
	self.max_bonus_pct = self:GetSpecialValueFor("max_bonus_pct")
	self.bonus_movement_speed = self:GetSpecialValueFor("bonus_movement_speed")
end

function modifier_bloodseeker_thirst_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT, 
			MODIFIER_PROPERTY_MOVESPEED_LIMIT }
end

function modifier_bloodseeker_thirst_buff:GetModifierMoveSpeedBonus_Percentage()
	if self:GetCaster():GetHealthPercent() < self.min_bonus_pct then
		if not self.NFX and IsServer() then
			self.NFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_bloodseeker/bloodseeker_thirst_owner.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster() )
		end
		return self.bonus_movement_speed * ( math.max( self.max_bonus_pct, self:GetCaster():GetHealthPercent() ) - self.min_bonus_pct) / (self.max_bonus_pct - self.min_bonus_pct)
	elseif self.NFX and IsServer() then
		ParticleManager:ClearParticle( self.NFX )
		self.NFX = nil
	end
end

function modifier_bloodseeker_thirst_buff:GetModifierIgnoreMovespeedLimit()
	return 1
end

function modifier_bloodseeker_thirst_buff:GetModifierMoveSpeed_Limit()
	return 3500
end

function modifier_bloodseeker_thirst_buff:IsHidden()
	return self:GetCaster():GetHealthPercent() >= self.min_bonus_pct
end