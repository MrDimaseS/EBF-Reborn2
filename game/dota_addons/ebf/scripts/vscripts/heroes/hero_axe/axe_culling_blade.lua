axe_culling_blade = class({})

function axe_culling_blade:GetIntrinsicModifierName()
	return "modifier_axe_culling_blade_handler"
end
--------------------------------------------------------------------------------
-- Ability Start
function axe_culling_blade:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- load data
	local damage = self:GetSpecialValueFor("damage")
	local debuff_immune = self:GetSpecialValueFor("debuff_immune") == 1
	local critical_damage = self:GetSpecialValueFor("critical_damage")

	if target:TriggerSpellAbsorb( self ) then return end
	if debuff_immune then
		caster:AddNewModifier( caster, self, "modifier_black_king_bar_immune", {duration = self:GetSpecialValueFor("immunity_duration")} )
	end
	if critical_damage > 0 then
		local trueCrit = critical_damage
		local hunger = target:FindModifierByName("modifier_axe_battle_hunger_debuff")
		if hunger then
			trueCrit = trueCrit + (hunger:GetAbility():GetSpecialValueFor("crit_base")-100) + hunger:GetAbility():GetSpecialValueFor("crit_stack") * hunger:GetStackCount()
		end
		local bonusSpellDamage = damage * (1+caster:GetSpellAmplification( false ))
		damage = caster:GetAverageTrueAttackDamage( target ) * (trueCrit / 100)
		self:DealDamage( caster, target, damage + bonusSpellDamage, {damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION}, OVERHEAD_ALERT_CRITICAL )
		caster:PerformAttack(target, true, true, true, true, false, true, true)
	else
		self:DealDamage( caster, target, damage )
	end
	self:OnCast( caster )
	self:PlayEffects( target, true )
	
	if not target:IsConsideredHero() or target:IsIllusion() then
		self:EndCooldown()
	end
end

function axe_culling_blade:OnCast( target )
	local caster = self:GetCaster()
	local bloodForged = target:FindModifierByName("modifier_axe_bloodforged_axe_handler")
	local axe_stacks = self:GetSpecialValueFor("axe_stacks")
	
	if bloodForged then
		bloodForged:RefreshAllIndependentStacks( )
		bloodForged:AddIndependentStack({stacks = axe_stacks, duration = bloodForged.stack_duration})
		if self._morbidTriggered then
			self:GetCaster()._permanentBloodForgedAxeStacks = ( self:GetCaster()._permanentBloodForgedAxeStacks or 0 ) + 1
			bloodForged:IncrementStackCount()
			self._morbidTriggered = false
		end
	end
	if self:GetSpecialValueFor("always_grant_allies") == 1 then
		self:ShareBloodForgedAxe( self:GetSpecialValueFor( "speed_aoe" ) )
	end
end

function axe_culling_blade:OnMorbid()
	self._morbidTriggered = true
	self:EndCooldown()
end

function axe_culling_blade:OnRefresh()
	local caster = self:GetCaster()
	caster:ModifyRage( self:GetSpecialValueFor("refresh_rage") )
	self:ShareBloodForgedAxe( self:GetSpecialValueFor("speed_aoe"), self:GetSpecialValueFor("speed_duration") )
end

function axe_culling_blade:ShareBloodForgedAxe( radius, durationIncrease )
	local caster = self:GetCaster()
	local bloodForged = caster:FindModifierByName("modifier_axe_bloodforged_axe_handler")
	if not bloodForged then return end
	local duration = bloodForged:GetDuration()
	if (durationIncrease or 0) > 0 then
		duration = duration + durationIncrease
		bloodForged:SetIndependentStackAllDurations( duration )
		bloodForged:SetDuration( duration, true )
	end
	for _, ally in ipairs( caster:FindFriendlyUnitsInRadius( caster:GetAbsOrigin(), radius, {type = DOTA_UNIT_TARGET_HERO} ) ) do
		if ally ~= caster then
			ally:AddNewModifier( bloodForged:GetCaster(), bloodForged:GetAbility(), "modifier_axe_bloodforged_axe_handler", {duration = duration} ):SetStackCount( bloodForged:GetStackCount() )
		end
	end
end

--------------------------------------------------------------------------------
function axe_culling_blade:PlayEffects( target, success )
	-- Get Resources
	local particle_cast = ""
	local sound_cast = ""
	if success then
		particle_cast = "particles/units/heroes/hero_axe/axe_culling_blade_kill.vpcf"
		sound_cast = "Hero_Axe.Culling_Blade_Success"
	else
		particle_cast = "particles/units/heroes/hero_axe/axe_culling_blade.vpcf"
		sound_cast = "Hero_Axe.Culling_Blade_Fail"
	end

	-- load data
	local direction = (target:GetOrigin()-self:GetCaster():GetOrigin()):Normalized()

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:SetParticleControl( effect_cast, 4, target:GetOrigin() )
	ParticleManager:SetParticleControlForward( effect_cast, 3, direction )
	ParticleManager:SetParticleControlForward( effect_cast, 4, direction )
	-- assert(loadfile("lua_abilities/rubick_spell_steal/rubick_spell_steal_color"))(self,effect_target)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOn( sound_cast, target )
end

modifier_axe_culling_blade_handler = class({})
LinkLuaModifier( "modifier_axe_culling_blade_handler", "heroes/hero_axe/axe_culling_blade", LUA_MODIFIER_MOTION_NONE )

function modifier_axe_culling_blade_handler:OnCreated()
	self.speed_aoe = self:GetSpecialValueFor("speed_aoe")
	if IsServer() then
		self:StartIntervalThink(0)
	end
	self._isCooldownReady = true
end

function modifier_axe_culling_blade_handler:OnIntervalThink()
	if self:GetAbility():IsCooldownReady() and not self._isCooldownReady then
		self:GetAbility():OnRefresh()
	end
	self._isCooldownReady = self:GetAbility():IsCooldownReady()
end

function modifier_axe_culling_blade_handler:DeclareFunctions()
	return {MODIFIER_EVENT_ON_DEATH}
end

function modifier_axe_culling_blade_handler:OnDeath( params )
	if params.unit == self:GetCaster() then return end
	if CalculateDistance( params.unit, self:GetCaster() ) > self.speed_aoe then return end
	if not params.unit:IsConsideredHero() then return end
	if params.unit:IsIllusion() then return end
	if not params.unit:HasAbility("enemy_champion") then return end
	Timers:CreateTimer( 0.1, function() self:GetAbility():OnMorbid() end )
end

function modifier_axe_culling_blade_handler:IsHidden()
	return true
end