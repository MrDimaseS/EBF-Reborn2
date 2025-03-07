windrunner_shackleshot = class({})

function windrunner_shackleshot:IsStealable()
    return true
end

function windrunner_shackleshot:IsHiddenWhenStolen()
    return false
end

function windrunner_shackleshot:GetAOERadius()
	return self:GetSpecialValueFor("shackle_distance")
end

function windrunner_shackleshot:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	self.direction = CalculateDirection(target, caster)

	EmitSoundOn("Hero_Windrunner.ShackleshotCast", caster)
	self.projectiles = self.projectiles or {}
	self.projectiles[self:FireTrackingProjectile("particles/units/heroes/hero_windrunner/windrunner_shackleshot.vpcf", target, 1650, {}, DOTA_PROJECTILE_ATTACHMENT_ATTACK_1)] = caster:GetAbsOrigin()
end

function windrunner_shackleshot:DoBolasStun( target, duration, failure, FX, source, sourceIsTree )
	local caster = self:GetCaster()
	local fDur = ( duration or TernaryOperator( self:GetSpecialValueFor("stun_duration"), failure, self:GetSpecialValueFor("fail_stun_duration") ) ) *  TernaryOperator( 1, target:IsConsideredHero(), 2 )
	self:Stun(target, fDur )
	local bolas = target:AddNewModifier( caster, self, "modifier_windrunner_shackleshot_primary", {duration = fDur} )
	if FX == true or FX == nil then
		if failure then
			local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_windrunner/windrunner_shackleshot_single.vpcf", PATTACH_POINT, caster)
    					ParticleManager:SetParticleControlEnt(nfx, 0, target, PATTACH_POINT, "attach_hitloc", target:GetAbsOrigin(), true)
    					ParticleManager:SetParticleControlEnt(nfx, 1, target, PATTACH_POINT, "attach_hitloc", target:GetAbsOrigin(), true)
    					ParticleManager:SetParticleControlForward(nfx, 2, self.direction)
    		bolas:AttachEffect(nfx)
		elseif source then
			if sourceIsTree then
				local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_windrunner/windrunner_shackleshot_pair_tree.vpcf", PATTACH_POINT, target)
								ParticleManager:SetParticleControlEnt(nfx, 0, target, PATTACH_POINT, "attach_hitloc", target:GetAbsOrigin(), true)
								ParticleManager:SetParticleControl(nfx, 1, source:GetAbsOrigin() + Vector(0,0,GetGroundHeight( target:GetAbsOrigin(), target ) - GetGroundHeight( source:GetAbsOrigin(), source ) ))
								ParticleManager:SetParticleControl( nfx, 2, Vector(bolas:GetRemainingTime(), 0, 0) )
				bolas:AttachEffect(nfx)
			else
				local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_windrunner/windrunner_shackleshot_pair.vpcf", PATTACH_POINT, caster)
								ParticleManager:SetParticleControlEnt(nfx, 0, target, PATTACH_POINT, "attach_hitloc", target:GetAbsOrigin(), true)
								ParticleManager:SetParticleControlEnt(nfx, 1, source, PATTACH_POINT, "attach_hitloc", source:GetAbsOrigin(), true)
								ParticleManager:SetParticleControl( nfx, 2, Vector(bolas:GetRemainingTime(), 0, 0) )
				bolas:AttachEffect(nfx)
			end
		end
	end
	local damageDur = self:GetSpecialValueFor("damage_buff_duration")
	if damageDur <= 0 then return end
	local damageBuff = caster:AddNewModifier( caster, self, "modifier_windrunner_shackleshot_self_damage_buff", {duration = damageDur})
	local damageBonus = self:GetSpecialValueFor("bonus_damage_per_hero") * TernaryOperator( 1, target:IsConsideredHero(), self:GetSpecialValueFor("bonus_damage_per_other_pct") / 100 )
	local damageBuffAmt = damageBuff:GetStackCount() + damageBonus
	damageBuff:SetStackCount( damageBuffAmt )
end

function windrunner_shackleshot:OnProjectileHitHandle(target, position, projectile)
	local caster = self:GetCaster()
	if target and not target:TriggerSpellAbsorb( self ) then
		local currentSeed = target
		local maxTargets = self:GetSpecialValueFor("shackle_count")
		local currentTargets = 0
		
		local duration = self:GetSpecialValueFor("stun_duration")
		local searchRadius = self:GetSpecialValueFor("shackle_distance")
		local direction = CalculateDirection( position, self.projectiles[projectile] )
		
		local shackledUnits = {}
		while currentTargets <= maxTargets and currentSeed do
			local seedPosition = currentSeed:GetAbsOrigin()
			currentSeed = nil
			for _, nextTarget in ipairs( caster:FindEnemyUnitsInRadius(seedPosition, searchRadius, {order = FIND_CLOSEST}) ) do
				if not HasValInTable( shackledUnits, nextTarget ) then
					table.insert( shackledUnits, nextTarget )
					currentTargets = currentTargets + 1
					currentSeed = nextTarget
					break
				end
			end
		end
		if currentTargets > 1 then -- units bound
			for order, enemy in ipairs( shackledUnits ) do
				self:DoBolasStun( enemy, duration, false, true, shackledUnits[order+1] )
			end
		else -- look for tree
			local trees = GridNav:GetAllTreesAroundPoint( position, searchRadius, true )
			if trees[1] then
				self:DoBolasStun( target, duration, false, true, trees[1], true )
			else -- fail state
				self:DoBolasStun( target, self:GetSpecialValueFor("fail_stun_duration"), true )
			end
		end
	end
end

modifier_windrunner_shackleshot_primary = class({})
LinkLuaModifier("modifier_windrunner_shackleshot_primary", "heroes/hero_windrunner/windrunner_shackleshot", LUA_MODIFIER_MOTION_NONE)
function modifier_windrunner_shackleshot_primary:OnCreated(kv)
	self:OnRefresh(kv)
end

function modifier_windrunner_shackleshot_primary:OnRefresh(kv)
	self.crit_damage = self:GetSpecialValueFor("crit_damage")
end

function modifier_windrunner_shackleshot_primary:OnIntervalThink()
	self:GetAbility():DealDamage( self:GetCaster(), self:GetParent(), self.damage )
end

function modifier_windrunner_shackleshot_primary:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_TARGET_CRITICALSTRIKE}
end

function modifier_windrunner_shackleshot_primary:GetModifierPreAttack_Target_CriticalStrike()
	return self.crit_damage
end

function modifier_windrunner_shackleshot_primary:IsHidden()
	return true
end

function modifier_windrunner_shackleshot_primary:IsPurgable()
	return false
end

function modifier_windrunner_shackleshot_primary:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end