mars_bulwark = class({})

function mars_bulwark:IsStealable()
	return false
end

function mars_bulwark:IsHiddenWhenStolen()
	return false
end

function mars_bulwark:OnToggle()
	local caster = self:GetCaster()
	if self:GetToggleState() then
		caster:AddNewModifier( caster, self, "modifier_mars_bulwark_toggle", {})
		caster:AddNewModifier( caster, self, "modifier_mars_bulwark_active", {})
	else
		caster:RemoveModifierByName("modifier_mars_bulwark_toggle") 
		caster:RemoveModifierByName("modifier_mars_bulwark_active") 
	end
end

function mars_bulwark:GetIntrinsicModifierName()
	return "modifier_mars_bulwark_passive"
end

modifier_mars_bulwark_toggle = class(toggleModifierBaseClass)
LinkLuaModifier( "modifier_mars_bulwark_toggle", "heroes/hero_mars/mars_bulwark.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_mars_bulwark_toggle:OnCreated()
	self.slow = self:GetSpecialValueFor("slow")
	self.threat = self:GetSpecialValueFor("threat_amp")
	self.projectile_chance = self:GetSpecialValueFor("projectile_redirect")
	self.soldier_offset = self:GetSpecialValueFor("soldier_offset")
	self.soldier_count = self:GetSpecialValueFor("soldier_count")
	self.scepter_bonus_damage = self:GetSpecialValueFor("scepter_bonus_damage")
	if IsServer() then
		self:StartIntervalThink( math.max( 0, self:GetCaster():GetSecondsPerAttack() - ( GameRules:GetGameTime() - ( self:GetAbility().lastTimeScepterAttacked or 0 ) ) ) )
	end
end

BASE_PLAYBACKRATE = 1/1.7

function modifier_mars_bulwark_toggle:OnIntervalThink()
	local caster = self:GetCaster()
	self:StartIntervalThink( caster:GetSecondsPerAttack() )
	if not caster:HasScepter() then return end
	
	self:GetAbility().lastTimeScepterAttacked = GameRules:GetGameTime()
	local soldiers = caster:FindFriendlyUnitsInRadius(caster:GetAbsOrigin(), self.soldier_offset * self.soldier_count / 2, {type = DOTA_UNIT_TARGET_ALL, flag = DOTA_UNIT_TARGET_FLAG_INVULNERABLE, order = FIND_CLOSEST})
	local unitsHit = {}
	for _, soldier in ipairs( soldiers ) do
		if soldier:GetUnitName() == "aghsfort_mars_bulwark_soldier" then
			local attackAnimationRate = BASE_PLAYBACKRATE * caster:GetAttackSpeed()
			soldier:StartGestureWithPlaybackRate( ACT_DOTA_ATTACK, attackAnimationRate )
			EmitSoundOn( "Hero_Mars.PreAttack", soldier )
			for _, enemy in ipairs( caster:FindEnemyUnitsInLine( soldier:GetAbsOrigin()+soldier:GetPaddedCollisionRadius(), soldier:GetAbsOrigin() + caster:GetForwardVector() * caster:GetAttackRange(), self.soldier_offset/2 ) )  do
				if not unitsHit[enemy] then
					unitsHit[enemy] = true
					Timers:CreateTimer( soldier:GetAttackAnimationPoint() / attackAnimationRate, function()
						caster:PerformGenericAttack( enemy, true )
					end)
				end
			end
    	end
	end
	-- caster
	local attackAnimationRate = BASE_PLAYBACKRATE * caster:GetAttackSpeed()
	caster:StartGestureWithFadeAndPlaybackRate( ACT_DOTA_ATTACK, caster:GetAttackSpeed()/2, caster:GetAttackSpeed()/2, caster:GetAttackSpeed() )
	for _, enemy in ipairs( caster:FindEnemyUnitsInLine( caster:GetAbsOrigin()+caster:GetPaddedCollisionRadius(), caster:GetAbsOrigin() + caster:GetForwardVector() * caster:GetAttackRange(), self.soldier_offset/2 ) )  do
		if not unitsHit[enemy] then
			unitsHit[enemy] = true
			Timers:CreateTimer( caster:GetAttackAnimationPoint() / attackAnimationRate, function()
				caster:PerformGenericAttack( enemy, true )
			end)
		end
	end
end

function modifier_mars_bulwark_toggle:CheckState()
	return {[MODIFIER_STATE_DISARMED] = true}
end

function modifier_mars_bulwark_toggle:DeclareFunctions()
	return {MODIFIER_PROPERTY_DISABLE_TURNING,
			MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
			MODIFIER_PROPERTY_IGNORE_CAST_ANGLE,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE 
			}
end

function modifier_mars_bulwark_toggle:GetModifierDisableTurning()
	return 1
end

function modifier_mars_bulwark_toggle:GetModifierPreAttack_BonusDamage()
	if self:GetCaster():HasScepter() then
		return self.scepter_bonus_damage
	end
end

function modifier_mars_bulwark_toggle:GetModifierIgnoreCastAngle()
	return 1
end

function modifier_mars_bulwark_toggle:GetActivityTranslationModifiers()
	return "bulwark"
end

function modifier_mars_bulwark_toggle:GetModifierMoveSpeedBonus_Percentage()
	return -self.slow
end

function modifier_mars_bulwark_toggle:GetTrackingProjectileRedirectChance( event )
	return self.projectile_chance
end

modifier_mars_bulwark_passive = class({})
LinkLuaModifier( "modifier_mars_bulwark_passive", "heroes/hero_mars/mars_bulwark.lua" ,LUA_MODIFIER_MOTION_NONE )
function modifier_mars_bulwark_passive:OnCreated()
	if IsServer() then
		self.physical_damage_reduction = self:GetSpecialValueFor("physical_damage_reduction")
		self.forward_angle = self:GetSpecialValueFor("forward_angle")
		self.physical_damage_reduction_side = self:GetSpecialValueFor("physical_damage_reduction_side")
		self.side_angle = self:GetSpecialValueFor("side_angle")
		self.rebuke = self:GetCaster():FindAbilityByName("mars_gods_rebuke")
	end
end

function modifier_mars_bulwark_passive:IsPurgable()
	return false
end

function modifier_mars_bulwark_passive:IsPurgeException()
	return false
end

function modifier_mars_bulwark_passive:IsDebuff()
	return false
end

function modifier_mars_bulwark_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_PERCENTAGE}
end

