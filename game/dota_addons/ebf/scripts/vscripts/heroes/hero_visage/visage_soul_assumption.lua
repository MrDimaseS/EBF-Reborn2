visage_soul_assumption = class({})

function visage_soul_assumption:IsStealable()
    return true
end

function visage_soul_assumption:IsHiddenWhenStolen()
    return false
end

function visage_soul_assumption:GetIntrinsicModifierName()
    return "modifier_visage_soul_assumption_handle"
end

function visage_soul_assumption:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	local targets = self:GetSpecialValueFor("targets")
	
	self:ReleaseSouls(target)
	targets = targets - 1
	if targets > 0 then
		for _,enemy in pairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self:GetTrueCastRange() ) ) do
			if enemy ~= target then
				self:ReleaseSouls(enemy)
				targets = targets - 1
				if targets <= 0 then
					break
				end
			end
		end
	end

	EmitSoundOn("Hero_Visage.SoulAssumption.Cast", caster)
	self:SoulsReleased()
end

function visage_soul_assumption:ReleaseSouls(hTarget)
	local caster = self:GetCaster()
	
	self.soulAssumptionProjectiles = self.soulAssumptionProjectiles or {}
	local speed = self:GetSpecialValueFor("bolt_speed")
	local projectile
	if self.currentStacks > 0 then
		projectile = self:FireTrackingProjectile("particles/units/heroes/hero_visage/visage_soul_assumption_bolt" .. self.currentStacks .. ".vpcf", hTarget, speed , {}, DOTA_PROJECTILE_ATTACHMENT_ATTACK_1, true, false, 0)
	else
		projectile = self:FireTrackingProjectile("particles/units/heroes/hero_visage/visage_soul_assumption_bolt", hTarget, speed, {}, DOTA_PROJECTILE_ATTACHMENT_ATTACK_1, true, false, 0)
	end
	self.soulAssumptionProjectiles[projectile] = self:GetSpecialValueFor("soul_base_damage") + self:GetSpecialValueFor("soul_charge_damage") * self.currentStacks
end

function visage_soul_assumption:OnProjectileHitHandle(hTarget, vLocation, iProjectile)
	local caster = self:GetCaster()
	if hTarget and not hTarget:TriggerSpellAbsorb( self ) then

		EmitSoundOn("Hero_Visage.SoulAssumption.Target", hTarget)
		self:DealDamage(caster, hTarget, self.soulAssumptionProjectiles[iProjectile], {}, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE)
	end
end

function visage_soul_assumption:IncrementStacks()
	local caster = self:GetCaster()

	local maxStacks = self:GetSpecialValueFor("stack_limit")
	
	self.currentStacks = math.min( (self.currentStacks or 0) + 1, maxStacks )
	
	if not self.nfx then
		self.nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_visage/visage_soul_overhead.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleAlwaysSimulate(self.nfx)
		ParticleManager:SetParticleControlEnt(self.nfx, 0, caster, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControl(self.nfx, 1, Vector(1,0,0))
		ParticleManager:SetParticleControl(self.nfx, 2, Vector(0,0,0))
		ParticleManager:SetParticleControl(self.nfx, 3, Vector(0,0,0))
		ParticleManager:SetParticleControl(self.nfx, 4, Vector(0,0,0))
		ParticleManager:SetParticleControl(self.nfx, 5, Vector(0,0,0))
		ParticleManager:SetParticleControl(self.nfx, 6, Vector(0,0,0))
	else
		for i = 1, maxStacks do
			if i <= self.currentStacks then
				ParticleManager:SetParticleControl(self.nfx, i, Vector(1,0,0))
			else
				ParticleManager:SetParticleControl(self.nfx, i, Vector(0,0,0))
			end
		end
	end
end

function visage_soul_assumption:SoulsReleased()
	local caster = self:GetCaster()

	self.currentStacks = 0
	
	ParticleManager:SetParticleControl(self.nfx, 1, Vector(0,0,0))
	ParticleManager:SetParticleControl(self.nfx, 2, Vector(0,0,0))
	ParticleManager:SetParticleControl(self.nfx, 3, Vector(0,0,0))
	ParticleManager:SetParticleControl(self.nfx, 4, Vector(0,0,0))
	ParticleManager:SetParticleControl(self.nfx, 5, Vector(0,0,0))
	ParticleManager:SetParticleControl(self.nfx, 6, Vector(0,0,0))
end

modifier_visage_soul_assumption_handle = class({})
LinkLuaModifier( "modifier_visage_soul_assumption_handle", "heroes/hero_visage/visage_soul_assumption.lua" ,LUA_MODIFIER_MOTION_NONE )
function modifier_visage_soul_assumption_handle:OnCreated(table)
	self.attacks_per_stack = self:GetSpecialValueFor("attacks_per_stack")	
end

function modifier_visage_soul_assumption_handle:OnRefresh(table)
	self.attacks_per_stack = self:GetSpecialValueFor("attacks_per_stack")
end

function modifier_visage_soul_assumption_handle:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK,
			MODIFIER_EVENT_ON_ABILITY_FULLY_CAST }
end

function modifier_visage_soul_assumption_handle:OnAttack(params)
	local caster = self:GetCaster()
	if params.attacker == caster then
		self.attackCounter = (self.attackCounter or 0) + 1
		if self.attackCounter >= self.attacks_per_stack then
			self:GetAbility():IncrementStacks()
			self.attackCounter = 0
		end
	end
end

function modifier_visage_soul_assumption_handle:OnAbilityFullyCast(params)
	local caster = self:GetCaster()
	if params.unit == caster and caster:HasAbility( params.ability:GetAbilityName() ) and params.ability ~= self:GetAbility() then
		self:GetAbility():IncrementStacks()
	end
end

function modifier_visage_soul_assumption_handle:IsHidden()
	return true
end