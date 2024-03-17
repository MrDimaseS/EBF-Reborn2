boss_rift_general_pit_of_malice = class({})

function boss_rift_general_pit_of_malice:IsStealable()
    return true
end

function boss_rift_general_pit_of_malice:IsHiddenWhenStolen()
    return false
end

function boss_rift_general_pit_of_malice:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function boss_rift_general_pit_of_malice:OnAbilityPhaseStart()
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    local radius = self:GetSpecialValueFor("radius")
	caster:EmitSound("Hero_AbyssalUnderlord.PitOfMalice.Start")
	self.nfx = ParticleManager:CreateParticle("particles/units/heroes/heroes_underlord/underlord_pitofmalice_pre.vpcf", PATTACH_POINT, caster)
                ParticleManager:SetParticleControl(self.nfx, 0, point)
                ParticleManager:SetParticleControl(self.nfx, 1, Vector(radius, radius, radius))

    return true
end

function boss_rift_general_pit_of_malice:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
	ParticleManager:ClearParticle(self.nfx)
	caster:StopSound("Hero_AbyssalUnderlord.PitOfMalice.Start")
end

function boss_rift_general_pit_of_malice:OnSpellStart()
	local caster = self:GetCaster()
    local point = self:GetCursorPosition()
	
	if self.nfx then
		ParticleManager:ClearParticle(self.nfx)
	end
	
	caster:EmitSound("Hero_AbyssalUnderlord.PitOfMalice")
    CreateModifierThinker(caster, self, "modifier_boss_rift_general_pit_of_malice", {Duration = self:GetSpecialValueFor("pit_duration")}, point, caster:GetTeam(), false)
end

modifier_boss_rift_general_pit_of_malice = class({})
LinkLuaModifier( "modifier_boss_rift_general_pit_of_malice", "bosses/boss_asura/boss_rift_general_pit_of_malice.lua" ,LUA_MODIFIER_MOTION_NONE )
function modifier_boss_rift_general_pit_of_malice:OnCreated(table)
    if IsServer() then
        local caster = self:GetCaster()
        local point = self:GetParent():GetAbsOrigin()

        self.radius = self:GetSpecialValueFor("radius")
        local duration = self:GetDuration()

        local nfx = ParticleManager:CreateParticle("particles/units/heroes/heroes_underlord/underlord_pitofmalice.vpcf", PATTACH_POINT, caster)
                    ParticleManager:SetParticleControl(nfx, 0, point)
                    ParticleManager:SetParticleControl(nfx, 1, Vector(self.radius, 10, self.radius))
                    ParticleManager:SetParticleControl(nfx, 2, Vector(duration, 0, 0))
        self:AttachEffect(nfx)
    end
end

function modifier_boss_rift_general_pit_of_malice:IsAura()
    return true
end

function modifier_boss_rift_general_pit_of_malice:GetAuraDuration()
    return 0.1
end

function modifier_boss_rift_general_pit_of_malice:GetAuraRadius()
    return self.radius
end

function modifier_boss_rift_general_pit_of_malice:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_boss_rift_general_pit_of_malice:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_boss_rift_general_pit_of_malice:GetModifierAura()
    return "modifier_boss_rift_general_pit_of_malice_root_handle"
end

modifier_boss_rift_general_pit_of_malice_root_handle = class({})
LinkLuaModifier( "modifier_boss_rift_general_pit_of_malice_root_handle", "bosses/boss_asura/boss_rift_general_pit_of_malice.lua" ,LUA_MODIFIER_MOTION_NONE )
function modifier_boss_rift_general_pit_of_malice_root_handle:IsHidden()
    return true
end

function modifier_boss_rift_general_pit_of_malice_root_handle:OnCreated(table)
	self.duration = self:GetSpecialValueFor("ensnare_duration")
    if IsServer() then
		self:StartIntervalThink( self:GetSpecialValueFor("pit_interval") )
		self:OnIntervalThink( )
    end
end

function modifier_boss_rift_general_pit_of_malice_root_handle:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = caster:FindAbilityByName("boss_rift_general_pit_of_malice")

    local duration = self:GetSpecialValueFor("ensnare_duration")

	if IsEntitySafe( caster ) then
		parent:AddNewModifier(caster, ability, "modifier_abyssal_underlord_pit_of_malice_ensare", {Duration = duration})
	else
		self:StartIntervalThink( -1 )
	end
end