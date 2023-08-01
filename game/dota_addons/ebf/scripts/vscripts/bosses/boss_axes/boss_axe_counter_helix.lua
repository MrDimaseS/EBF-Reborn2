boss_axe_counter_helix = class({})

function boss_axe_counter_helix:ShouldUseResources()
	return true
end

function boss_axe_counter_helix:GetIntrinsicModifierName()
	return "modifier_boss_axe_counter_helix_passive"
end

modifier_boss_axe_counter_helix_passive = class({})
LinkLuaModifier( "modifier_boss_axe_counter_helix_passive", "bosses/boss_axes/boss_axe_counter_helix", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_axe_counter_helix_passive:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
	}

	return funcs
end

function modifier_boss_axe_counter_helix_passive:GetModifierIncomingDamage_Percentage( params )
	if not IsEntitySafe(params.attacker:IsNull()) then return end
	local buff = params.attacker:FindModifierByNameAndCaster( "modifier_boss_axe_counter_helix_damage_reduction", self:GetCaster() )
	if IsModifierSafe( buff ) then
		return -self:GetSpecialValueFor("shard_damage_reduction") * buff:GetStackCount()
	end
end

function modifier_boss_axe_counter_helix_passive:OnAttackLanded( params )
	if IsServer() then
		if params.target~=self:GetCaster() then return end
		if self:GetCaster():PassivesDisabled() then return end
		if not self:GetAbility():IsCooldownReady() then return end
		if params.attacker:GetTeamNumber()==params.target:GetTeamNumber() then return end
		if params.attacker:IsOther() or params.attacker:IsBuilding() then return end
		if not IsEntitySafe(params.attacker:IsNull()) then return end
		if not IsEntitySafe(params.target:IsNull()) then return end
		if not Params.target:IsAlive() then return end
		local caster = self:GetCaster()
		
		local stacks = TernaryOperator( self:GetSpecialValueFor("hero_trigger"), params.attacker:IsRealHero(), 1 )
		self:SetStackCount( self:GetStackCount() + stacks ) 
		if self:GetStackCount() >= self:GetSpecialValueFor("trigger_attacks") then
			local ability = self:GetAbility()
			self:SetStackCount(0)
			
			local shard_max_stacks = self:GetSpecialValueFor("shard_max_stacks")
			local shard_debuff_duration = self:GetSpecialValueFor("shard_debuff_duration")
			
			for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self:GetSpecialValueFor("radius") ) ) do
				if shard_debuff_duration > 0 and IsEntitySafe( enemy ) and enemy:IsAlive() then
					local buff = enemy:FindModifierByNameAndCaster( "modifier_boss_axe_counter_helix_damage_reduction", caster )
					if buff then
						buff:ForceRefresh()
						if buff:GetStackCount() < shard_max_stacks then
							buff:IncrementStackCount()
						end
					else
						buff = enemy:AddNewModifier( caster, ability, "modifier_boss_axe_counter_helix_damage_reduction", {duration = shard_debuff_duration} )
						buff:SetStackCount(1)
					end
				end
				ability:DealDamage( caster, enemy, self:GetSpecialValueFor("damage") )
			end
			
			ParticleManager:CreateParticle( "particles/units/heroes/hero_axe/axe_counterhelix.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
			EmitSoundOn( "Hero_Axe.CounterHelix", caster )
			caster:StartGesture( ACT_DOTA_CAST_ABILITY_3 )
			ability:SetCooldown()
		end
	end
end

function modifier_boss_axe_counter_helix_passive:IsHidden()
	return self:GetStackCount() <= 0
end

function modifier_boss_axe_counter_helix_passive:IsPurgable()
	return false
end

modifier_boss_axe_counter_helix_damage_reduction = class({})
LinkLuaModifier( "modifier_boss_axe_counter_helix_damage_reduction", "bosses/boss_axes/boss_axe_counter_helix", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_axe_counter_helix_damage_reduction:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end