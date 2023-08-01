legion_commander_duel = class({})

function legion_commander_duel:GetIntrinsicModifierName()
	return "modifier_legion_commander_duel_wins"
end

function legion_commander_duel:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	caster:MoveToTargetToAttack( target )
	target:MoveToTargetToAttack( caster )
	
	caster:AddNewModifier( caster, self, "modifier_legion_commander_duel_taunt", {duration = self:GetSpecialValueFor("duration"), target = target:entindex() } )
	target:AddNewModifier( caster, self, "modifier_legion_commander_duel_taunt", {duration = self:GetSpecialValueFor("duration"), target = caster:entindex() } )
	
	EmitSoundOn( "Hero_LegionCommander.Duel.Cast", caster )
	EmitSoundOn( "Hero_LegionCommander.Duel", target )
	
	local odds = caster:FindAbilityByName("legion_commander_overwhelming_odds")
	if odds then
		odds:OnSpellStart()
	end
end


modifier_legion_commander_duel_wins = class({})
LinkLuaModifier( "modifier_legion_commander_duel_wins","heroes/hero_legion_commander/legion_commander_duel.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_legion_commander_duel_wins:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE }
end

function modifier_legion_commander_duel_wins:GetModifierPreAttack_BonusDamage()
	return self:GetStackCount()
end

function modifier_legion_commander_duel_wins:IsHidden()
	return self:GetStackCount() == 0
end

function modifier_legion_commander_duel_wins:IsPurgable()
	return false
end

function modifier_legion_commander_duel_wins:RemoveOnDeath()
	return false
end

function modifier_legion_commander_duel_wins:IsPermanent()
	return true
end

modifier_legion_commander_duel_taunt = class({})
LinkLuaModifier( "modifier_legion_commander_duel_taunt","heroes/hero_legion_commander/legion_commander_duel.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_legion_commander_duel_taunt:OnCreated( kv )
	self.reward = self:GetTalentSpecialValueFor("reward_damage")
	if IsServer() then
		self.target = EntIndexToHScript( kv.target )
		self:GetParent():SetForceAttackTarget( self.target )
		if self:GetParent() == self:GetCaster() then
			local duelFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_legion_commander/legion_duel_ring.vpcf", PATTACH_WORLDORIGIN, nil )
			ParticleManager:SetParticleControl( duelFX, 0, (self:GetParent():GetAbsOrigin() + self.target:GetAbsOrigin()) / 2 )
			ParticleManager:SetParticleControl( duelFX, 61, (self:GetParent():GetAbsOrigin() + self.target:GetAbsOrigin()) / 2 )
			
			self:AddEffect( duelFX )
		end
	end
end

function modifier_legion_commander_duel_taunt:OnDestroy( kv )
	if IsServer() then
		self.target:RemoveModifierByName("modifier_legion_commander_duel_taunt")
		self:GetParent():SetForceAttackTarget( nil )
		
		if self:GetParent() == self:GetCaster() then -- if modifier is LC's
			local wins = self:GetParent():FindModifierByName("modifier_legion_commander_duel_wins")
			if not self.target:IsAlive() then -- LC won
				wins:SetStackCount( wins:GetStackCount() + self.reward )
				EmitSoundOn( "Hero_LegionCommander.Duel.Victory", self:GetParent() )
			end
			if not self:GetParent():IsAlive() then -- LC lost
				wins:SetStackCount( math.max( 0, wins:GetStackCount() - self.reward ) )
			end
		else
			StopSoundOn( "Hero_LegionCommander.Duel", target )
		end
	end
end

function modifier_legion_commander_duel_taunt:CheckState()
	return {[MODIFIER_STATE_SILENCED] = true,
			[MODIFIER_STATE_MUTED] = true,
			[MODIFIER_STATE_TAUNTED] = true,
			[MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS] = true}
end

function modifier_legion_commander_duel_taunt:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end

function modifier_legion_commander_duel_taunt:GetModifierIncomingDamage_Percentage()
	if self:GetParent() == self:GetCaster() and self:GetCaster():HasScepter() then
		return -self:GetTalentSpecialValueFor("scepter_damage_reduction_pct")
	end
end

function modifier_legion_commander_duel_taunt:IsPurgable()
	return false
end