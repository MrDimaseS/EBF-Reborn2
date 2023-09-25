abaddon_borrowed_time = class({})

function abaddon_borrowed_time:IsStealable()
	return true
end

function abaddon_borrowed_time:IsHiddenWhenStolen()
	return false
end

function abaddon_borrowed_time:GetIntrinsicModifierName()
	return "modifier_abaddon_borrowed_time_autoproc"
end

function abaddon_borrowed_time:Activate()
	local caster = self:GetCaster()
	caster:Dispel(caster, true)
	EmitSoundOn("Hero_Abaddon.BorrowedTime", caster)
	local duration = TernaryOperator( self:GetSpecialValueFor("duration"), not caster:HasScepter(), self:GetSpecialValueFor("duration_scepter") )
	caster:AddNewModifier(caster, self, "modifier_abaddon_borrowed_time_active", {duration = duration})
	self:EndCooldown()
	self:SetActivated( false )
end

function abaddon_borrowed_time:OnSpellStart()
	self:Activate()
end

modifier_abaddon_borrowed_time_autoproc = class({})
LinkLuaModifier("modifier_abaddon_borrowed_time_autoproc", "heroes/hero_abaddon/abaddon_borrowed_time", LUA_MODIFIER_MOTION_NONE)

function modifier_abaddon_borrowed_time_autoproc:OnCreated()
	self:OnRefresh()
end

function modifier_abaddon_borrowed_time_autoproc:OnRefresh()
	self.hp_threshold = self:GetSpecialValueFor("hp_threshold")
end

function modifier_abaddon_borrowed_time_autoproc:DeclareFunctions()
	return {MODIFIER_PROPERTY_MIN_HEALTH, MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_abaddon_borrowed_time_autoproc:GetMinHealth(params)
	if self:GetAbility():IsCooldownReady() and self:GetParent():IsRealHero() then return 1 end
end

function modifier_abaddon_borrowed_time_autoproc:OnTakeDamage(params)
	if params.unit ~= self:GetParent() then return end
	if not self:GetAbility():IsCooldownReady() then return end
	if self:GetParent():IsFakeHero() then return end
	if self:GetParent():PassivesDisabled() then return end
	if self:GetParent():GetHealthPercent() <= self.hp_threshold then
		self:GetAbility():Activate()
	end
end

function modifier_abaddon_borrowed_time_autoproc:IsHidden()
	return true
end

modifier_abaddon_borrowed_time_active = class({})
LinkLuaModifier("modifier_abaddon_borrowed_time_active", "heroes/hero_abaddon/abaddon_borrowed_time", LUA_MODIFIER_MOTION_NONE)

function modifier_abaddon_borrowed_time_active:OnCreated()
	self:OnRefresh()
end

function modifier_abaddon_borrowed_time_active:OnRefresh()
	self.redirect_range_scepter = self:GetSpecialValueFor("redirect_range_scepter")
	self.immolate_damage = self:GetSpecialValueFor("immolate_damage")
	self.immolate_aoe = self:GetSpecialValueFor("immolate_aoe")
	self.immolate_tick = self:GetSpecialValueFor("immolate_tick")
	if IsServer() then
		self:StartIntervalThink(self.immolate_tick)
	end
end

function modifier_abaddon_borrowed_time_active:OnRemoved()
	if IsServer() then
		self:GetAbility():SetCooldown()
		self:GetAbility():SetActivated( true )
	end
end

function modifier_abaddon_borrowed_time_active:OnIntervalThink()
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	
	local damage = self.immolate_damage * self.immolate_tick
	ability:DealDamage( caster, caster, damage, {damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NON_LETHAL } )
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self.immolate_aoe ) ) do
		ability:DealDamage( caster, enemy, damage, {damage_type = DAMAGE_TYPE_MAGICAL} )
	end
end

function modifier_abaddon_borrowed_time_active:GetEffectName()
	return "particles/units/heroes/hero_abaddon/abaddon_borrowed_time.vpcf"
end

function modifier_abaddon_borrowed_time_active:GetStatusEffectName()
	return "particles/status_fx/status_effect_abaddon_borrowed_time.vpcf"
end

function modifier_abaddon_borrowed_time_active:StatusEffectPriority()
	return 10
end

function modifier_abaddon_borrowed_time_active:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE}
end

function modifier_abaddon_borrowed_time_active:GetModifierIncomingDamage_Percentage(params)
	if params.damage < 0 then return end
	local parent = self:GetParent()
	parent:HealEvent( params.damage, self:GetAbility(), self:GetCaster() )
	ParticleManager:FireParticle("particles/units/heroes/hero_abaddon/abaddon_borrowed_time_heal.vpcf", PATTACH_POINT_FOLLOW, parent )
	return -999
end

function modifier_abaddon_borrowed_time_active:IsAura()
	return self:GetCaster():HasScepter()
end

function modifier_abaddon_borrowed_time_active:GetModifierAura()
	return "modifier_abaddon_borrowed_time_scepter"
end

function modifier_abaddon_borrowed_time_active:GetAuraRadius()
	return self.redirect_range_scepter
end

function modifier_abaddon_borrowed_time_active:GetAuraEntityReject(entity)
	if entity == self:GetParent() then 
		return true
	else
		return false
	end
end

function modifier_abaddon_borrowed_time_active:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_abaddon_borrowed_time_active:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end


modifier_abaddon_borrowed_time_scepter = class({})
LinkLuaModifier("modifier_abaddon_borrowed_time_scepter", "heroes/hero_abaddon/abaddon_borrowed_time", LUA_MODIFIER_MOTION_NONE)

function modifier_abaddon_borrowed_time_scepter:OnCreated()
	self:OnRefresh()
end

function modifier_abaddon_borrowed_time_scepter:OnRefresh()
	self.damage_taken = 0
	self.redirect = self:GetSpecialValueFor("ally_threshold_scepter") / 100
	if IsServer() then
		self.coil = self:GetCaster():FindAbilityByName("abaddon_death_coil")
	end
end

function modifier_abaddon_borrowed_time_scepter:GetEffectName()
	return "particles/units/heroes/hero_abaddon/abaddon_ambient.vpcf"
end


function modifier_abaddon_borrowed_time_scepter:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_abaddon_borrowed_time_scepter:OnTakeDamage(params)
	if params.unit ~= self:GetParent() then return end
	if self:GetParent():IsIllusion() then return end
	self.damage_taken = self.damage_taken + params.damage
	if self.redirect * self:GetParent():GetMaxHealth() <= self.damage_taken then
		if self.coil and self.coil:IsTrained() then
			self:GetCaster():SetCursorCastTarget( self:GetParent() )
			self.coil:OnSpellStart()
		end
		self.damage_taken = 0
	end
end

function modifier_abaddon_borrowed_time_scepter:IsHidden()
	return true
end