mars_spear = class({})

function mars_spear:IsStealable()
	return true
end

function mars_spear:IsHiddenWhenStolen()
	return false
end

function mars_spear:GetCastRange( position, target )
	return self:GetSpecialValueFor("spear_range")
end

function mars_spear:GetIntrinsicModifierName()
	return "modifier_mars_spear_innate_handler"
end

function mars_spear:OnSpellStart()
	local caster = self:GetCaster()
	local direction = CalculateDirection( self:GetCursorPosition(), caster )
	self:LaunchSpear( )
end

function mars_spear:OnProjectileHitHandle( hTarget, vLocation, iProjectile )
	local caster = self:GetCaster()
	local projectileData = self._marsSpearProjectiles[iProjectile]
	if not hTarget then 
		-- handle spear ending
		local pinned = #projectileData.impaledUnits
		for _, target in ipairs( projectileData.impaledUnits ) do
			target:RemoveModifierByName("modifier_mars_spear_spear")
			if pinned > 1 then
				EmitSoundOn("Hero_Mars.Spear.Root", target)
				target:RemoveModifierByName("modifier_mars_spear_spear")
				target:AddNewModifier(caster, self, "modifier_mars_spear_stun", {Duration = self:GetSpecialValueFor("stun_duration")})
			end
		end
	else
		if not projectileData then return end
		if hTarget:TriggerSpellAbsorb(self) then return false end

		EmitSoundOn("Hero_Mars.Spear.Target", hTarget)

		self:DealDamage(caster, hTarget, projectileData.damage)
		if hTarget:IsConsideredHero() and projectileData.impale and #projectileData.impaledUnits < self:GetSpecialValueFor("units_hit") then
			table.insert( projectileData.impaledUnits, hTarget )
			hTarget:AddNewModifier(caster, self, "modifier_mars_spear_spear", {})
		else
			EmitSoundOn("Hero_Mars.Spear.Knockback", hTarget)
			hTarget:ApplyKnockBack(vLocation, projectileData.knockback_duration, projectileData.knockback_duration, projectileData.knockback_distance, 0, caster, self, false)
		end
	end
end

function mars_spear:OnProjectileThinkHandle(iProjectile)
	local caster = self:GetCaster()
	local position = ProjectileManager:GetLinearProjectileLocation( iProjectile )
	local velocity = ProjectileManager:GetLinearProjectileVelocity( iProjectile )
	local radius = ProjectileManager:GetLinearProjectileRadius( iProjectile )
	local projectileData = self._marsSpearProjectiles[iProjectile]
	if not projectileData then return end
	if velocity.z > 0 then velocity.z = 0 end
	local offset = 0
	for _, target in ipairs( projectileData.impaledUnits ) do
		if target:IsAlive() and target:HasModifier("modifier_mars_spear_spear") then
			local targetHeight = GetGroundHeight(target:GetAbsOrigin(), target)
			local expected_location = position + velocity * FrameTime()
			local expected_height = GetGroundHeight(expected_location, target)
			local heightDiff = targetHeight - expected_height
			local nearbyHero
			for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), target:GetPaddedCollisionRadius(), {flag = DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, order = FIND_CLOSEST} ) ) do
				if not enemy:HasModifier("modifier_mars_spear_spear") then
					nearbyHero = enemy
					break
				end
			end
			if GridNav:IsNearbyTree(expected_location, radius, false)
			or (GridNav:FindPathLength( position, expected_location ) == -1 and heightDiff < 0) 
			or nearbyHero then
				EmitSoundOn("Hero_Mars.Spear.Root", target)
				target:RemoveModifierByName("modifier_mars_spear_spear")
				target:AddNewModifier(caster, self, "modifier_mars_spear_stun", {Duration = self:GetSpecialValueFor("stun_duration")})
				if nearbyHero then
					EmitSoundOn("Hero_Mars.Spear.Root", nearbyHero)
					nearbyHero:RemoveModifierByName("modifier_mars_spear_spear")
					nearbyHero:AddNewModifier(caster, self, "modifier_mars_spear_stun", {Duration = self:GetSpecialValueFor("stun_duration")})
				end
			else
				target:SetForwardVector(-velocity)
				target:SetAbsOrigin(expected_location + offset)
				offset = offset + target:GetHullRadius()
			end
		end
	end
	if projectileData.shard then
		CreateModifierThinker(caster, self, "modifier_special_mars_spear_burning_trail_thinker", {duration = projectileData.trail_duration}, position, caster:GetTeamNumber(), false)
	end
end

function mars_spear:LaunchSpear( origin, direction, secondary, maxDistance )
	local caster = self:GetCaster()
	local source = origin or caster
	local startPos = source:GetAbsOrigin()

	local distance = maxDistance or self:GetTrueCastRange()
	local direction = direction or CalculateDirection(self:GetCursorPosition(), startPos)
	direction.z = 0

	local speed = self:GetSpecialValueFor("spear_speed")
	local velocity = direction * speed
	local startWidth = self:GetSpecialValueFor("spear_width")
	local spear_vision = self:GetSpecialValueFor("spear_vision")

	local damage = self:GetSpecialValueFor("damage")
	local knockback_duration = self:GetSpecialValueFor("knockback_duration")
	local knockback_distance = self:GetSpecialValueFor("knockback_distance")
	local shard_trail_duration = self:GetSpecialValueFor("shard_trail_duration")

	local impale = not self:GetAutoCastState()

	--Purely cosmetic only-------
	if not secondary then
		EmitSoundOn("Hero_Mars.Spear.Cast", caster)
		EmitSoundOn("Hero_Mars.Spear", caster)
	end
	local projectile = self:FireLinearProjectile("particles/units/heroes/hero_mars/mars_spear.vpcf", velocity, distance, startWidth, {source = source}, false, true, spear_vision)

	self._marsSpearProjectiles = self._marsSpearProjectiles or {}
	self._marsSpearProjectiles[projectile] = { secondary = secondary,
											   damage = damage,
											   knockback_duration = knockback_duration,
											   knockback_distance = knockback_distance,
											   damage = damage,
											   impale = impale,
											   impaledUnits = {},
											   shard = caster:HasShard(),
											   trail_duration = shard_trail_duration}
