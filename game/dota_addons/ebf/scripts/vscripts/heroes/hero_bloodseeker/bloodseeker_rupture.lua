bloodseeker_rupture = class({})

function bloodseeker_rupture:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	local duration = self:GetSpecialValueFor("duration")
	target:AddNewModifier( caster, self, "modifier_bloodseeker_rupture_debuff", { duration = duration} )
	self:DealDamage( caster, target, target:GetMaxHealth() * self:GetSpecialValueFor("hp_pct") / 100 )
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