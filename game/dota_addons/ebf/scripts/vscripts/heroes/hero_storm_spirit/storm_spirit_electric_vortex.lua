storm_spirit_electric_vortex = class({})

function storm_spirit_electric_vortex:IsStealable()
    return true
end

function storm_spirit_electric_vortex:IsHiddenWhenStolen()
    return false
end

function storm_spirit_electric_vortex:GetBehavior()
    return DOTA_ABILITY_BEHAVIOR_NO_TARGET
end

function storm_spirit_electric_vortex:GetCastRange(vLocation, hTarget)
    return self:GetSpecialValueFor("radius")
end

function storm_spirit_electric_vortex:OnSpellStart()
	local caster = self:GetCaster()


	EmitSoundOn("Hero_StormSpirit.ElectricVortexCast", caster)
	EmitSoundOn("Hero_StormSpirit.ElectricVortex", caster)
	
	local duration = self:GetSpecialValueFor("AbilityDuration")
	local enemies = caster:FindEnemyUnitsInRadius(caster:GetAbsOrigin(), self:GetSpecialValueFor("radius") )
	for _,enemy in pairs(enemies) do	
		if not enemy:TriggerSpellAbsorb( self ) then
			enemy:AddNewModifier(caster, self, "modifier_storm_spirit_electric_vortex_pull", {Duration = duration})
		end
	end
	if caster:HasScepter() then
		caster:AddNewModifier(caster, self, "modifier_storm_spirit_electric_vortex_scepter", {Duration = duration})
	end
end

modifier_storm_spirit_electric_vortex_scepter = class({})
LinkLuaModifier("modifier_storm_spirit_electric_vortex_scepter", "heroes/hero_storm_spirit/storm_spirit_electric_vortex", LUA_MODIFIER_MOTION_NONE)

function modifier_storm_spirit_electric_vortex_scepter:OnCreated()
	self.overload = self:GetCaster():FindAbilityByName("storm_spirit_overload")
end

function modifier_storm_spirit_electric_vortex_scepter:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_storm_spirit_electric_vortex_scepter:OnAttackLanded( params )
	if params.attacker == self:GetCaster() and params.target:HasModifier("modifier_storm_spirit_electric_vortex_pull") then
		local radius = self.overload:GetSpecialValueFor("overload_aoe")
		local damage = self.overload:GetSpecialValueFor("overload_damage")
		local duration = self.overload:GetSpecialValueFor("AbilityDuration")
		params.target:AddNewModifier( params.caster, self.overload, "modifier_storm_spirit_overload_debuff", {duration = duration} )
		
		for _, enemy in ipairs( params.attacker:FindEnemyUnitsInRadius( params.target:GetAbsOrigin(), radius ) ) do
			self.overload:DealDamage( params.attacker, params.target, damage )
		end
		ParticleManager:FireParticle( "particles/units/heroes/hero_void_spirit/voidspirit_overload_discharge.vpcf", PATTACH_POINT_FOLLOW, params.target )
	end
end

function modifier_storm_spirit_electric_vortex_scepter:IsHidden()
	return true
end

modifier_storm_spirit_electric_vortex = class({})
LinkLuaModifier("modifier_storm_spirit_electric_vortex", "heroes/hero_storm_spirit/storm_spirit_electric_vortex", LUA_MODIFIER_MOTION_NONE)
function modifier_storm_spirit_electric_vortex:OnCreated(table)
	if IsServer() then
		self.caster = self:GetCaster()
		self.point = self.caster:GetAbsOrigin()
		self.parent = self:GetParent()

		self.speed = self:GetSpecialValueFor("cast_range") / self:GetDuration() * FrameTime()

		self.talent1 = self.caster:HasTalent("special_bonus_unique_storm_spirit_electric_vortex_1")
		self.damage = self.caster:GetLevel()*self.caster:FindTalentValue("special_bonus_unique_storm_spirit_electric_vortex_1") * FrameTime()
		
		local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_stormspirit/stormspirit_electric_vortex.vpcf", PATTACH_POINT, self.caster)
					ParticleManager:SetParticleControl(nfx, 0, self.point)
					ParticleManager:SetParticleControlEnt(nfx, 1, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", self.parent:GetAbsOrigin(), true)

		self:AttachEffect(nfx)

		self:StartIntervalThink(FrameTime())
	end
end

function modifier_storm_spirit_electric_vortex:OnIntervalThink()
	local parentPoint = self.parent:GetAbsOrigin()
	local direction = CalculateDirection(self.point, parentPoint)
	local distance = CalculateDistance(self.point, parentPoint)
	if distance > self.speed then
		self.parent:SetAbsOrigin(GetGroundPosition(parentPoint, self.parent) + direction * self.speed)
	end

	if self.talent1 then
		self:GetAbility():DealDamage(self.caster, self.parent, self.damage )
	end
end

function modifier_storm_spirit_electric_vortex:OnRemoved()
	if IsServer() then
		FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
		self:GetAbility():EndDelayedCooldown()
	end
end

function modifier_storm_spirit_electric_vortex:CheckState()
	return {[MODIFIER_STATE_STUNNED] = true}
end

function modifier_storm_spirit_electric_vortex:IsDebuff()
	return true
end

function modifier_storm_spirit_electric_vortex:IsPurgable()
	return true
end