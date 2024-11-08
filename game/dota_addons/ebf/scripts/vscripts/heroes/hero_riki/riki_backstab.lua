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
	self.creep_agility_multiplier = self:GetSpecialValueFor("creep_agility_multiplier")
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
		self:GetAbility():SetCooldown( self.fade_delay )
		if self.attacks[params.record] then
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
            local damage = params.attacker:GetAgility() * agility_damage_multiplier * TernaryOperator( 1, params.target:IsConsideredHero(), self.creep_agility_multiplier )
            if not params.target:IsAtAngleWithEntity(caster, 360-self.backstab_angle ) 
			or caster:HasModifier("modifier_riki_tricks_of_the_trade_handler") 
			or caster:HasModifier("modifier_riki_invis_invisible")
			or params.target:HasModifier("modifier_riki_smoke_screen_aura_debuff") then 
				self.attacks[params.record] = true
				return damage
            end
        end
    end
end

function modifier_riki_backstab_handler:IsHidden()
    return true
end