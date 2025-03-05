pudge_dismember = class({})
LinkLuaModifier( "modifier_pudge_dismember", "heroes/hero_pudge/pudge_dismember.lua" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_pudge_dismember_armor", "heroes/hero_pudge/pudge_dismember.lua" ,LUA_MODIFIER_MOTION_NONE )

function pudge_dismember:GetConceptRecipientType()
	return DOTA_SPEECH_USER_ALL
end

function pudge_dismember:SpeakTrigger()
	return DOTA_ABILITY_SPEAK_CAST
end

function pudge_dismember:GetChannelTime()
	return self:GetSpecialValueFor( "duration" )
end

function pudge_dismember:GetChannelAnimation()
	return ACT_DOTA_CHANNEL_ABILITY_4
end

function pudge_dismember:GetAOERadius()
	return self:GetSpecialValueFor("aoe_radius")
end

function pudge_dismember:GetBehavior()
	if self:GetSpecialValueFor("aoe_radius") > 0  then
		return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_CHANNELLED + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING + DOTA_ABILITY_BEHAVIOR_AOE
	else
		return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_CHANNELLED + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING
	end
end

function pudge_dismember:OnSpellStart()
	local caster = self:GetCaster()

	if caster:HasTalent("special_bonus_unique_pudge_dismember_2") then
		caster:AddNewModifier(caster, self, "modifier_pudge_dismember_armor", {Duration = self:GetSpecialValueFor("duration")})
	end

	ParticleManager:FireParticle("particles/units/heroes/hero_pudge/pudge_dismember.vpcf", PATTACH_POINT_FOLLOW, caster, {[0]="attach_attack1"})
	ParticleManager:FireParticle("particles/units/heroes/hero_pudge/pudge_dismember.vpcf", PATTACH_POINT_FOLLOW, caster, {[0]="attach_attack2"})

	self.counter = 0
end

function pudge_dismember:OnChannelThink(flInterval)
	local caster = self:GetCaster()
	local endPoint = caster:GetAbsOrigin() + caster:GetForwardVector() * self:GetTrueCastRange()
	local speed = self:GetSpecialValueFor("speed")*flInterval
	self.counter = self.counter + flInterval
	local enemies = caster:FindEnemyUnitsInLine(caster:GetAbsOrigin(), endPoint, self:GetSpecialValueFor("width"), {})
	for _,enemy in pairs(enemies) do
		if CalculateDistance(enemy, caster) > caster:GetAttackRange() then
			enemy:SetAbsOrigin(enemy:GetAbsOrigin() - CalculateDirection(enemy, caster) * speed)
		end
	end

	if self.counter > 0.25 then
		EmitSoundOn("Hero_Pudge.Dismember", caster)
		EmitSoundOn("Hero_Pudge.DismemberSwings", caster)
		ParticleManager:FireParticle("particles/units/heroes/hero_pudge/pudge_dismember.vpcf", PATTACH_POINT_FOLLOW, caster, {[0]="attach_attack1"})
		ParticleManager:FireParticle("particles/units/heroes/hero_pudge/pudge_dismember.vpcf", PATTACH_POINT_FOLLOW, caster, {[0]="attach_attack2"})
			
		local enemies = caster:FindEnemyUnitsInLine(caster:GetAbsOrigin(), endPoint, self:GetSpecialValueFor("width"), {})
		for _,enemy in pairs(enemies) do
			if not enemy:TriggerSpellAbsorb( self ) then
				if not enemy:HasModifier("modifier_pudge_dismember") then
					enemy:AddNewModifier(caster, self, "modifier_pudge_dismember", {duration = self:GetSpecialValueFor("duration")})
				end
				local damage = self:GetSpecialValueFor("damage") + self:GetSpecialValueFor("str_damage")/100 * caster:GetStrength()
				damage = damage * 0.25
				caster:Lifesteal(self, self:GetSpecialValueFor("heal_pct"), damage, enemy, self:GetAbilityDamageType(), DOTA_LIFESTEAL_SOURCE_ABILITY, false)
				self.enemyCheck = true
			end
		end

		self.counter = 0
	end
end

modifier_pudge_dismember = class({})

function modifier_pudge_dismember:OnCreated(table)
	if IsServer() then
		self.nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_pudge/pudge_dismember_chain.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster())
		ParticleManager:SetParticleAlwaysSimulate(self.nfx)
		ParticleManager:SetParticleControlEnt(self.nfx, 3, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetCaster():GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(self.nfx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
		self:StartIntervalThink( 0.33 )
	end
end

function modifier_pudge_dismember:OnIntervalThink()
	if not self:GetCaster():IsChanneling() then
		self:Destroy()
	end
end

function modifier_pudge_dismember:OnRemoved()
	if IsServer() then
		ParticleManager:ClearParticle(self.nfx)
	end
end

function modifier_pudge_dismember:IsDebuff()
	return true
end

function modifier_pudge_dismember:IsStunDebuff()
	return true
end

function modifier_pudge_dismember:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_INVISIBLE] = false,
	}

	return state
end

function modifier_pudge_dismember:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}

	return funcs
end

function modifier_pudge_dismember:GetOverrideAnimation( params )
	return ACT_DOTA_FLAIL
end

function modifier_pudge_dismember:GetEffectName()
	return "particles/units/heroes/hero_bloodseeker/bloodseeker_rupture.vpcf"
end

modifier_pudge_dismember_armor = class({})


function modifier_pudge_dismember:OnCreated(table)
	if IsServer() then
		self:StartIntervalThink( 0.33 )
	end
end

function modifier_pudge_dismember:OnIntervalThink()
	if not self:GetCaster():IsChanneling() then
		self:Destroy()
	end
end

function modifier_pudge_dismember_armor:IsDebuff()
	return false
end

function modifier_pudge_dismember_armor:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
	}

	return funcs
end

function modifier_pudge_dismember_armor:GetModifierPhysicalArmorBonus()
	return self:GetCaster():FindTalentValue("special_bonus_unique_pudge_dismember_2")
end

function modifier_pudge_dismember_armor:GetEffectName()
	return "particles/units/heroes/hero_bloodseeker/bloodseeker_rupture.vpcf"
end