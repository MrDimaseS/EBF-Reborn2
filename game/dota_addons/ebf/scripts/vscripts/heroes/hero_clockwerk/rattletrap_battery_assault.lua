rattletrap_battery_assault = class({})

function rattletrap_battery_assault:OnSpellStart()
	local caster = self:GetCaster()
	
	caster:AddNewModifier( caster, self, "modifier_rattletrap_battery_assault_active", {duration = self:GetSpecialValueFor("duration")} )
end

function rattletrap_battery_assault:ShrapnelShot( target )
	local caster = self:GetCaster()
	EmitSoundOn( "Hero_Rattletrap.Battery_Assault_Launch", caster )
	if target.GetAbsOrigin then
		self:DealDamage(caster, target, self.damage)
		self:Stun(target, 0.15, false)
		
		EmitSoundOn( "Hero_Rattletrap.Battery_Assault_Impact", target )
		ParticleManager:FireRopeParticle("particles/units/heroes/hero_rattletrap/rattletrap_battery_shrapnel.vpcf", PATTACH_POINT_FOLLOW, caster, target)
	else
		ParticleManager:FireParticle( "particles/units/heroes/hero_rattletrap/rattletrap_battery_shrapnel.vpcf", PATTACH_POINT_FOLLOW, caster, {[1] = target})
	end
end

LinkLuaModifier("modifier_rattletrap_battery_assault_active", "heroes/hero_clockwerk/rattletrap_battery_assault", LUA_MODIFIER_MOTION_NONE)
modifier_rattletrap_battery_assault_active = class({})

function modifier_rattletrap_battery_assault_active:OnCreated()
	self:OnRefresh()
end

function modifier_rattletrap_battery_assault_active:OnRefresh()
	self.radius = self:GetSpecialValueFor("radius")
	self.interval = self:GetSpecialValueFor("interval")
	self:GetAbility().damage = self:GetSpecialValueFor("damage")
	if IsServer() then
		self:StartIntervalThink(self.interval)
	end
end

function modifier_rattletrap_battery_assault_active:OnIntervalThink()
	local caster = self:GetCaster()
	local enemyHit = false
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self.radius ) ) do
		enemyHit = true
		self:GetAbility():ShrapnelShot( enemy )
		if not caster:HasModifier("modifier_rattletrap_overclocking") then
			return
		end
	end
	if not enemyHit then
		self:GetAbility():ShrapnelShot( self:GetCaster():GetAbsOrigin() + RandomVector( self.radius ) )
	end
end

function modifier_rattletrap_battery_assault_active:IsHidden()
	return false
end

function modifier_rattletrap_battery_assault_active:IsPurgable()
	return false
end