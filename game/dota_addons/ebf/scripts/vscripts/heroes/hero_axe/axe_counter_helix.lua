axe_counter_helix = class({})

function axe_counter_helix:ShouldUseResources()
	return true
end

function axe_counter_helix:GetIntrinsicModifierName()
	return "modifier_axe_counter_helix_passive"
end

function axe_counter_helix:Counterhelix()
	local caster = self:GetCaster()
	
	local damage = self:GetSpecialValueFor("damage")
	local radius = self:GetSpecialValueFor("radius")
	local applies_attack = self:GetSpecialValueFor("applies_attack") == 1
	
	ParticleManager:CreateParticle( "particles/units/heroes/hero_axe/axe_counterhelix.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	EmitSoundOn( "Hero_Axe.CounterHelix", caster )
	caster:StartGesture( ACT_DOTA_CAST_ABILITY_3 )
	self:SetCooldown()
	
	caster:AddNewModifier( caster, self, "modifier_axe_counter_helix_attack_proc", {} )
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), radius ) ) do
		if applies_attack then
			caster:PerformGenericAttack(enemy, true, {neverMiss = true, suppressCleave = true})
		else
			self:DealDamage( caster, enemy, damage )
		end
	end
	caster:RemoveModifierByName( "modifier_axe_counter_helix_attack_proc" )
end

modifier_axe_counter_helix_attack_proc = class({})
LinkLuaModifier( "modifier_axe_counter_helix_attack_proc", "heroes/hero_axe/axe_counter_helix", LUA_MODIFIER_MOTION_NONE )

function modifier_axe_counter_helix_attack_proc:DeclareFunctions()
	return {MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PURE}
end

function modifier_axe_counter_helix_attack_proc:GetModifierProcAttack_BonusDamage_Pure( params )
	return self:GetSpecialValueFor("damage") * ( 1+self:GetCaster():GetSpellAmplification( false ) )
end

function modifier_axe_counter_helix_attack_proc:IsHidden()
	return true
end

modifier_axe_counter_helix_passive = class({})
LinkLuaModifier( "modifier_axe_counter_helix_passive", "heroes/hero_axe/axe_counter_helix", LUA_MODIFIER_MOTION_NONE )

function modifier_axe_counter_helix_passive:OnCreated()
	self:OnRefresh()
	if IsServer() and self.seconds_per_stack > 0 then
		self:StartIntervalThink( self.seconds_per_stack )
	end
end

function modifier_axe_counter_helix_passive:OnRefresh()
	self.hero_trigger = self:GetSpecialValueFor("hero_trigger")
	self.trigger_attacks = self:GetSpecialValueFor("trigger_attacks")
	self.radius = self:GetSpecialValueFor("radius")
	
	self.seconds_per_stack = self:GetSpecialValueFor("seconds_per_stack")
	
	self.reduction_duration = self:GetSpecialValueFor("reduction_duration")
	self.atk_dmg_reduction = self:GetSpecialValueFor("atk_dmg_reduction")
	self.max_red_stacks = self:GetSpecialValueFor("max_red_stacks")
	
	self.attacks_increase_counter = self:GetSpecialValueFor("attacks_increase_counter") == 1
end

function modifier_axe_counter_helix_passive:OnIntervalThink()
	if self:GetStackCount() < self.trigger_attacks then
		self:IncrementStackCount()
	end
	if self:GetStackCount() >= self.trigger_attacks 
	and self:GetParent():FindRandomEnemyInRadius(self:GetParent():GetAbsOrigin(), self.radius) then
		self:SetStackCount(0)
		self:GetAbility():Counterhelix()
	end
end

function modifier_axe_counter_helix_passive:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
	}

	return funcs
end

function modifier_axe_counter_helix_passive:GetModifierIncomingDamage_Percentage( params )
	if not IsEntitySafe(params.attacker) then return end
	if params.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK then return end
	local buff = params.attacker:FindModifierByNameAndCaster( "modifier_axe_counter_helix_jofurr_damage_reduction", self:GetCaster() )
	if IsModifierSafe( buff ) then
		return -self.atk_dmg_reduction * buff:GetStackCount()
	end
end

function modifier_axe_counter_helix_passive:OnTakeDamage( params )
	if params.inflictor == self:GetAbility() and params.unit:IsAlive() then
		if self.reduction_duration > 0 then
			local caster = self:GetCaster()
			local ability = self:GetAbility()
			local buff = params.unit:FindModifierByName( "modifier_axe_counter_helix_jofurr_damage_reduction")
			if buff then
				buff = params.unit:AddNewModifier( caster, ability, "modifier_axe_counter_helix_jofurr_damage_reduction", {duration = self.reduction_duration} )
				if buff:GetStackCount() < self.max_red_stacks then
					buff:IncrementStackCount()
				end
			elseif IsEntitySafe( params.unit ) and params.unit:IsAlive() then
				buff = params.unit:AddNewModifier( caster, ability, "modifier_axe_counter_helix_jofurr_damage_reduction", {duration = self.reduction_duration} )
				buff:SetStackCount(1)
			end
		end
	end
end

function modifier_axe_counter_helix_passive:OnAttackLanded( params )
	if IsServer() then
		if self:GetCaster():PassivesDisabled() then return end
		if not self:GetAbility():IsCooldownReady() then return end
		if params.attacker:IsOther() or params.attacker:IsBuilding() then return end
		if not (params.attacker == self:GetCaster() or params.target == self:GetCaster()) then return end
		local caster = self:GetCaster()
		
		if params.attacker ~= self:GetCaster() 
		or self.attacks_increase_counter then
			local unitToCheck = TernaryOperator( params.target, params.attacker == self:GetCaster(), params.attacker )
			local stacks = TernaryOperator( self.hero_trigger, unitToCheck:IsConsideredHero(), 1 )
			self:SetStackCount( self:GetStackCount() + stacks )
		end
		
		if self:GetStackCount() >= self.trigger_attacks then
			self:SetStackCount(0)
			self:GetAbility():Counterhelix()
		end
	end
end

function modifier_axe_counter_helix_passive:IsHidden()
	return self:GetStackCount() <= 0
end

function modifier_axe_counter_helix_passive:IsPurgable()
	return false
end

modifier_axe_counter_helix_jofurr_damage_reduction = class({})
LinkLuaModifier( "modifier_axe_counter_helix_jofurr_damage_reduction", "heroes/hero_axe/axe_counter_helix", LUA_MODIFIER_MOTION_NONE )

function modifier_axe_counter_helix_jofurr_damage_reduction:DeclareFunctions()
	return {MODIFIER_PROPERTY_TOOLTIP}
end
function modifier_axe_counter_helix_jofurr_damage_reduction:OnTooltip()
	return self:GetSpecialValueFor("atk_dmg_reduction") * self:GetStackCount()
end