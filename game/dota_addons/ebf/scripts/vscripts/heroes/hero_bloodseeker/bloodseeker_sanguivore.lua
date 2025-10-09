bloodseeker_sanguivore = class({})

function bloodseeker_sanguivore:GetIntrinsicModifierName()
	return "modifier_bloodseeker_sanguivore_buff"
end

modifier_bloodseeker_sanguivore_buff = class({})
LinkLuaModifier( "modifier_bloodseeker_sanguivore_buff", "heroes/hero_bloodseeker/bloodseeker_sanguivore", LUA_MODIFIER_MOTION_NONE )

function modifier_bloodseeker_sanguivore_buff:OnCreated()
	self:OnRefresh()
	if IsServer() then self:SetHasCustomTransmitterData(true) end
end

function modifier_bloodseeker_sanguivore_buff:OnRefresh()
	self.hero_stacks = 100 / self:GetSpecialValueFor("creep_pct")
	self.kill_stacks = self:GetSpecialValueFor("kill_pct") / 100
	self.heal_duration = self:GetSpecialValueFor("heal_duration")
	self.pure_damage_lifesteal_pct = self:GetSpecialValueFor("pure_damage_lifesteal_pct")
	
	self.blood_mist_aoe = self:GetSpecialValueFor("blood_mist_aoe")
	self.blood_mist_missing_hp_dmg = self:GetSpecialValueFor("blood_mist_missing_hp_dmg") / 100
	
	if IsServer() and self.blood_mist_aoe > 0 then 
		self:StartIntervalThink(1.5)
	end
end

function modifier_bloodseeker_sanguivore_buff:OnIntervalThink()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local missingHPDmg = self:GetCaster():GetHealthDeficit() * self.blood_mist_missing_hp_dmg
	if missingHPDmg > 1 then
		if not self.nFX then
			self.nFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_bloodseeker/bloodseeker_scepter_blood_mist_aoe.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster() )
			ParticleManager:SetParticleControl(self.nFX, 1, Vector( self.blood_mist_aoe, 1, 1 ) )
		end
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self.blood_mist_aoe ) ) do
			ability:DealDamage( caster, enemy, missingHPDmg, { damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION } )
		end
	else
		if self.nFX then
			ParticleManager:ClearParticle( self.nFX )
			self.nFX = nil
		end
	end
end

function modifier_bloodseeker_sanguivore_buff:OnDestroy()
	if self.nFX then
		ParticleManager:ClearParticle( self.nFX )
		self.nFX = nil
	end
end

function modifier_bloodseeker_sanguivore_buff:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_bloodseeker_sanguivore_buff:OnTakeDamage( params )
	local caster = self:GetCaster()
	if params.attacker ~= caster or params.attacker == params.unit then return end
	local ability = self:GetAbility()
	if params.damage_type == DAMAGE_TYPE_PURE and not HasBit(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION ) and not HasBit(params.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL )  then
		local lifesteal = params.damage * self.pure_damage_lifesteal_pct / 100
		if params.damage_category == DOTA_DAMAGE_CATEGORY_SPELL then
			if not params.unit:IsConsideredHero() then
				lifesteal = lifesteal * 0.2
			end
		elseif params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
			if not params.unit:IsConsideredHero() then
				lifesteal = lifesteal * 0.6
			end
		end
		caster:HealEvent( lifesteal, ability, caster )
	end
	if ( params.inflictor and caster:HasAbility( params.inflictor:GetAbilityName() ) ) or not params.unit:IsAlive() then
		local stacks = 1
		if params.unit:IsConsideredHero() then
			stacks = stacks * self.hero_stacks
		end
		if not params.unit:IsAlive() then
			stacks = stacks * self.kill_stacks
		end
		
		local regeneration = caster:AddNewModifier( caster, ability, "modifier_bloodseeker_sanguivore_regeneration", {duration = self.heal_duration} )
		regeneration:AddIndependentStack( { duration = self.heal_duration, stacks = math.floor( stacks ) } )
	end
end

function modifier_bloodseeker_sanguivore_buff:AddCustomTransmitterData()
	return {barrier_block = self.barrier_block}
end

function modifier_bloodseeker_sanguivore_buff:HandleCustomTransmitterData(data)
	self.barrier_block = data.barrier_block
end


function modifier_bloodseeker_sanguivore_buff:IsHidden()
	return true
end

modifier_bloodseeker_sanguivore_regeneration = class({})
LinkLuaModifier( "modifier_bloodseeker_sanguivore_regeneration", "heroes/hero_bloodseeker/bloodseeker_sanguivore", LUA_MODIFIER_MOTION_NONE )

function modifier_bloodseeker_sanguivore_regeneration:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink( 0.33 )
	end
end

function modifier_bloodseeker_sanguivore_regeneration:OnRefresh()
	self.max_hp_percent_heal_tooltip = self:GetSpecialValueFor("max_hp_percent_heal_tooltip") / 100
	self.creep_pct = self:GetSpecialValueFor("creep_pct") / 100
	
	self.heal_factor = 1
	self.heal_duration = self:GetSpecialValueFor("heal_duration")
end

function modifier_bloodseeker_sanguivore_regeneration:OnIntervalThink()
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	
	local healPerSec = (self.max_hp_percent_heal_tooltip * self.creep_pct) * self:GetStackCount() / self.heal_duration
	
	local realHPS = parent:GetMaxHealth() * healPerSec * 0.33 + (self.healOverFlow or 0)
	self.healOverFlow = realHPS % 1
	
	parent:HealEvent( math.floor( realHPS ), ability, caster )
end

function modifier_bloodseeker_sanguivore_regeneration:DeclareFunctions()
	return { MODIFIER_PROPERTY_TOOLTIP }
end

function modifier_bloodseeker_sanguivore_regeneration:OnTooltip()
	return 100 * (self.max_hp_percent_heal_tooltip * self.creep_pct) * self:GetStackCount() / self.heal_duration
end