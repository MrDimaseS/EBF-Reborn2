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
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
	self.linger_duration = self:GetSpecialValueFor("linger_duration")
	
	if IsServer() then
		self:StartIntervalThink( 0.25 )
	end
end

function modifier_bloodseeker_thirst_buff:OnIntervalThink()
	local stacks = 0
	if self:GetCaster():GetHealthPercent() < self.min_bonus_pct then
		local value = ( math.max( self.max_bonus_pct, self:GetCaster():GetHealthPercent() ) - self.min_bonus_pct) / (self.max_bonus_pct - self.min_bonus_pct)
		stacks = math.floor( value * 100 )
		if not self.NFX then
			self.NFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_bloodseeker/bloodseeker_thirst_owner.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster() )
		end
	else
		
		if self.NFX then
			ParticleManager:ClearParticle( self.NFX )
			self.NFX = nil
		end
	end
	if self.linger_duration > 0 and ( self:GetCaster():GetAttackTarget() or GameRules:GetGameTime() - (self:GetCaster():GetLastAttackTime() or 0) < self.linger_duration ) then
		stacks = 100 - stacks
	end
	self:SetStackCount( stacks )
end

function modifier_bloodseeker_thirst_buff:CheckState()
	if self.linger_duration > 0 and self:GetStackCount() >= 100 then
		return {[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true}
	end
end

function modifier_bloodseeker_thirst_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT, 
			MODIFIER_PROPERTY_MOVESPEED_LIMIT,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS 
			}
end

function modifier_bloodseeker_thirst_buff:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_movement_speed * self:GetStackCount() / 100
end

function modifier_bloodseeker_thirst_buff:GetModifierPhysicalArmorBonus()
	return self.bonus_armor * self:GetStackCount() / 100
end

function modifier_bloodseeker_thirst_buff:GetModifierIgnoreMovespeedLimit()
	return 1
end

function modifier_bloodseeker_thirst_buff:GetModifierMoveSpeed_Limit()
	return 3500
end

function modifier_bloodseeker_thirst_buff:IsHidden()
	return self:GetStackCount() == 0
end