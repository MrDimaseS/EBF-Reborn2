shadow_shaman_mass_serpent_ward = class({})

function shadow_shaman_mass_serpent_ward:GetIntrinsicModifierName()
	return "modifier_shadow_shaman_mass_serpent_ward_shard"
end

function shadow_shaman_mass_serpent_ward:OnSpellStart()
	local caster = self:GetCaster()
	local position = self:GetCursorPosition()
	
	local wards = self:GetSpecialValueFor("ward_count")
	local spawnRadius = self:GetSpecialValueFor("spawn_radius")
	local duration = self:GetSpecialValueFor("duration")
	local direction = caster:GetForwardVector()
	local angle = 360 / wards
	
	local megaWard = self:GetSpecialValueFor("is_mega_ward") == 1
	if megaWard then
		self:CreateWard( spawnPos, duration, megaWard )
	else
		for i = 1, wards do
			local spawnPos = position + RotateVector2D( direction, ToRadians( angle * (i-1) ) ) * spawnRadius 
			self:CreateWard( spawnPos, duration )
		end
	end
end

function shadow_shaman_mass_serpent_ward:CreateWard( position, duration, bMegaWard )
	local caster = self:GetCaster()
	local ward = caster:CreateSummon( "npc_dota_shadow_shaman_ward_1", position, duration )
	if bMegaWard then
		ward:SetCoreHealth( ward:GetMaxHealth() * self:GetSpecialValueFor("mega_ward_health_tooltip") )
	end
	ward:AddNewModifier( caster, self, "modifier_shadow_shaman_mass_serpent_ward_handler", {duration = duration} )
end

LinkLuaModifier("modifier_shadow_shaman_mass_serpent_ward_shard", "heroes/hero_shadow_shaman/shadow_shaman_mass_serpent_ward", LUA_MODIFIER_MOTION_NONE)
modifier_shadow_shaman_mass_serpent_ward_shard = class({})

function modifier_shadow_shaman_mass_serpent_ward_shard:OnCreated()
	self.shard_radius = self:GetSpecialValueFor("shard_radius")
	self.shard_duration = self:GetSpecialValueFor("shard_duration")
	
	self.abilitiesOnCooldown = {}
	
	if IsServer() then
		self:StartIntervalThink( 0.1 )
	end
end

function modifier_shadow_shaman_mass_serpent_ward_shard:OnIntervalThink()
	if not self:GetCaster():HasShard() then return end
	for i = 0, 6 do
        local ability = self:GetCaster():GetAbilityByIndex( i )
        if ability then
			if not ability:IsCooldownReady() and not self.abilitiesOnCooldown[ability] then -- first time ability is triggered on cd
				self:GetAbility():CreateWard( self:GetCaster():GetAbsOrigin() + RandomVector(self.shard_radius), self.shard_duration )
				self.abilitiesOnCooldown[ability] = true
			elseif ability:IsCooldownReady() and self.abilitiesOnCooldown[ability] then -- reset ability trigger
				self.abilitiesOnCooldown[ability] = false
			end
        end
    end
end

LinkLuaModifier("modifier_shadow_shaman_mass_serpent_ward_handler", "heroes/hero_shadow_shaman/shadow_shaman_mass_serpent_ward", LUA_MODIFIER_MOTION_NONE)
modifier_shadow_shaman_mass_serpent_ward_handler = class({})

function modifier_shadow_shaman_mass_serpent_ward_handler:OnCreated()
	self.damage_tooltip = self:GetSpecialValueFor("damage_tooltip") * self:GetSpecialValueFor("mega_ward_multiplier_tooltip")
	self.hits_to_destroy_tooltip = self:GetParent():GetMaxHealth() / self:GetSpecialValueFor("hits_to_destroy_tooltip")
	self.hits_to_destroy_tooltip_creeps = self:GetParent():GetMaxHealth() / self:GetSpecialValueFor("hits_to_destroy_tooltip_creeps")
	self.scepter_attack_speed = TernaryOperator( self:GetSpecialValueFor("scepter_attack_speed"), self:GetCaster():HasScepter(), 0 )
	self.scepter_range = self:GetSpecialValueFor("scepter_range")
	self.ether_shock_on_death = self:GetSpecialValueFor("ether_shock_on_death") == 1
	
	if IsServer() and self:GetCaster():HasScepter() then
		self:StartIntervalThink( 0.1 )
	end
end

function modifier_shadow_shaman_mass_serpent_ward_handler:OnDestroy()
	if IsServer() and self.ether_shock_on_death then
		local ward = self:GetParent()
		local shock = self:GetCaster():FindAbilityByName("shadow_shaman_ether_shock")
		if shock and shock:IsTrained() then
			local target = self.unitWhoKilledMe or ward:FindRandomEnemyInRadius( ward:GetAbsOrigin(), shock:GetTrueCastRange() )
			if target then
				shock:EtherShock( target, ward )
			end
		end
	end
end

function modifier_shadow_shaman_mass_serpent_ward_handler:OnIntervalThink()
	local ward = self:GetParent()
	if ward:IsAttacking() then return end
	if not ward:FindRandomEnemyInRadius( ward:GetAbsOrigin(), ward:GetAttackRange() ) and CalculateDistance( ward, self:GetCaster() ) >= self:GetSpecialValueFor("scepter_range") * 2 then -- no viable attack target
		local position = self:GetCaster():GetAbsOrigin() + RandomVector( self.scepter_range )
		local attackTarget = self:GetCaster():GetAttackTarget() or ward:FindRandomEnemyInRadius( self:GetCaster():GetAbsOrigin(), ward:GetAttackRange() + self.scepter_range )
		if attackTarget and CalculateDistance( position, attackTarget ) > ward:GetAttackRange() then
			position = position + CalculateDirection( attackTarget, position ) * ( ( CalculateDistance( position, attackTarget ) - ward:GetAttackRange() ) + 50 )
		end
		ward:Blink(position)
	end
end

function modifier_shadow_shaman_mass_serpent_ward_handler:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			 MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			 MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
			 MODIFIER_PROPERTY_HEALTHBAR_PIPS }
end

function modifier_shadow_shaman_mass_serpent_ward_handler:GetModifierPreAttack_BonusDamage()
	return self.damage_tooltip
end

function modifier_shadow_shaman_mass_serpent_ward_handler:GetModifierAttackSpeedBonus_Constant()
	return self.scepter_attack_speed
end

function modifier_shadow_shaman_mass_serpent_ward_handler:GetModifierHealthBarPips()
	return self.hits_to_destroy_tooltip
end

function modifier_shadow_shaman_mass_serpent_ward_handler:GetModifierIncomingDamage_Percentage(params)
	local parent = self:GetParent()
	if params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
		local hp = parent:GetHealth()
		local damage = TernaryOperator( self.hits_to_destroy_tooltip, params.attacker:IsConsideredHero(), self.hits_to_destroy_tooltip_creeps )
		if hp > damage then
			parent:SetHealth( hp - damage )
		else
			self:GetParent():StartGesture(ACT_DOTA_DIE)
			self.unitWhoKilledMe = params.attacker
			parent:Kill(params.inflictor, params.attacker)
		end
	end
	return -999
end

function modifier_shadow_shaman_mass_serpent_ward_handler:IsHidden()
	return true
end

function modifier_shadow_shaman_mass_serpent_ward_handler:IsPurgable()
	return false
end