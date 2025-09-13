chaos_knight_chaos_strike = class({})

function chaos_knight_chaos_strike:GetIntrinsicModifierName()
    return "modifier_chaos_knight_chaos_strike_passive"
end

function chaos_knight_chaos_strike:Precache(context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_chaos_knight.vsndevts", context)
    PrecacheResource("particle", "particles/units/heroes/hero_chaos_knight/chaos_knight_crit.vpcf", context)
end

modifier_chaos_knight_chaos_strike_passive = class({})
LinkLuaModifier("modifier_chaos_knight_chaos_strike_passive", "heroes/hero_chaos_knight/chaos_knight_chaos_strike.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_chaos_knight_chaos_strike_passive:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
end

function modifier_chaos_knight_chaos_strike_passive:IsHidden()
    return true
end

function modifier_chaos_knight_chaos_strike_passive:OnCreated()
    self:OnRefresh()
end

function modifier_chaos_knight_chaos_strike_passive:OnRefresh()
    self.crit_min = self:GetSpecialValueFor("critical_min")
    self.crit_max = self:GetSpecialValueFor("critical_max")
    self.lifesteal = self:GetSpecialValueFor("lifesteal")

    self.accumulated_crit_chance = self:GetSpecialValueFor("accumulated_crit_chance") or 0
    self.crit_chance_increment = self:GetSpecialValueFor("crit_chance_increment")

    self.break_chance = self:GetSpecialValueFor("break_chance")
    self.break_duration = self:GetSpecialValueFor("break_duration")

    self.bolt_on_attack = self:GetSpecialValueFor("bolt_on_attack")
    self.bolt = self:GetCaster():FindAbilityByName("chaos_knight_chaos_bolt")
    self.bolt_chance = self:GetSpecialValueFor("illu_bolt_chance")
end

function modifier_chaos_knight_chaos_strike_passive:GetModifierPreAttack_CriticalStrike(params)
    self.crit_chance = self:GetSpecialValueFor("crit_chance")
    if self:GetSpecialValueFor("true_crit_damage") == 1 then
        self.crit_damage = self.crit_max
    else
        self.crit_damage = math.random(self.crit_min, self.crit_max)
    end

    if self.crit_chance_increment >= 0 then
        self.crit_chance = self.crit_chance + self.accumulated_crit_chance
    end

    local roll = RollPseudoRandomPercentage(self.crit_chance, DOTA_PSEUDO_RANDOM_CUSTOM_GAME_1, params.attacker)
    if roll then
        self.record = params.record
        self.accumulated_crit_chance = 0
        return self.crit_damage
    else
        self.acumulated_crit_chance = self.accumulated_crit_chance + self.crit_chance_increment
    end
end

function modifier_chaos_knight_chaos_strike_passive:GetModifierAccumulatedCritChance_Percentage(params)
    return self.accumulated_crit_chance
end

function modifier_chaos_knight_chaos_strike_passive:OnTakeDamage( params )
    if IsServer() then
		-- filter to see if it crits or not
		local pass = false
		if self.record and params.record == self.record then
			pass = true
			self.record = nil
		end

        if pass then
            local ehp_mult = self:GetParent().EHP_MULT or 1
	        local lifesteal = params.damage * self.lifesteal / 100 * math.max(1, ehp_mult)
            if lifesteal > 0 then
                local hpGain = math.floor(lifesteal)
                local preHp = params.attacker:GetHealth()

                params.attacker:HealWithParams(hpGain, self:GetAbility(), false, true, self, true)
                local postHp = params.attacker:GetHealth()

                local actualHpGain = postHp - preHp
                if actualHpGain > 0 then
                    ParticleManager:FireParticle( "particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_POINT_FOLLOW, params.attacker )
                    ParticleManager:CreateParticle("particles/units/heroes/hero_chaos_knight/chaos_knight_crit.vpcf", PATTACH_CUSTOMORIGIN, self:GetParent())
                end
            end
            EmitSoundOn("Hero_ChaosKnight.ChaosStrike", self:GetParent())
        end
    end
end

function modifier_chaos_knight_chaos_strike_passive:OnAttackLanded( params )
    if IsServer() then
        if params.attacker == self:GetParent() and params.record == self.record and not params.attacker:IsIllusion() then
            local roll1 = RollPseudoRandomPercentage(self.break_chance, DOTA_PSEUDO_RANDOM_CUSTOM_GAME_1, params.attacker)
            if roll1 then
                params.target:AddNewModifier(params.attacker, self:GetAbility(), "modifier_break", {duration = self.break_duration})
            end
            if self.bolt_on_attack > 0 then
                local roll2 = RollPercentage(self.bolt_chance)
                if roll2 and self.bolt:IsTrained() then
                    self.bolt:ThrowBolt(params.target, params.attacker)
                end
            end
        end
    end
end