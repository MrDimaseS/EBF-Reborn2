nyx_assassin_impale = class({})

function nyx_assassin_impale:IsStealable()
	return true
end

function nyx_assassin_impale:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	local direction = CalculateDirection(point, caster:GetAbsOrigin())
	local distance = self:GetSpecialValueFor("length")
	local width = self:GetSpecialValueFor("width")
	local speed = self:GetSpecialValueFor("speed")

	EmitSoundOn("Hero_NyxAssassin.Impale", caster)

	self:FireLinearProjectile("particles/units/heroes/hero_nyx_assassin/nyx_assassin_impale.vpcf", direction*speed, distance, width, {}, false, true, width*2)
end

function nyx_assassin_impale:OnProjectileHit(hTarget, vLocation)
	local caster = self:GetCaster()
	
	local duration = self:GetSpecialValueFor("duration")
	local damage = self:GetSpecialValueFor("impale_damage")
	local knockUpDuration = 0.5
	local knockUpHeight = 350

	if hTarget then
		EmitSoundOn("Hero_NyxAssassin.Impale.Target", hTarget)
		ParticleManager:FireParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_impale_hit.vpcf", PATTACH_POINT, caster, {[0]=hTarget:GetAbsOrigin()})

		local knockUpRealDuration = hTarget:ApplyKnockBack(vLocation, knockUpDuration, knockUpDuration, 0, knockUpHeight, caster, self).knockback:GetRemainingTime()
		Timers:CreateTimer(knockUpRealDuration, function()
			EmitSoundOn("Hero_NyxAssassin.Impale.TargetLand", hTarget)
			self:DealDamage(caster, hTarget, damage)
		end)
		local reductionDuration = self:GetSpecialValueFor("reduction_duration")
		if reductionDuration > 0 then
			hTarget:AddNewModifier( caster, self, "modifier_nyx_assassin_impale_myrmeleomorph", {duration = reductionDuration} )
		end
		local damageDuration = self:GetSpecialValueFor("damage_duration")
		if damageDuration > 0 then
			hTarget:AddNewModifier( caster, self, "modifier_nyx_assassin_impale_libellumorph", {duration = damageDuration} )
		end
		local infestDuration = self:GetSpecialValueFor("infest_duration")
		if infestDuration > 0 then
			hTarget:AddNewModifier( caster, self, "modifier_nyx_assassin_impale_aulacimorph", {duration = infestDuration} )
		end
	end
end

modifier_nyx_assassin_impale_myrmeleomorph = class({})
LinkLuaModifier( "modifier_nyx_assassin_impale_myrmeleomorph", "heroes/hero_nyx_assassin/nyx_assassin_impale.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_nyx_assassin_impale_myrmeleomorph:OnCreated()
	self:OnRefresh()
end

function modifier_nyx_assassin_impale_myrmeleomorph:OnRefresh()
	self.damage_reduction = self:GetSpecialValueFor("damage_reduction")
end

function modifier_nyx_assassin_impale_myrmeleomorph:DeclareFunctions()
	return {MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE }
end

function modifier_nyx_assassin_impale_myrmeleomorph:GetModifierTotalDamageOutgoing_Percentage( params )
	if IsClient() then return self.damage_reduction end
	if params.target == self:GetCaster() then
		return self.damage_reduction
	end
end

modifier_nyx_assassin_impale_libellumorph = class({})
LinkLuaModifier( "modifier_nyx_assassin_impale_libellumorph", "heroes/hero_nyx_assassin/nyx_assassin_impale.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_nyx_assassin_impale_libellumorph:OnCreated()
	self:OnRefresh()
end

function modifier_nyx_assassin_impale_libellumorph:OnRefresh()
	self.damage_bonus = self:GetSpecialValueFor("damage_bonus")
end

function modifier_nyx_assassin_impale_libellumorph:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end

function modifier_nyx_assassin_impale_libellumorph:GetModifierIncomingDamage_Percentage( params )
	if IsClient() then return self.damage_bonus end
	if self._preventInfiniteDamageLoop then return end
	if params.attacker ~= self:GetCaster() then return end
	if params.inflictor and not params.attacker:HasAbility( params.inflictor:GetAbilityName() ) then return end -- only apply to nyx's abilities and attacks
	self._preventInfiniteDamageLoop = true
	self:GetAbility():DealDamage( params.attacker, params.target, self.damage_bonus, {damage_type = params.damage_type}, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE )
	self._preventInfiniteDamageLoop = false
end

modifier_nyx_assassin_impale_aulacimorph = class({})
LinkLuaModifier( "modifier_nyx_assassin_impale_aulacimorph", "heroes/hero_nyx_assassin/nyx_assassin_impale.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_nyx_assassin_impale_aulacimorph:OnCreated()
	self:OnRefresh()
end

function modifier_nyx_assassin_impale_aulacimorph:OnRefresh()
	self.infest_search_radius = self:GetSpecialValueFor("infest_search_radius")
	self.infest_dps = self:GetSpecialValueFor("infest_dps")
	if IsServer() then
		self:AddIndependentStack()
	end
end

function modifier_nyx_assassin_impale_aulacimorph:OnStackCountChanged()
	if IsServer() then
		self:StartIntervalThink( 1 / self:GetStackCount() )
	end
end

function modifier_nyx_assassin_impale_aulacimorph:OnIntervalThink()
	self:GetAbility():DealDamage( self:GetCaster(), self:GetParent(), self.infest_dps )
end
function modifier_nyx_assassin_impale_aulacimorph:DeclareFunctions()
	return {MODIFIER_PROPERTY_TOOLTIP }
end

function modifier_nyx_assassin_impale_aulacimorph:OnTooltip( params )
	return self.infest_dps
end