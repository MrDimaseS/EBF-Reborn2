boss_axe_berserkers_call = class({})

function boss_axe_berserkers_call:OnSpellStart()
	local caster = self:GetCaster()
	
	EmitSoundOn("Hero_Axe.Berserkers_Call", caster)

	local nfx = ParticleManager:FireParticle("particles/units/heroes/hero_axe/axe_beserkers_call_owner.vpcf", PATTACH_POINT_FOLLOW, caster, {[0] = caster:GetAbsOrigin(), [1] = "attach_mouth", [2] = Vector(self:GetTalentSpecialValueFor("radius"),0,0)})
	
	local battleHunger = caster:FindAbilityByName("boss_axe_battle_hunger")
	for _, unit in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self:GetSpecialValueFor("radius") ) ) do
		unit:AddNewModifier( caster, battleHunger, "modifier_boss_axe_battle_hunger", {duration = self:GetSpecialValueFor("duration")} )
	end
end