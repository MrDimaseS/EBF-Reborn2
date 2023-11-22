life_stealer_rage = class({})

function life_stealer_rage:GetCastRange( target, position )
	return self:GetSpecialValueFor("cast_range")
end

function life_stealer_rage:OnSpellStart()
    local caster = self:GetCaster()
	
	if caster:HasModifier("modifier_life_stealer_rage_active") then
		caster:RemoveModifierByName("modifier_life_stealer_rage_active")
	else
		caster:StartGesture(ACT_DOTA_LIFESTEALER_RAGE)
		caster:EmitSound("Hero_LifeStealer.Rage")
		
		local duration = self:GetSpecialValueFor("duration")
		caster:AddNewModifier(caster, self, "modifier_life_stealer_rage_active", {Duration = duration})
		caster:Dispel(caster, true)
		self:SetCooldown(0.25)
		-- infest management
		-- if caster:HasModifier("modifier_life_stealer_infest") then
			-- local modifier = caster:FindModifierByName("modifier_lifestealer_infest_bh")
			-- if modifier then
				-- local target = modifier.target
				-- if target and target:IsSameTeam( caster ) then
					-- target:AddNewModifier(caster, self, "modifier_life_stealer_rage_active", {Duration = duration})
				-- end
			-- end
		-- end
	end
    
end

modifier_life_stealer_rage_active = class({})
LinkLuaModifier( "modifier_life_stealer_rage_active", "heroes/hero_lifestealer/life_stealer_rage.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_life_stealer_rage_active:OnCreated(table)
	self:OnRefresh()
	if IsServer() then
		local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_life_stealer/life_stealer_rage.vpcf", PATTACH_POINT_FOLLOW, self:GetParent())
					ParticleManager:SetParticleControlEnt(nfx, 2, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloch", self:GetParent():GetAbsOrigin(), true)
		self:AttachEffect(nfx)
	end
end

function modifier_life_stealer_rage_active:OnRefresh()
	self.ms = self:GetSpecialValueFor("movement_speed_bonus")
	self.armor = self:GetSpecialValueFor("bonus_armor")
	self.bonus_magic_resist = self:GetSpecialValueFor("bonus_magic_resist")
end

function modifier_life_stealer_rage_active:OnDestroy()
	if IsServer() then
		self:GetAbility():SetCooldown()
	end
end

function modifier_life_stealer_rage_active:DeclareFunctions()
    return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
             MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			 MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS}
end

function modifier_life_stealer_rage_active:CheckState()
    local state = { [MODIFIER_STATE_DEBUFF_IMMUNE] = true}
    return state
end

function modifier_life_stealer_rage_active:GetModifierMagicalResistanceBonus()
    return self.bonus_magic_resist
end

function modifier_life_stealer_rage_active:GetModifierMoveSpeedBonus_Percentage()
    return self.ms
end

function modifier_life_stealer_rage_active:GetModifierPhysicalArmorBonus()
    return self.armor
end

function modifier_life_stealer_rage_active:IsHidden()
    return false
end

function modifier_life_stealer_rage_active:IsDebuff()
    return false
end

function modifier_life_stealer_rage_active:GetStatusEffectName()
    return "particles/status_fx/status_effect_life_stealer_rage.vpcf"
end

function modifier_life_stealer_rage_active:StatusEffectPriority()
    return 10
end