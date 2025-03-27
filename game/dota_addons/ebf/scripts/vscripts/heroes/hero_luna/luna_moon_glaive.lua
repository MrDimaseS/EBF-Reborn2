luna_moon_glaive = class({})

function luna_moon_glaive:GetIntrinsicModifierName()
	return "modifier_luna_moon_glaive_passive"
end

function luna_moon_glaive:LaunchMoonGlaive(target, damage, bounces, source)
	local caster = self:GetCaster()
	local hSource = source or caster
	
	local extraData = {damage = damage or 0, bounces = bounces or self:GetSpecialValueFor("bounces"), hitUnits = {}}
	local projID = self:FireTrackingProjectile( caster:GetRangedProjectileName(), target, caster:GetProjectileSpeed(), {extraData = extraData, source = hSource, origin = hSource:GetAbsOrigin() })
	
	self.glaives = self.glaives or {}
	self.glaives[projID] = extraData
	return projID
end

function luna_moon_glaive:OnProjectileHitHandle( target, position, projectileID )
	if target then
		local caster = self:GetCaster()
		local projectileData = self.glaives[projectileID]
		
		if not projectileData then return end
		
		local damage = tonumber(projectileData.damage)
		local bounces = tonumber(projectileData.bounces) or 0
		local hitUnits = projectileData.hitUnits
		
		hitUnits[target] = true
		self:DealDamage( caster, target, damage, {damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_SECONDARY_PROJECTILE_ATTACK } )
		
		local spiteShieldDuration = self:GetSpecialValueFor("damage_taken_increase_duration")
		local wrathLunarCooldown = self:GetSpecialValueFor("do_lucent_beam_on_last")
		if spiteShieldDuration > 0 then
			target:AddNewModifier(caster, self, "modifier_luna_moon_glaive_spiteshield", { duration = spiteShieldDuration })
		end
		if bounces > 1 then
			local radius = self:GetSpecialValueFor("range")
			local reduction = 1-self:GetSpecialValueFor("damage_reduction_percent") / 100
			local enemies = caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), radius, {flag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES} )
			::tryAgain::
			for _, enemy in ipairs( enemies ) do
				if not hitUnits[enemy] and enemy ~= target then
					local newID = self:LaunchMoonGlaive(enemy, damage * reduction, bounces - 1, target)
					self.glaives[newID].hitUnits = hitUnits
					self.glaives[projectileID] = nil
					return
				end
			end
			-- didn't find anything, reset table
			hitUnits = {}
			if #enemies > 1 then -- only try again if valid target
				goto tryAgain
			end
		elseif wrathLunarCooldown > 0 and not target:HasModifier("modifier_luna_moon_glaive_wrathbearer") then
			target:AddNewModifier( caster, self, "modifier_luna_moon_glaive_wrathbearer", { duration = wrathLunarCooldown })
			local lucent_beam = caster:FindAbilityByName("luna_lucent_beam")
			if lucent_beam ~= nil and lucent_beam:GetLevel() ~= 0 then
				lucent_beam:CastOn(target, 1.0)	
			end
		end
	end
end

modifier_luna_moon_glaive_passive = class({})
LinkLuaModifier( "modifier_luna_moon_glaive_passive", "heroes/hero_luna/luna_moon_glaive.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_luna_moon_glaive_passive:OnCreated()
	self:OnRefresh()
end

function modifier_luna_moon_glaive_passive:OnRefresh()
	self.bounces = self:GetSpecialValueFor("bounces")
	self.radius = self:GetSpecialValueFor("range")
	self.reduction = 1-self:GetSpecialValueFor("damage_reduction_percent") / 100
end

function modifier_luna_moon_glaive_passive:IsHidden()
	return true
end
function modifier_luna_moon_glaive_passive:IsPurgable()
	return false
end
function modifier_luna_moon_glaive_passive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end
function modifier_luna_moon_glaive_passive:OnAttackLanded(params)
	
	if not IsServer() then return end
	if params.attacker ~= self:GetParent() then return end
	if params.no_attack_cooldown then return end
	if self:GetParent():PassivesDisabled() then return end
	
	for _, enemy in ipairs( params.attacker:FindEnemyUnitsInRadius( params.target:GetAbsOrigin(), self.radius, {flag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES} ) ) do
		if enemy ~= params.target then
			self:GetAbility():LaunchMoonGlaive(enemy, params.original_damage * self.reduction, self.bounces, params.target)
			break
		end
	end
end

modifier_luna_moon_glaive_wrathbearer = class({})
LinkLuaModifier( "modifier_luna_moon_glaive_wrathbearer", "heroes/hero_luna/luna_moon_glaive.lua", LUA_MODIFIER_MOTION_NONE )

modifier_luna_moon_glaive_spiteshield = class({})
LinkLuaModifier( "modifier_luna_moon_glaive_spiteshield", "heroes/hero_luna/luna_moon_glaive.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_luna_moon_glaive_spiteshield:IsPurgable()
	return true
end
function modifier_luna_moon_glaive_spiteshield:IsDebuff()
	return true
end
function modifier_luna_moon_glaive_spiteshield:OnCreated()
	self:OnRefresh()
end
function modifier_luna_moon_glaive_spiteshield:OnRefresh()
	self.damage_taken_increase_percent = self:GetSpecialValueFor("damage_taken_increase_percent")
	self.damage_taken_increase_duration = self:GetSpecialValueFor("damage_taken_increase_duration")
	self.damage_taken_increase_max_stacks = self:GetSpecialValueFor("damage_taken_increase_max_stacks")
	
	if IsServer() then
		self:AddIndependentStack({ duration = self.damage_taken_increase_duration, limit = self.damage_taken_increase_max_stacks })
	end
end
function modifier_luna_moon_glaive_spiteshield:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
	}
end
function modifier_luna_moon_glaive_spiteshield:GetModifierIncomingDamage_Percentage()
	return self.damage_taken_increase_percent * self:GetStackCount()
end