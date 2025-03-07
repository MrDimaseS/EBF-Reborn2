bloodseeker_blood_bath = class({})

function bloodseeker_blood_bath:IsStealable()
	return true
end

function bloodseeker_blood_bath:IsHiddenWhenStolen()
	return false
end

function bloodseeker_blood_bath:GetIntrinsicModifierName()
	return "modifier_bloodseeker_blood_bath_passive"
end

function bloodseeker_blood_bath:GetBehavior()
	if self:GetSpecialValueFor("no_target") == 1 then
		return DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_NO_TARGET
	else
		return self.BaseClass.GetBehavior( self )
	end
end

function bloodseeker_blood_bath:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function bloodseeker_blood_bath:OnSpellStart()
	local caster = self:GetCaster()
	
	local delay = self:GetSpecialValueFor("delay")
	EmitSoundOn("Hero_Bloodseeker.BloodRite.Cast", caster)
	if self:GetSpecialValueFor("no_target") == 1  then
		EmitSoundOn("hero_bloodseeker.bloodRite", caster)
		caster:AddNewModifier( caster, self, "modifier_bloodseeker_blood_bath", {duration = delay} )
	else
		local point = self:GetCursorPosition()
		EmitSoundOnLocationWithCaster(point, "hero_bloodseeker.bloodRite", caster)
		CreateModifierThinker(caster, self, "modifier_bloodseeker_blood_bath", {Duration = delay}, point, caster:GetTeam(), false)
	end
end

modifier_bloodseeker_blood_bath_passive = class({})
LinkLuaModifier("modifier_bloodseeker_blood_bath_passive", "heroes/hero_bloodseeker/bloodseeker_blood_bath", LUA_MODIFIER_MOTION_NONE)

function modifier_bloodseeker_blood_bath_passive:OnCreated()
	self:OnRefresh()
end

function modifier_bloodseeker_blood_bath_passive:OnRefresh()
	self.silence_bonus_dmg = self:GetSpecialValueFor("silence_bonus_dmg")
end

function modifier_bloodseeker_blood_bath_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE}
end

function modifier_bloodseeker_blood_bath_passive:GetModifierTotalDamageOutgoing_Percentage( params )
	if self.silence_bonus_dmg <= 0 then return end
	if params.target:IsSilenced() then
		return self.silence_bonus_dmg
	end
end

function modifier_bloodseeker_blood_bath_passive:IsHidden()
	return true
end

modifier_bloodseeker_blood_bath = class({})
LinkLuaModifier("modifier_bloodseeker_blood_bath", "heroes/hero_bloodseeker/bloodseeker_blood_bath", LUA_MODIFIER_MOTION_NONE)

function modifier_bloodseeker_blood_bath:OnCreated(table)
	self.radius = self:GetSpecialValueFor("radius")
	self.duration = self:GetSpecialValueFor("silence_duration")
	self.damage = self:GetSpecialValueFor("damage")
	if IsServer() then

		local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_bloodseeker/bloodseeker_spell_bloodbath_bubbles.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
					ParticleManager:SetParticleControl(nfx, 1, Vector(self.radius,self.radius,self.radius))
		self:AttachEffect(nfx)
	end
end

function modifier_bloodseeker_blood_bath:OnRemoved()
	if IsServer() then
		local enemies = self:GetCaster():FindEnemyUnitsInRadius(self:GetParent():GetAbsOrigin(), self.radius)
		if #enemies > 0 then
			ParticleManager:FireParticle("particles/units/heroes/hero_bloodseeker/bloodseeker_bloodbath.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent(), {})
		end
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		for _,enemy in pairs(enemies) do
			EmitSoundOn("hero_bloodseeker.bloodRite.silence", enemy)
			ability:DealDamage(self:GetCaster(), enemy, self.damage)
			enemy:AddNewModifier( caster, ability, "modifier_bloodseeker_blood_bath_silence", {duration = self.duration})
		end
	end
end

modifier_bloodseeker_blood_bath_silence = class({})
LinkLuaModifier("modifier_bloodseeker_blood_bath_silence", "heroes/hero_bloodseeker/bloodseeker_blood_bath", LUA_MODIFIER_MOTION_NONE)

function modifier_bloodseeker_blood_bath_silence:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_bloodseeker_blood_bath_silence:IsHidden()
	return false
end

function modifier_bloodseeker_blood_bath_silence:CheckState()
	local state = { [MODIFIER_STATE_SILENCED] = true}
	return state
end

function modifier_bloodseeker_blood_bath_silence:IsPurgable()
	return true
end

function modifier_bloodseeker_blood_bath_silence:GetEffectName()
	return "particles/units/heroes/hero_bloodseeker/bloodseeker_silenced.vpcf"
end