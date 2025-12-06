winter_wyvern_winters_curse = class({})

function winter_wyvern_winters_curse:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local duration = self:GetSpecialValueFor("duration")
    local radius = self:GetSpecialValueFor("radius")

    if target:TriggerSpellAbsorb(self) then return end
    target:AddNewModifier(caster, self, "modifier_winter_wyvern_winters_curse_freeze", {duration = duration})

    local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_winter_wyvern/wyvern_winters_curse_ground.vpcf", PATTACH_ABSORIGIN, target)
                ParticleManager:SetParticleControl(nfx, 2, Vector(radius, 1, 1))

    EmitSoundOn("Hero_Winter_Wyvern.WintersCurse.Cast", caster)
    EmitSoundOn("Hero_Winter_Wyvern.WintersCurse.Target", target)
end

modifier_winter_wyvern_winters_curse_freeze = class({})
LinkLuaModifier("modifier_winter_wyvern_winters_curse_freeze", "heroes/hero_winter_wyvern/winter_wyvern_winters_curse", LUA_MODIFIER_MOTION_NONE)

function modifier_winter_wyvern_winters_curse_freeze:OnCreated()
    self.parent = self:GetParent()
    self.radius = self:GetSpecialValueFor("radius")
    self.damage_reduction = self:GetSpecialValueFor("damage_reduction")
    self.damage_amplification = self:GetSpecialValueFor("damage_amplification")
    self.affects_allies = self:GetSpecialValueFor("affects_allies") == 1
    self.nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_winter_wyvern/wyvern_winters_curse.vpcf", PATTACH_ABSORIGIN, self.parent)
               ParticleManager:SetParticleControl(self.nfx, 2, Vector(1, 1, self.radius))
    self.overhead = ParticleManager:CreateParticle("particles/units/heroes/hero_winter_wyvern/wyvern_winters_curse_overhead.vpcf", PATTACH_OVERHEAD_FOLLOW, self.parent)
end

function modifier_winter_wyvern_winters_curse_freeze:OnDestroy()
    ParticleManager:DestroyParticle(self.nfx, false)
    ParticleManager:DestroyParticle(self.overhead, false)
end

function modifier_winter_wyvern_winters_curse_freeze:CheckState()
    return
    {
        [MODIFIER_STATE_INVISIBLE] = false,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_FROZEN] = true,
        [MODIFIER_STATE_SPECIALLY_DENIABLE] = true
    }
end

function modifier_winter_wyvern_winters_curse_freeze:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_RECORD, MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end

function modifier_winter_wyvern_winters_curse_freeze:OnAttackRecord( params )
	local parent = self:GetParent()
	if params.target ~= parent then return end
	local caster = self:GetCaster()
	if not (params.target:IsSameTeam( params.attacker ) or params.attacker == caster or self.affects_allies) then return end
	params.attacker:AddNewModifier( caster, self:GetAbility(), "modifier_winter_wyvern_winters_curse_attack_speed", {duration = self:GetRemainingTime()} )
end

function modifier_winter_wyvern_winters_curse_freeze:GetModifierIncomingDamage_Percentage( params )
	if params.damage <= 0 then return end
	if params.target:IsSameTeam( params.attacker ) then return end
	if params.attacker == caster or self.affects_allies then
		if params.inflictor then
			return self.damage_amplification
		else return end
	else
		return self.damage_reduction
	end
end

function modifier_winter_wyvern_winters_curse_freeze:IsAura()
    return true
end

function modifier_winter_wyvern_winters_curse_freeze:GetAuraRadius()
    return self.radius
end

function modifier_winter_wyvern_winters_curse_freeze:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_winter_wyvern_winters_curse_freeze:GetAuraSearchType()
	return DOTA_UNIT_TARGET_ALL
end

function modifier_winter_wyvern_winters_curse_freeze:GetModifierAura()
    return "modifier_winter_wyvern_winters_curse_taunt"
end

modifier_winter_wyvern_winters_curse_attack_speed = class({})
LinkLuaModifier("modifier_winter_wyvern_winters_curse_attack_speed", "heroes/hero_winter_wyvern/winter_wyvern_winters_curse", LUA_MODIFIER_MOTION_NONE)

function modifier_winter_wyvern_winters_curse_attack_speed:OnCreated()
	if self:GetParent():IsSameTeam( self:GetCaster() ) then
		self.bonus_attack_speed = self:GetSpecialValueFor("attack_speed_wyvern")
	else
		self.bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
	end
end

function modifier_winter_wyvern_winters_curse_attack_speed:DeclareFunctions()
    return {MODIFIER_EVENT_ON_ATTACK_RECORD, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT}
end

function modifier_winter_wyvern_winters_curse_attack_speed:OnAttackRecord( params )
	if params.target:HasModifier("modifier_winter_wyvern_winters_curse_freeze") then return end
	self:Destroy()
end

function modifier_winter_wyvern_winters_curse_attack_speed:GetModifierAttackSpeedBonus_Constant()
    return self.bonus_attack_speed
end

modifier_winter_wyvern_winters_curse_taunt = class({})
LinkLuaModifier("modifier_winter_wyvern_winters_curse_taunt", "heroes/hero_winter_wyvern/winter_wyvern_winters_curse", LUA_MODIFIER_MOTION_NONE)

function modifier_winter_wyvern_winters_curse_taunt:OnCreated()
	self.radius = self:GetSpecialValueFor("radius")
	self.bonus_duration = TernaryOperator( self:GetSpecialValueFor("bonus_duration_per_hero"), self:GetParent():IsChampion(), self:GetSpecialValueFor("bonus_duration_per_creep") )
    if IsServer() then
		local parent = self:GetParent()
		local caster = self:GetCaster()
        local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_winter_wyvern/wyvern_winters_curse_buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
        self:AddEffect(nfx)
		
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( parent:GetAbsOrigin(), self.radius, {order = FIND_CLOSEST} ) ) do
			if enemy:HasModifier("modifier_winter_wyvern_winters_curse_freeze") then
				self.taunt_target = enemy
				parent:MoveToTargetToAttack(self.taunt_target)
				parent:SetAttacking(self.taunt_target)
				
				if self.bonus_duration > 0 then
					local modifier = enemy:FindModifierByName("modifier_winter_wyvern_winters_curse_freeze")
					modifier:SetDuration( modifier:GetDuration() + self.bonus_duration * ( 1-enemy:GetStatusResistance( ) ), true )
				end

				ExecuteOrderFromTable({
					UnitIndex = parent:entindex(),
					OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
					TargetIndex = self.taunt_target:entindex()
				})
				break
			end
		end
    end
end

function modifier_winter_wyvern_winters_curse_taunt:CheckState()
    if IsServer() then
        return
        {
            [MODIFIER_STATE_TAUNTED] = true,
            [MODIFIER_STATE_SILENCED] = true,
            [MODIFIER_STATE_MUTED] = true,
            [MODIFIER_STATE_COMMAND_RESTRICTED] = true
        }
    end
end
