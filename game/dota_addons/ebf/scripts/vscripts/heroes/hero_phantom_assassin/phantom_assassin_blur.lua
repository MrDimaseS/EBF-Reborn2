phantom_assassin_blur = class({})

function phantom_assassin_blur:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier( caster, self, "modifier_phantom_assassin_blur_handler", {duration = self:GetSpecialValueFor("duration")})
	caster:EmitSound("Hero_PhantomAssassin.Blur")
end

modifier_phantom_assassin_blur_handler = class({})
LinkLuaModifier( "modifier_phantom_assassin_blur_handler", "heroes/hero_phantom_assassin/phantom_assassin_blur", LUA_MODIFIER_MOTION_NONE )

function modifier_phantom_assassin_blur_handler:OnCreated()
	self:OnRefresh()
end

function modifier_phantom_assassin_blur_handler:OnRefresh()
	self.restore_delay = self:GetSpecialValueFor("restore_delay")
	self.radius = self:GetSpecialValueFor("radius")
	self.creeps_noreveal = self:GetSpecialValueFor("creeps_noreveal") == 1
	self.no_invis = self:GetSpecialValueFor("no_invis") == 1
	self.bonus_evasion = self:GetSpecialValueFor("bonus_evasion")
	self.active_movespeed_bonus = self:GetSpecialValueFor("active_movespeed_bonus")
	self.tick_rate = 0.5
	self.fade_timer = 0
	if IsServer() and not self.no_invis then
		local caster = self:GetCaster()
		local parent = self:GetParent()
		local ability = self:GetAbility()
		self.fade = parent:AddNewModifier( caster, ability, "modifier_phantom_assassin_blur_fade", {duration = self:GetRemainingTime()} )
		self:StartIntervalThink( self.tick_rate )
	end
end

function modifier_phantom_assassin_blur_handler:OnIntervalThink()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	
	local enemies = parent:FindEnemyUnitsInRadius( parent:GetAbsOrigin(), self.radius, {type = DOTA_UNIT_TARGET_HERO} )
	if self.fade then
		if #enemies > 0 then
			parent:RemoveModifierByName("modifier_phantom_assassin_blur_fade")
			self.fade = nil
			self.fade_timer = self.restore_delay
			parent:AddNewModifier( caster, ability, "modifier_phantom_assassin_blur_cd", {duration = self.fade_timer} )
		end
	elseif #enemies == 0 then
		self.fade_timer = self.fade_timer - self.tick_rate
		if self.fade_timer <= 0 then
			self.fade = parent:AddNewModifier( caster, ability, "modifier_phantom_assassin_blur_fade", {duration = self:GetRemainingTime()} )
		end
	else
		parent:AddNewModifier( caster, ability, "modifier_phantom_assassin_blur_cd", {duration = self.fade_timer} )
	end
end

function modifier_phantom_assassin_blur_handler:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK, MODIFIER_PROPERTY_EVASION_CONSTANT, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_phantom_assassin_blur_handler:OnAttack( params )
	if self.no_invis then return end
	if params.attacker ~= self:GetParent() then return end
	if not params.target:IsConsideredHero() and self.creeps_noreveal then return end
	if params.attacker:GetAttackData( params.record ).ability and params.attacker:GetAttackData( params.record ).ability:GetAbilityName() == "phantom_assassin_stifling_dagger" then return end
	
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	params.attacker:RemoveModifierByName("modifier_phantom_assassin_blur_fade")
	self.fade = nil
	self.fade_timer = self.restore_delay
	params.attacker:AddNewModifier( caster, ability, "modifier_phantom_assassin_blur_cd", {duration = self.fade_timer} )
end

function modifier_phantom_assassin_blur_handler:GetModifierEvasion_Constant()
	return self.bonus_evasion
end

function modifier_phantom_assassin_blur_handler:GetModifierMoveSpeedBonus_Percentage()
	return self.active_movespeed_bonus
end

function modifier_phantom_assassin_blur_handler:OnDestroy()
	if self.fade then self.fade:Destroy() end
end

function modifier_phantom_assassin_blur_handler:IsHidden()
	return not self.no_invis
end

modifier_phantom_assassin_blur_fade = class({})
LinkLuaModifier( "modifier_phantom_assassin_blur_fade", "heroes/hero_phantom_assassin/phantom_assassin_blur", LUA_MODIFIER_MOTION_NONE )
function modifier_phantom_assassin_blur_fade:OnCreated()
	self:OnRefresh()
end

function modifier_phantom_assassin_blur_fade:OnRefresh()
	self.aoe_bonus = self:GetSpecialValueFor("aoe_bonus")
	self.range_bonus = self:GetSpecialValueFor("range_bonus")
	
	self:GetCaster()._aoeModifiersList = self:GetCaster()._aoeModifiersList or {}
	self:GetCaster()._aoeModifiersList[self] = true
end

function modifier_phantom_assassin_blur_fade:OnDestroy()
	self:GetCaster()._aoeModifiersList[self] = nil
end

function modifier_phantom_assassin_blur_fade:DeclareFunctions()
	return {MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING, 
			MODIFIER_PROPERTY_EVASION_CONSTANT, 
	}
end

function modifier_phantom_assassin_blur_fade:CheckState()
	if not self:GetParent():HasModifier("modifier_phantom_assassin_blur_cd") then
		return { [MODIFIER_STATE_UNTARGETABLE] = true }
	end
end

function modifier_phantom_assassin_blur_fade:GetModifierCastRangeBonusStacking()
	return self.range_bonus
end

function modifier_phantom_assassin_blur_fade:GetModifierAoEBonusConstant()
	return self.aoe_bonus
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