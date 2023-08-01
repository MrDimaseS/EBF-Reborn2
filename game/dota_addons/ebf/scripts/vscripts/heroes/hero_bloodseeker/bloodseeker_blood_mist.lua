bloodseeker_blood_mist = class({})

function bloodseeker_blood_mist:OnToggle()
	if self:GetToggleState() then
		self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_bloodseeker_blood_mist_toggle", {} )
		ParticleManager:FireParticle( "particles/units/heroes/hero_bloodseeker/bloodseeker_scepter_blood_mist_activation.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster() )
		EmitSoundOn("Hero_Boodseeker.Bloodmist", self:GetCaster() )
	else
		self:GetCaster():RemoveModifierByName("modifier_bloodseeker_blood_mist_toggle")
		StopSoundOn("Hero_Boodseeker.Bloodmist", self:GetCaster() )
	end
end

function bloodseeker_blood_mist:ResetToggleOnRespawn()
	return true
end

modifier_bloodseeker_blood_mist_toggle = class({})
LinkLuaModifier( "modifier_bloodseeker_blood_mist_toggle", "heroes/hero_bloodseeker/bloodseeker_blood_mist", LUA_MODIFIER_MOTION_NONE )

function modifier_bloodseeker_blood_mist_toggle:OnCreated()
	self.damage = self:GetSpecialValueFor("hp_cost_per_second") / 100
	self.radius = self:GetSpecialValueFor("radius")
	self.tick = 0.1
	if IsServer() then
		local nFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_bloodseeker/bloodseeker_scepter_blood_mist_aoe.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster() )
		ParticleManager:SetParticleControl(nFX, 1, Vector( self.radius, 1, 1 ) )
		self:AddEffect( nFX )
		
		self:StartIntervalThink(self.tick)
	end
end

function modifier_bloodseeker_blood_mist_toggle:OnIntervalThink()
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	
	ability:DealDamage( caster, parent, parent:GetMaxHealth() * self.damage * self.tick, {damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL } )
end

function modifier_bloodseeker_blood_mist_toggle:IsAura()
	return true
end

function modifier_bloodseeker_blood_mist_toggle:GetModifierAura()
	return "modifier_bloodseeker_blood_mist_debuff"
end

function modifier_bloodseeker_blood_mist_toggle:GetAuraRadius()
	return self.radius
end

function modifier_bloodseeker_blood_mist_toggle:GetAuraDuration()
	return 0.5
end

function modifier_bloodseeker_blood_mist_toggle:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_bloodseeker_blood_mist_toggle:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

modifier_bloodseeker_blood_mist_debuff = class({})
LinkLuaModifier( "modifier_bloodseeker_blood_mist_debuff", "heroes/hero_bloodseeker/bloodseeker_blood_mist", LUA_MODIFIER_MOTION_NONE )

function modifier_bloodseeker_blood_mist_debuff:OnCreated()
	self.damage = self:GetSpecialValueFor("hp_cost_per_second") / 100
	self.slow = -self:GetSpecialValueFor("movement_slow")
	self.tick = 0.1
	if IsServer() then
		self:StartIntervalThink(self.tick)
	end
end

function modifier_bloodseeker_blood_mist_debuff:OnIntervalThink()
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	
	ability:DealDamage( caster, parent, caster:GetMaxHealth() * self.damage * self.tick, {damage_type = DAMAGE_TYPE_MAGICAL} )
end

function modifier_bloodseeker_blood_mist_debuff:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_bloodseeker_blood_mist_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

function modifier_bloodseeker_blood_mist_debuff:GetEffectName()
	return "particles/units/heroes/hero_bloodseeker/bloodseeker_scepter_blood_mist_spray_drips.vpcf"
end