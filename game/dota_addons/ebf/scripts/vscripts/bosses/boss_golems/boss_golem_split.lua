boss_golem_split = class({})

function boss_golem_split:GetIntrinsicModifierName()
	return "modifier_boss_golem_split"
end

function boss_golem_split:CreateGolem( position )
	local caster = self:GetCaster()
	if self:GetLevel() == 0 then return end
	
	local splitPct = self:GetSpecialValueFor("split_pct") / 100
	local travel_time = self:GetSpecialValueFor("travel_time")
	local distance = self:GetSpecialValueFor("distance")
	
	local golem = CreateUnitByName( "npc_dota_boss_granite_golem", position, true, nil, nil, caster:GetTeam() )
	
	local split = golem:FindAbilityByName("boss_golem_split")
	if split then
		split:SetLevel( self:GetLevel() - 1 )
	end
	
	local throw = golem:FindAbilityByName("boss_golem_rock_throw")
	if throw then
		throw:SetLevel( self:GetLevel() - 1 )
		local ogThrow = caster:FindAbilityByName("boss_golem_rock_throw")
		if ogThrow then throw:StartCooldown( ogThrow:GetCooldownTimeRemaining() ) end
	end
	
	golem:SetBaseMaxHealth( math.ceil( caster:GetBaseMaxHealth() * splitPct ) )
	golem:SetMaxHealth( math.ceil( caster:GetMaxHealth() * splitPct ) )
	golem:SetHealth( golem:GetMaxHealth() )
	
	golem:SetBaseMagicalResistanceValue( math.floor( caster:GetBaseMagicalResistanceValue() * splitPct ) )
	golem:SetPhysicalArmorBaseValue( math.floor( caster:GetPhysicalArmorBaseValue() * splitPct ) )
	
	golem:SetModelScale( math.max( splitPct, caster:GetModelScale() * splitPct ) )
	golem:SetHealthBarOffsetOverride( caster:GetBaseHealthBarOffset() * splitPct )
	
	golem:SetAverageBaseDamage( caster:GetAverageBaseDamage() * splitPct )
	
	golem:SetBaseMoveSpeed( caster:GetBaseMoveSpeed() / splitPct )
	
	print( caster:GetBaseMoveSpeed() / splitPct, golem:GetBaseMoveSpeed() )
	
	golem:ApplyKnockBack( position + RandomVector( 50 ), travel_time, travel_time, RandomInt( distance / 2, distance ), 128, golem, split )
	
	golem.hasBeenProcessed = true
	golem:CalculateGenericBonuses()
end

modifier_boss_golem_split = class({})
LinkLuaModifier( "modifier_boss_golem_split", "bosses/boss_golems/boss_golem_split", LUA_MODIFIER_MOTION_NONE)

function modifier_boss_golem_split:DeclareFunctions()
	return {MODIFIER_EVENT_ON_DEATH}
end

function modifier_boss_golem_split:OnDeath( params )
	if params.unit == self:GetParent() and GameRules._currentRound and GameRules._currentRound.currentlyActive and params.unit:GetTeam() ~= DOTA_TEAM_GOODGUYS then
		for i = 1, self:GetSpecialValueFor("count") do
			self:GetAbility():CreateGolem( self:GetCaster():GetAbsOrigin() )
		end
	end
end