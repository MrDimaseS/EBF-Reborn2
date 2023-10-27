visage_summon_familiars = class({})
LinkLuaModifier( "modifier_visage_summon_familiars", "heroes/hero_visage/visage_summon_familiars.lua" ,LUA_MODIFIER_MOTION_NONE )

function visage_summon_familiars:IsStealable()
    return false
end

function visage_summon_familiars:IsHiddenWhenStolen()
    return false
end

function visage_summon_familiars:OnSpellStart()
	local caster = self:GetCaster()
	
	local totalCount = self:GetSpecialValueFor("familiar_count")
	local health = self:GetSpecialValueFor("familiar_hp")
	local damage = self:GetSpecialValueFor("familiar_attack_damage")
	local armor = self:GetSpecialValueFor("familiar_armor")
	local magic_resist = self:GetSpecialValueFor("familiar_mr")
	local speed = self:GetSpecialValueFor("familiar_speed")

	EmitSoundOn("Hero_Visage.SummonFamiliars.Cast", caster)

	local units = caster:FindAllUnitsInRadius(caster:GetAbsOrigin(), FIND_UNITS_EVERYWHERE, {flag = DOTA_UNIT_TARGET_FLAG_INVULNERABLE })
	for _,unit in pairs(units) do
		if unit:GetOwner() == caster and unit:GetUnitLabel() == "visage_familiars" then
			unit:ForceKill(false)
		end
	end

	for i=1,totalCount do
		local familiar = caster:CreateSummon("npc_dota_visage_familiar1", caster:GetAbsOrigin() + caster:GetForwardVector() * 128 + 96 * caster:GetLeftVector() * math.floor( (1+i-totalCount%2)/2 ) * (-1)^i )
		
		local stone = familiar:FindAbilityByName( "visage_summon_familiars_stone_form" )
		if stone then
			stone:SetLevel( self:GetLevel() )
		end
		familiar.visage = caster
		familiar:AddNewModifier( caster, self, "modifier_visage_summon_familiars_damage_charge", {} )
		familiar:AddNewModifier( caster, self, "modifier_visage_summon_familiars_talents", {} )

		familiar:SetCoreHealth(health)
		familiar:SetPhysicalArmorBaseValue(armor)
		familiar:SetBaseMoveSpeed(speed)
		familiar:SetAverageBaseDamage(damage, 20)

		FindClearSpaceForUnit(familiar, familiar:GetAbsOrigin(), false)
		ParticleManager:FireParticle("particles/units/heroes/hero_visage/visage_summon_familiars.vpcf", PATTACH_POINT, caster, {[0]=familiar:GetAbsOrigin()})
	end
	
	local stone_form = caster:FindAbilityByName("visage_stone_form_self_cast")
	if stone_form then
		stone_form:SetActivated( true )
	end
end