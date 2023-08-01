pudge_rot = class({})
--------------------------------------------------------------------------------

function pudge_rot:ProcsMagicStick()
	return false
end

--------------------------------------------------------------------------------

function pudge_rot:OnToggle()
	if self:GetToggleState() then
		self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_pudge_rot_aura", nil )

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
	self.rot_radius = self:GetSpecialValueFor( "rot_radius" )
	self.rot_slow = self:GetSpecialValueFor( "rot_slow" )
	self.rot_damage = self:GetSpecialValueFor( "rot_damage" )
	self.rot_str_damage = self:GetSpecialValueFor( "rot_str_damage" ) / 100
	self.rot_tick = self:GetSpecialValueFor( "rot_tick" )
	
	self.scepter_rot_regen_reduction_pct = -self:GetSpecialValueFor( "scepter_rot_regen_reduction_pct" )
	self.scepter_bonus_enemy_damage = 1 + self:GetSpecialValueFor( "scepter_bonus_enemy_damage" )/100
	
	if not self:GetCaster():HasScepter() then
		self.scepter_rot_regen_reduction_pct = 0
		self.scepter_bonus_enemy_damage = 1
	end

	if IsServer() then
		if self:GetParent() == self:GetCaster() then
			EmitSoundOn( "Hero_Pudge.Rot", self:GetCaster() )
			local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_pudge/pudge_rot.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
			ParticleManager:SetParticleControl( nFXIndex, 1, Vector( self.rot_radius, 1, self.rot_radius ) )
			self:AddParticle( nFXIndex, false, false, -1, false, false )
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
	end
end

function modifier_pudge_rot_debuff:OnIntervalThink()
	if IsServer() then
		local flDamagePerTick = self.rot_tick * ( self.rot_damage + self:GetCaster():GetStrength() * self.rot_str_damage ) * self.scepter_bonus_enemy_damage
		if self:GetCaster():IsAlive() then
			self:GetAbility():DealDamage( self:GetCaster(), self:GetParent(), flDamagePerTick )
		end
	end
end

function modifier_pudge_rot_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE 
	}

	return funcs
end

function modifier_pudge_rot_debuff:GetModifierMoveSpeedBonus_Percentage( params )
	return self.rot_slow
end

function modifier_pudge_rot_debuff:GetModifierHPRegenAmplify_Percentage( params )
	return self.scepter_rot_regen_reduction_pct
end

function modifier_pudge_rot_debuff:IsDebuff()
	return true
end

LinkLuaModifier( "modifier_pudge_rot_aura", "heroes/hero_pudge/pudge_rot", LUA_MODIFIER_MOTION_NONE )
modifier_pudge_rot_aura = class(modifier_pudge_rot_debuff)

function modifier_pudge_rot_aura:OnIntervalThink()
	if IsServer() then
		if not self:GetAbility():GetToggleState() then
			self:Destroy()
			return
		end
		local flDamagePerTick = self.rot_tick * self.rot_damage
		if self:GetCaster():IsAlive() then
			self:GetAbility():DealDamage( self:GetCaster(), self:GetParent(), flDamagePerTick, {damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NON_LETHAL } )
		end
	end
end

function modifier_pudge_rot_aura:GetModifierMoveSpeedBonus_Percentage( params )
	return 0
end

function modifier_pudge_rot_aura:GetModifierHPRegenAmplify_Percentage( params )
	return 0
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
