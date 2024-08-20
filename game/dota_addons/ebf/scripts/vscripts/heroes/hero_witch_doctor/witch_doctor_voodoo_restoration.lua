witch_doctor_voodoo_restoration = class({})

function witch_doctor_voodoo_restoration:GetCastRange()
	return self:GetSpecialValueFor("radius") - self:GetCaster():GetCastRangeBonus()
end

function witch_doctor_voodoo_restoration:OnToggle()
	local caster = self:GetCaster()
	if self:GetToggleState() then
		EmitSoundOn("Hero_WitchDoctor.Voodoo_Restoration", self:GetCaster())
		EmitSoundOn("Hero_WitchDoctor.Voodoo_Restoration.Loop", self:GetCaster())

		caster:AddNewModifier(caster, self, "modifier_witch_doctor_voodoo_restoration_handler", {})
	else
		EmitSoundOn("Hero_WitchDoctor.Voodoo_Restoration.Off", caster)
		StopSoundEvent("Hero_WitchDoctor.Voodoo_Restoration.Loop", caster)
		caster:RemoveModifierByName("modifier_witch_doctor_voodoo_restoration_handler")
	end
end

modifier_witch_doctor_voodoo_restoration_handler = class({})
LinkLuaModifier("modifier_witch_doctor_voodoo_restoration_handler", "heroes/hero_witch_doctor/witch_doctor_voodoo_restoration", LUA_MODIFIER_MOTION_NONE)

function modifier_witch_doctor_voodoo_restoration_handler:OnCreated()
	self.interval = self:GetAbility():GetSpecialValueFor("heal_interval")
	self.manaCost = self:GetAbility():GetSpecialValueFor("mana_per_second") / 8
	self.radius = self:GetAbility():GetSpecialValueFor("radius")
	self.self_only_heal_percentage = self:GetAbility():GetSpecialValueFor("self_only_heal_percentage")
	self.enemy_damage_pct = self:GetAbility():GetSpecialValueFor("enemy_damage_pct")
	
	if IsServer() then
		local mainParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_witchdoctor/witchdoctor_voodoo_restoration.vpcf", PATTACH_POINT_FOLLOW, self:GetParent())
			ParticleManager:SetParticleControlEnt(mainParticle, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
			ParticleManager:SetParticleControl(mainParticle, 1, Vector( self.radius, self.radius, self.radius ) )
			ParticleManager:SetParticleControlEnt(mainParticle, 2, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_staff", self:GetParent():GetAbsOrigin(), true)
		self:AddEffect(mainParticle)
		self:StartIntervalThink( 1/8 )
	end
end

function modifier_witch_doctor_voodoo_restoration_handler:OnIntervalThink()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if caster:GetMana() >= self.manaCost then
		caster:SpendMana(self.manaCost, ability)
	else
		ability:ToggleAbility()
	end
end

function modifier_witch_doctor_voodoo_restoration_handler:IsAura()
	return true
end

function modifier_witch_doctor_voodoo_restoration_handler:IsAuraActiveOnDeath()
	return false
end

function modifier_witch_doctor_voodoo_restoration_handler:GetAuraRadius()
	return self.radius
end

function modifier_witch_doctor_voodoo_restoration_handler:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_witch_doctor_voodoo_restoration_handler:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_witch_doctor_voodoo_restoration_handler:GetModifierAura()
	return "modifier_witch_doctor_voodoo_restoration_aura"
end

function modifier_witch_doctor_voodoo_restoration_handler:GetAuraEntityReject( target )
	local caster = self:GetCaster()
	if self.enemy_damage_pct == 0 and not target:IsSameTeam( caster ) then
		return true
	end
	if target == caster then
		return false
	elseif self.self_only_heal_percentage > 0 then
		return target:IsSameTeam( caster )
	end
end

function modifier_witch_doctor_voodoo_restoration_handler:GetAuraDuration()
	return 0.5
end

function modifier_witch_doctor_voodoo_restoration_handler:IsHidden()
	return true
end

function modifier_witch_doctor_voodoo_restoration_handler:IsPurgable()
	return false
end


modifier_witch_doctor_voodoo_restoration_aura = class({})
LinkLuaModifier("modifier_witch_doctor_voodoo_restoration_aura", "heroes/hero_witch_doctor/witch_doctor_voodoo_restoration", LUA_MODIFIER_MOTION_NONE)

function modifier_witch_doctor_voodoo_restoration_aura:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink( self.interval )
	end
end

function modifier_witch_doctor_voodoo_restoration_aura:OnRefresh()
	self.interval = self:GetSpecialValueFor("heal_interval")
	self.heal = self:GetSpecialValueFor("heal") * self.interval
	self.enemy_damage_pct = self:GetAbility():GetSpecialValueFor("enemy_damage_pct") / 100
	self.self_only_heal_percentage = self:GetAbility():GetSpecialValueFor("self_only_heal_percentage") / 100
	
	self.heal_pct = (self:GetSpecialValueFor("heal_pct") * self.interval) / 100
end

function modifier_witch_doctor_voodoo_restoration_aura:OnIntervalThink()
	local parent = self:GetParent()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if parent:IsSameTeam( caster ) then
		parent:HealEvent( (self.heal + parent:GetMaxHealth() * self.heal_pct) * TernaryOperator( self.self_only_heal_percentage, caster == parent and self.self_only_heal_percentage > 0, 1 ), ability, caster)
	elseif self.enemy_damage_pct > 0 then
		ability:DealDamage( caster, parent, self.heal * self.enemy_damage_pct * (1+caster:GetSpellAmplification(false)) + parent:GetMaxHealth() * self.heal_pct * self.enemy_damage_pct , {damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION} )
	end
end