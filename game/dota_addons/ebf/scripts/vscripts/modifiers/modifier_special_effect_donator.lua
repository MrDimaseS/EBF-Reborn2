
if modifier_special_effect_donator == nil then
    modifier_special_effect_donator = class({})
end

function modifier_special_effect_donator:IsHidden()
	return false
end

function modifier_special_effect_donator:IsPurgable() 
	return false 
end

function modifier_special_effect_donator:GetTexture()
    return "terrorblade_metamorphosis"
end

function modifier_special_effect_donator:OnCreated()

	local parent = self:GetParent()
--	local particleName1 = "particles/econ/items/legion/legion_fallen/legion_fallen_press.vpcf"
	local particleName1 = "particles/items_fx/magic_armlet/magic_armlet.vpcf"
	
	local pfx1 = ParticleManager:CreateParticle( particleName1, PATTACH_ABSORIGIN_FOLLOW, parent )
--	ParticleManager:SetParticleControlEnt(pfx1, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
--	ParticleManager:SetParticleControlEnt(pfx1, 2, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
--	ParticleManager:SetParticleControlEnt(pfx1, 3, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)

--	SetParticleControl(pfx1, 0, parent:GetAbsOrigin())
--	SetParticleControl(pfx1, 1, Vector (0,0,0))
--	SetParticleControl(pfx1, 2, Vector (0,0,0))
--	SetParticleControl(pfx1, 3, Vector (0,0,0))

	local particleName2 = "particles/econ/events/ti7/ti7_hero_effect.vpcf"
	local pfx2 = ParticleManager:CreateParticle(particleName2,PATTACH_ABSORIGIN_FOLLOW,parent)
	
--	local pfx2 = ParticleManager:CreateParticle( particleName2, PATTACH_POINT_FOLLOW, parent )
--	ParticleManager:SetParticleControlEnt(pfx2,0,parent,PATTACH_POINT_FOLLOW,'attach_origin',parent:GetAbsOrigin(),true)
	--	ParticleManager:SetParticleControlEnt(pfx1, 5, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)

end

function modifier_special_effect_donator:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_special_effect_donator:AllowIllusionDuplicate()
	return true
end