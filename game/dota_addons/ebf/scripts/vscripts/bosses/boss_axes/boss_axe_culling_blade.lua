boss_axe_culling_blade = class({})

function boss_axe_culling_blade:GetIntrinsicModifierName()
	return "modifier_boss_axe_culling_blade_permanent_armor"
end

--------------------------------------------------------------------------------
-- Ability Start
function boss_axe_culling_blade:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	-- load data
	local damage = self:GetSpecialValueFor("damage")
	local threshold = self:GetSpecialValueFor("kill_threshold")
	local radius = self:GetSpecialValueFor("speed_aoe")
	local duration = self:GetSpecialValueFor("speed_duration")
	local heroMult = self:GetSpecialValueFor("hero_cd_reduction") / 100

	if not IsEntitySafe( target ) then
		self:EndCooldown()
		return
	end
	-- Check success / not
	local success = target:GetHealth() <= damage * caster:GetSpellAmplification( false )

	-- effects
	self:PlayEffects( target, success )

	if success then
		for _, ally in ipairs( caster:FindFriendlyUnitsInRadius( target:GetAbsOrigin(), radius ) ) do
			ally:AddNewModifier( caster, self, "modifier_boss_axe_culling_blade_kill", { duration = duration } )
		end
		
		if target:IsRealHero() then
			local cooldown = self:GetCooldownTimeRemaining()
			self:EndCooldown()
			
			local modifier = caster:AddNewModifier( caster, self, "modifier_boss_axe_culling_blade_permanent_armor", {} )
			modifier:IncrementStackCount()
		end
	end
	self:DealDamage( caster, target, damage )
end

--------------------------------------------------------------------------------
function boss_axe_culling_blade:PlayEffects( target, success )
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

modifier_boss_axe_culling_blade_kill = class({})
LinkLuaModifier( "modifier_boss_axe_culling_blade_kill", "bosses/boss_axes/boss_axe_culling_blade", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Classifications
function modifier_boss_axe_culling_blade_kill:IsHidden()
	return false
end

function modifier_boss_axe_culling_blade_kill:IsDebuff()
	return false
end

function modifier_boss_axe_culling_blade_kill:IsPurgable()
	return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_boss_axe_culling_blade_kill:OnCreated( kv )
	self:OnRefresh()
end

function modifier_boss_axe_culling_blade_kill:OnRefresh( kv )
	self.as_bonus = self:GetAbility():GetSpecialValueFor( "atk_speed_bonus" ) -- special value
	self.ms_bonus = self:GetAbility():GetSpecialValueFor( "speed_bonus" ) -- special value
end

function modifier_boss_axe_culling_blade_kill:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_boss_axe_culling_blade_kill:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}

	return funcs
end
function modifier_boss_axe_culling_blade_kill:GetModifierMoveSpeedBonus_Percentage()
	return self.ms_bonus
end
function modifier_boss_axe_culling_blade_kill:GetModifierAttackSpeedBonus_Constant()
	return self.as_bonus
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_boss_axe_culling_blade_kill:GetEffectName()
	return "particles/units/heroes/hero_axe/axe_cullingblade_sprint.vpcf"
end

function modifier_boss_axe_culling_blade_kill:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

modifier_boss_axe_culling_blade_permanent_armor = class({})
LinkLuaModifier( "modifier_boss_axe_culling_blade_permanent_armor", "bosses/boss_axes/boss_axe_culling_blade", LUA_MODIFIER_MOTION_NONE )
--------------------------------------------------------------------------------
-- Classifications
function modifier_boss_axe_culling_blade_permanent_armor:IsHidden()
	return self:GetStackCount() <= 0
end

function modifier_boss_axe_culling_blade_permanent_armor:IsDebuff()
	return false
end

function modifier_boss_axe_culling_blade_permanent_armor:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_boss_axe_culling_blade_permanent_armor:OnCreated( kv )
	self:OnRefresh()
end

function modifier_boss_axe_culling_blade_permanent_armor:OnRefresh( kv )
	self.armor = self:GetAbility():GetSpecialValueFor( "armor_per_stack" )
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_boss_axe_culling_blade_permanent_armor:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}

	return funcs
end

function modifier_boss_axe_culling_blade_permanent_armor:GetModifierPhysicalArmorBonus()
	return self.armor * self:GetStackCount()
end