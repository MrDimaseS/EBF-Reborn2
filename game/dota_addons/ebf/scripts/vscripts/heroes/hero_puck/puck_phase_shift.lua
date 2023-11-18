puck_phase_shift = class({})

function puck_phase_shift:GetIntrinsicModifierName()
	return "modifier_puck_phase_shift_shard"
end

function puck_phase_shift:GetChannelTime()
	self.duration = self:GetSpecialValueFor( "duration" )
	return self.duration
end

function puck_phase_shift:OnSpellStart()
	local caster = self:GetCaster()
	self.phase = caster:AddNewModifier(caster, self, "modifier_puck_phase_shift_immune", {})
	EmitSoundOn("Hero_Puck.Phase_Shift", caster)
	self:SetFrozenCooldown( true )
	
	if caster:HasShard() then
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), caster:GetAttackRange() + self:GetSpecialValueFor("shard_attack_range_bonus") ) ) do
			caster:PerformGenericAttack(enemy, false, false)
		end
	end
end

function puck_phase_shift:OnChannelFinish(bInterrupt)
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_puck_phase_shift_immune", {duration = self:GetSpecialValueFor( "linger_duration" ) })
	self:SetFrozenCooldown( false )
	StopSoundOn("Hero_Puck.Phase_Shift", caster)
end

modifier_puck_phase_shift_immune = class({})
LinkLuaModifier("modifier_puck_phase_shift_immune", "heroes/hero_puck/puck_phase_shift", LUA_MODIFIER_MOTION_NONE)

function modifier_puck_phase_shift_immune:OnCreated()
	if IsServer() then
		self:GetParent():StartGesture( ACT_DOTA_VERSUS )
	end
end

function modifier_puck_phase_shift_immune:OnDestroy()
	if IsServer() then
		self:GetParent():RemoveGesture( ACT_DOTA_VERSUS )
	end
end

function modifier_puck_phase_shift_immune:CheckState()
	return {[MODIFIER_STATE_ATTACK_IMMUNE] = true,
			[MODIFIER_STATE_MAGIC_IMMUNE] = true,
			[MODIFIER_STATE_INVULNERABLE] = true,
			[MODIFIER_STATE_NO_HEALTH_BAR] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			[MODIFIER_STATE_UNSELECTABLE] = true,
			[MODIFIER_STATE_OUT_OF_GAME] = true}
end

function modifier_puck_phase_shift_immune:GetStatusEffectName()
	return "particles/status_fx/status_effect_phase_shift.vpcf"
end

function modifier_puck_phase_shift_immune:StatusEffectPriority()
	return 5
end

function modifier_puck_phase_shift_immune:GetEffectName()
	return "particles/units/heroes/hero_puck/puck_phase_shift.vpcf"
end

modifier_puck_phase_shift_shard = class({})
LinkLuaModifier("modifier_puck_phase_shift_shard", "heroes/hero_puck/puck_phase_shift", LUA_MODIFIER_MOTION_NONE)

function modifier_puck_phase_shift_shard:OnCreated()
	self:OnRefresh()
end

function modifier_puck_phase_shift_shard:OnRefresh()
	self.shard_bonus_damage = self:GetSpecialValueFor("shard_bonus_damage")
end

function modifier_puck_phase_shift_shard:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL,
	}
	return funcs
end

function modifier_puck_phase_shift_shard:GetModifierProcAttack_BonusDamage_Magical()
	if self:GetCaster():HasShard() then
		return self.shard_bonus_damage
	end
end

function modifier_puck_phase_shift_shard:IsHidden()
	return true
end