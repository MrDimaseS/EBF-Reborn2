zuus_thundergods_wrath = class({})

function zuus_thundergods_wrath:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	EmitSoundOn( "Hero_Zuus.GodsWrath.PreCast", caster )
end

function zuus_thundergods_wrath:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
	StopSoundOn( "Hero_Zuus.GodsWrath.PreCast", caster )
end

function zuus_thundergods_wrath:OnSpellStart()
	local caster = self:GetCaster()
	
	local damage = self:GetSpecialValueFor("damage")
	local growing_delay = self:GetSpecialValueFor("growing_delay")
	local grow_kill_amp = self:GetSpecialValueFor("grow_kill_amp")/100
	local buffDuration = self:GetSpecialValueFor("buff_duration")
	local totalDamage = 0
	local creepDamage = self:GetSpecialValueFor("bonus_damage_creep")
	local heroDamage = self:GetSpecialValueFor("bonus_damage_hero")
	
	EmitSoundOn( "Hero_Zuus.GodsWrath", caster )
	local enemies = caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), -1 )
	
	caster:RemoveModifierByName("modifier_zuus_thundergods_wrath_brontaios")
	Timers:CreateTimer( growing_delay, function()
		local enemyToStrike
		local enemyToStrikeIndex
		for index, enemy in ipairs( enemies ) do
			if not enemyToStrike or enemy:GetHealth() < enemyToStrike:GetHealth() then
				enemyToStrike = enemy
				enemyToStrikeIndex = index
			end
		end
		if enemyToStrike then
			table.remove( enemies, enemyToStrikeIndex )

			ParticleManager:FireRopeParticle("particles/units/heroes/hero_zuus/zuus_thundergods_wrath.vpcf", PATTACH_POINT, caster, enemyToStrike:GetAbsOrigin(), {[0]=enemyToStrike:GetAbsOrigin()+Vector(0,0,1000)})
			EmitSoundOn( "Hero_Zuus.GodsWrath.Target", enemyToStrike )
			
			if buffDuration > 0 then
				caster:AddNewModifier( caster, self, "modifier_zuus_thundergods_wrath_brontaios", {duration = buffDuration, damage = TernaryOperator( heroDamage, enemyToStrike:IsConsideredHero(), creepDamage )} )
			end
			self:DealDamage( caster, enemyToStrike, damage )
			if not enemyToStrike:IsAlive() then
				damage = damage * (1+grow_kill_amp)
			end
			return growing_delay
		end
	end )
	
	
	local damage_to_barrier = self:GetSpecialValueFor("damage_to_barrier")
	local barrier_duration = self:GetSpecialValueFor("barrier_duration")
	if damage_to_barrier > 0 then
		local allies = caster:FindFriendlyUnitsInRadius( caster:GetAbsOrigin(), -1 )
		for _, ally in ipairs( allies ) do
			ParticleManager:FireRopeParticle("particles/units/heroes/hero_zuus/zuus_thundergods_wrath.vpcf", PATTACH_POINT, caster, ally:GetAbsOrigin(), {[0]=ally:GetAbsOrigin()+Vector(0,0,1000)})
			EmitSoundOn( "Hero_Zuus.GodsWrath.Target", ally )
			
			ally:AddNewModifier( caster, self, "modifier_zuus_thundergods_wrath_areios", {duration = barrier_duration} )
		end
	end
end

LinkLuaModifier("modifier_zuus_thundergods_wrath_brontaios", "heroes/hero_zeus/zuus_thundergods_wrath", LUA_MODIFIER_MOTION_NONE)
modifier_zuus_thundergods_wrath_brontaios = class({})

function modifier_zuus_thundergods_wrath_brontaios:OnCreated( kv )
	if IsServer() then 
		self:SetHasCustomTransmitterData(true)
		
		local caster = self:GetCaster()
		local leftFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_stormspirit/stormspirit_overload_ambient.vpcf", PATTACH_POINT_FOLLOW, caster )
		local rightFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_stormspirit/stormspirit_overload_ambient.vpcf", PATTACH_POINT_FOLLOW, caster )
		ParticleManager:SetParticleControlEnt(leftFX, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(rightFX, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack2", caster:GetAbsOrigin(), true)
		
		self:AddEffect( leftFX )
		self:AddEffect( rightFX )
	end
	self:OnRefresh( kv )
end

function modifier_zuus_thundergods_wrath_brontaios:OnRefresh( kv )
	if IsServer() then
		self.damage = (self.damage or 0) + kv.damage
		self:SendBuffRefreshToClients()
	end
end

function modifier_zuus_thundergods_wrath_brontaios:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE }
end

function modifier_zuus_thundergods_wrath_brontaios:GetModifierPreAttack_BonusDamage( params )
	return self.damage
end

function modifier_zuus_thundergods_wrath_brontaios:AddCustomTransmitterData()
	return {damage = self.damage}
end

function modifier_zuus_thundergods_wrath_brontaios:HandleCustomTransmitterData(data)
	self.damage = data.damage
end

LinkLuaModifier("modifier_zuus_thundergods_wrath_areios", "heroes/hero_zeus/zuus_thundergods_wrath", LUA_MODIFIER_MOTION_NONE)
modifier_zuus_thundergods_wrath_areios = class({})

function modifier_zuus_thundergods_wrath_areios:OnCreated()
	if IsServer() then self:SetHasCustomTransmitterData(true) end
	self:OnRefresh()
end

function modifier_zuus_thundergods_wrath_areios:OnRefresh()
	if IsServer() then
		self.barrier = self:GetSpecialValueFor("damage") * self:GetSpecialValueFor("damage_to_barrier") / 100
		self:SendBuffRefreshToClients()
	end
end

function modifier_zuus_thundergods_wrath_areios:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT }
end

function modifier_zuus_thundergods_wrath_areios:GetModifierIncomingDamageConstant( params )
	if self.barrier < 0 then return end
	if IsServer() then
		local barrier = math.min( self.barrier, math.max( self.barrier, params.damage ) )
		self.barrier = math.max( 0, self.barrier - params.damage )
		if self.barrier > 0 then
			self:SendBuffRefreshToClients()
		else
			self:Destroy()
		end
		EmitSoundOn( "Hero_Antimage.Counterspell.Absorb", self:GetParent() )
		return -barrier
	else
		return self.barrier
	end
end

function modifier_zuus_thundergods_wrath_areios:AddCustomTransmitterData()
	return {barrier = self.barrier}
end

function modifier_zuus_thundergods_wrath_areios:HandleCustomTransmitterData(data)
	self.barrier = data.barrier
end

function modifier_zuus_thundergods_wrath_areios:GetEffectName()
	return "particles/units/heroes/hero_zuus/zuus_thundergods_wrath_shield.vpcf"
end

function modifier_zuus_thundergods_wrath_areios:IsHidden()
	return false
end