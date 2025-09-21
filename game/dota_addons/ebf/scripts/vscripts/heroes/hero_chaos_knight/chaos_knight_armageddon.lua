chaos_knight_armageddon = class({})

function chaos_knight_armageddon:Precache(context)
	PrecacheResource("particle", "particles/units/heroes/hero_chaos_knight/chaos_knight_calamity_overhead.vpcf", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_chaos_knight.vsndevts", context)
end

function chaos_knight_armageddon:OnSpellStart()
	local caster = self:GetCaster()
    local affects_allies = self:GetSpecialValueFor("affects_allies")
    local duration = self:GetSpecialValueFor("duration")

	local allies = caster:FindFriendlyUnitsInRadius(caster:GetOrigin(), FIND_UNITS_EVERYWHERE)
	for _, heroes in pairs(allies) do
    	if affects_allies >= 1 and heroes:IsRealHero() then
        	heroes:AddNewModifier(caster, self, "modifier_chaos_knight_armageddon_buff", {duration = duration})
			heroes:AddNewModifier(caster, self, "modifier_chaos_knight_armageddon_aura", {duration = duration})
    	end
	end
    EmitSoundOn("Hero_ChaosKnight.Phantasm", caster)
    caster:AddNewModifier(caster, self, "modifier_chaos_knight_armageddon_buff", {duration = duration})
	caster:AddNewModifier(caster, self, "modifier_chaos_knight_armageddon_aura", {duration = duration})
end

function chaos_knight_armageddon:RefreshChanceModifiers()
	if not IsServer() then return end
	if self:GetCaster()._currentlyRefreshingAllModifiers then return end
	self:GetCaster()._currentlyRefreshingAllModifiers = true
	
	self:GetCaster():RefreshAllIntrinsicModifiers()
	Timers:CreateTimer( function() self:GetCaster()._currentlyRefreshingAllModifiers = false end )
end

modifier_chaos_knight_armageddon_buff = class({})  
LinkLuaModifier("modifier_chaos_knight_armageddon_buff", "heroes/hero_chaos_knight/chaos_knight_armageddon", LUA_MODIFIER_MOTION_NONE)

function modifier_chaos_knight_armageddon_buff:OnCreated()
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
	self:StartIntervalThink(2)
end

function modifier_chaos_knight_armageddon_buff:OnIntervalThink()
	local parent = self:GetParent()
	local radius = self:GetSpecialValueFor("aura_radius")
	local fx = ParticleManager:CreateParticle("particles/items5_fx/wraith_pact_pulses.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControl(fx, 1, Vector(radius, radius, 50))

	ParticleManager:ReleaseParticleIndex(fx)
end

function modifier_chaos_knight_armageddon_buff:OnRefresh()
    self.chance_increase = self:GetSpecialValueFor("chance_increase")
end

function modifier_chaos_knight_armageddon_buff:OnRemoved()
	self:GetParent()._chanceModifiersList[self] = nil

	if IsServer() then
		Timers:CreateTimer( function()
			if IsModifierSafe( self ) and IsEntitySafe( self:GetAbility() ) then
				self:GetAbility():RefreshChanceModifiers()
			end
		end )
	end
end
function modifier_chaos_knight_armageddon_buff:GetEffectName()
	return "particles/units/heroes/hero_chaos_knight/chaos_knight_calamity_overhead.vpcf"
end

function modifier_chaos_knight_armageddon_buff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_chaos_knight_armageddon_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE}
end

function modifier_chaos_knight_armageddon_buff:GetModifierChanceBonusConstant()
	return self.chance_increase
end

function modifier_chaos_knight_armageddon_buff:IsHidden()
    return false
end

function modifier_chaos_knight_armageddon_buff:IsPurgable()
    return true
end

function modifier_chaos_knight_armageddon_buff:IsBuff()
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
	return DOTA_UNIT_TARGET_TEAM_ENEMY
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
end

function modifier_chaos_knight_armageddon_debuff:OnRefresh()
	self.stat_res_reduction = self:GetSpecialValueFor("stat_res_reduction")
end

function modifier_chaos_knight_armageddon_debuff:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING}
end

function modifier_chaos_knight_armageddon_debuff:GetModifierStatusResistanceStacking()
	return -self.stat_res_reduction
end