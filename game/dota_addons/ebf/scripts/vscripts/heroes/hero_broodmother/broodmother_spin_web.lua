broodmother_spin_web = class({})

function broodmother_spin_web:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function broodmother_spin_web:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

    EmitSoundOn("Hero_Broodmother.SpinWebCast", caster)
    local radius = self:GetSpecialValueFor("radius")
    local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_broodmother/broodmother_spin_web_cast.vpcf", PATTACH_POINT, caster)
                ParticleManager:SetParticleControlEnt(nfx, 0, caster, PATTACH_POINT, "attach_attack1", caster:GetAbsOrigin(), true)
                ParticleManager:SetParticleControl(nfx, 1, point)
                ParticleManager:SetParticleControl(nfx, 2, Vector(radius,radius,radius))
                ParticleManager:SetParticleControl(nfx, 3, Vector(radius,radius,radius))
                ParticleManager:ReleaseParticleIndex(nfx)

    self.webs = self.webs or {}
    local dummy = CreateModifierThinker( caster, self, "modifier_broodmother_spin_web_effect_aura", {}, point, caster:GetTeamNumber(), false )
	table.insert( self.webs, dummy )
	while #self.webs > self:GetSpecialValueFor("count") do
		if IsEntitySafe( self.webs[1] ) then self.webs[1]:RemoveSelf() end
		table.remove( self.webs, 1 )
	end
end

modifier_broodmother_spin_web_effect_aura = class({})
LinkLuaModifier("modifier_broodmother_spin_web_effect_aura", "heroes/hero_broodmother/broodmother_spin_web", LUA_MODIFIER_MOTION_NONE)
function modifier_broodmother_spin_web_effect_aura:OnCreated(table)
	self.radius = self:GetSpecialValueFor("radius")
    if IsServer() then
        local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_broodmother/broodmother_web.vpcf", PATTACH_POINT, self:GetParent())
                    ParticleManager:SetParticleControl(nfx, 0, self:GetParent():GetAbsOrigin())
                    ParticleManager:SetParticleControl(nfx, 1, Vector(self.radius, 0, 0))
        self:AttachEffect(nfx)
    end
end

function modifier_broodmother_spin_web_effect_aura:GetAuraEntityReject(hEntity)
    if hEntity:GetPlayerOwnerID() == self:GetCaster():GetPlayerOwnerID() then
        return false
	elseif not hEntity:IsSameTeam( self:GetCaster() ) then
		return not self:GetCaster():HasScepter()
    end
	return true
end

function modifier_broodmother_spin_web_effect_aura:IsAura()
    return true
end

function modifier_broodmother_spin_web_effect_aura:GetAuraDuration()
    return 0.5
end

function modifier_broodmother_spin_web_effect_aura:GetAuraRadius()
    return self.radius
end

function modifier_broodmother_spin_web_effect_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_broodmother_spin_web_effect_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_broodmother_spin_web_effect_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_broodmother_spin_web_effect_aura:GetModifierAura()
    return "modifier_broodmother_spin_web_effect"
end

function modifier_broodmother_spin_web_effect_aura:IsAuraActiveOnDeath()
    return false
end

function modifier_broodmother_spin_web_effect_aura:IsHidden()
    return true
end

function modifier_broodmother_spin_web_effect_aura:CheckState()
    return {[MODIFIER_STATE_NO_HEALTH_BAR] = true,
            [MODIFIER_STATE_NO_TEAM_SELECT] = true,
            [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
            [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
            [MODIFIER_STATE_ROOTED] = true,
            [MODIFIER_STATE_INVULNERABLE] = true,
        }
end

modifier_broodmother_spin_web_effect = class({})
LinkLuaModifier("modifier_broodmother_spin_web_effect", "heroes/hero_broodmother/broodmother_spin_web", LUA_MODIFIER_MOTION_NONE)
function modifier_broodmother_spin_web_effect:IsHidden() return false end
function modifier_broodmother_spin_web_effect:IsDebuff() return false end

function modifier_broodmother_spin_web_effect:OnCreated()
	if self:GetParent():IsSameTeam( self:GetCaster() ) then
		self.health_regen = self:GetSpecialValueFor("health_regen")
		self.bonus_movespeed = self:GetSpecialValueFor("bonus_movespeed")
	else
		self.bonus_movespeed = 0
		self.scepter_movement_loss = self:GetSpecialValueFor("scepter_movement_loss")
		self.scepter_dps = self:GetSpecialValueFor("scepter_dps")
		self.scepter_ms_threshold = self:GetSpecialValueFor("scepter_ms_threshold")
		self.scepter_debuff_duration = self:GetSpecialValueFor("scepter_debuff_duration")
		
		self:StartIntervalThink(1)
	end
end

function modifier_broodmother_spin_web_effect:OnIntervalThink()
	local triggered
	if not self:GetParent():HasModifier("modifier_broodmother_spin_web_effect_root") then
		self.bonus_movespeed = math.max( self.bonus_movespeed + self.scepter_movement_loss, self.scepter_ms_threshold )
		if self.bonus_movespeed <= self.scepter_ms_threshold then
			self.bonus_movespeed = 0
			triggered = true
		end
	end
	if IsServer() then
		if triggered then
			self:GetParent():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_broodmother_spin_web_effect_root", {duration = self.scepter_debuff_duration, source = self:GetParent():entindex()} )
		end
		self:GetAbility():DealDamage( self:GetCaster(), self:GetParent(), self.scepter_dps, {damage_type = DAMAGE_TYPE_MAGICAL} )
	end
end

function modifier_broodmother_spin_web_effect:DeclareFunctions()
    return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
			MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS }
end

function modifier_broodmother_spin_web_effect:GetModifierMoveSpeedBonus_Percentage()
    return self.bonus_movespeed
end

function modifier_broodmother_spin_web_effect:GetModifierHealthRegenPercentage()
    return self.health_regen
end

function modifier_broodmother_spin_web_effect:GetActivityTranslationModifiers()
    return "web"
end

function modifier_broodmother_spin_web_effect:CheckState()
    if self:GetParent():IsSameTeam( self:GetCaster() ) then return {[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true } end
end

modifier_broodmother_spin_web_effect_root = class({})
LinkLuaModifier("modifier_broodmother_spin_web_effect_root", "heroes/hero_broodmother/broodmother_spin_web", LUA_MODIFIER_MOTION_NONE)

function modifier_broodmother_spin_web_effect_root:OnCreated(kv)
	if IsServer() then
		local bola = self:GetCaster():FindAbilityByName("broodmother_silken_bola")
		bola:FireTrackingProjectile("particles/units/heroes/hero_broodmother/broodmother_silken_bola_projectile.vpcf", self:GetParent(), bola:GetSpecialValueFor("projectile_speed"), {source = EntIndexToHScript(kv.source)})
	end
end

function modifier_broodmother_spin_web_effect_root:CheckState()
	return {[MODIFIER_STATE_ROOTED] = true,
			[MODIFIER_STATE_DISARMED] = true,}
end

function modifier_broodmother_spin_web_effect_root:GetEffectName()
	return "particles/units/heroes/hero_broodmother/broodmother_silken_bola_root.vpcf"
end