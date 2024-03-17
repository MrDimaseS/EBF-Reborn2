phoenix_supernova = class({})

function phoenix_supernova:IsStealable()
    return true
end

function phoenix_supernova:IsHiddenWhenStolen()
    return false
end

function phoenix_supernova:GetBehavior()
	if self:GetCaster():HasScepter() then
		return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK + DOTA_ABILITY_BEHAVIOR_UNRESTRICTED
	else
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK + DOTA_ABILITY_BEHAVIOR_UNRESTRICTED
	end
end

function phoenix_supernova:OnSpellStart()
    local caster = self:GetCaster()
	
    EmitSoundOn("Hero_Phoenix.SuperNova.Cast", caster)

    local egg = caster:CreateSummon( "npc_dota_phoenix_sun", caster:GetAbsOrigin() )
	egg:SetCoreHealth( self:GetSpecialValueFor("max_hero_attacks") * self:GetSpecialValueFor("hero_damage") )
	
    egg:AddNewModifier(caster, self, "modifier_phoenix_supernova_form", {Duration = self:GetDuration()})
	egg.owners = {}
    EmitSoundOn("Hero_Phoenix.SuperNova.Begin", egg)

    caster:AddNewModifier(caster, self, "modifier_phoenix_supernova_caster", {})
	table.insert(egg.owners, caster)
	if self:GetCursorTarget() then
		local target = self:GetCursorTarget()
		target:AddNewModifier(caster, self, "modifier_phoenix_supernova_caster", {})
		table.insert(egg.owners, target)
		target:SetAbsOrigin(egg:GetAbsOrigin())
	end
end

modifier_phoenix_supernova_caster = class({})
LinkLuaModifier( "modifier_phoenix_supernova_caster", "heroes/hero_phoenix/phoenix_supernova.lua", LUA_MODIFIER_MOTION_NONE )
function modifier_phoenix_supernova_caster:OnCreated(table)
	self.shard_spell_amplification = self:GetSpecialValueFor("shard_spell_amplification")
    if IsServer() then
        self:GetParent():AddNoDraw()
    end
end

function modifier_phoenix_supernova_caster:OnRemoved()
    if IsServer() then
        self:GetParent():RemoveNoDraw()
        self:GetParent():StartGesture(ACT_DOTA_INTRO)
    end
end

function modifier_phoenix_supernova_caster:CheckState()
    local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    [MODIFIER_STATE_ROOTED] = true,
					[MODIFIER_STATE_INVULNERABLE] = true,
					[MODIFIER_STATE_PROVIDES_VISION] = true,
					[MODIFIER_STATE_NO_HEALTH_BAR] = true,
					[MODIFIER_STATE_UNTARGETABLE] = true,
                    [MODIFIER_STATE_OUT_OF_GAME] = true,
					[MODIFIER_STATE_DISARMED] = true,
                    [MODIFIER_STATE_SILENCED] = true,
                    [MODIFIER_STATE_MUTED] = true,
                }
	if self:GetParent() == self:GetCaster() and self:GetCaster():HasShard() then
		state[MODIFIER_STATE_SILENCED] = nil
	end
    return state
end

function modifier_phoenix_supernova_caster:DeclareFunctions()
	return {MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE}
end

function modifier_phoenix_supernova_caster:GetModifierSpellAmplify_Percentage()
	if self:GetCaster():HasShard() and self:GetCaster() == self:GetParent() then return self.shard_spell_amplification end
end

modifier_phoenix_supernova_form = class({})
LinkLuaModifier( "modifier_phoenix_supernova_form", "heroes/hero_phoenix/phoenix_supernova.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_phoenix_supernova_form:OnCreated(table)
	self.hero_damage = self:GetSpecialValueFor("hero_damage")
	self.max_hero_attacks = self:GetSpecialValueFor("max_hero_attacks")
	self.aura_radius = self:GetSpecialValueFor("aura_radius")
    if IsServer() then
        local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_egg.vpcf", PATTACH_POINT_FOLLOW, self:GetParent())
        ParticleManager:SetParticleControlEnt(nfx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), false)
        ParticleManager:SetParticleControlEnt(nfx, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), false)
		self:AddEffect( nfx )
    end
