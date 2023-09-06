earth_spirit_magnetize = class({})

function earth_spirit_magnetize:GetIntrinsicModifierName()
	return "modifier_earth_spirit_magnetize_listener"
end

function earth_spirit_magnetize:IsStealable()
	return true
end

function earth_spirit_magnetize:IsHiddenWhenStolen()
	return false
end

function earth_spirit_magnetize:OnSpellStart()
    local caster = self:GetCaster()
	
    EmitSoundOn("Hero_EarthSpirit.Magnetize.Cast", caster)
	self:EmitMagnetizeEffect( caster )
end

function earth_spirit_magnetize:EmitMagnetizeEffect( unit, flDur, bStack )
    local caster = self:GetCaster()
	
    EmitSoundOn("Hero_EarthSpirit.Magnetize.StoneBolt", caster)
	local isRemnant = (unit:GetName() == "npc_dota_earth_spirit_stone") or caster == unit
	local remnantRadius = self:GetSpecialValueFor("rock_explosion_radius")
	local rockDelay = self:GetSpecialValueFor("rock_explosion_delay")
	local enemyRadius = self:GetSpecialValueFor("cast_radius")
	local effectRadius = TernaryOperator(remnantRadius, isRemnant, enemyRadius)
	local duration = flDur or self:GetSpecialValueFor("damage_duration")
	local stackDurations = bStack or false
	
    local nfx = ParticleManager:FireParticle( "particles/units/heroes/hero_earth_spirit/espirit_magnetize_target.vpcf", PATTACH_POINT_FOLLOW, unit, {[2] = Vector(effectRadius,effectRadius,effectRadius)} )
																										
    local stones = caster:FindFriendlyUnitsInRadius(unit:GetAbsOrigin(), TernaryOperator(remnantRadius, isRemnant, enemyRadius), {type = DOTA_UNIT_TARGET_ALL, flag = DOTA_UNIT_TARGET_FLAG_INVULNERABLE })
    for _,stone in ipairs(stones) do
    	if stone:GetName() == "npc_dota_earth_spirit_stone" or ( stone == caster and caster:HasShard() ) then
    		if not stone:HasModifier("modifier_earth_spirit_magnetize_effect") or stone == caster then
    			ParticleManager:FireRopeParticle("particles/units/heroes/hero_earth_spirit/espirit_stone_explosion_bolt.vpcf", PATTACH_POINT_FOLLOW, unit, stone)
				EmitSoundOn( "Hero_EarthSpirit.Magnetize.StoneBolt", unit )
				
				stone:AddNewModifier(caster, self, "modifier_earth_spirit_magnetize_effect", {Duration = rockDelay, effectDur = duration})
				if stone ~= caster then self:EmitMagnetizeEffect( stone, duration ) end
			end
    	end
    end
    
    local enemies = caster:FindEnemyUnitsInRadius(unit:GetAbsOrigin(), effectRadius)
    for _,enemy in ipairs(enemies) do
    	ParticleManager:FireRopeParticle("particles/units/heroes/hero_earth_spirit/espirit_stone_explosion_bolt.vpcf", PATTACH_POINT_FOLLOW, unit, enemy)
		EmitSoundOn( "Hero_EarthSpirit.Magnetize.StoneBolt", unit )
		
		if not stackDurations then
			enemy:AddNewModifier(caster, self, "modifier_earth_spirit_magnetize_effect", {Duration = duration, effectDur = duration})
		else
			enemy:AddNewModifierStacking(caster, self, "modifier_earth_spirit_magnetize_effect", {Duration = duration})
		end
    end
end


