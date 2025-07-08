bounty_hunter_track = class({})

function bounty_hunter_track:IsStealable()
	return true
end

function bounty_hunter_track:IsHiddenWhenStolen()
	return false
end

function bounty_hunter_track:CastFilterResultTarget( target )
	return self:UnitFilter( target )
end

function bounty_hunter_track:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	EmitSoundOn("Hero_BountyHunter.Target", caster)
	self:Track(target)
end

function bounty_hunter_track:Track(target)
	local caster = self:GetCaster()
	if target:TriggerSpellAbsorb( self ) then return end
	ParticleManager:FireRopeParticle( "particles/units/heroes/hero_bounty_hunter/bounty_hunter_track_cast.vpcf", PATTACH_POINT, caster, target )
	target:AddNewModifier(caster, self, "modifier_bounty_hunter_track_debuff_mark", {Duration = self:GetSpecialValueFor("duration")})
end

modifier_bounty_hunter_track_debuff_mark = class({})
LinkLuaModifier( "modifier_bounty_hunter_track_debuff_mark", "heroes/hero_bounty_hunter/bounty_hunter_track.lua" ,LUA_MODIFIER_MOTION_NONE )
function modifier_bounty_hunter_track_debuff_mark:OnCreated()
	self:OnRefresh()
    if IsServer() then
		local caster = self:GetCaster()
		local parent = self:GetParent()
    	local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_bounty_hunter/bounty_hunter_track_trail.vpcf", PATTACH_POINT_FOLLOW, caster)
    				ParticleManager:SetParticleControlEnt(nfx, 0, parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
    				ParticleManager:SetParticleControlEnt(nfx, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
    	self:AttachEffect(nfx)

    	local nfx2 = ParticleManager:CreateParticle("particles/units/heroes/hero_bounty_hunter/bounty_hunter_track_shield.vpcf", PATTACH_OVERHEAD_FOLLOW, caster)
					ParticleManager:SetParticleControlEnt(nfx2, 0, parent, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
		self:AttachEffect(nfx2)

		self:StartIntervalThink(0.1)
    end
end

function modifier_bounty_hunter_track_debuff_mark:OnRefresh()
	self.target_damage_amp = self:GetSpecialValueFor("target_damage_amp")
	self.bonus_gold_radius = self:GetSpecialValueFor("bonus_gold_radius")
	
	self.self_damage_amp = self:GetSpecialValueFor("self_damage_amp")
	self.ally_lifesteal = self:GetSpecialValueFor("ally_lifesteal")
	self.proc_jinada = self:GetSpecialValueFor("proc_jinada")
	
	self:GetParent()._attackLifestealTargetModifiersList = self:GetParent()._attackLifestealTargetModifiersList or {}
	self:GetParent()._attackLifestealTargetModifiersList[self] = true
end

function modifier_bounty_hunter_track_debuff_mark:OnIntervalThink()
	AddFOWViewer(self:GetCaster():GetTeamNumber(), self:GetParent():GetAbsOrigin(), 150, 0.1, false)
end

function modifier_bounty_hunter_track_debuff_mark:DeclareFunctions()
    return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
			MODIFIER_EVENT_SPELL_APPLIED_SUCCESSFULLY
			}
end

function modifier_bounty_hunter_track_debuff_mark:GetModifierIncomingDamage_Percentage( params )
	return TernaryOperator( self.self_damage_amp, params.attacker == self:GetCaster() and self.self_damage_amp > 0, self.target_damage_amp )
end

function modifier_bounty_hunter_track_debuff_mark:GetModifierProperty_PhysicalLifestealTarget( params )
	return self.ally_lifesteal
end

function modifier_bounty_hunter_track_debuff_mark:OnSpellAppliedSuccessfully( params )
	local caster = self:GetCaster()
	
	if proc_jinada == 0 then return end
	if params.ability:GetCaster() ~= caster then return end
	local parent = self:GetParent()
	if params.target ~= parent then return end
	self._jinada = self._jinada or caster:FindAbilityByName("bounty_hunter_jinada")
	if params.ability == self._jinada then return end
	self._jinada:TriggerJinada( parent )
end

function modifier_bounty_hunter_track_debuff_mark:IsAura()
	return true
end

function modifier_bounty_hunter_track_debuff_mark:GetModifierAura()
	return "modifier_bounty_hunter_track_debuff_aura"
end

function modifier_bounty_hunter_track_debuff_mark:GetAuraEntityReject( entity )
	return not (entity == self:GetCaster() or self.ally_lifesteal > 0)
end

function modifier_bounty_hunter_track_debuff_mark:GetAuraRadius()
	return self.bonus_gold_radius
end

function modifier_bounty_hunter_track_debuff_mark:GetAuraDuration()
	return 0.5
end

function modifier_bounty_hunter_track_debuff_mark:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_bounty_hunter_track_debuff_mark:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_HERO
end

modifier_bounty_hunter_track_debuff_aura = class({})
LinkLuaModifier( "modifier_bounty_hunter_track_debuff_aura", "heroes/hero_bounty_hunter/bounty_hunter_track.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_bounty_hunter_track_debuff_aura:OnCreated()
	self:OnRefresh()
end

function modifier_bounty_hunter_track_debuff_aura:OnRefresh()
	self.bonus_move_speed_pct = self:GetSpecialValueFor("bonus_move_speed_pct")
	self.bonus_attackspeed = self.bonus_move_speed_pct * self:GetSpecialValueFor("bonus_attackspeed")
end

function modifier_bounty_hunter_track_debuff_aura:DeclareFunctions()
    return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT}
end

function modifier_bounty_hunter_track_debuff_aura:GetModifierMoveSpeedBonus_Percentage( params )
	return self.bonus_move_speed_pct
end

function modifier_bounty_hunter_track_debuff_aura:GetModifierAttackSpeedBonus_Constant( params )
	return self.bonus_attackspeed
end

function modifier_bounty_hunter_track_debuff_aura:GetEffectName()
	return "particles/units/heroes/hero_bounty_hunter/bounty_hunter_track_haste.vpcf"
end