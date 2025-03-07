riki_invis = class({})

function riki_invis:GetIntrinsicModifierName()
    return "modifier_riki_invis_handler"
end

modifier_riki_invis_handler = class({})
LinkLuaModifier( "modifier_riki_invis_handler", "heroes/hero_riki/riki_invis.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_riki_invis_handler:OnCreated()
	self:OnRefresh()
end

function modifier_riki_invis_handler:OnRefresh()
	self.fade_delay = self:GetSpecialValueFor("fade_delay")
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.kill_creeps = self:GetSpecialValueFor("kill_creeps")
	self.disarm_duration = self:GetSpecialValueFor("disarm_duration")
	self.attacks = {}
	if IsServer() then
		self:StartIntervalThink( 0 )
	end
end

function modifier_riki_invis_handler:OnIntervalThink()
	local parent = self:GetParent()
	if parent:HasModifier("modifier_riki_invis_invisible") then
		return
	end
	if not self._lastAttackTime then
		self._lastAttackTime = GameRules:GetGameTime()
		self:GetAbility():SetCooldown( self.fade_delay )
	end
	if self._lastAttackTime + self.fade_delay < GameRules:GetGameTime() or parent:HasModifier("modifier_riki_smoke_screen_infiltrator") then
		parent:AddNewModifier( parent, self:GetAbility(), "modifier_riki_invis_invisible", {} )
		self._lastAttackTime = nil
	end
end

function modifier_riki_invis_handler:DeclareFunctions()
    return {MODIFIER_EVENT_ON_ATTACK_LANDED,
			MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE }  
end

function modifier_riki_invis_handler:OnAttackLanded(params)
	if params.attacker == self:GetCaster() then
		local ability = self:GetAbility()
		self._lastAttackTime = GameRules:GetGameTime()
		ability:SetCooldown( self.fade_delay )
		if params.attacker:HasModifier("modifier_riki_invis_invisible") then
			self.attacks[params.record] = true
			if not params.attacker:HasModifier("modifier_riki_smoke_screen_infiltrator") then
				params.attacker:RemoveModifierByName("modifier_riki_invis_invisible")
			end
			if self.kill_creeps > 0 and not params.target:IsConsideredHero() then
				params.target:AttemptKill( ability, params.attacker )
			end
			if self.disarm_duration > 0 then
				local disarm = ability:Disarm(params.target, self.disarm_duration)
				Timers:CreateTimer(function()
					if IsModifierSafe(disarm) and IsEntitySafe( disarm:GetParent() ) then
						local dt = GetGameFrameTime()
						if disarm:GetParent():IsStunned() then
							disarm:SetDuration( disarm:GetRemainingTime() + dt	, true )
						end
						return dt
					end
				end)
			end
		end
	end
end

function modifier_riki_invis_handler:GetModifierTotalDamageOutgoing_Percentage(params)
	if params.attacker == self:GetCaster() and self.attacks[params.record] then
		self.attacks[params.record] = nil
		return self.bonus_damage
	end
end

function modifier_riki_invis_handler:IsHidden()
    return true
end

modifier_riki_invis_invisible = class({})
LinkLuaModifier( "modifier_riki_invis_invisible", "heroes/hero_riki/riki_invis.lua" ,LUA_MODIFIER_MOTION_NONE )


function modifier_riki_invis_invisible:OnCreated()
	self.bonus_movespeed = self:GetSpecialValueFor("bonus_movespeed")
end

function modifier_riki_invis_invisible:CheckState()
    return {[MODIFIER_STATE_INVISIBLE] = true}
end

function modifier_riki_invis_invisible:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }   
    return funcs
end

function modifier_riki_invis_invisible:GetModifierInvisibilityLevel()
	return 1
end

function modifier_riki_invis_invisible:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_movespeed
end