modifier_earth_spirit_magnetize_effect = class({})
LinkLuaModifier( "modifier_earth_spirit_magnetize_effect", "heroes/hero_earth_spirit/earth_spirit_magnetize.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_earth_spirit_magnetize_effect:OnCreated(kv)
	self.effectDur = kv.effectDur or self:GetDuration()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink(0.25)
		
		self.counterFX = ParticleManager:CreateParticle("particles/units/heroes/hero_earth_spirit/earth_spirit_magnetize_counter.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent() )
		ParticleManager:SetParticleControl(self.counterFX, 1, Vector( math.floor( math.ceil( self:GetRemainingTime()*10 )/100 ), math.ceil( self:GetRemainingTime() )%10, 1 ) )
		self:AddOverHeadEffect( self.counterFX )
	end
end

function modifier_earth_spirit_magnetize_effect:OnRefresh(table)
	self.remnantRadius = self:GetSpecialValueFor("rock_explosion_radius")
	self.enemyRadius = self:GetSpecialValueFor("rock_search_radius")
	self.rockDelay = self:GetSpecialValueFor("rock_explosion_delay")
	self.damage = self:GetSpecialValueFor("damage_per_second")
	self.damageInterval = self:GetSpecialValueFor("damage_interval")
	self.undispellable = self:GetSpecialValueFor("undispellable")
	self.currInterval = self.damageInterval
	
	self.shardSpellAmp = self:GetSpecialValueFor("shard_magnetize_spell_amp")
	self.shardArmor = self:GetSpecialValueFor("shard_magnetize_armor")
	if not IsServer() then return end
	local caster = self:GetCaster()
	local parent = self:GetParent()
	if caster == parent then
		caster:Dispel( caster, true )
	end
end

function modifier_earth_spirit_magnetize_effect:OnIntervalThink()
	local target = self:GetParent()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	ParticleManager:SetParticleControl(self.counterFX, 1, Vector( math.floor( math.ceil( self:GetRemainingTime()*10 )/100 ), math.ceil( self:GetRemainingTime() )%10, 1 ) )
	ParticleManager:FireParticle("particles/units/heroes/hero_earth_spirit/espirit_magnetize_target.vpcf", PATTACH_POINT_FOLLOW, target, {[2] = Vector(enemyRadius, enemyRadius, enemyRadius)})
	
	self.currInterval = self.currInterval - 0.25
	if self.currInterval <= 0 then
		if not target:IsSameTeam( caster ) then
			ability:DealDamage( caster, target, self.damage )
		end
		self.currInterval = self.damageInterval
	end
	if target == caster then
		local enemies = caster:FindEnemyUnitsInRadius(target:GetAbsOrigin(), self.remnantRadius)
		for _,enemy in ipairs(enemies) do
			local magnetize = enemy:FindModifierByNameAndCaster( "modifier_earth_spirit_magnetize_effect", caster )
			if not magnetize or magnetize:GetRemainingTime() < self:GetRemainingTime() then
				ParticleManager:FireRopeParticle("particles/units/heroes/hero_earth_spirit/espirit_stone_explosion_bolt.vpcf", PATTACH_POINT_FOLLOW, target, enemy)
				EmitSoundOn( "Hero_EarthSpirit.Magnetize.StoneBolt", enemy )
				
				enemy:AddNewModifier(caster, ability, "modifier_earth_spirit_magnetize_effect", {Duration = self:GetRemainingTime()})
			end
		end
	end
	local stones = caster:FindFriendlyUnitsInRadius(target:GetAbsOrigin(), self.remnantRadius, {type = DOTA_UNIT_TARGET_ALL, flag = DOTA_UNIT_TARGET_FLAG_INVULNERABLE })
    for _,stone in ipairs(stones) do
    	if stone:GetName() == "npc_dota_earth_spirit_stone" or ( stone == caster and caster:HasShard() ) then
    		if not stone:HasModifier("modifier_earth_spirit_magnetize_effect") then
    			ParticleManager:FireRopeParticle("particles/units/heroes/hero_earth_spirit/espirit_stone_explosion_bolt.vpcf", PATTACH_POINT_FOLLOW, target, stone)
				EmitSoundOn( "Hero_EarthSpirit.Magnetize.StoneBolt", target )
				
				stone:AddNewModifier(caster, ability, "modifier_earth_spirit_magnetize_effect", {Duration = self.rockDelay})
				if stone ~= caster then ability:EmitMagnetizeEffect( stone, self.effectDur ) end
			end
    	end
    end
end

function modifier_earth_spirit_magnetize_effect:OnRemoved()
	if IsServer() then
		if self:GetParent():GetName() == "npc_dota_earth_spirit_stone" then
			self:GetParent():ForceKill(false)
		end
	end
end

function modifier_earth_spirit_magnetize_effect:DeclareFunctions()
	return {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE }
end

function modifier_earth_spirit_magnetize_effect:GetModifierPhysicalArmorBonus()
	if self:GetCaster() == self:GetParent() then return self.shardArmor end
end

function modifier_earth_spirit_magnetize_effect:GetModifierSpellAmplify_Percentage()
	if self:GetCaster() == self:GetParent() then return self.shardSpellAmp end
end

function modifier_earth_spirit_magnetize_effect:IsPurgable()
	return self.undispellable ~= 1
end

modifier_earth_spirit_magnetize_listener = class({})
LinkLuaModifier( "modifier_earth_spirit_magnetize_listener", "heroes/hero_earth_spirit/earth_spirit_magnetize.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_earth_spirit_magnetize_listener:OnCreated()
	self.scepter_duration = self:GetSpecialValueFor("scepter_magnetize_duration")
end

function modifier_earth_spirit_magnetize_listener:DeclareFunctions()
	return { MODIFIER_EVENT_ON_DEATH_COMPLETED }
end

function modifier_earth_spirit_magnetize_listener:OnDeathCompleted( params )
	if self:GetCaster():HasScepter() and params.unit:GetName() == "npc_dota_earth_spirit_stone" then
		self:GetAbility():EmitMagnetizeEffect( params.unit, self.scepter_duration, true )
	end
end

function modifier_earth_spirit_magnetize_listener:IsHidden()
	return true
end