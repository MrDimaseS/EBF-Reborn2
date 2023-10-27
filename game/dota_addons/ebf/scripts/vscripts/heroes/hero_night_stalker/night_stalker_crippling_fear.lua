night_stalker_crippling_fear = class({})

function night_stalker_crippling_fear:GetIntrinsicModifierName()
	return "modifier_night_stalker_crippling_fear_passive"
end

function night_stalker_crippling_fear:OnSpellStart()
	local caster = self:GetCaster()
	
	local duration = TernaryOperator( self:GetSpecialValueFor("duration_night"), not GameRules:IsDaytime() or caster:HasModifier("modifier_night_stalker_void_zone"), self:GetSpecialValueFor("duration_day") )
	
	EmitSoundOn("Hero_Nightstalker.Trickling_Fear", caster)
	caster:AddNewModifier(caster, self, "modifier_night_stalker_crippling_fear_active", {duration = duration})
end

modifier_night_stalker_crippling_fear_passive = class({})
LinkLuaModifier("modifier_night_stalker_crippling_fear_passive", "heroes/hero_night_stalker/night_stalker_crippling_fear", LUA_MODIFIER_MOTION_NONE)

function modifier_night_stalker_crippling_fear_passive:OnCreated()
	self:OnRefresh()
end

function modifier_night_stalker_crippling_fear_passive:OnRefresh()
	self.radius = self:GetSpecialValueFor("radius")
end

function modifier_night_stalker_crippling_fear_passive:IsAura()
	return self:GetCaster():GetCurrentVisionRange() == self:GetCaster():GetNightTimeVisionRange() or self:GetCaster():HasModifier("modifier_night_stalker_void_zone")
end

function modifier_night_stalker_crippling_fear_passive:GetModifierAura()
	return "modifier_night_stalker_crippling_fear_miss"
end

function modifier_night_stalker_crippling_fear_passive:GetAuraRadius()
	return self.radius
end

function modifier_night_stalker_crippling_fear_passive:GetAuraDuration()
	return 0.5
end

function modifier_night_stalker_crippling_fear_passive:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_night_stalker_crippling_fear_passive:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_night_stalker_crippling_fear_passive:IsHidden()
	return true
end

modifier_night_stalker_crippling_fear_active = class({})
LinkLuaModifier("modifier_night_stalker_crippling_fear_active", "heroes/hero_night_stalker/night_stalker_crippling_fear", LUA_MODIFIER_MOTION_NONE)

function modifier_night_stalker_crippling_fear_active:OnCreated()
	self.radius = self:GetSpecialValueFor("radius")
	if IsServer() then
		local sFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_night_stalker/nightstalker_crippling_fear_aura.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
		ParticleManager:SetParticleControl(sFX, 2, Vector(self.radius,self.radius,self.radius) )
		self:AddEffect(sFX)
	end
end

function modifier_night_stalker_crippling_fear_active:OnDestroy()
	if IsServer() then
		EmitSoundOn("Hero_Nightstalker.Trickling_Fear_end", self:GetParent() )
	end
end

function modifier_night_stalker_crippling_fear_active:IsAura()
	return true
end

function modifier_night_stalker_crippling_fear_active:GetModifierAura()
	return "modifier_night_stalker_crippling_fear_silence"
end

function modifier_night_stalker_crippling_fear_active:GetAuraRadius()
	return self.radius
end

function modifier_night_stalker_crippling_fear_active:GetAuraDuration()
	return 0.5
end

function modifier_night_stalker_crippling_fear_active:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_night_stalker_crippling_fear_active:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

modifier_night_stalker_crippling_fear_silence = class({})
LinkLuaModifier("modifier_night_stalker_crippling_fear_silence", "heroes/hero_night_stalker/night_stalker_crippling_fear", LUA_MODIFIER_MOTION_NONE)

function modifier_night_stalker_crippling_fear_silence:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink( self.tick_rate )
	end
end

function modifier_night_stalker_crippling_fear_silence:OnRefresh()
	self.miss = self:GetSpecialValueFor("miss_chance")
	self.tick_rate = self:GetSpecialValueFor("tick_rate")
	self.dps = self:GetSpecialValueFor("dps")
end

function modifier_night_stalker_crippling_fear_silence:OnIntervalThink()
	self:GetAbility():DealDamage( self:GetCaster(), self:GetParent(), self.dps * self.tick_rate )
end

function modifier_night_stalker_crippling_fear_silence:GetEffectName()
	return "particles/units/heroes/hero_night_stalker/nightstalker_crippling_fear.vpcf"
end

function modifier_night_stalker_crippling_fear_silence:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_night_stalker_crippling_fear_silence:DeclareFunctions()
	return {MODIFIER_PROPERTY_MISS_PERCENTAGE}
end

function modifier_night_stalker_crippling_fear_silence:GetModifierMiss_Percentage()
	return self.miss
end

function modifier_night_stalker_crippling_fear_silence:CheckState()
	return {[MODIFIER_STATE_SILENCED] = true}
end

modifier_night_stalker_crippling_fear_miss = class({})
LinkLuaModifier("modifier_night_stalker_crippling_fear_miss", "heroes/hero_night_stalker/night_stalker_crippling_fear", LUA_MODIFIER_MOTION_NONE)

function modifier_night_stalker_crippling_fear_miss:OnCreated()
	self:OnRefresh()
end

function modifier_night_stalker_crippling_fear_miss:OnRefresh()
	self.miss = self:GetSpecialValueFor("night_miss")
end

function modifier_night_stalker_crippling_fear_miss:DeclareFunctions()
	return {MODIFIER_PROPERTY_MISS_PERCENTAGE}
end

function modifier_night_stalker_crippling_fear_miss:GetModifierMiss_Percentage()
	return self.miss
end

function modifier_night_stalker_crippling_fear_miss:IsHidden()
	return false
end