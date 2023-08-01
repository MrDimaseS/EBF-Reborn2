ogre_magi_ignite = class({})

function ogre_magi_ignite:IsStealable()
	return true
end

function ogre_magi_ignite:IsHiddenWhenStolen()
	return false
end

function ogre_magi_ignite:GetAOERadius()
	return self:GetEffectiveCastRange( self:GetCaster():GetAbsOrigin(), self:GetCaster() ) + 200
end

function ogre_magi_ignite:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	EmitSoundOn("Hero_OgreMagi.Ignite.Cast", caster)
	
	self:Ignite( target )
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self:GetTrueCastRange() ) ) do
		if target ~= enemy then
			self:Ignite( enemy )
			break
		end
	end
	
end

function ogre_magi_ignite:Ignite( target )
	local caster = self:GetCaster()
	local target = target or self:GetCursorTarget()

	self:FireTrackingProjectile("particles/units/heroes/hero_ogre_magi/ogre_magi_ignite.vpcf", target, self:GetSpecialValueFor("projectile_speed"), {}, DOTA_PROJECTILE_ATTACHMENT_ATTACK_3)
end

function ogre_magi_ignite:OnProjectileHit(hTarget, vLocation)
	local caster = self:GetCaster()

	if hTarget and not hTarget:TriggerSpellAbsorb(self) then
		EmitSoundOn("Hero_OgreMagi.Ignite.Target", hTarget)
		
		local duration = self:GetSpecialValueFor("duration")
		local ignite = hTarget:FindModifierByName("modifier_ogre_magi_ignite")
		if ignite then
			duration = duration + ignite:GetRemainingTime()
		end
		hTarget:AddNewModifier(caster, self, "modifier_ogre_magi_ignite", {Duration = duration})
	end
end

modifier_ogre_magi_ignite = class({})
LinkLuaModifier("modifier_ogre_magi_ignite", "heroes/hero_ogre_magi/ogre_magi_ignite", LUA_MODIFIER_MOTION_NONE)

function modifier_ogre_magi_ignite:OnCreated( )
	if IsServer() then self:StartIntervalThink(1) end
end

function modifier_ogre_magi_ignite:OnIntervalThink()
	EmitSoundOn("Hero_OgreMagi.Ignite.Damage", self:GetParent())
	self:GetAbility():DealDamage(self:GetCaster(), self:GetParent(), self:GetSpecialValueFor("burn_damage"), {}, 0)
end

function modifier_ogre_magi_ignite:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
	return funcs
end

function modifier_ogre_magi_ignite:GetModifierMoveSpeedBonus_Percentage()
	return self:GetSpecialValueFor("slow_movement_speed_pct")
end

function modifier_ogre_magi_ignite:GetEffectName()
	return "particles/units/heroes/hero_ogre_magi/ogre_magi_ignite_debuff.vpcf"
end

function modifier_ogre_magi_ignite:GetStatusEffectName()
	return "particles/status_fx/status_effect_burn.vpcf"
end

function modifier_ogre_magi_ignite:StatusEffectPriority()
	return 10
end

function modifier_ogre_magi_ignite:IsDebuff()
	return true
end