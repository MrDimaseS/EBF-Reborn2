clinkz_death_pact = class({})

function clinkz_death_pact:IsStealable()
    return true
end

function clinkz_death_pact:IsHiddenWhenStolen()
    return false
end

function clinkz_death_pact:CastFilterResultTarget( target )
	return UnitFilter(target, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, self:GetCaster():GetTeamNumber() )
end

function clinkz_death_pact:OnSpellStart()
	local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    EmitSoundOn("Hero_Clinkz.DeathPact.Cast", caster)
    EmitSoundOn("Hero_Clinkz.DeathPact", target)

    local damage = self:GetSpecialValueFor("damage")

    local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_clinkz/clinkz_death_pact.vpcf", PATTACH_POINT_FOLLOW, caster)
                ParticleManager:SetParticleControlEnt(nfx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
                ParticleManager:SetParticleControlEnt(nfx, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
                ParticleManager:SetParticleControlEnt(nfx, 5, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
                ParticleManager:ReleaseParticleIndex(nfx)

    local damage = self:DealDamage(caster, target, damage)
	caster:RemoveModifierByName("modifier_clinkz_death_pact_buff")
    caster:AddNewModifier(caster, self, "modifier_clinkz_death_pact_buff", {duration = self:GetSpecialValueFor("duration"), damage = damage})
	caster:HealEvent( damage * self:GetSpecialValueFor("health_gain_pct")/100, self, caster )
	
	-- skeleton
	if not self.deathPactSkeletonArcher then
		self.deathPactSkeletonArcher = caster:CreateSummon( "npc_dota_clinkz_skeleton_archer", target:GetAbsOrigin() + RandomVector(150), 30 )
		self.deathPactSkeletonArcher:SetUnitCanRespawn( true )
	end
	self.deathPactSkeletonArcher:RespawnUnit()
	self.deathPactSkeletonArcher:AddNewModifier( caster, self, "modifier_clinkz_burning_army", {duration = 30} )
	
	local tarBomb = caster:FindAbilityByName("clinkz_tar_bomb")
	if tarBomb and tarBomb:IsTrained() then
		self.deathPactSkeletonArcher:AddNewModifier( caster, tarBomb, "modifier_clinkz_tar_bomb_searing_arrows", {} )
	end
	FindClearSpaceForUnit(self.deathPactSkeletonArcher, target:GetAbsOrigin() + RandomVector(150), true)
end

modifier_clinkz_death_pact_buff = class({})
LinkLuaModifier( "modifier_clinkz_death_pact_buff", "heroes/hero_clinkz/clinkz_death_pact.lua" ,LUA_MODIFIER_MOTION_NONE )


function modifier_clinkz_death_pact_buff:OnCreated(kv)
	if IsServer() then
		self:OnRefresh(kv)
		self:SetHasCustomTransmitterData( true )
	end
end

function modifier_clinkz_death_pact_buff:OnRefresh(kv)
    if IsServer() then 
		self.health = kv.damage * self:GetSpecialValueFor("health_gain_pct")/100
		self.damage = kv.damage * self:GetSpecialValueFor("damage_gain_pct")/100
	end
end

function modifier_clinkz_death_pact_buff:AddCustomTransmitterData()
	local data = { health = self.health,
				   damage = self.damage }
	return data
end

function modifier_clinkz_death_pact_buff:HandleCustomTransmitterData( data )
	self.health = data.health
	self.damage = data.damage
end

function modifier_clinkz_death_pact_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_HEALTH_BONUS,
    }
    return funcs
end

function modifier_clinkz_death_pact_buff:GetModifierPreAttack_BonusDamage()
    return self.damage
end

function modifier_clinkz_death_pact_buff:GetModifierHealthBonus()
    return self.health
end

function modifier_clinkz_death_pact_buff:GetEffectName()
    return "particles/units/heroes/hero_clinkz/clinkz_death_pact_buff.vpcf"
end

function modifier_clinkz_death_pact_buff:IsPurgable()
    return false
end