pudge_rot = class({})
--------------------------------------------------------------------------------

function pudge_rot:ProcsMagicStick()
	return false
end

--------------------------------------------------------------------------------

function pudge_rot:OnToggle()
	if self:GetToggleState() then
		self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_pudge_rot_aura", nil )
		if self:GetSpecialValueFor("time_for_max_stacks") > 0 then
			self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_pudge_rot_flesh_carver", nil )
		end
		if self:GetSpecialValueFor("time_for_max_rot_stacks") > 0 then
			self:GetCaster()._rotPowerModifier = self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_pudge_rot_rotten_giant", nil )
		end


		if not self:GetCaster():IsChanneling() then
			self:GetCaster():StartGesture( ACT_DOTA_CAST_ABILITY_ROT )
		end
	else
		local hRotBuff = self:GetCaster():FindModifierByName( "modifier_pudge_rot_aura" )
		if hRotBuff ~= nil then
			hRotBuff:Destroy()
		end
	end
end

LinkLuaModifier( "modifier_pudge_rot_debuff", "heroes/hero_pudge/pudge_rot", LUA_MODIFIER_MOTION_NONE )
modifier_pudge_rot_debuff = class({})

function modifier_pudge_rot_debuff:OnCreated( kv )
	self.base_rot_radius = self:GetSpecialValueFor( "rot_radius" )
	self.rot_radius = self.base_rot_radius
	self.bonus_radius_per_sec = self:GetSpecialValueFor( "bonus_radius_per_sec" )
	self.rot_slow = self:GetSpecialValueFor( "rot_slow" )
	self.rot_regen_reduction = self:GetSpecialValueFor( "rot_regen_reduction" )
	self.rot_damage = self:GetSpecialValueFor( "rot_damage" )
	self.bonus_damage_per_sec = self:GetSpecialValueFor( "bonus_damage_per_sec" )
	self.rot_tick = self:GetSpecialValueFor( "rot_tick" )
	self.self_damage = self:GetSpecialValueFor( "self_damage" ) / 100
	self.max_rot_power = self:GetSpecialValueFor( "max_rot_power" ) / 100
	
	if IsServer() then
		if self:GetParent() == self:GetCaster() then
			self.damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NON_LETHAL
			self.self_rot = true
			EmitSoundOn( "Hero_Pudge.Rot", self:GetCaster() )
			self.nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_pudge/pudge_rot.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
			ParticleManager:SetParticleControl( self.nFXIndex, 1, Vector( self.rot_radius, 1, self.rot_radius ) )
			self:AddParticle( self.nFXIndex, false, false, -1, false, false )
		else
			local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_pudge/pudge_rot_recipient.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
			self:AddParticle( nFXIndex, false, false, -1, false, false )
		end

		self:StartIntervalThink( self.rot_tick )
		self:OnIntervalThink()
	end
end

function modifier_pudge_rot_debuff:OnDestroy()
	if IsServer() then
		StopSoundOn( "Hero_Pudge.Rot", self:GetCaster() )
		ParticleManager:ClearParticle( self.nFXIndex, true )
	end
end

function modifier_pudge_rot_debuff:OnIntervalThink()
	if IsServer() then
		if not self:GetAbility():GetToggleState() then
			self:Destroy()
			return
		end
		local flDamagePerTick = self.rot_tick * self.rot_damage
		
		if self.max_rot_power > 0 and IsModifierSafe( self:GetCaster()._rotPowerModifier ) then
			local rotPower = 1 + self.max_rot_power * self:GetCaster()._rotPowerModifier:GetStackCount() / 100
			flDamagePerTick = flDamagePerTick * rotPower
			if self.rot_radius ~= self.base_rot_radius * rotPower then
				self.rot_radius = self.base_rot_radius * rotPower
				ParticleManager:SetParticleControl( self.nFXIndex, 1, Vector( self.rot_radius, 1, self.rot_radius ) )
			end
		end
		if self.self_rot then
			flDamagePerTick = flDamagePerTick * self.self_damage
		end
		if self:GetCaster():IsAlive() then
			self:GetAbility():DealDamage( self:GetCaster(), self:GetParent(), flDamagePerTick, {damage_flags = self.damage_flags } )
		else
			self:Destroy()
		end
	end
end

function modifier_pudge_rot_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
		MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
		
	}
	return funcs
end

function modifier_pudge_rot_debuff:GetModifierMoveSpeedBonus_Percentage( params )
	return self.rot_slow
