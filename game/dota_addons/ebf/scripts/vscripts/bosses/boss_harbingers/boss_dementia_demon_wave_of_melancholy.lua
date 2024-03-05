boss_dementia_demon_wave_of_melancholy = class({})

function boss_dementia_demon_wave_of_melancholy:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	local direction = CalculateDirection(point, caster:GetAbsOrigin())
	local speed = self:GetSpecialValueFor("speed")
	local radius = self:GetSpecialValueFor("radius")
	local velocity = direction * speed

	EmitSoundOn("Hero_ShadowDemon.ShadowPoison.Cast", caster)
	EmitSoundOn("Hero_ShadowDemon.ShadowPoison", caster)

	self:FireLinearProjectile("particles/units/heroes/hero_shadow_demon/shadow_demon_shadow_poison_projectile.vpcf", velocity, self:GetTrueCastRange(), radius, {flags = DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD})
end

function boss_dementia_demon_wave_of_melancholy:OnProjectileHit(hTarget, vLocation)
	local caster = self:GetCaster()

	if hTarget then
		EmitSoundOn("Hero_ShadowDemon.ShadowPoison.Impact", hTarget)

		local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_shadow_demon/shadow_demon_loadout.vpcf", PATTACH_POINT, caster)
					ParticleManager:SetParticleControlEnt(nfx, 0, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
					ParticleManager:SetParticleControlEnt(nfx, 2, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
					ParticleManager:SetParticleControl(nfx, 3, Vector(1,0,0))
					ParticleManager:ReleaseParticleIndex(nfx)

		local impactDamage = self:GetSpecialValueFor("hit_damage")

		hTarget:AddNewModifier(caster, self, "modifier_boss_dementia_demon_wave_of_melancholy_poison", {Duration = self:GetDuration()}):IncrementStackCount()

		self:DealDamage(caster, hTarget, impactDamage, {}, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE)
	end
end

modifier_boss_dementia_demon_wave_of_melancholy_poison = class({})
LinkLuaModifier( "modifier_boss_dementia_demon_wave_of_melancholy_poison", "bosses/boss_harbingers/boss_dementia_demon_wave_of_melancholy", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_dementia_demon_wave_of_melancholy_poison:OnCreated()
	self:OnRefresh()
end

function modifier_boss_dementia_demon_wave_of_melancholy_poison:OnRefresh()
	self.stack_damage = self:GetSpecialValueFor("stack_damage")
end

function modifier_boss_dementia_demon_wave_of_melancholy_poison:OnDestroy()
	if not IsServer() then return end
	if self.triggeredDestroy or self:GetRemainingTime() <= 0 then
		self:GetAbility():DealDamage( self:GetCaster(), self:GetParent(), self:OnTooltip() )
	end
end

function modifier_boss_dementia_demon_wave_of_melancholy_poison:DeclareFunctions()
	return {MODIFIER_PROPERTY_TOOLTIP}
end

function modifier_boss_dementia_demon_wave_of_melancholy_poison:OnTooltip()
	return ( self.stack_damage * self:GetStackCount() ) * self:GetStackCount()
end


boss_dementia_demon_release_melancholy = class({})
function boss_dementia_demon_release_melancholy:OnSpellStart()
	local caster = self:GetCaster()
	
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), -1 ) ) do
		local poison = enemy:FindModifierByName("modifier_boss_dementia_demon_wave_of_melancholy_poison")
		if poison then
			poison.triggeredDestroy = true
			poison:Destroy()
		end
	end
end