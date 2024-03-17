visage_summon_familiars = class({})
LinkLuaModifier( "modifier_visage_summon_familiars", "heroes/hero_visage/visage_summon_familiars.lua" ,LUA_MODIFIER_MOTION_NONE )

function visage_summon_familiars:IsStealable()
    return false
end

function visage_summon_familiars:IsHiddenWhenStolen()
    return false
end

function visage_summon_familiars:Spawn()
	if IsServer() then PrecacheUnitByNameAsync( "npc_dota_visage_familiar1", function() print("precache done", self:GetCaster():GetPlayerID()) end ) end
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
		local position =  caster:GetAbsOrigin() + caster:GetForwardVector() * 128 + 96 * caster:GetLeftVector() * math.floor( (1+i-totalCount%2)/2 ) * (-1)^i
		CreateUnitByNameAsync( "npc_dota_visage_familiar1", position, true, nil, nil, caster:GetTeam(), function(familiar)
			print("1")
			familiar:SetControllableByPlayer(caster:GetPlayerID(), true)
			print("2")
			familiar:SetOwner(caster)
			print("3")
			familiar:StartGesture( ACT_DOTA_SPAWN )
			print("4")
			
			local stone = familiar:FindAbilityByName( "visage_summon_familiars_stone_form" )
			print("5")
			if stone then
				stone:SetLevel( self:GetLevel() )
			print("6")
			end
			familiar.visage = caster
			print("7")
			familiar:AddNewModifier( caster, self, "modifier_visage_summon_familiars_damage_charge", {} )
			print("8")
			familiar:AddNewModifier( caster, self, "modifier_visage_summon_familiars_talents", {} )
			print("9")
			familiar:AddNewModifier( caster, self, "modifier_generic_level_scaling_for_summons", {} )

			familiar:SetCoreHealth(health)
			print("10")
			familiar:SetPhysicalArmorBaseValue(armor)
			print("11")
			familiar:SetBaseMoveSpeed(speed)
			print("12")
			familiar:SetAverageBaseDamage(damage, 20)
			print("13")

			FindClearSpaceForUnit(familiar, familiar:GetAbsOrigin(), false)
			print("14")
			ParticleManager:FireParticle("particles/units/heroes/hero_visage/visage_summon_familiars.vpcf", PATTACH_POINT, caster, {[0]=familiar:GetAbsOrigin()})
			print("15")
		end)
	end
	
	local stone_form = caster:FindAbilityByName("visage_stone_form_self_cast")
	if stone_form then
		stone_form:SetActivated( true )
	end
end