end

function modifier_pudge_rot_debuff:GetModifierHealAmplify_PercentageSource( params )
	return self.rot_regen_reduction
end

function modifier_pudge_rot_debuff:GetModifierSpellLifestealRegenAmplify_Percentage( params )
	return self.rot_regen_reduction
end

function modifier_pudge_rot_debuff:GetModifierLifestealRegenAmplify_Percentage( params )
	return self.rot_regen_reduction
end

function modifier_pudge_rot_debuff:GetModifierHPRegenAmplify_Percentage( params )
	return self.rot_regen_reduction
end

function modifier_pudge_rot_debuff:IsDebuff()
	return true
end

LinkLuaModifier( "modifier_pudge_rot_aura", "heroes/hero_pudge/pudge_rot", LUA_MODIFIER_MOTION_NONE )
modifier_pudge_rot_aura = class(modifier_pudge_rot_debuff)

function modifier_pudge_rot_aura:GetModifierMoveSpeedBonus_Percentage( params )
	if self:GetParent():GetHealth() < self.rot_damage then
		return self.rot_slow
	else
		return 0
	end
end

function modifier_pudge_rot_aura:IsAura()
	return true
end

function modifier_pudge_rot_aura:GetModifierAura()
	return "modifier_pudge_rot_debuff"
end

function modifier_pudge_rot_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_pudge_rot_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_pudge_rot_aura:GetAuraRadius()
	return self.rot_radius
end

function modifier_pudge_rot_aura:GetAuraDuration()
	return 0.1
end

LinkLuaModifier( "modifier_pudge_rot_flesh_carver", "heroes/hero_pudge/pudge_rot", LUA_MODIFIER_MOTION_NONE )
modifier_pudge_rot_flesh_carver = class({})

function modifier_pudge_rot_flesh_carver:OnCreated()
	self.time_for_max_stacks = self:GetSpecialValueFor("time_for_max_stacks")
	self.time_for_decay = self:GetSpecialValueFor("time_for_decay")
	self.max_bonus_damage = self:GetSpecialValueFor("max_bonus_damage")
	
	self.rot_tick = self:GetSpecialValueFor( "rot_tick" )
	self.stacks_per_tick = math.floor(100 / self.time_for_max_stacks) * self.rot_tick
	
	if IsServer() then
		self:StartIntervalThink( self.rot_tick )
	end
end

function modifier_pudge_rot_flesh_carver:OnIntervalThink()
	if self:GetCaster():HasModifier("modifier_pudge_rot_aura") then
		if self:GetStackCount() < 100 then
			self:SetStackCount( math.min( 100, self:GetStackCount() + self.stacks_per_tick ) )
		end
	else
		if self:GetStackCount() <= self.stacks_per_tick then
			self:Destroy()
		else
			self:SetStackCount( self:GetStackCount() - self.stacks_per_tick )
		end
	end
end

function modifier_pudge_rot_flesh_carver:DeclareFunctions()
	return {MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE}
end

function modifier_pudge_rot_flesh_carver:GetModifierBaseDamageOutgoing_Percentage()
	return self.max_bonus_damage * self:GetStackCount() / 100
end

function modifier_pudge_rot_flesh_carver:IsPurgable()
	return false
end

LinkLuaModifier( "modifier_pudge_rot_rotten_giant", "heroes/hero_pudge/pudge_rot", LUA_MODIFIER_MOTION_NONE )
modifier_pudge_rot_rotten_giant = class({})

function modifier_pudge_rot_rotten_giant:OnCreated()
	self.time_for_max_stacks = self:GetSpecialValueFor("time_for_max_rot_stacks")
	self.time_for_decay = self:GetSpecialValueFor("time_for_rot_decay")
	
	self.rot_tick = self:GetSpecialValueFor( "rot_tick" )
	self.stacks_per_tick = math.floor(100 / self.time_for_max_stacks) * self.rot_tick
	
	if IsServer() then
		self:StartIntervalThink( self.rot_tick )
	end
end

function modifier_pudge_rot_rotten_giant:OnIntervalThink()
	if self:GetCaster():HasModifier("modifier_pudge_rot_aura") then
		if self:GetStackCount() < 100 then
			self:SetStackCount( math.min( 100, self:GetStackCount() + self.stacks_per_tick ) )
		end
	else
		self:Destroy()
	end
end

function modifier_pudge_rot_rotten_giant:IsPurgable()
	return false
end