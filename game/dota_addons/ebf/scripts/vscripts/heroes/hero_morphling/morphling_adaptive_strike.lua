morphling_adaptive_strike_agi = class({})


function morphling_adaptive_strike_agi:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	local speed = self:GetSpecialValueFor("projectile_speed")

	EmitSoundOn("Hero_Morphling.AdaptiveStrikeAgi.Cast", caster)
	
	local shared_cooldown = self:GetSpecialValueFor("shared_cooldown")
	if shared_cooldown > 0 then
		local strStrike = caster:FindAbilityByName("morphling_adaptive_strike_str")
		if strStrike and strStrike:IsTrained() and strStrike:GetCooldownTimeRemaining() < shared_cooldown then
			strStrike:SetCooldown( shared_cooldown )
		end
	end
	if not target:TriggerSpellAbsorb( self ) then
		self:FireTrackingProjectile("particles/units/heroes/hero_morphling/morphling_adaptive_strike_agi_proj.vpcf", target, speed )
	end
	local bonusTargets = self:GetSpecialValueFor("bonus_targets")
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self:GetTrueCastRange() ) ) do
		if enemy ~= target then
			if bonusTargets <= 0 then
				break
			end
			bonusTargets = bonusTargets - 1
			self:FireTrackingProjectile("particles/units/heroes/hero_morphling/morphling_adaptive_strike_agi_proj.vpcf", enemy, speed )
		end
	end
end

function morphling_adaptive_strike_agi:OnProjectileHit( target, position )
	if IsEntitySafe( target ) then
		local caster = self:GetCaster()
		
		if target:TriggerSpellAbsorb( self ) then return end
		local agiPercentage = caster:GetBaseAgility() / ( caster:GetBaseAgility() + caster:GetBaseStrength() )
		local maxPercentage = self:GetSpecialValueFor("max_threshold") / 100
		local damageMin = self:GetSpecialValueFor("damage_min_mult") / 100
		local damageMax = self:GetSpecialValueFor("damage_max_mult") / 100
		local damageSlider = damageMax - damageMin
		
		local damageMult = damageMin + math.min( damageSlider, damageSlider * (agiPercentage / maxPercentage) )
		local damage = self:GetSpecialValueFor("damage_base") * damageMult
		self:DealDamage( caster, target, damage )
		
		EmitSoundOn("Hero_Morphling.AdaptiveStrikeAgi.Target", caster)
		ParticleManager:FireParticle( "particles/units/heroes/hero_morphling/morphling_adaptive_strike.vpcf", PATTACH_POINT_FOLLOW, target, {[1] = target:GetAbsOrigin()} )
	end
end

morphling_adaptive_strike_str = class({})

function morphling_adaptive_strike_str:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	local speed = self:GetSpecialValueFor("projectile_speed")

	EmitSoundOn("Hero_Morphling.AdaptiveStrikeStr.Cast", caster)
	
	local shared_cooldown = self:GetSpecialValueFor("shared_cooldown")
	if shared_cooldown > 0 then
		local agiStrike = caster:FindAbilityByName("morphling_adaptive_strike_agi")
		if agiStrike and agiStrike:IsTrained() and agiStrike:GetCooldownTimeRemaining() < shared_cooldown then
			agiStrike:SetCooldown( shared_cooldown )
		end
	end
	if not target:TriggerSpellAbsorb( self ) then
		self:FireTrackingProjectile("particles/units/heroes/hero_morphling/morphling_adaptive_strike_str_proj.vpcf", target, speed )
	end
	local bonusTargets = self:GetSpecialValueFor("bonus_targets")
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self:GetTrueCastRange() ) ) do
		if enemy ~= target then
			if bonusTargets <= 0 then
				break
			end
			bonusTargets = bonusTargets - 1
			self:FireTrackingProjectile("particles/units/heroes/hero_morphling/morphling_adaptive_strike_str_proj.vpcf", enemy, speed )
		end
	end
end

function morphling_adaptive_strike_str:OnProjectileHit( target, position )
	if IsEntitySafe( target ) then
		local caster = self:GetCaster()
		if target:TriggerSpellAbsorb( self ) then return end
		local strPercentage = caster:GetBaseStrength() / ( caster:GetBaseAgility() + caster:GetBaseStrength() )
		local maxPercentage = self:GetSpecialValueFor("max_threshold") / 100
		local stunMin = self:GetSpecialValueFor("stun_min")
		local stunMax = self:GetSpecialValueFor("stun_max")
		local stunSlider = stunMax - stunMin
		
		local stunDur = stunMin + math.min( stunSlider, stunSlider * (strPercentage / maxPercentage) )
		self:Stun(target, stunDur)
		
		if self:GetSpecialValueFor("slow") > 0 then
			local slowMin = self:GetSpecialValueFor("slow_min")
			local slowMax = self:GetSpecialValueFor("slow_max")
			local slowSlider = slowMax - slowMin
			local slowDur = slowMin + math.min( slowSlider, slowSlider * (strPercentage / maxPercentage) )
			target:AddNewModifier( caster, self, "modifier_morphling_adaptive_strike_str_slow", {duration = slowDur} )
		end
		
		EmitSoundOn("Hero_Morphling.AdaptiveStrikeStr.Target", caster)
		ParticleManager:FireParticle( "particles/units/heroes/hero_morphling/morphling_adaptive_str_impact.vpcf", PATTACH_POINT_FOLLOW, target )
	end
end

modifier_morphling_adaptive_strike_str_slow = class({})
LinkLuaModifier( "modifier_morphling_adaptive_strike_str_slow", "heroes/hero_morphling/morphling_adaptive_strike", LUA_MODIFIER_MOTION_NONE )

function modifier_morphling_adaptive_strike_str_slow:OnCreated()
	self:OnRefresh()
end

function modifier_morphling_adaptive_strike_str_slow:OnCreated()
	self.slow = self:GetSpecialValueFor("slow")
end

function modifier_morphling_adaptive_strike_str_slow:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_morphling_adaptive_strike_str_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self.slow
end

function modifier_morphling_adaptive_strike_str_slow:GetEffectName()
	return "particles/units/heroes/hero_slark/slark_fish_bait_slow.vpcf"
end
