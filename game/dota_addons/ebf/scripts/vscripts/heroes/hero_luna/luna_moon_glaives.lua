luna_moon_glaives = class({})

function luna_moon_glaives:GetIntrinsicModifierName()
	return "modifier_luna_moon_glaives_passive"
end

modifier_luna_moon_glaives_passive = class({})
LinkLuaModifier( "modifier_luna_moon_glaives_passive", "heroes/hero_luna/luna_moon_glaives.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_luna_moon_glaives_passive:IsHidden()
	return true
end
function modifier_luna_moon_glaives_passive:IsPurgable()
	return false
end
function modifier_luna_moon_glaives_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK
	}
end
function modifier_luna_moon_glaives_passive:GetModifierProcAttack_Feedback(params)
	if not IsServer() then return end
	if self:GetParent():PassivesDisabled() then return end

	CreateModifierThinker(
		self:GetParent(),
		self:GetAbility(),
		"modifier_luna_moon_glaives_thinker",
		{ target=params.target },
		params.target:GetOrigin(),
		self:GetParent():GetTeamNumber(),
		false
	)
end

modifier_luna_moon_glaives_thinker = class({})
LinkLuaModifier( "modifier_luna_moon_glaives_thinker", "heroes/hero_luna/luna_moon_glaives.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_luna_moon_glaives_thinker:IsHidden()
	return true
end
function modifier_luna_moon_glaives_thinker:IsPurgable()
	return false
end
function modifier_luna_moon_glaives_thinker:OnCreated(params)
	self:OnRefresh(params)
end
function modifier_luna_moon_glaives_thinker:OnRefresh(params)
	self.range = self:GetSpecialValueFor("range")
	self.bounces = self:GetSpecialValueFor("bounces")
	self.damage_reduction_percent = self:GetSpecialValueFor("damage_reduction_percent")
	self.damage_reduction_percent = (100 - self.damage_reduction_percent) / 100
	self.do_lucent_beam_on_last = self:GetSpecialValueFor("do_lucent_beam_on_last")
	self.damage_taken_increase_percent = self:GetSpecialValueFor("damage_taken_increase_percent")
	self.damage_taken_increase_duration = self:GetSpecialValueFor("damage_taken_increase_duration")
	self.damage_taken_increase_max_stacks = self:GetSpecialValueFor("damage_taken_increase_max_stacks")

	if not IsServer() then return end

	self.parent = self:GetParent()
	self.caster = self:GetCaster()
	self.bounce = 0
	self.targets = {}

	self.parent:SetOrigin(self.parent:GetOrigin() + Vector(0, 0, 100))
	self.parent:SetAttackCapability(self.caster:GetAttackCapability())
	self.parent:SetRangedProjectileName(self.caster:GetRangedProjectileName())
	self.projectile_speed = self.caster:GetProjectileSpeed()

	if params.target:IsAlive() then
		self.targets[params.target] = true
	end

	self:DoGlaive()
end
function modifier_luna_moon_glaives_thinker:OnDestroy()
	if not IsServer() then return end
	UTIL_Remove(self.parent)
end
function modifier_luna_moon_glaives_thinker:DoGlaive()
	self.bounce = self.bounce + 1

	local units = FindUnitsInRadius(
		self.caster:GetTeamNumber(),
		self.parent:GetOrigin(),
		nil,
		self.range,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)
	if #units < 2 then
		if self.bounce > 1 and self.do_lucent_beam_on_last then
			-- do beam
		end
		self:Destroy()
		return
	end

	-- we want to bounce to every available target in range before repeating
	local unit = nil
	for i = 2, #units do
		unit = units[i]
		if not self.targets[unit] then
			self.targets[unit] = true
			break
		end
		unit = nil
	end
	if unit == nil then
		-- we've hit all targets, clear the list
		self.targets = {}
		self.targets[units[1]] = true
		unit = units[2]
	end

	-- since modifiers can't do projectiles, we have to do some weird attack shit
	self.parent:PerformAttack(
		unit,	-- target
		false,	-- orbs
		true,	-- procs
		true,	-- skip cooldown
		true,	-- ignore invis
		true,	-- use projectile
		true,	-- fake
		true 	-- never miss
	)
end
function modifier_luna_moon_glaives_thinker:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
		MODIFIER_EVENT_ON_ATTACK_FAIL,
		MODIFIER_PROPERTY_PROJECTILE_SPEED,
	}
end
function modifier_luna_moon_glaives_thinker:OnAttackFail(params)
	if not IsServer() then return end

	if params.attacker == self.parent then
		self:Destroy()
	end
end
function modifier_luna_moon_glaives_thinker:GetModifierProjectileSpeed()
	if not IsServer() then return end

	return self.projectile_speed
end
function modifier_luna_moon_glaives_thinker:GetModifierProcAttack_Feedback(params)
	if not IsServer() then return end

	local outgoing = math.pow(self.damage_reduction_percent, self.bounce) * 100 - 100
	self.caster:PerformGenericAttack(params.target, true, 
	{ 
		neverMiss = true, 
		suppressCleave = true, 
		bonusDamagePct = outgoing, 
		procAttackEffects = false, 
		ability = self:GetAbility() 
	})

	self.parent:SetOrigin(params.target:GetOrigin() + Vector(0, 0, 100))

	if self.damage_taken_increase_percent ~= 0 then
		local debuff = params.target:FindModifierByName("modifier_luna_moon_glaives_spiteshield")
		if debuff and debuff:GetStackCount() < self.damage_taken_increase_max_stacks then
			debuff:AddIndependentStack({ duration = self.stacking_damage_duration })
		else
			debuff = params.target:AddNewModifier(self.caster, self:GetAbility(), "modifier_luna_moon_glaives_spiteshield")
			debuff:AddIndependentStack({ duration = self.stacking_damage_duration })
	end

	if self.bounce >= self.bounces then
		if self.do_lucent_beam_on_last then
			local lucent_beam = self.caster:FindAbilityByName("luna_lucent_beam")
			if lucent_beam ~= nil then
				lucent_beam:CastOn(params.target, 1.0)
			end
		end
		self:Destroy()
	else
		self:StartIntervalThink(0.05)
	end

	-- sounds
	local sound = "Hero_Luna.MoonGlaive.Impact"
	EmitSoundOn(sound, params.target)
end
function modifier_luna_moon_glaives_thinker:OnIntervalThink()
	self:StartIntervalThink(-1)
	self:DoGlaive()
end

modifier_luna_moon_glaives_spiteshield = class({})
LinkLuaModifier( "modifier_luna_moon_glaives_spiteshield", "heroes/hero_luna/luna_moon_glaives.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_luna_moon_glaives_spiteshield:IsPurgable()
	return true
end
function modifier_luna_moon_glaives_spiteshield:IsDebuff()
	return true
end
function modifier_luna_moon_glaives_spiteshield:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
	}
end
function modifier_luna_moon_glaives_spiteshield:GetModifierIncomingDamage_Percentage()
	return self.damage_taken_increase_percent * self:GetStackCount()
end