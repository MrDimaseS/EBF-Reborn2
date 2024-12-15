nyx_assassin_spiked_carapace = class({})

function nyx_assassin_spiked_carapace:IsStealable()
	return true
end

function nyx_assassin_spiked_carapace:GetBehavior()
	local caster = self:GetCaster()
	if caster:HasModifier("modifier_nyx_assassin_burrowed") then
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_UNRESTRICTED
	else
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET
	end
end

function nyx_assassin_spiked_carapace:GetIntrinsicModifierName()
	return "modifier_nyx_assassin_spiked_carapace_passive"
end

function nyx_assassin_spiked_carapace:OnSpellStart()
	local caster = self:GetCaster()
	
	local duration = self:GetSpecialValueFor("reflect_duration")
	caster:AddNewModifier(caster, self, "modifier_nyx_assassin_spiked_carapace_active", {Duration = duration})

	if caster:HasModifier("modifier_nyx_assassin_burrowed") then
		local burrow = caster:FindModifierByName("modifier_nyx_assassin_burrowed"):GetAbility()
		local radius = burrow:GetSpecialValueFor("carapace_radius")
		EmitSoundOn("Hero_NyxAssassin.SpikedCarapace.Stun", caster)
		ParticleManager:FireParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_spiked_carapace_burrow.vpcf", PATTACH_POINT, caster, {[0]=caster:GetAbsOrigin(), [1]=Vector(radius, 0, 0)})
		local enemies = caster:FindEnemyUnitsInRadius(caster:GetAbsOrigin(), radius)
		for _, enemy in pairs(enemies) do
			if not enemy:TriggerSpellAbsorb(self) then
				self:SpikedCarapaceStun( enemy )
			end
		end
	end
	EmitSoundOn("Hero_NyxAssassin.SpikedCarapace", caster)
end

function nyx_assassin_spiked_carapace:SpikedCarapaceStun( target )
	local caster = self:GetCaster()
	self:Stun(target, self:GetSpecialValueFor("stun_duration"), "particles/units/heroes/hero_nyx_assassin/nyx_assassin_spiked_carapace_hit.vpcf", {[1]=caster:GetAbsOrigin(), [2]=caster:GetAbsOrigin()})
end

modifier_nyx_assassin_spiked_carapace_passive = class({})
LinkLuaModifier( "modifier_nyx_assassin_spiked_carapace_passive", "heroes/hero_nyx_assassin/nyx_assassin_spiked_carapace.lua", LUA_MODIFIER_MOTION_NONE )


function modifier_nyx_assassin_spiked_carapace_passive:OnCreated()
	self.barrier_block = 0
	if IsServer() then self:SetHasCustomTransmitterData(true) end
	self:OnRefresh()
end

function modifier_nyx_assassin_spiked_carapace_passive:OnRefresh()
	self.mana_to_barrier = self:GetSpecialValueFor("mana_to_barrier")
	if IsServer() then self:SendBuffRefreshToClients() end
end

function modifier_nyx_assassin_spiked_carapace_passive:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_SPENT_MANA,
		MODIFIER_EVENT_ON_MANA_GAINED,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
	}
	return funcs
end

function modifier_nyx_assassin_spiked_carapace_passive:OnSpentMana(params)
	if not params.unit:HasModifier("modifier_nyx_assassin_spiked_carapace_active") then return end
	self.barrier_block = self.barrier_block + params.cost * self.mana_to_barrier
	self:SendBuffRefreshToClients()
end

function modifier_nyx_assassin_spiked_carapace_passive:OnManaGained(params)
	if not params.unit:HasModifier("modifier_nyx_assassin_spiked_carapace_active") then return end
	self.barrier_block = self.barrier_block + params.gain * self.mana_to_barrier
	self:SendBuffRefreshToClients()
end

