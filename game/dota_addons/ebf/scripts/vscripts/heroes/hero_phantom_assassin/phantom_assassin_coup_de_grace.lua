phantom_assassin_coup_de_grace = class({})

function phantom_assassin_coup_de_grace:GetIntrinsicModifierName()
    return "modifier_phantom_assassin_coup_de_grace_handler"
end

modifier_phantom_assassin_coup_de_grace_deadly_mark = class({})
LinkLuaModifier( "modifier_phantom_assassin_coup_de_grace_deadly_mark", "heroes/hero_phantom_assassin/phantom_assassin_coup_de_grace", LUA_MODIFIER_MOTION_NONE )

function modifier_phantom_assassin_coup_de_grace_deadly_mark:OnCreated()
	self:OnRefresh()
end

function modifier_phantom_assassin_coup_de_grace_deadly_mark:OnRefresh()
	self.crit_bonus = self:GetSpecialValueFor("crit_bonus")
	self.current_health_damage = self:GetSpecialValueFor("current_health_damage") / 100
	self.break_duration = self:GetSpecialValueFor("break_duration")
end


function modifier_phantom_assassin_coup_de_grace_deadly_mark:DeclareFunctions()
    return {MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PURE, MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE, MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_phantom_assassin_coup_de_grace_deadly_mark:GetModifierPreAttack_CriticalStrike( params )
   self.on_crit = params.record
   return self.crit_bonus
end

function modifier_phantom_assassin_coup_de_grace_deadly_mark:GetModifierProcAttack_BonusDamage_Pure( params )
	if self.current_health_damage <= 0 then return end
	return params.target:GetHealth() * self.current_health_damage
end

function modifier_phantom_assassin_coup_de_grace_deadly_mark:OnAttackLanded( params )
    if params.record == self.on_crit and params.attacker == self:GetParent() then
        local enemy = params.target
        -- If that attack was marked as a critical strike, apply the particles
		EmitSoundOn( "Hero_PhantomAssassin.CoupDeGrace", enemy )
        local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf", PATTACH_CUSTOMORIGIN, self:GetParent() )
                    ParticleManager:SetParticleControlEnt( nFXIndex, 0, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetOrigin(), true )
                    ParticleManager:SetParticleControl( nFXIndex, 1, enemy:GetOrigin() )
                    ParticleManager:SetParticleControlForward( nFXIndex, 1, CalculateDirection( params.attacker, enemy ) )
                    ParticleManager:SetParticleControlEnt( nFXIndex, 10, enemy, PATTACH_ABSORIGIN_FOLLOW, nil, enemy:GetOrigin(), true )
                    ParticleManager:ReleaseParticleIndex( nFXIndex )
		if self.break_duration > 0 then
			enemy:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_break", {duration = self.break_duration} )
		end
		self:Destroy()
    end
end

function modifier_phantom_assassin_coup_de_grace_deadly_mark:GetEffectName()
	return "particles/units/heroes/hero_phantom_assassin/phantom_assassin_mark_overhead.vpcf"
end

function modifier_phantom_assassin_coup_de_grace_deadly_mark:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_phantom_assassin_coup_de_grace_deadly_mark:GetPriority() -- make sure this attack event always triggers first
	return MODIFIER_PRIORITY_SUPER_ULTRA
end

modifier_phantom_assassin_coup_de_grace_handler = class({})
LinkLuaModifier( "modifier_phantom_assassin_coup_de_grace_handler", "heroes/hero_phantom_assassin/phantom_assassin_coup_de_grace", LUA_MODIFIER_MOTION_NONE )

function modifier_phantom_assassin_coup_de_grace_handler:OnCreated()
	self:OnRefresh()
end

function modifier_phantom_assassin_coup_de_grace_handler:OnRefresh()
	self.crit_chance = self:GetSpecialValueFor("base_crit_chance")
	self.stifling_crit_chance = self:GetSpecialValueFor("stifling_crit_chance")
	self.bonus_crit_chance = self:GetSpecialValueFor("bonus_crit_chance")
	self.invis_crit_chance_bonus = self:GetSpecialValueFor("invis_crit_chance_bonus")
	self.duration = self:GetSpecialValueFor("duration")
end


function modifier_phantom_assassin_coup_de_grace_handler:DeclareFunctions()
    return {MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_phantom_assassin_coup_de_grace_handler:OnAttackLanded( params )
    if params.attacker ~= self:GetParent() then return end
	local total_crit_chance = self.crit_chance
	if self.stifling_crit_chance > 0 and params.attacker:GetAttackData( params.record ).ability then
		if params.attacker:GetAttackData( params.record ).ability:GetAbilityName() == "phantom_assassin_stifling_dagger" then
			total_crit_chance = self.stifling_crit_chance
		end
	end
	if self.bonus_crit_chance > 0 then
		local immaterial = params.attacker:FindModifierByName("modifier_phantom_assassin_immaterial_handler")
		total_crit_chance = total_crit_chance + self.bonus_crit_chance * immaterial:GetStackCount()
	end
	if self.invis_crit_chance_bonus > 0 and params.attacker:IsInvisible() then
		total_crit_chance = total_crit_chance * self.invis_crit_chance_bonus
	end
	if self:RollPRNG( total_crit_chance ) then
		params.attacker:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_phantom_assassin_coup_de_grace_deadly_mark", {duration = self.duration} )
	end
end

function modifier_phantom_assassin_coup_de_grace_handler:IsHidden()
    return true
end