chaos_knight_armageddon = class({})

function chaos_knight_armageddon:Precache(context)
	PrecacheResource("particle", "particles/units/heroes/hero_chaos_knight/chaos_knight_calamity_overhead.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/effigies/status_fx_effigies/se_ambient_ti6_lvl3_ribbon.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/effigies/status_fx_effigies/aghs_statue_standard_elite_ambient_i.vpcf", context)
	PrecacheResource("particle", "particles/items5_fx/wraith_pact_pulses.vpcf", context)
end

function chaos_knight_armageddon:OnSpellStart()
	local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")

    EmitSoundOn("Hero_ChaosKnight.Phantasm", caster)
    caster:AddNewModifier(caster, self, "modifier_chaos_knight_armageddon_handler", {duration = duration})
	caster:AddNewModifier(caster, self, "modifier_chaos_knight_armageddon_aura", {duration = duration})
end

function chaos_knight_armageddon:RefreshChanceModifiers()
	if not IsServer() then return end
	if self:GetCaster()._currentlyRefreshingAllModifiers then return end
	self:GetCaster()._currentlyRefreshingAllModifiers = true
	
	self:GetCaster():RefreshAllIntrinsicModifiers()
	Timers:CreateTimer( function() self:GetCaster()._currentlyRefreshingAllModifiers = false end )
end

modifier_chaos_knight_armageddon_handler = class({})  
LinkLuaModifier("modifier_chaos_knight_armageddon_handler", "heroes/hero_chaos_knight/chaos_knight_armageddon", LUA_MODIFIER_MOTION_NONE)

function modifier_chaos_knight_armageddon_handler:OnCreated()
	self:StartIntervalThink(2)
end

function modifier_chaos_knight_armageddon_handler:OnIntervalThink()
	local parent = self:GetParent()
	local radius = self:GetSpecialValueFor("aura_radius")
	local fx = ParticleManager:CreateParticle("particles/items5_fx/wraith_pact_pulses.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControl(fx, 1, Vector(radius, radius, 50))

	ParticleManager:ReleaseParticleIndex(fx)
end

function modifier_chaos_knight_armageddon_handler:GetEffectName()
	return "particles/units/heroes/hero_chaos_knight/chaos_knight_calamity_overhead.vpcf"
end

function modifier_chaos_knight_armageddon_handler:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_chaos_knight_armageddon_handler:IsHidden()
    return false
end

function modifier_chaos_knight_armageddon_handler:IsPurgable()
    return false
end

function modifier_chaos_knight_armageddon_handler:IsBuff()
	return true
end

modifier_chaos_knight_armageddon_aura = class({})
LinkLuaModifier("modifier_chaos_knight_armageddon_aura", "heroes/hero_chaos_knight/chaos_knight_armageddon", LUA_MODIFIER_MOTION_NONE)

function modifier_chaos_knight_armageddon_aura:IsHidden()
    return true
end

function modifier_chaos_knight_armageddon_aura:OnCreated()
    self:OnRefresh()
end

function modifier_chaos_knight_armageddon_aura:OnRefresh()
    self.radius = self:GetSpecialValueFor("aura_radius")
end

function modifier_chaos_knight_armageddon_aura:IsAura()
    return true
end

function modifier_chaos_knight_armageddon_aura:GetAuraRadius()
    return self.radius
end

function modifier_chaos_knight_armageddon_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_chaos_knight_armageddon_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_ALL
end

function modifier_chaos_knight_armageddon_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS
end

function modifier_chaos_knight_armageddon_aura:GetModifierAura()
    return "modifier_chaos_knight_armageddon_debuff"
end


modifier_chaos_knight_armageddon_debuff = class({})
LinkLuaModifier("modifier_chaos_knight_armageddon_debuff", "heroes/hero_chaos_knight/chaos_knight_armageddon", LUA_MODIFIER_MOTION_NONE)

function modifier_chaos_knight_armageddon_debuff:IsDebuff()
	return true
end

function modifier_chaos_knight_armageddon_debuff:GetTextureName()
	return "chaos_knight_armageddon"
end

function modifier_chaos_knight_armageddon_debuff:OnCreated()
	self:OnRefresh()
	self:GetParent()._chanceModifiersList = self:GetParent()._chanceModifiersList or {}
	self:GetParent()._chanceModifiersList[self] = true

	if IsServer() then
		self.particle1 = ParticleManager:CreateParticle("particles/econ/items/effigies/status_fx_effigies/se_ambient_ti6_lvl3_ribbon.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		self.particle2 = ParticleManager:CreateParticle("particles/econ/items/effigies/status_fx_effigies/aghs_statue_standard_elite_ambient_i.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())

		self:AttachEffect(self.particle1)
		self:AttachEffect(self.particle2)

		Timers:CreateTimer( function()
		self:GetAbility():RefreshChanceModifiers() end )
	end
end

function modifier_chaos_knight_armageddon_debuff:OnRefresh()
	self.stat_res_reduction = self:GetSpecialValueFor("stat_res_reduction")
	self.mres_reduc = self:GetSpecialValueFor("mres_reduc")
	self.chance_increase = self:GetSpecialValueFor("chance_increase")

	self.no_penalty = self:GetSpecialValueFor("no_ally_penalty")
end

function modifier_chaos_knight_armageddon_debuff:OnRemoved()
	self:GetParent()._chanceModifiersList[self] = nil

	if IsServer() then
		Timers:CreateTimer( function()
			if IsModifierSafe( self ) and IsEntitySafe( self:GetAbility() ) then
				self:GetAbility():RefreshChanceModifiers()
			end
		end )
	end
end

function modifier_chaos_knight_armageddon_debuff:DeclareFunctions()
	return
	{
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE
	}
end

function modifier_chaos_knight_armageddon_debuff:GetModifierChanceBonusConstant()
	return self.chance_increase
end

function modifier_chaos_knight_armageddon_debuff:GetModifierMagicalResistanceBonus()
	if self.no_penalty ~= 0 then
		if self:GetParent():GetTeamNumber() == 2 then
			return self.mres_reduc
		else
			return -self.mres_reduc
		end
	else
		return -self.mres_reduc
	end
end

function modifier_chaos_knight_armageddon_debuff:GetModifierStatusResistanceStacking()
	if self.no_penalty ~= 0 then
		if self:GetParent():GetTeamNumber() == 2 then
			return self.stat_res_reduction
		else
			return -self.stat_res_reduction
		end
	else
		return -self.stat_res_reduction
	end
end