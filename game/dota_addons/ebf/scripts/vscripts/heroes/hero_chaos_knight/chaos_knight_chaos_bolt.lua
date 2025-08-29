chaos_knight_chaos_bolt = class({})

function chaos_knight_chaos_bolt:Preacache(context)
    PrecacheResource("particle", "particles/units/heroes/hero_chaos_knight/chaos_knight_chaos_bolt.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_chaos_knight/chaos_knight_bolt_msg.vpcf", context)
end

function chaos_knight_chaos_bolt:GetBehavior()
    if self:GetSpecialValueFor("aoe_bolt") ~= 0 then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_AOE
    else
        return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
    end
end

function chaos_knight_chaos_bolt:OnAbilityPhaseStart()
    self.caster = self:GetCaster()
    self.illusion_throw_bolt = self:GetSpecialValueFor("illusion_throw_bolt") 
    if self.illusion_throw_bolt > 0 then
        local illusions = self.caster:FindFriendlyUnitsInRadius(self.caster:GetAbsOrigin(), self:GetSpecialValueFor("fake_bolt_radius"))
        for _, illusion in ipairs(illusions) do
            if illusion:IsIllusion() and illusion:GetPlayerOwnerID() == self.caster:GetPlayerOwnerID() then
                illusion:StartGesture(ACT_DOTA_CAST_ABILITY_1)
            end
        end
    end
end

function chaos_knight_chaos_bolt:OnAbilityPhaseInterrupted()
    if self.illusion_throw_bolt > 0 then
        local illusions = self.caster:FindFriendlyUnitsInRadius(self.caster:GetAbsOrigin(), self:GetSpecialValueFor("fake_bolt_radius"))
        for _, illusion in ipairs(illusions) do
            if illusion:IsIllusion() and illusion:GetPlayerOwnerID() == self.caster:GetPlayerOwnerID() then
                illusion:StopGesture(ACT_DOTA_CAST_ABILITY_1)
            end
        end
    end
end

function chaos_knight_chaos_bolt:OnSpellStart()
    local caster = self:GetCaster()
	local target = self:GetCursorTarget()

    EmitSoundOn("Hero_ChaosKnight.ChaosBolt.Cast", caster)
    local radius = self:GetSpecialValueFor("aoe_bolt")

    if radius ~= 0 then
        local enemies = self.caster:FindEnemyUnitsInRadius(self.caster:GetAbsOrigin(), radius)
        for _, unit in ipairs (enemies) do
            self:ThrowBolt(unit, caster)
        end
    else
        self:ThrowBolt(target, caster)
    end

    if self.illusion_throw_bolt > 0 then
        local illusions = self.caster:FindFriendlyUnitsInRadius(self.caster:GetAbsOrigin(), self:GetSpecialValueFor("fake_bolt_radius"))
        for _, illusion in ipairs(illusions) do
            if illusion:IsIllusion() and illusion:GetPlayerOwnerID() == self.caster:GetPlayerOwnerID() then
                self:ThrowBolt(target, illusion)
            end
        end
    end
end

function chaos_knight_chaos_bolt:ThrowBolt(target, origin)
    local bolt = self:FireTrackingProjectile("particles/units/heroes/hero_chaos_knight/chaos_knight_chaos_bolt.vpcf", target, self:GetSpecialValueFor("chaos_bolt_speed"), {source = origin})

    self.projectiles = self.projectiles or {}
    self.projectiles[bolt] = {bounces = self:GetSpecialValueFor("bounce_count"), targets = {[origin:entindex()] = true}}

    return bolt
end

function chaos_knight_chaos_bolt:OnProjectileHitHandle(target, position, projectile)
    local caster = self:GetCaster()
    self.illusion_duration = self:GetSpecialValueFor("illu_dur")
    if IsEntitySafe( target ) then
        local minDamage = self:GetSpecialValueFor("damage_min")
        local maxDamage = self:GetSpecialValueFor("damage_max")

        local minStun = self:GetSpecialValueFor("stun_min")
        local maxStun = self:GetSpecialValueFor("stun_max")

        local damage = math.random(minDamage, maxDamage)
        local stunDuration = math.random(minStun, maxStun)

        if target:TriggerSpellAbsorb( self ) then return end

        self:DealDamage(caster, target, damage)
        self:Stun(target, stunDuration)

        ---------------------------------------------------------------------------------------------
        local illusion_create = self:GetSpecialValueFor("illusion_create")
        local phantasm_illu = self:GetCaster():FindAbilityByName("chaos_knight_phantasm")
        
        if illusion_create > 0 and phantasm_illu:IsTrained() then
            phantasm_illu:CreateAbilityIllusion(self.illusion_duration, illusion_create, target:GetAbsOrigin())
        end

        ---------------------------------------------------------------------------------------------
        local bounce_chance_pct = self:GetSpecialValueFor("bounce_chance_pct")

        self.projectiles[projectile].targets[target:entindex()] = true

        if self.projectiles[projectile] and self.projectiles[projectile].bounces > 0 then
            local bounce_radius = self:GetSpecialValueFor("AbilityCastRange")
            for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), bounce_radius ) ) do
                if not self.projectiles[projectile].targets[enemy:entindex()] and RollPercentage(bounce_chance_pct) then
                    local newProj = self:ThrowBolt(enemy, target)
                    self.projectiles[newProj].targets = table.copy( self.projectiles[projectile].targets )
					self.projectiles[newProj].bounces = self.projectiles[projectile].bounces - 1
                    break
                end
            end
            self.projectiles[projectile] = nil
        end
        self:StunCounter(target, damage, stunDuration)
    end
end

function chaos_knight_chaos_bolt:StunCounter(target, damage, stun)
    local digit = 4
	if damage < 100 then digit = 3 end
	local digit1 = damage%10
	local digit2 = math.floor((damage%100)/10)
	local digit3 = math.floor((damage%1000)/100)
	local number = digit3*100 + digit2*10 + digit1

    local nFXIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_chaos_knight/chaos_knight_bolt_msg.vpcf", PATTACH_OVERHEAD_FOLLOW, target)
    ParticleManager:SetParticleControl( nFXIndex, 0, target:GetOrigin() )
	ParticleManager:SetParticleControl( nFXIndex, 1, Vector( 0, number, 3 ) )
	ParticleManager:SetParticleControl( nFXIndex, 2, Vector( 2, digit, 0 ) )
	ParticleManager:SetParticleControl( nFXIndex, 3, Vector( 0,	stun, 4 ) )
	ParticleManager:SetParticleControl( nFXIndex, 4, Vector( 2,	2, 0 ) )
	ParticleManager:ReleaseParticleIndex( nFXIndex )

    EmitSoundOn("Hero_ChaosKnight.ChaosBolt.Impact", target)
end
