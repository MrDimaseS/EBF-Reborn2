warlock_eldritch_summoning = class({})

function warlock_eldritch_summoning:Spawn()
	self:GetCaster()._innateAbility = self
	self:GetCaster().SpawnImp = function( self, position ) return self._innateAbility:SpawnImp( position ) end
end

function warlock_eldritch_summoning:SpawnImp(position)
	local caster = self:GetCaster()
	local imp = caster:CreateSummon( "npc_dota_warlock_minor_imp", position, self:GetSpecialValueFor("minor_imp_duration") )
	
	FindClearSpaceForUnit(imp, position, true)
	local impHP = self:GetSpecialValueFor("tooltip_imp_health")
	local impSpeed = self:GetSpecialValueFor("tooltip_imp_speed")

	imp:SetCoreHealth(impHP)
	imp:SetBaseMoveSpeed(impSpeed)
	
	local attackDamage = imp:GetAverageBaseDamage()
	if not IsEntitySafe( self._golemsReference ) then
		self._golemsReference = caster:FindAbilityByName("warlock_rain_of_chaos")
	end
	if IsEntitySafe( self._golemsReference ) and self._golemsReference:IsTrained() then
		attackDamage = attackDamage + self._golemsReference:GetSpecialValueFor("golem_dmg") * (self:GetSpecialValueFor("imp_attack_damage") / 100)
	end
	imp:SetAverageBaseDamage( attackDamage, 10 )
	imp:AddNewModifier( caster, self, "modifier_warlock_eldritch_summoning_imp", {} )
	return imp
end

LinkLuaModifier("modifier_warlock_eldritch_summoning_imp", "heroes/hero_warlock/warlock_eldritch_summoning", LUA_MODIFIER_MOTION_NONE)
modifier_warlock_eldritch_summoning_imp = class({})

function modifier_warlock_eldritch_summoning_imp:OnCreated()
	self:OnRefresh()
end

function modifier_warlock_eldritch_summoning_imp:OnRefresh()
	self.cdr_on_death = self:GetSpecialValueFor("cdr_on_death")
	self.imp_attack_damage = self:GetSpecialValueFor("imp_attack_damage")
end

function modifier_warlock_eldritch_summoning_imp:OnDestroy()
	if IsServer() and not self:GetParent():IsAlive() then
		local position = self:GetParent():GetAbsOrigin()
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local radius = self:GetSpecialValueFor("explosion_radius")
		local damage = self:GetSpecialValueFor("explosion_dmg")
		local slowDuration = self:GetSpecialValueFor("explosion_slow_duration")
		
		if self.cdr_on_death < 0 then
			for i = 0, self:GetCaster():GetAbilityCount() - 1 do
				local ability = self:GetCaster():GetAbilityByIndex( i )
				if IsEntitySafe( ability ) then
					ability:ModifyCooldown( self.cdr_on_death )
				end
			end
			for i=DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
				local current_item = self:GetCaster():GetItemInSlot(i)
				if IsEntitySafe( current_item ) then
					current_item:ModifyCooldown( self.cdr_on_death )
				end
			end
			local neutralItem =	self:GetCaster():GetItemInSlot(DOTA_ITEM_NEUTRAL_ACTIVE_SLOT)  
			if IsEntitySafe( neutralItem ) then
				neutralItem:ModifyCooldown( self.cdr_on_death )
			end
		end
		
		local explodeFX = ParticleManager:CreateParticle("particles/units/heroes/hero_warlock/warlock_imp_explode.vpcf", PATTACH_WORLDORIGIN, nil )
		ParticleManager:SetParticleControl( explodeFX, 0, position )
		ParticleManager:SetParticleControl( explodeFX, 3, Vector( radius, radius, radius ) )
		Timers:CreateTimer( self:GetSpecialValueFor("explosion_delay"), function()
			EmitSoundOnLocationWithCaster( position, "Warlock_Imp.Explode", caster )
			ParticleManager:ClearParticle( explodeFX )
			
			for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( position, radius ) ) do
				ability:DealDamage( caster, enemy, damage, {damage_flags = DOTA_DAMAGE_FLAG_REFLECTION} )
				if slowDuration > 0 then
					enemy:AddNewModifier( caster, ability, "modifier_warlock_eldritch_summoning_tome_pact_slow", {duration = slowDuration} )
				end
			end
		end)
	end
end

function modifier_warlock_eldritch_summoning_imp:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_START}
end

function modifier_warlock_eldritch_summoning_imp:OnAttackStart( params )
	if params.attacker == self:GetParent() and self.imp_attack_damage == 0 then
		params.attacker:KillTarget()
	end
end

function modifier_warlock_eldritch_summoning_imp:IsHidden()
	return true
end

function modifier_warlock_eldritch_summoning_imp:IsPurgable()
	return false
end

LinkLuaModifier("modifier_warlock_eldritch_summoning_tome_pact_slow", "heroes/hero_warlock/warlock_eldritch_summoning", LUA_MODIFIER_MOTION_NONE)
modifier_warlock_eldritch_summoning_tome_pact_slow = class({})

function modifier_warlock_eldritch_summoning_tome_pact_slow:OnCreated()
	self:OnRefresh()
end

function modifier_warlock_eldritch_summoning_tome_pact_slow:OnRefresh()
	self.explosion_slow = self:GetSpecialValueFor("explosion_slow")
end

function modifier_warlock_eldritch_summoning_tome_pact_slow:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT}
end

function modifier_warlock_eldritch_summoning_tome_pact_slow:GetModifierAttackSpeedBonus_Constant()
	return self.explosion_slow
end

function modifier_warlock_eldritch_summoning_tome_pact_slow:GetModifierMoveSpeedBonus_Constant()
	return self.explosion_slow
end