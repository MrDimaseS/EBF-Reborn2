tidehunter_kraken_shell = class({})

function tidehunter_kraken_shell:GetIntrinsicModifierName()
	return "modifier_tidehunter_kraken_shell_passive"
end

function tidehunter_kraken_shell:ShouldUseResources()
	return true
end

LinkLuaModifier("modifier_tidehunter_kraken_shell_passive", "heroes/hero_tidehunter/tidehunter_kraken_shell", LUA_MODIFIER_MOTION_NONE)
modifier_tidehunter_kraken_shell_passive = class({})

function modifier_tidehunter_kraken_shell_passive:OnCreated()
	if IsServer() then
		self:StartIntervalThink( 0.1 )
	end
end

function modifier_tidehunter_kraken_shell_passive:OnIntervalThink()
	local caster = self:GetCaster()
	if caster:HasModifier("modifier_tidehunter_kraken_shell_effect") then return end
	local ability = self:GetAbility()
	if ability:IsCooldownReady() then
		caster:AddNewModifier( caster, ability, "modifier_tidehunter_kraken_shell_effect", {} )
	end
end

function modifier_tidehunter_kraken_shell_passive:IsHidden()
	return true
end

function modifier_tidehunter_kraken_shell_passive:IsPurgable()
	return false
end

LinkLuaModifier("modifier_tidehunter_kraken_shell_effect", "heroes/hero_tidehunter/tidehunter_kraken_shell", LUA_MODIFIER_MOTION_NONE)
modifier_tidehunter_kraken_shell_effect = class({})

function modifier_tidehunter_kraken_shell_effect:OnCreated()
	self.linger_duration = self:GetSpecialValueFor("linger_duration")
end

function modifier_tidehunter_kraken_shell_effect:OnIntervalThink()
	self:GetCaster():Dispel( self:GetCaster(), true )
end

function modifier_tidehunter_kraken_shell_effect:OnDestroy()
	if IsServer() then
		self:GetAbility():SetFrozenCooldown( false )
	end
end

function modifier_tidehunter_kraken_shell_effect:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE}
end

function modifier_tidehunter_kraken_shell_effect:GetModifierIncomingDamage_Percentage( params )
	if self:GetParent():PassivesDisabled() and self:GetRemainingTime() < 0 then return end
	if not self.triggered then
		EmitSoundOn( "Hero_Tidehunter.KrakenShell", self:GetParent() )
		ParticleManager:FireParticle( "particles/units/heroes/hero_tidehunter/tidehunter_krakenshell_purge.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
		
		self.triggered = true
		self:SetDuration( self.linger_duration, true )
		self:GetAbility():SetCooldown()
		ability:SetFrozenCooldown( true )
		self:OnIntervalThink()
		self:StartIntervalThink(0.1)
	end
	if self:GetSpecialValueFor("should_ravage") > 0 then
        local caster = self:GetCaster()
        local target = params.attacker
        local ability = self:GetAbility()
		self.ravage = self:GetCaster():FindAbilityByName("tidehunter_ravage")
		if self.ravage:GetLevel() > 0 then
			local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_tidehunter/tidehunter_ravage_tentacle_model.vpcf", PATTACH_POINT, caster)
			ParticleManager:SetParticleControl(nfx, 0, target:GetAbsOrigin())
			ParticleManager:ReleaseParticleIndex(nfx)
			
			local position = target:GetAbsOrigin()
			target:ApplyKnockBack(position, 0.5, 0.5, 0, 350, caster, ability)
			ability:Stun(target, self.ravage:GetSpecialValueFor("duration"))
			EmitSoundOn( "Hero_Tidehunter.RavageDamage", target )
			Timers:CreateTimer( 0.5, function()
				self.ravage:DealDamage(caster, target)
				
			end)
		end
	end
	return -999
end

function modifier_tidehunter_kraken_shell_effect:IsHidden()
	return self:GetRemainingTime() < 0
end