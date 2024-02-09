boss_psionic_assassin_vendetta = class({})


function boss_psionic_assassin_vendetta:ShouldUseResources()
	return true
end

function boss_psionic_assassin_vendetta:GetIntrinsicModifierName()
	return "modifier_boss_psionic_assassin_vendetta_handler"
end

function boss_psionic_assassin_vendetta:TriggerVendetta()
	local caster = self:GetCaster()
	
	if caster:PassivesDisabled() then return end
	
	ParticleManager:FireParticle( "particles/units/heroes/hero_nyx_assassin/nyx_assassin_vendetta_start.vpcf", PATTACH_POINT_FOLLOW, caster )
	EmitSoundOn( "Hero_NyxAssassin.Vendetta", caster )
	caster:AddNewModifier( caster, self, "modifier_nyx_assassin_vendetta", {duration = self:GetSpecialValueFor("duration")} )
end

modifier_boss_psionic_assassin_vendetta_handler = class({})
LinkLuaModifier( "modifier_boss_psionic_assassin_vendetta_handler", "bosses/boss_scarabs/boss_psionic_assassin_vendetta.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_boss_psionic_assassin_vendetta_handler:OnCreated()
	if IsServer() then
		self:StartIntervalThink( 0.1 )
	end
end

function modifier_boss_psionic_assassin_vendetta_handler:OnIntervalThink()
	if self.reflectionTriggered and not self:GetCaster():HasModifier("modifier_boss_psionic_assassin_reflecting_carapace_reflect") then
		self.reflectionTriggered = false
	elseif self:GetCaster():HasModifier("modifier_boss_psionic_assassin_reflecting_carapace_reflect") then
		self.reflectionTriggered = true
	end
end

function modifier_boss_psionic_assassin_vendetta_handler:DeclareFunctions()
	return {MODIFIER_EVENT_ON_DEATH}
end

function modifier_boss_psionic_assassin_vendetta_handler:OnDeath( params )
	if params.attacker == self:GetParent() then
		self:GetAbility():TriggerVendetta()
	end
end