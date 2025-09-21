chaos_knight_reality_rift = class{}
function chaos_knight_reality_rift:OnAbilityPhaseStart()
    self.caster = self:GetCaster()
	self.target = self:GetCursorTarget()

	local casterPos = self.caster:GetAbsOrigin()
	local targetPos = self.target:GetAbsOrigin()
	local vDir = CalculateDirection( targetPos, casterPos )
	self.endPos = casterPos + vDir * CalculateDistance(targetPos, casterPos) * RandomFloat(0.3, 0.7)
	EmitSoundOn("Hero_ChaosKnight.RealityRift", self.caster)


	self.FX = {}
	local oRiftFX = ParticleManager:CreateParticle("particles/units/heroes/hero_chaos_knight/chaos_knight_reality_rift.vpcf", PATTACH_CUSTOMORIGIN, self.target)
	ParticleManager:SetParticleControlEnt(oRiftFX, 0, self.caster, PATTACH_POINT_FOLLOW, "attach_hitloc", casterPos, true)
	ParticleManager:SetParticleControlEnt(oRiftFX, 1, self.target, PATTACH_POINT_FOLLOW, "attach_hitloc", targetPos, true)
	ParticleManager:SetParticleControl(oRiftFX, 2, self.endPos)
	ParticleManager:SetParticleControlOrientation(oRiftFX, 2, vDir, Vector(0,1,0), Vector(1,0,0))
	table.insert(self.FX, oRiftFX)

	local searchRadius = self:GetSpecialValueFor("illusion_search_radius")
	self.illusions = self.caster:FindFriendlyUnitsInRadius(self.caster:GetAbsOrigin(), searchRadius, {flag = DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED})
	for _, illusion in ipairs( self.illusions ) do
		if self.caster ~= illusion and illusion:IsIllusion() and illusion:GetPlayerOwnerID() == self.caster:GetPlayerOwnerID() then
			local iRiftFX = ParticleManager:CreateParticle("particles/units/heroes/hero_chaos_knight/chaos_knight_reality_rift.vpcf", PATTACH_CUSTOMORIGIN, self.target)
			ParticleManager:SetParticleControlEnt(iRiftFX, 0, illusion, PATTACH_POINT_FOLLOW, "attach_hitloc", illusion:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(iRiftFX, 1, self.target, PATTACH_POINT_FOLLOW, "attach_hitloc", targetPos, true)
			ParticleManager:SetParticleControl(iRiftFX, 2, self.endPos)
			ParticleManager:SetParticleControlOrientation(iRiftFX, 2, vDir, Vector(0,1,0), Vector(1,0,0))
			table.insert(self.FX, iRiftFX)
		end
	end
    return true
end

function chaos_knight_reality_rift:OnSpellStart()
    for _, fx in ipairs(self.FX) do
		ParticleManager:ReleaseParticleIndex(fx)
	end

	local duration = self:GetSpecialValueFor("debuff_dur")
	if self.target:TriggerSpellAbsorb( self ) then return end
	FindClearSpaceForUnit(self.caster, self.endPos, true)
	FindClearSpaceForUnit(self.target, self.endPos, true)

	local vDir = CalculateDirection(self.caster, self.target)

	self.caster:FaceTowards(self.target:GetAbsOrigin())
	self.target:FaceTowards(self.caster:GetAbsOrigin())

	self.caster:MoveToTargetToAttack(self.target)
	self.target:AddNewModifier(self.caster, self, "modifier_chaos_knight_reality_rift_ebf_debuff", {duration = duration})

	------------------------------------------------------------------------------------------------------------------
    local illusion_extension = self:GetSpecialValueFor("illusion_extension")
    local creates_illu = self:GetSpecialValueFor("creates_illusion")

    if creates_illu > 0 then
	    for _, illusion in ipairs( self.illusions ) do
		    if self.caster ~= illusion and illusion:IsIllusion() and illusion:GetPlayerOwnerID() == self.caster:GetPlayerOwnerID() then
                FindClearRandomPositionAroundUnit(illusion, self.target, 20)
			    illusion:MoveToTargetToAttack(self.target)

                local illuModifier = illusion:FindModifierByName("modifier_illusion")
                illuModifier:SetDuration(illuModifier:GetRemainingTime() + illusion_extension, true)
            end
        end
	end

    ------------------------------------------------------------------------------------------------------------------
    local extra_debuff_chance1 = self:GetSpecialValueFor("extra_debuff_chance")
    local extra_debuff_chance2 = extra_debuff_chance1

    if extra_debuff_chance1 > 0 then
        local extra_debuff_dur = self:GetSpecialValueFor("extra_debuff_duration")
        if extra_debuff_chance1 < 100 and RollPercentage(extra_debuff_chance1) then
            if RollPercentage(extra_debuff_chance2) then
                self:Silence(self.target, extra_debuff_dur)
            else
                self:Disarm(self.target, extra_debuff_dur)
            end
        else
            if extra_debuff_chance1 == 100 then
                self:Silence(self.target, extra_debuff_dur)
                self:Disarm(self.target, extra_debuff_dur)
            end
        end
    end
end

modifier_chaos_knight_reality_rift_ebf_debuff = class({})
LinkLuaModifier("modifier_chaos_knight_reality_rift_ebf_debuff", "heroes/hero_chaos_knight/chaos_knight_reality_rift", LUA_MODIFIER_MOTION_NONE)

function modifier_chaos_knight_reality_rift_ebf_debuff:OnCreated()
    return self:OnRefresh()
end

function modifier_chaos_knight_reality_rift_ebf_debuff:OnRefresh()
   self.armor_reduction = self:GetSpecialValueFor("armor_red")
end

function modifier_chaos_knight_reality_rift_ebf_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    }
end

function modifier_chaos_knight_reality_rift_ebf_debuff:GetModifierPhysicalArmorBonus()
    return -self.armor_reduction
end
function modifier_chaos_knight_reality_rift_ebf_debuff:IsDebuff()
    return true
end
function modifier_chaos_knight_reality_rift_ebf_debuff:IsPurgable()
    return true
end