spectre_desolate = class({})

function spectre_desolate:GetIntrinsicModifierName()
	return "modifier_spectre_desolate_passive"
end

modifier_spectre_desolate_passive = class({})
LinkLuaModifier( "modifier_spectre_desolate_passive", "heroes/hero_spectre/spectre_desolate", LUA_MODIFIER_MOTION_NONE )

function modifier_spectre_desolate_passive:OnCreated()
	self:OnRefresh()
end

function modifier_spectre_desolate_passive:OnRefresh()
	self.damage = self:GetTalentSpecialValueFor("bonus_damage")
	self.lonely_multiplier = self:GetTalentSpecialValueFor("lonely_multiplier") / 100
	self.radius = self:GetTalentSpecialValueFor("radius")
end

function modifier_spectre_desolate_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PURE}
end

function modifier_spectre_desolate_passive:GetModifierProcAttack_BonusDamage_Pure(params)
	if params.attacker == self:GetParent() then
		local solo = true
		if not params.attacker:HasModifier("modifier_spectre_haunt_active") then
			for _, ally in ipairs( params.attacker:FindEnemyUnitsInRadius( params.target:GetAbsOrigin(), self.radius) ) do
				if params.target ~= ally then
					solo = false
					break
				end
			end
		end
		local damage = TernaryOperator( self.damage * self.lonely_multiplier, solo, self.damage )
		if solo then
			params.target:EmitSound("Hero_Spectre.Desolate")
			local vDir = CalculateDirection( params.target, params.attacker )
			local hitFX = ParticleManager:CreateParticle("particles/units/heroes/hero_spectre/spectre_desolate.vpcf", PATTACH_ABSORIGIN, params.target)
			ParticleManager:SetParticleControl( hitFX, 0, params.attacker:GetAbsOrigin() + params.attacker:GetForwardVector() * 50 )
			ParticleManager:SetParticleControlForward( hitFX, 0, vDir )
			ParticleManager:ReleaseParticleIndex( hitFX )
		end
		return damage -- self:GetAbility():DealDamage( params.attacker, params.target, damage )
	end
end

function modifier_spectre_desolate_passive:IsHidden()
	return true
end