function modifier_nyx_assassin_spiked_carapace_passive:GetModifierIncomingDamageConstant( params )
	if (self.barrier_block or 0) <= 0 then return end
	if IsServer() then
		local barrier_block = math.min( self.barrier_block, params.damage )
		self.barrier_block = math.max( 0, self.barrier_block - barrier_block )
		self:SendBuffRefreshToClients()
		return -barrier_block
	else
		return self.barrier_block
	end
end

function modifier_nyx_assassin_spiked_carapace_passive:AddCustomTransmitterData()
	return {barrier_block = self.barrier_block}
end

function modifier_nyx_assassin_spiked_carapace_passive:HandleCustomTransmitterData(data)
	self.barrier_block = data.barrier_block
end

function modifier_nyx_assassin_spiked_carapace_passive:IsHidden()
	return true
end

modifier_nyx_assassin_spiked_carapace_active = class({})
LinkLuaModifier( "modifier_nyx_assassin_spiked_carapace_active", "heroes/hero_nyx_assassin/nyx_assassin_spiked_carapace.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_nyx_assassin_spiked_carapace_active:OnCreated()
	self:OnRefresh()
end

function modifier_nyx_assassin_spiked_carapace_active:OnRefresh()
	self.stun_duration = self:GetSpecialValueFor("stun_duration")
	self.damage_reflect_pct = self:GetSpecialValueFor("damage_reflect_pct") / 100
	self.linger_percentage = self:GetSpecialValueFor("linger_percentage") / 100
	self.linger_duration = self:GetSpecialValueFor("linger_duration")
	self.linger_radius = self:GetSpecialValueFor("linger_radius")
	self.linger_burrow_bonus = self:GetSpecialValueFor("linger_burrow_bonus")
	self.can_hit_multiple = self:GetSpecialValueFor("can_hit_multiple") == 1
	self.mana_to_barrier = self:GetSpecialValueFor("mana_to_barrier") / 100
	
	self.unitsHit = {}
end

function modifier_nyx_assassin_spiked_carapace_active:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
	}
	return funcs
end

function modifier_nyx_assassin_spiked_carapace_active:GetModifierIncomingDamage_Percentage(params)
	if not IsServer() or not params.attacker or not params.target or params.original_damage <= 0 then return end
	
	local ability = self:GetAbility()
	local stunDuration = self:GetSpecialValueFor("stun_duration")
	if not params.attacker:IsMagicImmune() and not self.unitsHit[params.attacker] then
		local damageTaken = params.damage * self.damage_reflect_pct
		
		self:SpikedCarapaceStun( params.target )
		ability:DealDamage(params.target, params.attacker, damageTaken, {damage_type=params.damageType, damage_flags=DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_REFLECTION})
		
		EmitSoundOn("Hero_NyxAssassin.SpikedCarapace.Stun", params.target)
		
		if self.linger_percentage > 0 then
			Timers:CreateTimer( self.linger_duration, function()
				for _, enemy in ipairs( params.target:FindEnemyUnitsInRadius( params.target:GetAbsOrigin(), self.linger_radius ) ) do
					ability:DealDamage( params.target, enemy, damageTaken * self.linger_percentage, {damage_type=params.damageType, damage_flags=DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_REFLECTION} )
					ability:FireTrackingProjectile("particles/units/heroes/hero_nyx_assassin/nyx_assassin_spiked_carapace_spine.vpcf", enemy, 3000)
				end
			end)
		end
		
		if not self.can_hit_multiple then
			self.unitsHit[params.attacker] = true
		end
		
		return -999
	end
end

function modifier_nyx_assassin_spiked_carapace_active:OnSpentMana(params)
	if params.unit ~= self:GetParent() then return end
end

function modifier_nyx_assassin_spiked_carapace_active:OnManaGained(params)
	if params.unit ~= self:GetParent() then return end
	
end

function modifier_nyx_assassin_spiked_carapace_active:GetEffectName()
	return "particles/units/heroes/hero_nyx_assassin/nyx_assassin_spiked_carapace.vpcf"
end