bounty_hunter_wind_walk = class({})

function bounty_hunter_wind_walk:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget() or caster
	local fadeTime = self:GetSpecialValueFor("fade_time")
	
	EmitSoundOn("Hero_BountyHunter.WindWalk", target)

	ParticleManager:FireParticle("particles/units/heroes/hero_bounty_hunter/bounty_hunter_windwalk.vpcf", PATTACH_POINT, target, {})
	
	local duration = self:GetSpecialValueFor("duration")
	local refreshCDs = self:GetSpecialValueFor("refresh_cds") == 1
	local guaranteedHeadhunter = self:GetSpecialValueFor("guaranteed_headhunter")
	local shurikenTossAOE = self:GetSpecialValueFor("shuriken_toss_aoe")
	if refreshCDs then
		caster:RefreshAllCooldowns( true, {"bounty_hunter_wind_walk", "bounty_hunter_wind_walk_ally"} )
	end
	if guaranteedHeadhunter then
		caster:AddNewModifier(caster, self, "modifier_bounty_hunter_wind_walk_headhunter", {Duration = duration})
	end
	if shurikenTossAOE > 0 then
		local shurikenToss = caster:FindAbilityByName("bounty_hunter_shuriken_toss")
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), shurikenTossAOE ) ) do
			shurikenToss:TossShuriken(enemy, target)
		end
	end
	
	Timers:CreateTimer(fadeTime, function()
		target:AddNewModifier(caster, self, "modifier_bounty_hunter_wind_walk_effect", {Duration = duration})
	end)
	
end

bounty_hunter_wind_walk_ally = class(bounty_hunter_wind_walk)

modifier_bounty_hunter_wind_walk_headhunter = class({})
LinkLuaModifier( "modifier_bounty_hunter_wind_walk_headhunter", "heroes/hero_bounty_hunter/bounty_hunter_wind_walk.lua" ,LUA_MODIFIER_MOTION_NONE )

modifier_bounty_hunter_wind_walk_specialist = class({})
LinkLuaModifier( "modifier_bounty_hunter_wind_walk_specialist", "heroes/hero_bounty_hunter/bounty_hunter_wind_walk.lua" ,LUA_MODIFIER_MOTION_NONE )
 
function modifier_bounty_hunter_wind_walk_specialist:OnCreated()
	self:OnRefresh()
end

function modifier_bounty_hunter_wind_walk_specialist:OnRefresh(table)
    self.armor_loss = -self:GetSpecialValueFor("armor_loss")
end


function modifier_bounty_hunter_wind_walk_specialist:DeclareFunctions()
    return {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS}
end

function modifier_bounty_hunter_wind_walk_specialist:GetModifierPhysicalArmorBonus()
    return self.armor_loss
end

modifier_bounty_hunter_wind_walk_effect = class({})
LinkLuaModifier( "modifier_bounty_hunter_wind_walk_effect", "heroes/hero_bounty_hunter/bounty_hunter_wind_walk.lua" ,LUA_MODIFIER_MOTION_NONE )
function modifier_bounty_hunter_wind_walk_effect:OnCreated()
	self:OnRefresh()
end

function modifier_bounty_hunter_wind_walk_effect:OnRefresh(table)
    self.stun_duration = self:GetSpecialValueFor("stun_duration")
	
    self.armor_loss = self:GetSpecialValueFor("armor_loss")
    self.armor_loss_linger = self:GetSpecialValueFor("armor_loss_linger")
    self.damage_reduction_pct = self:GetSpecialValueFor("damage_reduction_pct")
    self.shuriken_toss_aoe = self:GetSpecialValueFor("shuriken_toss_aoe")
end

function modifier_bounty_hunter_wind_walk_effect:OnDestroy()
	if IsClient() then return end
	self:GetCaster():RemoveModifierByName("modifier_bounty_hunter_wind_walk_headhunter")
end

function modifier_bounty_hunter_wind_walk_effect:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_EVENT_ON_ABILITY_EXECUTED,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    }
    return funcs
end

function modifier_bounty_hunter_wind_walk_effect:CheckState()
	local state = { [MODIFIER_STATE_INVISIBLE] = true,
					[MODIFIER_STATE_NO_UNIT_COLLISION] = true}
	return state
end

function modifier_bounty_hunter_wind_walk_effect:GetModifierIncomingDamage_Percentage()
    return -self.damage_reduction_pct
end

function modifier_bounty_hunter_wind_walk_effect:OnAbilityExecuted(params)
	if IsServer() then
		local parent = self:GetParent()
		local unit = params.unit
		local ability = params.ability
		
		if not params.ability then return end

		local exceptions = {["bounty_hunter_track"] = true, ["bounty_hunter_wind_walk_ally"] = true, }
		if unit == parent and not exceptions[params.ability:GetAbilityName()] then
			self:Destroy()
		end
	end
end

function modifier_bounty_hunter_wind_walk_effect:OnAttack(params)
	if IsServer() then
		if params.attacker == self:GetParent() then
			local ability = self:GetAbility()
			local stunDuration = self.stun_duration
			local track = params.target:FindModifierByName("modifier_bounty_hunter_track_debuff_mark")
			if track then
				stunDuration = stunDuration + (track.invis_bonus_duration or 0)
			end
			ability:Stun( params.target, stunDuration )
			if self.armor_loss > 0 then
				params.target:AddNewModifier( params.attacker, ability, "modifier_bounty_hunter_wind_walk_specialist", {self.stun_duration + self.armor_loss_linger} )
			end
			Timers:CreateTimer(function() self:Destroy() end)
		end
	end
end

function modifier_bounty_hunter_wind_walk_effect:GetModifierInvisibilityLevel()
    return 1
end

function modifier_bounty_hunter_wind_walk_effect:GetEffectName()
    return "particles/generic_hero_status/status_invisibility_start.vpcf"
end