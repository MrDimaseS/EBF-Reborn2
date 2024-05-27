phantom_assassin_blur = class({})

function phantom_assassin_blur:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_NO_TARGET
end

function phantom_assassin_blur:GetCastPoint( )
	if self:GetCaster():HasScepter() then
		return 0
	else
		return self.BaseClass.GetCastPoint( self )
	end
end

function phantom_assassin_blur:GetIntrinsicModifierName()
    return "modifier_phantom_assassin_blur_handler"
end

function phantom_assassin_blur:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier( caster, self, "modifier_phantom_assassin_blur_fade", {duration = self:GetSpecialValueFor("duration")})
	caster:EmitSound("Hero_PhantomAssassin.Blur")
	
	if caster:HasScepter() then
		caster:Dispel( caster, true )
	end
end

LinkLuaModifier( "modifier_phantom_assassin_blur_handler", "heroes/hero_phantom_assassin/phantom_assassin_blur", LUA_MODIFIER_MOTION_NONE )
modifier_phantom_assassin_blur_handler = class({})

function modifier_phantom_assassin_blur_handler:OnCreated()
    self:OnRefresh()
end

function modifier_phantom_assassin_blur_handler:OnRefresh()
    self.evasion = self:GetSpecialValueFor("bonus_evasion")
	
	if IsServer() then
		self.coupdegrace = self:GetCaster():FindAbilityByName("phantom_assassin_coup_de_grace")
	end
end

function modifier_phantom_assassin_blur_handler:OnIntervalThink()
	local caster = self:GetCaster()
	if not self.talent1 then
		self:StartIntervalThink(-1)
		return
	end
	if caster:HasModifier("modifier_phantom_assassin_blur_fade") then return end
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self.t1Radius ) ) do
		return
	end
	if not caster:HasModifier("modifier_phantom_assassin_blur_fade_lesser") then 
		caster:AddNewModifier( caster, self:GetAbility(), "modifier_phantom_assassin_blur_fade_lesser", {} )
	end
end

function modifier_phantom_assassin_blur_handler:DeclareFunctions()
    funcs = {MODIFIER_EVENT_ON_DEATH}
    return funcs
end

function modifier_phantom_assassin_blur_handler:OnDeath(params)
	if self:GetParent():PassivesDisabled() then return end
	if not self:GetParent():HasScepter() then return end
	if params.attacker ~= self:GetParent() then return end
	if params.unit:IsConsideredHero() and params.unit.Holdout_IsCore then
		params.attacker:RefreshAllCooldowns()
	elseif self.coupdegrace and self.coupdegrace:IsTrained() then
		params.attacker:AddNewModifier( params.attacker, self.coupdegrace, "modifier_phantom_assassin_mark_of_death", {duration = self.coupdegrace:GetSpecialValueFor("duration")} )
	end
end

function modifier_phantom_assassin_blur_handler:IsHidden()
	return true
end

modifier_phantom_assassin_blur_fade = class({})
LinkLuaModifier( "modifier_phantom_assassin_blur_fade", "heroes/hero_phantom_assassin/phantom_assassin_blur", LUA_MODIFIER_MOTION_NONE )
function modifier_phantom_assassin_blur_fade:OnCreated()
	self:OnRefresh()
end

function modifier_phantom_assassin_blur_fade:OnRefresh()
	self.fade_duration = self:GetSpecialValueFor("fade_duration")
	self.manacost_reduction_during_blur_pct = self:GetSpecialValueFor("manacost_reduction_during_blur_pct")
	self.manacost_reduction_after_blur_pct = self:GetSpecialValueFor("manacost_reduction_after_blur_pct")
end

function modifier_phantom_assassin_blur_fade:DeclareFunctions()
	return { MODIFIER_EVENT_ON_TAKEDAMAGE, MODIFIER_PROPERTY_MANACOST_PERCENTAGE_STACKING }
end

function modifier_phantom_assassin_blur_fade:CheckState()
	if not self:GetParent():HasModifier("modifier_phantom_assassin_blur_cd") then
		return { [MODIFIER_STATE_UNTARGETABLE] = true }
	end
end

function modifier_phantom_assassin_blur_fade:GetModifierPercentageManacostStacking()
	if self:GetCaster():HasModifier("modifier_phantom_assassin_blur_cd") then
		return self.manacost_reduction_after_blur_pct
	else
		return self.manacost_reduction_during_blur_pct
	end
end

function modifier_phantom_assassin_blur_fade:OnTakeDamage(params)
	if params.attacker == self:GetParent() and params.unit:IsConsideredHero() then
		self.currentlyBlurred = false
		self:StartIntervalThink( self.fade_duration )
		self:GetParent():AddNewModifier( self:GetParent(), self:GetAbility(), "modifier_phantom_assassin_blur_cd", {duration = self.fade_duration} )
	end
end

function modifier_phantom_assassin_blur_fade:GetStatusEffectName()
	return "particles/status_fx/status_effect_phantom_assassin_active_blur.vpcf"
end

function modifier_phantom_assassin_blur_fade:StatusEffectPriority()
	return 10
end

function modifier_phantom_assassin_blur_fade:GetEffectName()
	return "particles/units/heroes/hero_phantom_assassin/phantom_assassin_active_blur.vpcf"
end

function modifier_phantom_assassin_blur_fade:IsHidden()
	return self:GetParent():HasModifier("modifier_phantom_assassin_blur_cd")
end

modifier_phantom_assassin_blur_cd = class({})
LinkLuaModifier( "modifier_phantom_assassin_blur_cd", "heroes/hero_phantom_assassin/phantom_assassin_blur", LUA_MODIFIER_MOTION_NONE )

function modifier_phantom_assassin_blur_cd:IsDebuff()
	return true
end

function modifier_phantom_assassin_blur_cd:IsPurgable()
	return false
end