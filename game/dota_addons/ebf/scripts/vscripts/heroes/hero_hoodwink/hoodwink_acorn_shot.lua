hoodwink_acorn_shot = class({})

function hoodwink_acorn_shot:GetIntrinsicModifierName()
	return "modifier_hoodwink_acorn_shot_autocast"
end

function hoodwink_acorn_shot:GetCastRange()
	return self:GetCaster():GetAttackRange() - self:GetCaster():GetCastRangeBonus() + self:GetSpecialValueFor("bonus_range")
end

function hoodwink_acorn_shot:ShouldUseResources()
	return true
end

function hoodwink_acorn_shot:Spawn()
	self.projectileData = self.projectileData or {}
end

function hoodwink_acorn_shot:FireAcorn( target, iBounces )
	local caster = self:GetCaster()
	local bounces = iBounces or self:GetSpecialValueFor("bounce_count")
	
	self.projectileData = self.projectileData or {}
	local direction = CalculateDirection( target, caster )
	local distance = CalculateDistance( target, caster )
	local projIndex = self:FireTrackingProjectile("particles/units/heroes/hero_hoodwink/hoodwink_acorn_shot_tracking.vpcf", target, self:GetSpecialValueFor("projectile_speed"), {source = caster}, DOTA_PROJECTILE_ATTACHMENT_ATTACK_1, true, true, 200)
	self.projectileData[projIndex] = {}
	self.projectileData[projIndex].isInitial = true
	self.projectileData[projIndex].bounces = bounces
	
end

function hoodwink_acorn_shot:OnProjectileHitHandle( target, position, projectile )
	local data = self.projectileData[projectile]
	local caster = self:GetCaster()
	if not target then return end
	if data then
		if data.isInitial then
			local dummy = caster:CreateDummy( position, 15 )
			dummy:AddNewModifier( caster, self, "hoodwink_acorn_shot_dummy", {} )
			AddFOWViewer( caster:GetTeam(), position, 200, 15, false )
			CreateTempTree( position, 15 )
			ResolveNPCPositions( position, 128 )
		else
			caster:AddNewModifier( caster, self, "modifier_hoodwink_acorn_shot_damage", {} )
			self.processingAcornBounce = true
			caster:PerformGenericAttack( target, true )
			self.processingAcornBounce = false
		end
		EmitSoundOn( "Hero_Hoodwink.AcornShot.Target", target )
		EmitSoundOn( "Hero_Hoodwink.AcornShot.Slow", target )
		target:AddNewModifier( caster, self, "modifier_hoodwink_acorn_shot_slow", { duration = self:GetSpecialValueFor("debuff_duration")} )
		
		if self.projectileData[projectile].bounces > 0 then
			for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( position, self:GetCastRange() ) ) do
				if enemy ~= target then
					EmitSoundOn( "Hero_Hoodwink.AcornShot.Bounce", caster )
					local projIndex = self:FireTrackingProjectile("particles/units/heroes/hero_hoodwink/hoodwink_acorn_shot_tracking.vpcf", enemy, self:GetSpecialValueFor("projectile_speed"), {source = target}, DOTA_PROJECTILE_ATTACHMENT_ATTACK_1, true, true, 200)
					self.projectileData[projIndex] = {}
					self.projectileData[projIndex].isInitial = false
					self.projectileData[projIndex].bounces = self.projectileData[projectile].bounces - 1
					self.projectileData[projectile] = nil
					break
				end
			end
		end
		caster:RemoveModifierByName( "modifier_hoodwink_acorn_shot_damage" )
	end
end

hoodwink_acorn_shot_dummy = class({})
LinkLuaModifier("hoodwink_acorn_shot_dummy", "heroes/hero_hoodwink/hoodwink_acorn_shot", LUA_MODIFIER_MOTION_NONE)

function hoodwink_acorn_shot_dummy:GetEffectName()
	return "particles/units/heroes/hero_hoodwink/hoodwink_acorn_shot_tree.vpcf"
end


modifier_hoodwink_acorn_shot_autocast = class({})
LinkLuaModifier("modifier_hoodwink_acorn_shot_autocast", "heroes/hero_hoodwink/hoodwink_acorn_shot", LUA_MODIFIER_MOTION_NONE)

function modifier_hoodwink_acorn_shot_autocast:OnCreated()
	self.attacks = {}
	self.projectile_speed = self:GetSpecialValueFor("projectile_speed")
	self.bonus_range = self:GetSpecialValueFor("bonus_range")
end

function modifier_hoodwink_acorn_shot_autocast:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK, 
			MODIFIER_EVENT_ON_ATTACK_RECORD, 
			MODIFIER_EVENT_ON_ORDER, 
			MODIFIER_EVENT_ON_ATTACK_LANDED,
			MODIFIER_EVENT_ON_ATTACKED,
			MODIFIER_PROPERTY_PROJECTILE_NAME,
			MODIFIER_PROPERTY_PROJECTILE_SPEED,
			MODIFIER_PROPERTY_ATTACK_RANGE_BONUS
			}
end

function modifier_hoodwink_acorn_shot_autocast:OnOrder(params)
	if params.unit == self:GetParent() then
		if params.ability == self:GetAbility() and params.order_type == DOTA_UNIT_ORDER_CAST_TARGET then
			self.autocast = true
		else
			self.autocast = false
		end
	end
end

function modifier_hoodwink_acorn_shot_autocast:OnAttackRecord(params)
	if params.attacker == self:GetParent() and params.target and (( self:GetAbility():GetAutoCastState() and self:GetAbility():IsFullyCastable() ) or self.autocast) then
		local ability = self:GetAbility()
		local caster = self:GetCaster()
		params.attacker:AddNewModifier( caster, ability, "modifier_hoodwink_acorn_shot_damage", {} )
	end
end
function modifier_hoodwink_acorn_shot_autocast:OnAttack(params)
	if params.attacker == self:GetParent() and params.target and (( self:GetAbility():GetAutoCastState() and self:GetAbility():IsFullyCastable() ) or self.autocast) then
		local ability = self:GetAbility()
		local caster = self:GetCaster()
		if params.attacker:HasModifier("modifier_hoodwink_acorn_shot_damage") then 
			params.attacker:RemoveModifierByName( "modifier_hoodwink_acorn_shot_damage" )
		end
		if ability.processingAcornBounce then return end
		self.attacks[params.record] = true
		EmitSoundOn( "Hero_Hoodwink.AcornShot.Cast", caster )
		ability:FireAcorn( params.target )
		if ability:GetMaxAbilityCharges(-1) > 1 then
			ability:SpendAbilityCharge()
		else
			ability:SetCooldown(  )
		end
		
		ability:PayManaCost()
	end
end

function modifier_hoodwink_acorn_shot_autocast:GetModifierProjectileName(params)
	if IsServer() and (self:GetAbility():IsCooldownReady() and self:GetAbility():GetAutoCastState()) or self.autocast then
		return ""
	end
end

function modifier_hoodwink_acorn_shot_autocast:GetModifierProjectileSpeed(params)
	if IsServer() and (self:GetAbility():IsCooldownReady() and self:GetAbility():GetAutoCastState()) or self.autocast then
		return self.projectile_speed
	end
end

function modifier_hoodwink_acorn_shot_autocast:GetModifierAttackRangeBonus(params)
	if IsServer() and (self:GetAbility():IsCooldownReady() and self:GetAbility():GetAutoCastState()) or self.autocast then
		return self.bonus_range
	end
end

function modifier_hoodwink_acorn_shot_autocast:IsHidden()
	return false
end