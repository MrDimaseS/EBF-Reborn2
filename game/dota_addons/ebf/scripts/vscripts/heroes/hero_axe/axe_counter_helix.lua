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
			caster:PerformGenericAttack(enemy, true, {neverMiss = true, suppressCleave = true, ability = self})
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
	
	self.slow_duration = self:GetSpecialValueFor("slow_duration")
	
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
	}

	return funcs
end

function modifier_axe_counter_helix_passive:OnTakeDamage( params )
	if params.inflictor == self:GetAbility() and params.unit:IsAlive() then
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		if self.slow_duration > 0 then
			params.unit:AddNewModifier( caster, ability, "modifier_axe_counter_helix_jofurr", {duration = self.slow_duration} )
		end
		if self.reduction_duration > 0 then
			local buff = params.unit:FindModifierByName( "modifier_axe_counter_helix_skald")
			if buff then
				buff = params.unit:AddNewModifier( caster, ability, "modifier_axe_counter_helix_skald", {duration = self.reduction_duration} )
				if buff:GetStackCount() < self.max_red_stacks then
					buff:IncrementStackCount()
				end
			elseif IsEntitySafe( params.unit ) and params.unit:IsAlive() then
				buff = params.unit:AddNewModifier( caster, ability, "modifier_axe_counter_helix_skald", {duration = self.reduction_duration} )
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
	return false
end

function modifier_axe_counter_helix_passive:IsPurgable()
	return false
end

modifier_axe_counter_helix_skald = class({})
LinkLuaModifier( "modifier_axe_counter_helix_skald", "heroes/hero_axe/axe_counter_helix", LUA_MODIFIER_MOTION_NONE )

function modifier_axe_counter_helix_skald:OnCreated()
	self.atk_dmg_reduction = -self:GetSpecialValueFor("atk_dmg_reduction")
end

function modifier_axe_counter_helix_skald:DeclareFunctions()
	return {MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE }
end

function modifier_axe_counter_helix_skald:GetModifierDamageOutgoing_Percentage()
	return self.atk_dmg_reduction * self:GetStackCount()
end

modifier_axe_counter_helix_jofurr = class({})
LinkLuaModifier( "modifier_axe_counter_helix_jofurr", "heroes/hero_axe/axe_counter_helix", LUA_MODIFIER_MOTION_NONE )

function modifier_axe_counter_helix_jofurr:OnCreated()
	self.slow = -self:GetSpecialValueFor("slow")
end

function modifier_axe_counter_helix_jofurr:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end
function modifier_axe_counter_helix_jofurr:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end