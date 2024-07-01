minion_demonic_imp_explode = class({})

function minion_demonic_imp_explode:GetIntrinsicModifierName()
	return "modifier_minion_demonic_imp_explode"
end

modifier_minion_demonic_imp_explode = class({})
LinkLuaModifier( "modifier_minion_demonic_imp_explode", "bosses/boss_warlocks/minion_demonic_imp_explode", LUA_MODIFIER_MOTION_NONE )

function modifier_minion_demonic_imp_explode:OnCreated()
	self:OnRefresh()
end

function modifier_minion_demonic_imp_explode:OnRefresh()
	self.explosion_delay = self:GetSpecialValueFor("explosion_delay")
	self.die_on_attack = self:GetSpecialValueFor("die_on_attack") == 1
	self.explosion_dmg = self:GetSpecialValueFor("explosion_dmg")
	self.explosion_radius = self:GetSpecialValueFor("explosion_radius")
end

function modifier_minion_demonic_imp_explode:OnDestroy()
	if not IsServer() then return end
end

function modifier_minion_demonic_imp_explode:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED, MODIFIER_EVENT_ON_DEATH }
end

function modifier_minion_demonic_imp_explode:OnAttackLanded( params )
	if self.die_on_attack and params.attacker == self:GetParent() then
		params.attacker:ForceKill(true)
	end
end

function modifier_minion_demonic_imp_explode:OnDeath( params )
	if params.unit == self:GetParent() then
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local nFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_warlock/warlock_imp_explode.vpcf", PATTACH_WORLDORIGIN, nil )
		ParticleManager:SetParticleControl( nFX, 0, parent:GetAbsOrigin() )
		ParticleManager:SetParticleControl( nFX, 3, Vector( self.explosion_radius, self.explosion_radius, self.explosion_radius ) )
		
		local position = parent:GetAbsOrigin()
		Timers:CreateTimer( self.explosion_delay, function()
			for _, enemy in ipairs( parent:FindEnemyUnitsInRadius( position, self.explosion_radius ) ) do
				ability:DealDamage( parent, enemy, self.explosion_dmg )
			end
			EmitSoundOn( "Warlock_Imp.Explode", parent )
			ParticleManager:ClearParticle( nFX )
		end )
	end
end