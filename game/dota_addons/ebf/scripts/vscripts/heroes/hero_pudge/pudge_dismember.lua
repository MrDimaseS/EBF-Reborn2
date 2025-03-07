pudge_dismember = class({})

function pudge_dismember:GetConceptRecipientType()
	return DOTA_SPEECH_USER_ALL
end

function pudge_dismember:SpeakTrigger()
	return DOTA_ABILITY_SPEAK_CAST
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
	
	local aoe_radius = self:GetSpecialValueFor("aoe_radius")
	local duration = self:GetSpecialValueFor("AbilityChannelTime")
	self.targets = {}
	if aoe_radius > 0 then
		local position = self:GetCursorPosition()
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( position, aoe_radius ) ) do
			enemy:AddNewModifier( caster, self, "modifier_pudge_dismember_channeled", {duration = duration })
			table.insert( self.targets, enemy )
		end
	else
		local target = self:GetCursorTarget()
		target:AddNewModifier( caster, self, "modifier_pudge_dismember_channeled", {duration = duration })
		table.insert( self.targets, target )
	end
end

function pudge_dismember:OnChannelThink( dt )
	local caster = self:GetCaster()
	
	local pull_distance_limit = self:GetSpecialValueFor("pull_distance_limit")
	local pull_units_per_second = self:GetSpecialValueFor("pull_units_per_second")
	
	local pullToPoint = caster:GetAbsOrigin() + caster:GetForwardVector() * pull_distance_limit
	for _, enemy in ipairs( self.targets ) do
		if enemy:HasModifier( "modifier_pudge_dismember_channeled" ) and CalculateDistance( enemy, caster ) > pull_distance_limit then
			local direction = CalculateDirection( pullToPoint, enemy )
			local newPosition = enemy:GetAbsOrigin() + direction * pull_units_per_second * dt
			enemy:SetAbsOrigin( newPosition )
		end
	end
end

function pudge_dismember:OnChannelFinish()
	local caster = self:GetCaster()
	ResolveNPCPositions( caster:GetAbsOrigin(), self:GetTrueCastRange() + self:GetSpecialValueFor("aoe_radius") + 32 )
end

modifier_pudge_dismember_channeled = class({})
LinkLuaModifier( "modifier_pudge_dismember_channeled", "heroes/hero_pudge/pudge_dismember.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_pudge_dismember_channeled:OnCreated(table)
	self.dismember_damage = self:GetSpecialValueFor("dismember_damage")
	self.tick_interval = self:GetRemainingTime() / self:GetSpecialValueFor("ticks")
	
	self.glutton_strength_stack_duration = self:GetSpecialValueFor("glutton_strength_stack_duration")
	self.gluttony_damage_bonus_duration = self:GetSpecialValueFor("gluttony_damage_bonus_duration")
	if IsServer() then
		EmitSoundOn("Hero_Pudge.Dismember", self:GetParent() )
		self.nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_pudge/pudge_dismember_chain.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster())
		ParticleManager:SetParticleAlwaysSimulate(self.nfx)
		ParticleManager:SetParticleControlEnt(self.nfx, 3, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetCaster():GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(self.nfx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
		
		self:StartIntervalThink( self.tick_interval )
	end
end

function modifier_pudge_dismember_channeled:OnIntervalThink()
	local caster = self:GetCaster()
	if not self:GetCaster():IsChanneling() then
		self:Destroy()
		return
	end
	local parent = self:GetParent()
	local ability = self:GetAbility()
	
	local damage = self.dismember_damage * self.tick_interval
	local damageDealt = ability:DealDamage( caster, parent, damage )
	caster:HealEvent( damageDealt, ability, caster, {heal_type = DOTA_HEAL_TYPE_LIFESTEAL, heal_category = DOTA_LIFESTEAL_SOURCE_ABILITY} )
	
	if parent:IsConsideredHero() then
		EmitSoundOn("Hero_Pudge.DismemberSwings", parent)
		ParticleManager:FireParticle("particles/units/heroes/hero_pudge/pudge_dismember.vpcf", PATTACH_POINT_FOLLOW, caster, {[0]=TernaryOperator( "attach_attack1", RollPercentage(50), "attach_attack2")})
		
		if self.glutton_strength_stack_duration > 0 then
			caster:AddNewModifier( caster, ability, "modifier_pudge_dismember_rotten_giant", {duration = self.glutton_strength_stack_duration})
		end
	end
	if self.gluttony_damage_bonus_duration > 0 then
		caster:AddNewModifier( caster, ability, "modifier_pudge_dismember_flesh_carver", {duration = self.gluttony_damage_bonus_duration})
	end
end

function modifier_pudge_dismember_channeled:OnRemoved()
	if IsServer() then
		ParticleManager:ClearParticle(self.nfx)
	end
end

function modifier_pudge_dismember_channeled:IsDebuff()
	return true
end

function modifier_pudge_dismember_channeled:IsStunDebuff()
	return true
end

function modifier_pudge_dismember_channeled:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_INVISIBLE] = false,
	}

	return state
end

function modifier_pudge_dismember_channeled:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}

	return funcs
end

function modifier_pudge_dismember_channeled:GetOverrideAnimation( params )
	return ACT_DOTA_FLAIL
end

function modifier_pudge_dismember_channeled:GetEffectName()
	return "particles/units/heroes/hero_bloodseeker/bloodseeker_rupture.vpcf"
end

modifier_pudge_dismember_rotten_giant = class({})
LinkLuaModifier( "modifier_pudge_dismember_rotten_giant", "heroes/hero_pudge/pudge_dismember.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_pudge_dismember_rotten_giant:OnCreated()
	self:OnRefresh()
end

function modifier_pudge_dismember_rotten_giant:OnRefresh(table)
	self.gluttony_strength_bonus = self:GetSpecialValueFor("gluttony_strength_bonus")
	if IsServer() then
		self:AddIndependentStack()
		self:GetParent():CalculateStatBonus( true )
	end
end

function modifier_pudge_dismember_rotten_giant:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS
	}

	return funcs
end

function modifier_pudge_dismember_rotten_giant:GetModifierBonusStats_Strength()
	return self.gluttony_strength_bonus * self:GetStackCount()
end

modifier_pudge_dismember_flesh_carver = class({})
LinkLuaModifier( "modifier_pudge_dismember_flesh_carver", "heroes/hero_pudge/pudge_dismember.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_pudge_dismember_flesh_carver:OnCreated()
	self:OnRefresh()
end

function modifier_pudge_dismember_flesh_carver:OnRefresh(table)
	self.gluttony_damage_bonus = self:GetSpecialValueFor("gluttony_damage_bonus")
	if IsServer() then
		self:AddIndependentStack()
		self:GetParent():CalculateStatBonus( true )
	end
end


function modifier_pudge_dismember_flesh_carver:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
	}

	return funcs
end

function modifier_pudge_dismember_flesh_carver:GetModifierTotalDamageOutgoing_Percentage()
	return self.gluttony_damage_bonus * self:GetStackCount()
end