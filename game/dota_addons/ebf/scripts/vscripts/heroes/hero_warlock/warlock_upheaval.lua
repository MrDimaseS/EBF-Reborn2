warlock_upheaval = class({})

function warlock_upheaval:OnSpellStart()
	local caster = self:GetCaster()
	local position = self:GetCursorPosition()
	
	self.slowStrength = self:GetSpecialValueFor("base_slow")
	self.damageStrength = self:GetSpecialValueFor("base_damage")
	self.attackSpeedStrength = self:GetSpecialValueFor("base_aspd")
	
	CreateModifierThinker(caster, self, "modifier_warlock_upheaval_thinker", {duration = self:GetSpecialValueFor("AbilityChannelTime")}, position, caster:GetTeam(), false)
end

LinkLuaModifier("modifier_warlock_upheaval_thinker", "heroes/hero_warlock/warlock_upheaval", LUA_MODIFIER_MOTION_NONE)
modifier_warlock_upheaval_thinker = class({})

function modifier_warlock_upheaval_thinker:OnCreated()
	self:OnRefresh()
	if IsServer() then
		local nFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_warlock/warlock_upheaval.vpcf", PATTACH_WORLDORIGIN, nil )
		ParticleManager:SetParticleControl( nFX, 0, self:GetParent():GetAbsOrigin() )
		ParticleManager:SetParticleControl( nFX, 1, Vector( self.aoe, 0, 0 ) )
		
		EmitSoundOn("Hero_Warlock.Upheaval", self:GetParent() )
		
		self:AddEffect( nFX )
		
		self:StartIntervalThink( 0.1 )
	end
end

function modifier_warlock_upheaval_thinker:OnRefresh()
	self.aoe = self:GetSpecialValueFor("aoe")
	self.duration = self:GetSpecialValueFor("duration")
	
	self.slow_per_second = self:GetSpecialValueFor("slow_per_second")
	self.max_slow = self:GetSpecialValueFor("max_slow")
	self.damage_per_second = self:GetSpecialValueFor("damage_per_second")
	self.max_damage = self:GetSpecialValueFor("max_damage")
	self.aspd_per_second = self:GetSpecialValueFor("aspd_per_second")
	self.max_aspd = self:GetSpecialValueFor("max_aspd")
	
	self.imps_interval = self:GetSpecialValueFor("imps_interval")
	
	self.interval = 0
end

function modifier_warlock_upheaval_thinker:OnIntervalThink()
	if not self:GetCaster():IsChanneling() then
		self:Destroy()
	end
	if self.imps_interval > 0 then
		self.interval = self.interval + 0.1
		if self.imps_interval < self.interval then
			self:GetCaster():SpawnImp( self:GetParent():GetAbsOrigin() )
			self.interval = 0
		end
	end
	if self:GetAbility().slowStrength < self.max_slow then
		self:GetAbility().slowStrength = math.min( self.max_slow, self:GetAbility().slowStrength + self.slow_per_second * 0.1 )
	end
	if self:GetAbility().damageStrength < self.max_damage then
		self:GetAbility().damageStrength = math.min( self.max_damage, self:GetAbility().damageStrength + self.damage_per_second * 0.1 )
	end
	if self:GetAbility().attackSpeedStrength < self.max_aspd then
		self:GetAbility().attackSpeedStrength = math.min( self.max_aspd, self:GetAbility().attackSpeedStrength + self.aspd_per_second * 0.1 )
	end
end

function modifier_warlock_upheaval_thinker:OnDestroy()
	if not IsServer() then return end
		
	StopSoundOn("Hero_Warlock.Upheaval", self:GetParent() )
	if IsEntitySafe( self:GetParent() ) then
		UTIL_Remove( self:GetParent() )
	end
	if self:GetCaster():IsChanneling() then
		self:GetCaster():Stop()
	end
end

function modifier_warlock_upheaval_thinker:IsAura()
	return true
end

function modifier_warlock_upheaval_thinker:GetModifierAura()
	return "modifier_warlock_upheaval_effect"
end

function modifier_warlock_upheaval_thinker:GetAuraRadius()
	return self.aoe
end

function modifier_warlock_upheaval_thinker:GetAuraDuration()
	return self.duration
end

function modifier_warlock_upheaval_thinker:GetAuraSearchTeam()    
	local team = DOTA_UNIT_TARGET_TEAM_ENEMY
	if self.max_aspd > 0 then
		team = team + DOTA_UNIT_TARGET_TEAM_FRIENDLY
	end
	return team
end

function modifier_warlock_upheaval_thinker:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

LinkLuaModifier("modifier_warlock_upheaval_effect", "heroes/hero_warlock/warlock_upheaval", LUA_MODIFIER_MOTION_NONE)
modifier_warlock_upheaval_effect = class({})

function modifier_warlock_upheaval_effect:OnCreated()
	self:SetHasCustomTransmitterData(true)
	if IsServer() then
		self:OnRefresh()
		self:StartIntervalThink(0.5)
	end
end

function modifier_warlock_upheaval_effect:OnRefresh()
	if not IsServer() then return end
	self.aoe = self:GetSpecialValueFor("aoe")
	if self:GetCaster():IsSameTeam( self:GetParent() ) then
		self.damage = 0
		self.slow = 0
		self.attackspeed = self:GetAbility().attackSpeedStrength or 0
	else
		self.damage = self:GetAbility().damageStrength or 0
		self.slow = self:GetAbility().slowStrength or 0
		self.attackspeed = 0
	end
	self:SendBuffRefreshToClients()
end

function modifier_warlock_upheaval_effect:OnIntervalThink()
	self:OnRefresh()
	if self.damage > 0 and (self:GetDuration() - self:GetRemainingTime()) < FrameTime() * 2  then
		self:GetAbility():DealDamage( self:GetCaster(), self:GetParent(), self.damage )
	end
end

function modifier_warlock_upheaval_effect:OnDestroy()
	if IsServer() and self:GetParent():IsSameTeam(self:GetCaster()) then
		self:GetCaster():SpawnImp( self:GetParent():GetAbsOrigin() + RandomVector( 300 ) )
	end
end

function modifier_warlock_upheaval_effect:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_warlock_upheaval_effect:GetModifierAttackSpeedBonus_Constant()
	return self.attackspeed
end

function modifier_warlock_upheaval_effect:GetModifierMoveSpeedBonus_Percentage()
	return -(self.slow or 0)
end

function modifier_warlock_upheaval_effect:AddCustomTransmitterData()
	return {slow = tonumber(self.slow),
			attackspeed = tonumber(self.attackspeed)}
end

function modifier_warlock_upheaval_effect:HandleCustomTransmitterData(data)
	self.slow = tonumber(data.slow)
	self.attackspeed = tonumber(data.attackspeed)
end