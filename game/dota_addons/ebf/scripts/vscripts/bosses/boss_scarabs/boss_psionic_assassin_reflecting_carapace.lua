boss_psionic_assassin_reflecting_carapace = class({})

function boss_psionic_assassin_reflecting_carapace:ShouldUseResources()
	return true
end

function boss_psionic_assassin_reflecting_carapace:GetIntrinsicModifierName()
	return "modifier_boss_psionic_assassin_reflecting_carapace_handler"
end

modifier_boss_psionic_assassin_reflecting_carapace_handler = class({})
LinkLuaModifier( "modifier_boss_psionic_assassin_reflecting_carapace_handler", "bosses/boss_scarabs/boss_psionic_assassin_reflecting_carapace.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_boss_psionic_assassin_reflecting_carapace_handler:OnCreated()
	self:OnRefresh()
	self.health_lost = 0
end

function modifier_boss_psionic_assassin_reflecting_carapace_handler:OnRefresh()
	self.reflect_duration = self:GetSpecialValueFor("reflect_duration")
	self.hp_trigger_threshold = self:GetSpecialValueFor("hp_trigger_threshold") / 100
end

function modifier_boss_psionic_assassin_reflecting_carapace_handler:DeclareFunctions()
	return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_boss_psionic_assassin_reflecting_carapace_handler:OnTakeDamage( params )
	if params.unit == self:GetParent() and self:GetAbility():IsCooldownReady() and not self:GetParent():PassivesDisabled() then
		self.health_lost = self.health_lost + params.damage
		if self.health_lost >= self:GetParent():GetMaxHealth() * self.hp_trigger_threshold then
			params.unit:AddNewModifier( params.unit, self:GetAbility(), "modifier_boss_psionic_assassin_reflecting_carapace_reflect", {duration = self.reflect_duration} )
			params.unit:Dispel( params.unit, true )
			EmitSoundOn( "Hero_NyxAssassin.SpikedCarapace", params.unit )
			self.health_lost = 0
			self:GetAbility():SetCooldown()
		end
	end
end

function modifier_boss_psionic_assassin_reflecting_carapace_handler:IsHidden()
	return true
end

modifier_boss_psionic_assassin_reflecting_carapace_reflect = class({})
LinkLuaModifier( "modifier_boss_psionic_assassin_reflecting_carapace_reflect", "bosses/boss_scarabs/boss_psionic_assassin_reflecting_carapace.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_boss_psionic_assassin_reflecting_carapace_reflect:OnCreated()
	self.damage_reflect_pct = 0
	self.max_damage_reflect_pct = self:GetSpecialValueFor("damage_reflect_pct")
	self.delay_duration = self:GetSpecialValueFor("delay_duration")
	self.reflect_scaling = self.max_damage_reflect_pct / self.delay_duration
	self:StartIntervalThink( 0.1 )
end

function modifier_boss_psionic_assassin_reflecting_carapace_reflect:OnIntervalThink()
	self.damage_reflect_pct = math.min( self.damage_reflect_pct + self.reflect_scaling * 0.1, self.max_damage_reflect_pct )
	print( self.damage_reflect_pct )
	if self.damage_reflect_pct >= self.max_damage_reflect_pct then
		self:StartIntervalThink( -1 )
	end
end

function modifier_boss_psionic_assassin_reflecting_carapace_reflect:OnDestroy()
	if self:GetRemainingTime() > 0 then return end -- dispelled
	local vendetta = self:GetCaster():FindAbilityByName("boss_psionic_assassin_vendetta")
	if vendetta then
		vendetta:TriggerVendetta()
	end
end

function modifier_boss_psionic_assassin_reflecting_carapace_reflect:DeclareFunctions()
	return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_boss_psionic_assassin_reflecting_carapace_reflect:OnTakeDamage( params )
	if not self.damage_reflect_pct then return end
	if HasBit(params.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) or HasBit(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) then return end
	if params.unit == self:GetParent() then
		self:GetAbility():DealDamage( params.unit, params.attacker, params.original_damage, {damage_type = params.damage_type, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_REFLECTION} )
		ParticleManager:FireRopeParticle( "particles/units/heroes/hero_nyx_assassin/nyx_assassin_spiked_carapace_hit.vpcf", PATTACH_POINT_FOLLOW, params.unit, params.attacker )
	end
end

function modifier_boss_psionic_assassin_reflecting_carapace_reflect:GetEffectName()
	return "particles/units/heroes/hero_nyx_assassin/nyx_assassin_spiked_carapace.vpcf"
end