BIG_BLOCK = 2
SMALL_BLOCK = 1

function modifier_mars_bulwark_passive:GetModifierIncomingPhysicalDamage_Percentage( params )
	local damageBlock
	local blocked
	if params.target:IsAtAngleWithEntity(params.attacker, self.forward_angle) then
		damageBlock = -self.physical_damage_reduction
		blocked = BIG_BLOCK
	elseif params.target:IsAtAngleWithEntity(params.attacker, self.side_angle) then
		damageBlock = -self.physical_damage_reduction_side
		blocked = SMALL_BLOCK
	end
	if blocked then
		if blocked == BIG_BLOCK and params.attacker:IsConsideredHero() then
			ParticleManager:FireParticle("particles/units/heroes/hero_mars/mars_shield_of_mars.vpcf", PATTACH_ABSORIGIN_FOLLOW, params.target, {[0] = "attach_hitloc"})
			EmitSoundOn("Hero_Mars.Shield.Block", params.target)
			
			if self.rebuke and self.rebuke:IsTrained() then
				if self:GetCaster():HasModifier("modifier_mars_bulwark_toggle") and RollPercentage( self:GetSpecialValueFor("rebuke_chance") ) then
					self.rebuke:Rebuke( self:GetCaster(), params.attacker:GetAbsOrigin() )
				end
			end
		else
			ParticleManager:FireParticle("particles/units/heroes/hero_mars/mars_shield_of_mars_small.vpcf", PATTACH_ABSORIGIN_FOLLOW, params.target, {[0] = "attach_hitloc"})
			EmitSoundOn("Hero_Mars.Shield.BlockSmall", params.target)
		end
		params.target:StartGesture( ACT_DOTA_OVERRIDE_ABILITY_2 )
	end
	return damageBlock
end

function modifier_mars_bulwark_passive:IsHidden()
	return true
end