end

function modifier_phoenix_supernova_form:CheckState()
    local state = { [MODIFIER_STATE_ROOTED] = true,
                    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                }
    return state
end

function modifier_phoenix_supernova_form:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DISABLE_HEALING,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_PROPERTY_HEALTHBAR_PIPS 
    }
end

function modifier_phoenix_supernova_form:GetDisableHealing()
    return 1
end

function modifier_phoenix_supernova_form:GetModifierHealthBarPips()
    return self.max_hero_attacks
end

function modifier_phoenix_supernova_form:GetModifierIncomingDamage_Percentage(params)
	ParticleManager:FireParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_hit.vpcf", PATTACH_POINT, params.target, {})
	
	local egg = self:GetParent()
	local attacker = params.attacker
	local numAttacked = egg.supernova_numAttacked or 0
	local damage = TernaryOperator( self.hero_damage, attacker:IsConsideredHero(), 1 )
	if egg:GetHealth() <= damage then
		egg:RemoveModifierByName("modifier_phoenix_supernova_form")
		egg:ForceKill(true)
	else
		egg:SetHealth( egg:GetHealth() - damage )
	end
	return -999
end

function modifier_phoenix_supernova_form:OnRemoved()
    if IsServer() then
		local egg = self:GetParent()
        local caster = self:GetCaster()
        local ability = self:GetAbility()
		
		for _, hero in ipairs( egg.owners ) do
			local invuln = hero:FindModifierByName("modifier_phoenix_supernova_caster")
			if invuln then invuln:Destroy() end
		end
        if not egg:IsAlive() then
            for _, hero in ipairs( egg.owners ) do
				hero:ForceKill(true)
			end
        else
			for _, hero in ipairs( egg.owners ) do
				hero:SetHealth( hero:GetMaxHealth() )
				hero:SetMana( hero:GetMaxMana() )
				hero:Dispel(caster, true)

				for i=0,6 do
					local abil = hero:GetAbilityByIndex(i)
					if abil:GetAbilityType() ~= 1 then
						abil:EndCooldown()
					end
				end
			end
            

            local enemies = caster:FindEnemyUnitsInRadius(egg:GetAbsOrigin(), self:GetSpecialValueFor("radius"))
            for _,enemy in pairs(enemies) do
				ability:Stun(enemy, self:GetSpecialValueFor("stun_duration"), false)
            end
        end

        -- Play sound effect
        local soundName = "Hero_Phoenix.SuperNova." .. ( not egg:IsAlive() and "Death" or "Explode" )
        StartSoundEvent( soundName, caster )

        -- Create particle effect
        local pfxName = "particles/units/heroes/hero_phoenix/phoenix_supernova_" .. ( not egg:IsAlive() and "death" or "reborn" ) .. ".vpcf"
        local pfx = ParticleManager:CreateParticle( pfxName, PATTACH_ABSORIGIN, caster )
        ParticleManager:SetParticleControlEnt( pfx, 0, caster, PATTACH_POINT_FOLLOW, "follow_origin", caster:GetAbsOrigin(), true )
        ParticleManager:SetParticleControlEnt( pfx, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true )
		ResolveNPCPositions(egg:GetAbsOrigin(), 9000)
        -- Remove the egg
		UTIL_Remove( egg )
    end
end

function modifier_phoenix_supernova_form:IsAura()
    return true
end

function modifier_phoenix_supernova_form:GetAuraDuration()
    return 0.5
end

function modifier_phoenix_supernova_form:GetAuraRadius()
    return self.aura_radius
end

function modifier_phoenix_supernova_form:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_phoenix_supernova_form:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_phoenix_supernova_form:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_phoenix_supernova_form:GetModifierAura()
    return "modifier_phoenix_sun_debuff"
end

function modifier_phoenix_supernova_form:IsAuraActiveOnDeath()
    return false
end