end

modifier_mars_spear_spear = class({})
LinkLuaModifier( "modifier_mars_spear_spear", "heroes/hero_mars/mars_spear.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_mars_spear_spear:OnRemoved()
	if IsServer() then
		FindClearSpaceForUnit(self:GetParent(), self:GetParent():GetAbsOrigin(), true)
	end
end

function modifier_mars_spear_spear:CheckState()
	return { [MODIFIER_STATE_STUNNED] = true }
end

function modifier_mars_spear_spear:IsPurgable()
	return true
end

function modifier_mars_spear_spear:IsStunDebuff()
	return true
end

function modifier_mars_spear_spear:IsPurgeException()
	return true
end

function modifier_mars_spear_spear:IsDebuff()
	return true
end

function modifier_mars_spear_spear:IsHidden()
	return true
end

function modifier_mars_spear_spear:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}
end

function modifier_mars_spear_spear:GetOverrideAnimation()
	return ACT_DOTA_FLAIL
end

modifier_mars_spear_debuff = class({})
LinkLuaModifier( "modifier_mars_spear_debuff", "heroes/hero_mars/mars_spear.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_mars_spear_debuff:OnCreated()
	if IsServer() then
		self.spear = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/mars/mars_spear.vmdl"})
		--self.spear:FollowEntity(self:GetParent(), false)
		local attachName = self:GetParent():ScriptLookupAttachment("attach_hitloc")
		self.spear:SetAbsOrigin(self:GetParent():GetAttachmentOrigin(attachName))
		self.spear:SetSequence("spear_impact")
		self.spear:SetForwardVector(-self:GetParent():GetForwardVector())

		self.secondsTime = 0

		self:StartIntervalThink(0.04)
	end
end

function modifier_mars_spear_debuff:OnRefresh(table)
	if IsServer() and self.spear then
		UTIL_Remove(self.spear)
		self.spear = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/mars/mars_spear.vmdl"})
		local attachName = self:GetParent():ScriptLookupAttachment("attach_hitloc")
		self.spear:SetAbsOrigin(self:GetParent():GetAttachmentOrigin(attachName))
		self.spear:SetSequence("spear_impact")
		self.spear:SetForwardVector(-self:GetParent():GetForwardVector())

		self.secondsTime = 0

		self:StartIntervalThink(0.04)
	end
end

function modifier_mars_spear_debuff:OnIntervalThink()
	local attachName = self:GetParent():ScriptLookupAttachment("attach_hitloc")
	self.spear:SetAbsOrigin(self:GetParent():GetAttachmentOrigin(attachName))
	self.spear:SetSequence("spear_impact")
	self.spear:SetForwardVector(-self:GetParent():GetForwardVector())

	if self.secondsTime >= 1.04 then
		self.secondsTime = 0
	else
		self.secondsTime = self.secondsTime + 0.04
	end
end

function modifier_mars_spear_debuff:OnRemoved()
	if IsServer() then
		UTIL_Remove(self.spear)
		FindClearSpaceForUnit(self:GetParent(), self:GetParent():GetAbsOrigin(), true)
	end
end

function modifier_mars_spear_debuff:CheckState()
	return { [MODIFIER_STATE_STUNNED] = true }
end

function modifier_mars_spear_debuff:IsPurgable()
	return true
end

function modifier_mars_spear_debuff:IsStunDebuff()
	return true
end

function modifier_mars_spear_debuff:IsPurgeException()
	return true
end

function modifier_mars_spear_spear:IsDebuff()
	return true
end

function modifier_mars_spear_debuff:GetEffectName()
	return "particles/units/heroes/hero_mars/mars_spear_impact_debuff.vpcf"
end

function modifier_mars_spear_debuff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_mars_spear_debuff:GetStatusEffectName()
	return "particles/status_fx/status_effect_mars_spear.vpcf"
end

function modifier_mars_spear_debuff:StatusEffectPriority()
	return 10
end

function modifier_mars_spear_debuff:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}
end

function modifier_mars_spear_debuff:GetOverrideAnimation()
	return ACT_DOTA_DISABLED
end

modifier_mars_spear_innate_handler = class({})
LinkLuaModifier( "modifier_mars_spear_innate_handler", "heroes/hero_mars/mars_spear.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_mars_spear_innate_handler:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK}
end

function modifier_mars_spear_innate_handler:OnAttack( params )
	if params.attacker == self:GetCaster() and params.target:IsConsideredHero() and RollPercentage( self:GetSpecialValueFor("spear_chance") ) then
		self:GetAbility():LaunchSpear( params.attacker, CalculateDirection( params.target, params.attacker ), true, CalculateDistance( params.attacker, params.target ) )
	end
end

function modifier_mars_spear_innate_handler:IsHidden()
	return true
end