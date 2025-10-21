morphling_accumulation = class({})

--this is just the 25 talent's code

function morphling_accumulation:Precache(context)
    PrecacheResource("particle", "particles/econ/items/juggernaut/jugg_fortunes_tout/jugg_healing_ward_fortunes_tout_ward_edge_magic.vpcf", context)
    PrecacheResource("particle", "particles/items_fx/black_king_bar_avatar.vpcf", context)
    PrecacheResource("particle", "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_ambient.vpcf", context)
end

function morphling_accumulation:GetIntrinsicModifierName()
    return "modifier_morphling_surge"
end

function morphling_accumulation:GetAbilityTextureName()
    return "morphling_surge"
end

modifier_morphling_surge = class({})
LinkLuaModifier("modifier_morphling_surge", "heroes/hero_morphling/morphling_accumulation", LUA_MODIFIER_MOTION_NONE)

function modifier_morphling_surge:IsHidden()
    return true
end

function modifier_morphling_surge:OnCreated()
    self:StartIntervalThink(0.1)
end

function modifier_morphling_surge:OnIntervalThink()
	if IsServer() then
    	local base_attack_time = self:GetSpecialValueFor("morph_agi_bat")
	    local debuff_immune = self:GetSpecialValueFor("morph_str_debuff_immune")
	    local total_dmg_bonus = self:GetSpecialValueFor("morph_uni_total_dmg_bonus")

		local parent = self:GetParent()
		local baseStr = parent:GetBaseStrength()
		local baseAgi = parent:GetBaseAgility()
		local statBalance = (math.floor(baseStr + baseAgi) / 2) * 0.75 --hehe
        
		if baseStr == 1 and base_attack_time ~= 0 then
			parent:AddNewModifier(parent, self:GetAbility(), "modifier_morphling_surge_agi")
        else
            parent:RemoveModifierByName("modifier_morphling_surge_agi")
		end

        if baseAgi == 1 and debuff_immune ~= 0 then
            parent:AddNewModifier(parent, self:GetAbility(), "modifier_morphling_surge_str")
        else
            parent:RemoveModifierByName("modifier_morphling_surge_str")
        end

		if baseStr > statBalance and baseAgi > statBalance and total_dmg_bonus ~= 0 then
            parent:AddNewModifier(parent, self:GetAbility(), "modifier_morphling_surge_uni")
        else
            parent:RemoveModifierByName("modifier_morphling_surge_uni")
		end
	end
end

function modifier_morphling_surge:GetTexture()
    return "morphling_surge"
end

modifier_morphling_surge_agi = class({})
LinkLuaModifier("modifier_morphling_surge_agi", "heroes/hero_morphling/morphling_accumulation", LUA_MODIFIER_MOTION_NONE)

function modifier_morphling_surge_agi:IsDebuff()
    return false
end

function modifier_morphling_surge_agi:OnCreated()
    if IsServer() then
        self.base_bat = self:GetParent():GetBaseAttackTime()
        self.bat = self:GetSpecialValueFor("morph_agi_bat")
        self:GetParent():SetBaseAttackTime(self.bat)
    end
end

function modifier_morphling_surge_agi:GetEffectName()
    return "particles/econ/items/juggernaut/jugg_fortunes_tout/jugg_healing_ward_fortunes_tout_ward_edge_magic.vpcf"
end

function modifier_morphling_surge_agi:OnRemoved()
    if IsServer() then
        self:GetParent():SetBaseAttackTime(self.base_bat)
    end
end

modifier_morphling_surge_str = class({})
LinkLuaModifier("modifier_morphling_surge_str", "heroes/hero_morphling/morphling_accumulation", LUA_MODIFIER_MOTION_NONE)

function modifier_morphling_surge_str:CheckState()
    return
    {
        [MODIFIER_STATE_DEBUFF_IMMUNE] = true,
    }
end

function modifier_morphling_surge_str:OnCreated()
    if IsServer() then
        self.nfx = ParticleManager:CreateParticle("particles/items_fx/black_king_bar_avatar.vpcf", PATTACH_CUSTOMORIGIN, self:GetParent())
                   ParticleManager:SetParticleControlEnt(self.nfx, 0 , self:GetParent(), PATTACH_POINT_FOLLOW, "attach_base", self:GetParent():GetAbsOrigin(), true)
                   self:AttachEffect(self.nfx)
    end
end

function modifier_morphling_surge_str:OnRemoved()
    if IsServer() then
        ParticleManager:DestroyParticle(self.nfx, false)
    end
end

modifier_morphling_surge_uni = class({})
LinkLuaModifier("modifier_morphling_surge_uni", "heroes/hero_morphling/morphling_accumulation", LUA_MODIFIER_MOTION_NONE)
function modifier_morphling_surge_uni:OnCreated()
    if IsServer() then
        self.total_dmg_amp = self:GetSpecialValueFor("morph_uni_total_dmg_bonus")
    end
end

function modifier_morphling_surge_uni:DeclareFunctions()
    return {MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE, MODIFIER_PROPERTY_TOOLTIP}
end

function modifier_morphling_surge_uni:OnTooltip()
    return self.total_dmg_amp
end

function modifier_morphling_surge_uni:GetModifierTotalDamageOutgoing_Percentage()
    return self.total_dmg_amp
end

function modifier_morphling_surge_uni:GetEffectName()
    return "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_ambient.vpcf"
end

function modifier_morphling_surge_uni:GetTexture()
    return "morphling_surge"
end