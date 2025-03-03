bloodseeker_rupture = class({})

function bloodseeker_rupture:GetBehavior()
	local behavior = tonumber(tostring(self.BaseClass.GetBehavior( self )))
	if self:GetSpecialValueFor("burst_aoe") > 0 then
		behavior = behavior + DOTA_ABILITY_BEHAVIOR_AOE
	end
	return behavior
end

function bloodseeker_rupture:GetAOERadius()
	return self:GetSpecialValueFor("burst_aoe")
end

function bloodseeker_rupture:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	local duration = self:GetSpecialValueFor("duration")
	local maxHPDamage = target:GetMaxHealth() * self:GetSpecialValueFor("hp_pct")
	if self:GetSpecialValueFor("burst_aoe") > 0 then
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), self:GetSpecialValueFor("burst_aoe") ) ) do
			self:DealDamage( caster, enemy, target:GetMaxHealth() * self:GetSpecialValueFor("hp_pct") / 100 )
			enemy:AddNewModifier( caster, self, "modifier_bloodseeker_rupture_debuff", { duration = duration} )
		end
		ParticleManager:FireParticle("particles/econ/items/bloodseeker/bloodseeker_crownfall_immortal/bloodseeker_crownfall_immortal_explosiondriver.vpcf", PATTACH_POINT, target, {[0] = target:GetAbsOrigin()} )
	else
		self:DealDamage( caster, target, target:GetMaxHealth() * self:GetSpecialValueFor("hp_pct") / 100 )
		target:AddNewModifier( caster, self, "modifier_bloodseeker_rupture_debuff", { duration = duration} )
	end
	EmitSoundOn( "hero_bloodseeker.rupture.cast", caster )
	EmitSoundOn( "hero_bloodseeker.rupture", target )
end

modifier_bloodseeker_rupture_debuff = class({})
LinkLuaModifier( "modifier_bloodseeker_rupture_debuff", "heroes/hero_bloodseeker/bloodseeker_rupture", LUA_MODIFIER_MOTION_NONE )

function modifier_bloodseeker_rupture_debuff:OnCreated()
	self:OnRefresh()
end

function modifier_bloodseeker_rupture_debuff:OnRefresh()
	self.damage_per_second = self:GetSpecialValueFor("damage_per_second")
	self.movement_damage_pct = 1 + self:GetSpecialValueFor("movement_damage_pct") / 100
	
	if IsServer() then
		self:StartIntervalThink( 1 )
	end
end

function modifier_bloodseeker_rupture_debuff:OnIntervalThink()
	local parent = self:GetParent()
	local damage = self.damage_per_second * TernaryOperator( self.movement_damage_pct, parent:IsMoving(), 1 )
	self:GetAbility():DealDamage( self:GetCaster(), parent, damage )
end

function modifier_bloodseeker_rupture_debuff:GetEffectName()
	return "particles/units/heroes/hero_bloodseeker/bloodseeker_rupture.vpcf"
end

function modifier_bloodseeker_rupture_debuff:GetStatusEffectName()
	return "particles/status_fx/status_effect_rupture.vpcf"
end

function modifier_bloodseeker_rupture_debuff:StatusEffectPriority()
	return 1
end