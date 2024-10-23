boss_rift_general_firestorm = class({})
LinkLuaModifier( "modifier_boss_rift_general_firestorm", "bosses/boss_asura/boss_rift_general_firestorm.lua" ,LUA_MODIFIER_MOTION_NONE )

function boss_rift_general_firestorm:IsStealable()
    return true
end

function boss_rift_general_firestorm:IsHiddenWhenStolen()
    return false
end

function boss_rift_general_firestorm:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function boss_rift_general_firestorm:OnAbilityPhaseStart()
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
	caster:EmitSound("Hero_AbyssalUnderlord.Firestorm.Start")
    local radius = self:GetSpecialValueFor("radius")

    self.nfx = ParticleManager:CreateParticle("particles/units/heroes/heroes_underlord/underlord_firestorm_pre.vpcf", PATTACH_POINT, caster)
                ParticleManager:SetParticleControl(self.nfx, 0, point)
                ParticleManager:SetParticleControl(self.nfx, 1, Vector(radius, radius, 1))

    return true
end

function boss_rift_general_firestorm:OnAbilityPhaseInterrupted()
	ParticleManager:ClearParticle( self.nfx )
	self:GetCaster():StopSound("Hero_AbyssalUnderlord.Firestorm.Start")
end

function boss_rift_general_firestorm:OnSpellStart()
	local caster = self:GetCaster()
    local point = self:GetCursorPosition()
	
	caster:EmitSound("Hero_AbyssalUnderlord.Firestorm.Cast")
	if self.nfx then
		ParticleManager:ClearParticle( self.nfx )
	end
	local duration = self:GetSpecialValueFor("wave_count") * self:GetSpecialValueFor("wave_interval")
    CreateModifierThinker(caster, self, "modifier_boss_rift_general_firestorm", {Duration = duration + 1}, point, caster:GetTeam(), false)
end

modifier_boss_rift_general_firestorm = class({})
function modifier_boss_rift_general_firestorm:OnCreated(table)
    if IsServer() then
        self:StartIntervalThink( self:GetSpecialValueFor("wave_interval") )
    end
end

function modifier_boss_rift_general_firestorm:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local point = parent:GetAbsOrigin()
	
	if not ( IsEntitySafe( caster ) and IsEntitySafe( ability ) ) then
		self:Destroy()
		return
	end
	
    local damage = self:GetSpecialValueFor("wave_damage")
    local radius = self:GetSpecialValueFor("radius")

    local nfx = ParticleManager:CreateParticle("particles/units/heroes/heroes_underlord/abyssal_underlord_firestorm_wave.vpcf", PATTACH_POINT, caster)
                ParticleManager:SetParticleControl(nfx, 0, point)
                ParticleManager:SetParticleControl(nfx, 4, Vector(radius, radius, radius))
                ParticleManager:ReleaseParticleIndex(nfx)
	parent:EmitSound("Hero_AbyssalUnderlord.Firestorm")
    local enemies = caster:FindEnemyUnitsInRadius(point, radius)
    for _,enemy in pairs(enemies) do
		enemy:AddNewModifier(caster, ability, "modifier_boss_rift_general_firestorm_burn", {Duration = self:GetSpecialValueFor("burn_duration")})
		ability:DealDamage(caster, enemy, damage, {}, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE)
		enemy:EmitSound("Hero_AbyssalUnderlord.Firestorm.Target")
    end
	AddFOWViewer( DOTA_TEAM_GOODGUYS, parent:GetAbsOrigin(), radius, 1, false )
end

modifier_boss_rift_general_firestorm_burn = class({})
LinkLuaModifier( "modifier_boss_rift_general_firestorm_burn", "bosses/boss_asura/boss_rift_general_firestorm" ,LUA_MODIFIER_MOTION_NONE )

function modifier_boss_rift_general_firestorm_burn:OnCreated(kv)
	self.interval = self:GetSpecialValueFor("burn_interval")
	self.burn_damage = self:GetSpecialValueFor("burn_damage") / 100
    if IsServer() then
        self:StartIntervalThink( self.interval )
    end
end


function modifier_boss_rift_general_firestorm_burn:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()
	
	if not ( IsEntitySafe( caster ) and IsEntitySafe( ability ) ) then
		self:Destroy()
		return 
	end
    local damage = parent:GetMaxHealth() * self.burn_damage
	
    ability:DealDamage(caster, parent, parent:GetMaxHealth() * self.burn_damage, {}, OVERHEAD_ALERT_BONUS_POISON_DAMAGE)
end

function modifier_boss_rift_general_firestorm_burn:GetEffectName()
    return "particles/units/heroes/heroes_underlord/abyssal_underlord_firestorm_wave_burn.vpcf"
end

function modifier_boss_rift_general_firestorm_burn:IsDebuff()
    return true
end