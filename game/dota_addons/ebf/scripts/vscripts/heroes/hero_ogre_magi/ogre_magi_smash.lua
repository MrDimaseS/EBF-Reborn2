ogre_magi_smash = class({})

function ogre_magi_smash:GetIntrinsicModifierName()
	return "modifier_oogre_magi_smash_passive"
end

function ogre_magi_smash:IsStealable()
	return true
end

function ogre_magi_smash:IsHiddenWhenStolen()
	return false
end

function ogre_magi_smash:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	self:FireShield( target )
	EmitSoundOn( "Hero_OgreMagi.FireShield.Cast", self:GetCaster() )
end

function ogre_magi_smash:FireShield( hTarget )
	local caster = self:GetCaster()
	local target = hTarget or self:GetCursorTarget()

	EmitSoundOn("Hero_OgreMagi.FireShield.Target", target)
	
	target:RemoveModifierByName("modifier_ogre_magi_smash_shield")
	target:AddNewModifier(caster, self, "modifier_ogre_magi_smash_shield", {Duration = self:GetSpecialValueFor("duration")}):SetStackCount( self:GetSpecialValueFor("attacks") )
end

function ogre_magi_smash:OnProjectileHit(hTarget, vLocation)
	local caster = self:GetCaster()

	if hTarget then
		EmitSoundOn("Hero_OgreMagi.FireShield.Damage", hTarget)
		self:DealDamage( caster, hTarget, self:GetSpecialValueFor("damage") )
	end
end

modifier_ogre_magi_smash_shield = class({})
LinkLuaModifier( "modifier_ogre_magi_smash_shield", "heroes/hero_ogre_magi/ogre_magi_smash.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_ogre_magi_smash_shield:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self.shieldFX = ParticleManager:CreateParticle("particles/units/heroes/hero_ogre_magi/ogre_magi_fire_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )ParticleManager:SetParticleControlEnt( self.shieldFX, 0, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
		ParticleManager:SetParticleControl( self.shieldFX, 1, Vector( self:GetStackCount(), 1, 1 ) )
		ParticleManager:SetParticleControl( self.shieldFX, 9, Vector( 1, 1, 1 ) )
		ParticleManager:SetParticleControl( self.shieldFX, 10, Vector( 1, 1, 1) )
		ParticleManager:SetParticleControl( self.shieldFX, 11, Vector( 1, 1, 1 ) )
	end
end

function modifier_ogre_magi_smash_shield:OnRefresh()
	self.damage_absorb_pct = self:GetSpecialValueFor("damage_absorb_pct") / 100
	self.projectile_speed = self:GetSpecialValueFor("projectile_speed")
end

function modifier_ogre_magi_smash_shield:OnDestroy()
	if IsServer() then
		ParticleManager:ClearParticle( self.shieldFX )
		local caster = self:GetCaster()
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local stacks = self:GetStackCount()
		if stacks > 0 then
			for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self.projectile_speed ) ) do
				stacks = stacks - 1
				ability:FireTrackingProjectile("particles/units/heroes/hero_ogre_magi/ogre_magi_fire_shield_projectile.vpcf", enemy, self.projectile_speed, {source = parent})
				if stacks == 0 then
					return
				end
			end
		end
	end
end

function modifier_ogre_magi_smash_shield:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK
	}
	return funcs
end

function modifier_ogre_magi_smash_shield:GetModifierTotal_ConstantBlock( params )
	PrintAll( params )
	if params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
		local ability = self:GetAbility()
		
		self:DecrementStackCount()
		ParticleManager:SetParticleControl( self.shieldFX, 1, Vector( self:GetStackCount(), 0, 0 ) )
		ability:FireTrackingProjectile("particles/units/heroes/hero_ogre_magi/ogre_magi_fire_shield_projectile.vpcf", params.attacker, self.projectile_speed, {source = self:GetParent()})
		if self:GetStackCount() == 0 then
			self:Destroy()
		end
		return params.damage * self.damage_absorb_pct
	end
end

function modifier_ogre_magi_smash_shield:GetModifierAttackSpeedBonus_Constant()
	return self.attack_speed
end

function modifier_ogre_magi_smash_shield:GetModifierModelScale()
	return self.modelscale
end

function modifier_ogre_magi_smash_shield:GetEffectName()
	return "particles/units/heroes/hero_ogre_magi/oogre_magi_smash_buff.vpcf"
end

function modifier_ogre_magi_smash_shield:IsDebuff()
	return false
end