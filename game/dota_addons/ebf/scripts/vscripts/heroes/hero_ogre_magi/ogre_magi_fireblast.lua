ogre_magi_fireblast = class({})

function ogre_magi_fireblast:IsStealable()
	return true
end

function ogre_magi_fireblast:IsHiddenWhenStolen()
	return false
end

function ogre_magi_fireblast:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_ogre_magi/ogre_magi_fireblast_cast.vpcf", PATTACH_POINT_FOLLOW, caster)
				ParticleManager:SetParticleControlEnt(self.fx, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack3", caster:GetAbsOrigin(), true)
				
	return true
end

function ogre_magi_fireblast:OnAbilityPhaseInterrupted()
	ParticleManager:ClearParticle( self.fx )
end

function ogre_magi_fireblast:OnSpellStart()

	self:Fireblast( self:GetCursorTarget() )
	
	EmitSoundOn("Hero_OgreMagi.Fireblast.Cast", self:GetCaster())
	ParticleManager:ClearParticle( self.fx )
end

function ogre_magi_fireblast:Fireblast(target)
	local caster = self:GetCaster()
	local target = target or self:GetCursorTarget()

	EmitSoundOn("Hero_OgreMagi.Fireblast.Target", target)
	local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_ogre_magi/ogre_magi_fireblast.vpcf", PATTACH_POINT_FOLLOW, caster)
				ParticleManager:SetParticleControlEnt(nfx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
				ParticleManager:SetParticleControl(nfx, 1, target:GetAbsOrigin())
				ParticleManager:ReleaseParticleIndex(nfx)
				
	if target:TriggerSpellAbsorb(self) then return end
	self:Stun(target, self:GetSpecialValueFor("stun_duration"), false)
	self:DealDamage(caster, target, self:GetSpecialValueFor("fireblast_damage"))
end

ogre_magi_unrefined_fireblast = class(ogre_magi_fireblast)

function ogre_magi_unrefined_fireblast:GetManaCost( iLvl )
	return self:GetCaster():GetMana() * self:GetSpecialValueFor("scepter_mana") / 100
end

function ogre_magi_fireblast:GetIntrinsicModifierName()
	return "modifier_ogre_magi_fireblast_passive"
end


modifier_ogre_magi_fireblast_passive = class({})
LinkLuaModifier("modifier_ogre_magi_fireblast_passive", "heroes/hero_ogre_magi/ogre_magi_fireblast", LUA_MODIFIER_MOTION_NONE)

function modifier_ogre_magi_fireblast_passive:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_ogre_magi_fireblast_passive:OnAttackLanded( params )
	if params.attacker == self:GetCaster() and RollPercentage( self:GetSpecialValueFor("attack_proc_chance") ) then
		local cd = self:GetAbility():GetCooldownTimeRemaining()
		self:GetAbility():EndCooldown()
		params.attacker:SetCursorCastTarget( params.target )
		self:GetAbility():CastAbility( )
		self:GetAbility():RefundManaCost( )
		self:GetAbility():SetCooldown( cd )
	end
end

function modifier_ogre_magi_fireblast_passive:IsHidden()
	return true
end