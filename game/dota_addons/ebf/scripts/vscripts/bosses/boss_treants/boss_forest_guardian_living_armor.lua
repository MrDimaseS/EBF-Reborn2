boss_forest_guardian_living_armor = class({})

function boss_forest_guardian_living_armor:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
	
	for _, ally in ipairs( caster:FindFriendlyUnitsInRadius( caster:GetAbsOrigin(), self:GetSpecialValueFor("radius") ) ) do
		self:ApplyLivingArmor(ally)
	end
	caster:EmitSound("Hero_Treant.LivingArmor.Cast")
end

function boss_forest_guardian_living_armor:ApplyLivingArmor(target, duration)
	local caster = self:GetCaster()
	local bDur = duration or self:GetTalentSpecialValueFor("duration")
	target:AddNewModifier( caster, self, "modifier_boss_forest_guardian_living_armor", {duration = bDur})
	target:EmitSound("Hero_Treant.LivingArmor.Target")
end

modifier_boss_forest_guardian_living_armor = class({})
LinkLuaModifier( "modifier_boss_forest_guardian_living_armor", "bosses/boss_treants/boss_forest_guardian_living_armor", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_forest_guardian_living_armor:OnCreated()
	self:OnRefresh()
	if IsServer() then
		local target = self:GetParent()
		local treeFX = ParticleManager:CreateParticle("particles/units/heroes/hero_treant/treant_livingarmor.vpcf", PATTACH_POINT_FOLLOW, target)
		ParticleManager:SetParticleControlEnt(treeFX, 0, target, PATTACH_POINT_FOLLOW, "attach_feet", target:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(treeFX, 1, target, PATTACH_POINT_FOLLOW, "attach_feet", target:GetAbsOrigin(), true)
		self:AddEffect(treeFX)
	end
end

function modifier_boss_forest_guardian_living_armor:OnRefresh()
	self.regen = self:GetTalentSpecialValueFor("health_regen")
	self.armor = self:GetTalentSpecialValueFor("bonus_armor")
end

function modifier_boss_forest_guardian_living_armor:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS}
end

function modifier_boss_forest_guardian_living_armor:GetModifierConstantHealthRegen()
	return self.regen
end

function modifier_boss_forest_guardian_living_armor:GetModifierPhysicalArmorBonus()
	return self.armor
end

function modifier_boss_forest_guardian_living_armor:GetModifierHealAmplify_Percentage()
	return self.healAmp
end