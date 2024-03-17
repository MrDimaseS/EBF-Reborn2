grimstroke_spirit_walk = class({})

function grimstroke_spirit_walk:IsStealable()
    return true
end

function grimstroke_spirit_walk:IsHiddenWhenStolen()
    return false
end

function grimstroke_spirit_walk:GetCastRange(vLocation, hTarget)
    return self:GetSpecialValueFor("cast_range")
end

function grimstroke_spirit_walk:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	local duration = self:GetSpecialValueFor("buff_duration")

	EmitSoundOn("Hero_Grimstroke.InkSwell.Cast", target)
	
	target:Dispel( caster, caster:HasShard() )
	target:AddNewModifier(caster, self, "modifier_grimstroke_spirit_walk_one", {Duration = duration})
end

modifier_grimstroke_spirit_walk_one = class({})
LinkLuaModifier("modifier_grimstroke_spirit_walk_one", "heroes/hero_grimstroke/grimstroke_spirit_walk", LUA_MODIFIER_MOTION_NONE)
function modifier_grimstroke_spirit_walk_one:OnCreated(table)
	self:OnRefresh()
	if IsServer() then
		local caster = self:GetCaster()
		local parent = self:GetParent()

		local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_grimstroke/grimstroke_ink_swell_buff.vpcf", PATTACH_POINT, caster)
					ParticleManager:SetParticleControlEnt(nfx, 0, parent, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
					ParticleManager:SetParticleControlEnt(nfx, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
					ParticleManager:SetParticleControl(nfx, 2, Vector(self.radius, 0, 0))
					ParticleManager:SetParticleControlEnt(nfx, 3, parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
		self:AttachEffect(nfx)

		self:StartIntervalThink(self.tick_rate)
	end
end

function modifier_grimstroke_spirit_walk_one:OnRefresh(table)
	self.bonus_ms = self:GetSpecialValueFor("bonus_ms")
	self.max_damage = self:GetSpecialValueFor("max_damage")
	self.radius = self:GetSpecialValueFor("radius")
	self.max_stun = self:GetSpecialValueFor("max_stun")
	self.tick_rate = self:GetSpecialValueFor("tick_rate")
	self.tick_dps_tooltip = self:GetSpecialValueFor("tick_dps_tooltip")
	self.shard_heal_pct = self:GetSpecialValueFor("shard_heal_pct")
end

function modifier_grimstroke_spirit_walk_one:OnIntervalThink()
	local parent = self:GetParent()
	local caster = self:GetCaster()
	local ability = self:GetAbility()

	local enemies = caster:FindEnemyUnitsInRadius(parent:GetAbsOrigin(), self.radius)
	if #enemies > 0 then EmitSoundOn("Hero_Grimstroke.InkSwell.Damage", parent) end
	local endDamage = 0
	for _,enemy in pairs(enemies) do
		ParticleManager:FireRopeParticle("particles/units/heroes/hero_grimstroke/grimstroke_ink_swell_tick_damage.vpcf", PATTACH_POINT_FOLLOW, parent, enemy )
		endDamage = endDamage + ability:DealDamage( caster, enemy, self.tick_dps_tooltip * self.tick_rate )
	end
	if caster:HasShard() then
		parent:HealEvent( endDamage, ability, caster )
		parent:Dispel( caster, false )
	end
end

function modifier_grimstroke_spirit_walk_one:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_grimstroke_spirit_walk_one:GetModifierMoveSpeedBonus_Percentage()
	return self.bonusMS
end

function modifier_grimstroke_spirit_walk_one:OnRemoved()
	if IsServer() then
		local parent = self:GetParent()
		local caster = self:GetCaster()
		local ability = self:GetAbility()

		EmitSoundOn("Hero_Grimstroke.InkSwell.Stun", parent)

		ParticleManager:FireParticle("particles/units/heroes/hero_grimstroke/grimstroke_ink_swell_aoe.vpcf", PATTACH_POINT, parent, {[0] = parent:GetAbsOrigin(),
																																	[2] = Vector(self.radius, self.radius, self.radius)})
		local enemies = caster:FindEnemyUnitsInRadius(parent:GetAbsOrigin(), self.radius)
		for _,enemy in pairs(enemies) do
			EmitSoundOn("Hero_Grimstroke.InkSwell.Target", enemy)
			ability:Stun(enemy, self.max_stun, false)					
			ability:DealDamage(caster, enemy, self.max_damage, {}, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE)
		end
	end
end

function modifier_grimstroke_spirit_walk_one:GetStatusEffectName()
	return "particles/status_fx/status_effect_grimstroke_spirit_walk_swell.vpcf"
end

function modifier_grimstroke_spirit_walk_one:StatusEffectPriority()
	return 11
end

function modifier_grimstroke_spirit_walk_one:IsDebuff()
	return false
end

function modifier_grimstroke_spirit_walk_one:IsPurgable()
	return true
end