lycan_howl = class({})

function lycan_howl:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function lycan_howl:OnSpellStart()
    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("radius")
    local duration = self:GetSpecialValueFor("howl_duration")
    local fear_duration = self:GetSpecialValueFor("fear_duration")
    local night_duration = self:GetSpecialValueFor("nighttime_fear_duration")

    local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_lycan/lycan_howl_cast.vpcf", PATTACH_CUSTOMORIGIN, caster)
                ParticleManager:SetParticleControlEnt(nfx, 0 , caster, PATTACH_ABSORIGIN_FOLLOW,  "attach_hitloc", caster:GetAbsOrigin(), true)
                ParticleManager:SetParticleControlEnt(nfx, 1 , caster, PATTACH_POINT_FOLLOW, "attach_mouth", caster:GetAbsOrigin(), true)
    EmitSoundOn("Hero_Lycan.Howl", caster)

    local unit_day = caster:FindAllUnitsInRadius(caster:GetAbsOrigin(), radius)
    local unit_night = caster:FindAllUnitsInRadius(caster:GetAbsOrigin(), 99999)
    if GameRules:IsDaytime() then
        for _, entity in ipairs(unit_day) do
            if not entity:IsSameTeam(caster) then
                entity:AddNewModifier(caster, self, "modifier_lycan_howl_debuff", {duration = fear_duration})
                entity:AddNewModifier(caster, self, "modifier_lycan_howl", {duration = duration})
            else
                if night_duration == 0 then
                    entity:AddNewModifier(caster, self, "modifier_lycan_howl_buff", {duration = duration})
                end
            end
        end
    else
        for _, entity in ipairs(unit_night) do
            if not entity:IsSameTeam(caster) then
                entity:AddNewModifier(caster, self, "modifier_lycan_howl_debuff", {duration = night_duration})
                entity:AddNewModifier(caster, self, "modifier_lycan_howl", {duration = duration})
            else
                if night_duration == 0 then
                    entity:AddNewModifier(caster, self, "modifier_lycan_howl_buff", {duration = duration})
                end
            end
        end
    end
end

modifier_lycan_howl_buff = class({})
LinkLuaModifier("modifier_lycan_howl_buff", "heroes/hero_lycan/lycan_howl", LUA_MODIFIER_MOTION_NONE)

function modifier_lycan_howl_buff:OnCreated()
    if IsServer() then self:SetHasCustomTransmitterData(true) end
    self:OnRefresh()
end

function modifier_lycan_howl_buff:OnRefresh()
    if not IsServer() then return end
    self.barrier_block = self:GetSpecialValueFor("barrier")
    self.aspd = self:GetSpecialValueFor("aspd")
    self:SendBuffRefreshToClients()
end

function modifier_lycan_howl_buff:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
end

function modifier_lycan_howl_buff:GetModifierAttackSpeedBonus_Constant()
    return self.aspd
end

function modifier_lycan_howl_buff:GetModifierIncomingDamageConstant(params)
    if IsServer() then
		local barrier_block = math.min( self.barrier_block, math.max( self.barrier_block, params.damage ) )
		self.barrier_block = self.barrier_block - params.damage
		if self.barrier_block <= 0 then
			self:Destroy()
			return
		end
		self:SendBuffRefreshToClients()
		return -barrier_block
	else
		return self.barrier_block
	end
end

function modifier_lycan_howl_buff:AddCustomTransmitterData()
    return {barrier_block = self.barrier_block}
end

function modifier_lycan_howl_buff:HandleCustomTransmitterData(data)
    self.barrier_block = data.barrier_block
end

modifier_lycan_howl_debuff = class({})
LinkLuaModifier("modifier_lycan_howl_debuff", "heroes/hero_lycan/lycan_howl", LUA_MODIFIER_MOTION_NONE)

function modifier_lycan_howl_debuff:CheckState()
	return {[MODIFIER_STATE_FEARED] = true,
			[MODIFIER_STATE_DISARMED] = true,
			[MODIFIER_STATE_SILENCED] = true,
			[MODIFIER_STATE_MUTED] = true,
			[MODIFIER_STATE_COMMAND_RESTRICTED] = true,}
end

function modifier_lycan_howl_debuff:GetStatusEffectName()
    return "particles/status_fx/status_effect_dark_willow_wisp_fear.vpcf"
end