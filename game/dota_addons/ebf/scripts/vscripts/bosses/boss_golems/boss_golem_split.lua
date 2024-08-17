boss_golem_split = class({})

function boss_golem_split:GetIntrinsicModifierName()
	return "modifier_boss_golem_split"
end

function boss_golem_split:CreateGolem( position )
	local caster = self:GetCaster()
	if self:GetLevel() == 1 then return end
	
	local splitPct = self:GetSpecialValueFor("split_pct") / 100
	local travel_time = self:GetSpecialValueFor("travel_time")
	local distance = self:GetSpecialValueFor("distance")
	
	local golem = CreateUnitByName( "npc_dota_boss_granite_golem", position, true, nil, nil, caster:GetTeam() )
	local split = golem:FindAbilityByName("boss_golem_split")
	if split then
		split:SetLevel( self:GetLevel() - 1 )
	end
	
	golem:SetOriginalModel( "models/heroes/tiny/tiny_0"..split:GetLevel().."/tiny_0"..split:GetLevel()..".vmdl" )
	golem:SetModel( "models/heroes/tiny/tiny_0"..split:GetLevel().."/tiny_0"..split:GetLevel()..".vmdl" )
	
	local throw = golem:FindAbilityByName("boss_golem_rock_throw")
	local ogThrow = caster:FindAbilityByName("boss_golem_rock_throw")
	if throw then
		throw:SetLevel( self:GetLevel() - 1 )
		if ogThrow then throw:StartCooldown( ogThrow:GetCooldownTimeRemaining() ) end
	end
	local avalanche = golem:FindAbilityByName("boss_golem_avalanche")
	if avalanche then
		avalanche:SetLevel( self:GetLevel() - 1 )
		local ogAvalanche = caster:FindAbilityByName("boss_golem_avalanche")
		if ogAvalanche then avalanche:StartCooldown( ogAvalanche:GetCooldownTimeRemaining() ) end
	end
	
	golem:SetCoreHealth( math.ceil( caster:GetHealth() * splitPct ) )
	golem:SetBaseMoveSpeed( caster:GetBaseMoveSpeed() * splitPct + 40 )
	
	local yeetPosition = position + RandomVector( 50 )
	if throw then
		throw:ThrowGolem( golem, yeetPosition )
	else
		golem:ApplyKnockBack( yeetPosition, travel_time, travel_time, RandomInt( distance / 2, distance ), 128, golem, split )
	end
	
	golem.hasBeenProcessed = true
	golem:CalculateGenericBonuses()
	ParticleManager:FireParticle( "particles/units/heroes/hero_tiny/tiny_transform.vpcf", PATTACH_POINT_FOLLOW, golem )
	EmitSoundOn( "Tiny.Grow", golem )
end

function boss_golem_split:Spawn()	
	if not IsServer() then return end
	Timers:CreateTimer( function()
		if self:GetSpecialValueFor("cleave") > 0 then
			local tree = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_01/tiny_01_tree.vmdl"})
			tree:FollowEntity(self:GetCaster(), true)
		end
	end)
end

modifier_boss_golem_split = class({})
LinkLuaModifier( "modifier_boss_golem_split", "bosses/boss_golems/boss_golem_split", LUA_MODIFIER_MOTION_NONE)

function modifier_boss_golem_split:OnCreated()
	self:OnRefresh()
end

function modifier_boss_golem_split:OnRefresh()
	self.cleave = self:GetSpecialValueFor("cleave")
	self.attack_range = self:GetSpecialValueFor("attack_range")
end

function modifier_boss_golem_split:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE,
			MODIFIER_EVENT_ON_ATTACK_LANDED,
			MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
			MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS}
end

function modifier_boss_golem_split:OnAttackLanded( params )
	if params.attacker == self:GetParent() and self.cleave > 0 then
		DoCleaveAttack( params.attacker, params.target, self:GetAbility(), params.original_damage * self.cleave / 100, params.attacker:GetAttackRange(), params.attacker:GetAttackRange() * 2, params.attacker:GetAttackRange() * 2, "particles/units/heroes/hero_tiny/tiny_craggy_cleave.vpcf" )
	end
end


function modifier_boss_golem_split:OnTakeDamage( params )
	if self._splitHasBeenInitiated then return end
	if self:GetAbility():GetLevel() == 1 then return end
	if params.unit == self:GetParent() and params.unit:GetHealthPercent() <= self:GetSpecialValueFor("split_threshold") then
		self._splitHasBeenInitiated = true
		params.unit:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_boss_golem_split_in_progress", {duration = self:GetSpecialValueFor("split_duration")} )
	end
end

function modifier_boss_golem_split:GetModifierAttackRangeBonus()
	return self.attack_range
end

function modifier_boss_golem_split:GetActivityTranslationModifiers()
	if self.cleave > 0 then
		return "tree"
	end
end

modifier_boss_golem_split_in_progress = class({})
LinkLuaModifier( "modifier_boss_golem_split_in_progress", "bosses/boss_golems/boss_golem_split", LUA_MODIFIER_MOTION_NONE)

function modifier_boss_golem_split_in_progress:OnCreated()
	if IsServer() then
		self:OnIntervalThink()
		self:StartIntervalThink( 0.1 )
	end
end

function modifier_boss_golem_split_in_progress:OnIntervalThink()
	ParticleManager:FireParticle( "particles/units/heroes/hero_tiny/tiny_death_rocks.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
	ParticleManager:FireParticle( "particles/units/heroes/hero_tiny/tiny_death_rocks.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
	ParticleManager:FireParticle( "particles/units/heroes/hero_tiny/tiny_death_rocks.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
end

function modifier_boss_golem_split_in_progress:OnDestroy()
	if not IsServer() then return end
	if IsEntitySafe( self:GetParent() ) and self:GetParent():IsAlive() 
	-- and GameRules._currentRound and GameRules._currentRound.currentlyActive and params.unit:GetTeam() ~= DOTA_TEAM_GOODGUYS 
	then
		for i = 1, self:GetSpecialValueFor("count") do
			self:GetAbility():CreateGolem( self:GetParent():GetAbsOrigin() )
		end
		ParticleManager:FireParticle( "particles/units/heroes/hero_tiny/tiny0"..self:GetAbility():GetLevel().."_death.vpcf", PATTACH_ABSORIGIN, nil, {[0] = self:GetParent():GetAbsOrigin()} )
		EmitSoundOn( "Hero_Tiny.Death_04", self:GetParent() )
		self:GetParent():ForceKill(true)
	end
end

function modifier_boss_golem_split_in_progress:CheckState()
	return {[MODIFIER_STATE_STUNNED] = true}
end

function modifier_boss_golem_split_in_progress:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, MODIFIER_PROPERTY_OVERRIDE_ANIMATION }
end

function modifier_boss_golem_split_in_progress:GetOverrideAnimation( params )
	return ACT_DOTA_DISABLED
end

function modifier_boss_golem_split_in_progress:GetModifierIncomingDamage_Percentage( params )
	return -self:GetSpecialValueFor("split_resistance")
end

