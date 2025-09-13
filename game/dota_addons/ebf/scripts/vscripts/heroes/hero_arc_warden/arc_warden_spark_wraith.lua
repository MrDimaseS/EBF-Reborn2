arc_warden_spark_wraith = class({})

function arc_warden_spark_wraith:GetAOERadius()
    return self:GetSpecialValueFor("wraith_radius")
end

function arc_warden_spark_wraith:OnSpellStart()
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    local duration = self:GetSpecialValueFor("duration")

    if self:GetSpecialValueFor("maximum_targets") ~= 0 then
        CreateModifierThinker(caster, self, "modifier_arc_warden_spark_wraith_unity", {duration = duration}, point, caster:GetTeam(), false)
    else
        CreateModifierThinker(caster, self, "modifier_arc_warden_spark_wraith_disunity", {duration = duration}, point, caster:GetTeam(), false)
    end

    EmitSoundOn("Hero_ArcWarden.SparkWraith.Cast", caster)
    local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_arc_warden/arc_warden_wraith_cast.vpcf", PATTACH_POINT, caster)
                ParticleManager:SetParticleControlEnt(nfx, 1, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(nfx)
end

function arc_warden_spark_wraith:OnProjectileHitHandle(target)
    local caster = self:GetCaster()

    local spark_damage = self:GetSpecialValueFor("spark_damage_base")
    local aoe = caster:FindEnemyUnitsInRadius(target:GetAbsOrigin(), self:GetSpecialValueFor("spark_aoe"))
    local aoe_damage = self:GetSpecialValueFor("spark_aoe_damage")

    local pure_damage = self:GetSpecialValueFor("pure_damage")
    if pure_damage ~= 1 then
        self.damage_type = DAMAGE_TYPE_MAGICAL
    else
        self.damage_type = DAMAGE_TYPE_PURE
    end

    if target then
        EmitSoundOn("Hero_ArcWarden.SparkWraith.Damage", target)
        self:DealDamage(caster, target, spark_damage, {damage_type = self.damage_type})
        AddFOWViewer(caster:GetTeamNumber(), target:GetAbsOrigin(), self:GetSpecialValueFor("wraith_vision_radius"), self:GetSpecialValueFor("wraith_vision_duration"), true)
        for _, unit in ipairs(aoe) do
            if unit ~= target then
                self:DealDamage(caster, unit, aoe_damage, {damage_type = self.damage_type})
            end
        end
    end
end


-----------------------------------------------------------------------------------------------------------------------------------------
modifier_arc_warden_spark_wraith_disunity = class({})
LinkLuaModifier("modifier_arc_warden_spark_wraith_disunity", "heroes/hero_arc_warden/arc_warden_spark_wraith", LUA_MODIFIER_MOTION_NONE)

function modifier_arc_warden_spark_wraith_disunity:OnCreated()
    if IsServer() then
        local parent = self:GetParent()
        self.startup_time = self:GetSpecialValueFor("activation_delay")
		self.duration = self:GetSpecialValueFor("duration")
		self.radius = self:GetSpecialValueFor("wraith_radius")
		self.vision_radius = self:GetSpecialValueFor("wraith_vision_radius")

        local wraith_pos = parent:GetAbsOrigin()
        local wraith = ParticleManager:CreateParticle("particles/units/heroes/hero_arc_warden/arc_warden_wraith.vpcf", PATTACH_WORLDORIGIN, parent)
                ParticleManager:SetParticleControl(wraith, 0, wraith_pos)
                ParticleManager:SetParticleControl(wraith, 1, Vector(self.radius, self.radius, self.radius))
        self:AddEffect(wraith)
        self:StartIntervalThink(self.startup_time)
        EmitSoundOn("Hero_ArcWarden.SparkWraith.Appear", parent)
        EmitSoundOn("Hero_ArcWarden.SparkWraith.Loop", parent)
    end
end

function modifier_arc_warden_spark_wraith_disunity:OnIntervalThink()
    local wraith = self:GetParent()
	local caster = self:GetCaster()

    local outgoing_dmg = self:GetSpecialValueFor("outgoing_damage")

	if self.startup_time ~= nil then
		self.startup_time = nil
		self.expire = GameRules:GetGameTime() + self.duration
		self:StartIntervalThink(self:GetSpecialValueFor("attack_rate"))
    elseif self.duration ~= nil then
		if GameRules:GetGameTime() > self.expire then
			self:Destroy()
		else
            local enemies = caster:FindEnemyUnitsInRadius(wraith:GetAbsOrigin(), self.radius)
			for _,enemy in pairs(enemies) do
                caster:PerformGenericAttack(enemy, true, {bonusDamagePct = outgoing_dmg, procAttackEffects = true, neverMiss = true})
            end
            EmitSoundOn("Hero_ArcWarden.SparkWraith.Activate", wraith)
        end
    end
end

--------------------------------------------------------------------------------------------------------------------------------------------
modifier_arc_warden_spark_wraith_unity = class({})
LinkLuaModifier("modifier_arc_warden_spark_wraith_unity", "heroes/hero_arc_warden/arc_warden_spark_wraith", LUA_MODIFIER_MOTION_NONE)

function modifier_arc_warden_spark_wraith_unity:OnCreated()
    if IsServer() then
        local parent = self:GetParent()
        self.startup_time = self:GetSpecialValueFor("activation_delay") + 1.5
		self.duration = self:GetSpecialValueFor("duration")
		self.speed = self:GetSpecialValueFor("wraith_speed_base")
		self.radius = self:GetSpecialValueFor("wraith_radius")
		self.vision_radius = self:GetSpecialValueFor("wraith_vision_radius")

        local wraith_pos = parent:GetAbsOrigin()
        local wraith = ParticleManager:CreateParticle("particles/units/heroes/hero_arc_warden/arc_warden_wraith_tempest.vpcf", PATTACH_WORLDORIGIN, parent)
                ParticleManager:SetParticleControl(wraith, 0, wraith_pos)
                ParticleManager:SetParticleControl(wraith, 1, Vector(self.radius, self.radius, self.radius))
        self:AddEffect(wraith)
        self:StartIntervalThink(self.startup_time)
        EmitSoundOn("Hero_ArcWarden.SparkWraith.Appear", parent)
        EmitSoundOn("Hero_ArcWarden.SparkWraith.Loop", parent)
    end
end

function modifier_arc_warden_spark_wraith_unity:OnIntervalThink()
    local wraith = self:GetParent()
	local caster = self:GetCaster()
    local wraith_pos = wraith:GetAbsOrigin()

	if self.startup_time ~= nil then
		self.startup_time = nil
		self.expire = GameRules:GetGameTime() + self.duration
		self:StartIntervalThink(self:GetSpecialValueFor("think_interval"))
    elseif self.duration ~= nil then
		if GameRules:GetGameTime() > self.expire then
			self:Destroy()
		else
            local enemies = caster:FindEnemyUnitsInRadius(wraith_pos, self.radius, {order=FIND_CLOSEST})
            local maximum_targets = self:GetSpecialValueFor("maximum_targets")
            local real_targets = maximum_targets
			    for _, enemy in ipairs(enemies) do
                real_targets = real_targets - 1
                while real_targets > 0 and real_targets < maximum_targets do
                    EmitSoundOn("Hero_ArcWarden.SparkWraith.Activate", wraith)
                    self.duration = nil
                    self.expire = nil
                    self:StartIntervalThink(-1)
                    local proj =
                        {
                        Target = enemy,
                        Source = wraith,
                        Ability = self:GetAbility(),
                        EffectName = "particles/units/heroes/hero_arc_warden/arc_warden_wraith_prj.vpcf",
                        vSourceLoc = wraith_pos,
                        bDrawsOnMinimap = false,
                        iSourceAttachment = 1,
                        iMoveSpeed = self.speed,
                        bDodgeable = false,
                        bProvidesVision = true,
                        iVisionRadius = self.vision_radius,
                        iVisionTeamNumber = caster:GetTeam(),
                        bVisibleToEnemies = true,
                        flExpireTime = nil,
                        bReplaceExisting = false
                        }
                    ProjectileManager:CreateTrackingProjectile(proj)
                    self:Destroy()
                    break
                end
            end
        end
    end
end

function modifier_arc_warden_spark_wraith_unity:CheckState()
    if self.duration then
        return{[MODIFIER_STATE_PROVIDES_VISION] = true}
    end
    return nil
end