chaos_knight_armageddon = class({})

function chaos_knight_armageddon:Precache(context)
	PrecacheResource("particle", "particles/units/heroes/hero_chaos_knight/chaos_knight_calamity_overhead.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/effigies/status_fx_effigies/se_ambient_ti6_lvl3_ribbon.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/effigies/status_fx_effigies/aghs_statue_standard_elite_ambient_i.vpcf", context)
	PrecacheResource("particle", "particles/items5_fx/wraith_pact_pulses.vpcf", context)
end

function chaos_knight_armageddon:OnSpellStart()
	local caster = self:GetCaster()
    local affects_allies = self:GetSpecialValueFor("affects_allies")
    local duration = self:GetSpecialValueFor("duration")

	local allies = caster:FindFriendlyUnitsInRadius(caster:GetOrigin(), FIND_UNITS_EVERYWHERE)
	for _, heroes in pairs(allies) do
    	if affects_allies >= 1 and heroes:IsRealHero() then
        	heroes:AddNewModifier(caster, self, "modifier_chaos_knight_armageddon_buff", {duration = duration})
    	end
	end
    EmitSoundOn("Hero_ChaosKnight.Phantasm", caster)
    caster:AddNewModifier(caster, self, "modifier_chaos_knight_armageddon_buff", {duration = duration})
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

	if IsServer() then Timers:CreateTimer( function() 
		self:GetAbility():RefreshChanceModifiers() end )
	end
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