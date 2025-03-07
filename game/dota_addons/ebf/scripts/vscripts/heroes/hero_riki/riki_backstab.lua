riki_backstab = class({})

function riki_backstab:GetIntrinsicModifierName()
    return "modifier_riki_backstab_handler"
end

modifier_riki_backstab_handler = class({})
LinkLuaModifier( "modifier_riki_backstab_handler", "heroes/hero_riki/riki_backstab.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_riki_backstab_handler:OnCreated()
	self:OnRefresh()
end

function modifier_riki_backstab_handler:OnRefresh()
	self.backstab_angle = self:GetSpecialValueFor("backstab_angle")
	self.pity_pct = self:GetSpecialValueFor("pity_pct")
	self.heal_radius = self:GetSpecialValueFor("heal_radius")
	self.heal_pct = self:GetSpecialValueFor("heal_pct")
	self.attacks = {}
end

function modifier_riki_backstab_handler:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED  
    }   
    return funcs
end

function modifier_riki_backstab_handler:OnAttackLanded(params)
	if params.attacker == self:GetCaster() then
		self._lastAttackTime = GameRules:GetGameTime()
		if self.attacks[params.record] then
			if self.heal_pct > 0 then
				local ability =  self:GetAbility()
				local heal = self.attacks[params.record] * self.heal_pct / 100
				params.attacker:HealEvent( heal, ability, params.attacker )
				ParticleManager:FireRopeParticle( "particles/units/heroes/hero_riki/riki_backstab_heal.vpcf", PATTACH_POINT_FOLLOW, params.target, params.attacker )
				for _, ally in ipairs( params.attacker:FindFriendlyUnitsInRadius( params.target:GetAbsOrigin(), self.heal_radius ) ) do
					if ally ~= params.attacker then
						ally:HealEvent( heal, ability, params.attacker )
						ParticleManager:FireRopeParticle( "particles/units/heroes/hero_riki/riki_backstab_heal.vpcf", PATTACH_POINT_FOLLOW, params.target, ally )
					end
				end
			end
			self.attacks[params.record] = nil
			-- Create the back particle effect.
			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_backstab.vpcf", PATTACH_ABSORIGIN_FOLLOW, params.target) 
			-- Set Control Point 1 for the backstab particle; this controls where it's positioned in the world. In this case, it should be positioned on the victim.
			ParticleManager:SetParticleControlEnt(particle, 1, params.target, PATTACH_POINT_FOLLOW, "attach_hitloc", params.target:GetAbsOrigin(), true)
			ParticleManager:ReleaseParticleIndex(particle)
			if params.attacker:HasModifier("modifier_riki_tricks_of_the_trade_handler") and not params.attacker:IsConsideredHero() then
				return
			end
			 -- Play the sound on the victim.
			EmitSoundOn("Hero_Riki.Backstab", params.target)
		end
	end
end

function modifier_riki_backstab_handler:GetModifierPreAttack_BonusDamage(params)
    if IsServer() then
        local caster = self:GetCaster()
        if params.attacker == caster then
			self.attacks[params.record] = false
            local agility_damage_multiplier = self:GetSpecialValueFor("damage_multiplier")
            local damage = params.attacker:GetAgility() * agility_damage_multiplier
            if not params.target:IsAtAngleWithEntity(caster, 360-self.backstab_angle ) 
			or caster:HasModifier("modifier_riki_tricks_of_the_trade_handler") 
			or caster:HasModifier("modifier_riki_invis_invisible") then 
				self.attacks[params.record] = damage
				return damage
			elseif self.pity_pct > 0 then
				return damage * self.pity_pct / 100
            end
        end
    end
end

function modifier_riki_backstab_handler:IsHidden()
    return true
end