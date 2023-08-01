silencer_glaives_of_wisdom = class({})

function silencer_glaives_of_wisdom:GetIntrinsicModifierName()
	return "modifier_silencer_glaives_of_wisdom_autocast"
end

function silencer_glaives_of_wisdom:IsStealable()
	return false
end

function silencer_glaives_of_wisdom:ShouldUseResources()
	return false
end

function silencer_glaives_of_wisdom:GetAOERadius()
	return self:GetSpecialValueFor("shard_radius")
end

function silencer_glaives_of_wisdom:GetCastRange( position, target )
	return self:GetCaster():GetAttackRange() - self:GetCaster():GetCastRangeBonus()
end

function silencer_glaives_of_wisdom:Spawn()
	if not IsServer() then return end
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_silencer_glaives_of_wisdom_autocast", {} )
end

function silencer_glaives_of_wisdom:CreateBouncingGlaive( target, origin )
	local caster = self:GetCaster()
	local glaive = self:FireTrackingProjectile("particles/units/heroes/hero_silencer/silencer_glaives_of_wisdom.vpcf", target, caster:GetProjectileSpeed(), {source = origin} )
	
	self.projectiles = self.projectiles or {}
	self.projectiles[glaive] = {bounces = self:GetSpecialValueFor("bounce_count"), targets = {[origin:entindex()] = true}}
	
	return glaive
end

function silencer_glaives_of_wisdom:OnProjectileHitHandle( target, position, projectile )
	if target then
		local caster = self:GetCaster()
		
		EmitSoundOn( "Hero_Silencer.GlaivesOfWisdom.Damage", target )

		self.projectiles[projectile].targets[target:entindex()] = true
		
		self.forceGlaivesBehavior = true
		caster:PerformAbilityAttack( target, true, self )
		
		if self.projectiles[projectile] and self.projectiles[projectile].bounces > 0 then
			local radius = self:GetSpecialValueFor("bounce_range")
			for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), radius ) ) do
				if not self.projectiles[projectile].targets[enemy:entindex()] then
					local newProj = self:CreateBouncingGlaive(enemy, target)
					self.projectiles[newProj].targets = table.copy( self.projectiles[projectile].targets )
					self.projectiles[newProj].bounces = self.projectiles[projectile].bounces - 1
					break
				end
			end
			self.projectiles[projectile] = nil
		end
	end
end

modifier_silencer_glaives_of_wisdom_autocast = class({})
LinkLuaModifier("modifier_silencer_glaives_of_wisdom_autocast", "heroes/hero_silencer/silencer_glaives_of_wisdom", LUA_MODIFIER_MOTION_NONE)

function modifier_silencer_glaives_of_wisdom_autocast:OnCreated()
	self.attacks = {}
end

function modifier_silencer_glaives_of_wisdom_autocast:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK, 
			MODIFIER_EVENT_ON_ORDER, 
			MODIFIER_EVENT_ON_ATTACK_START,
			MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PURE,
			MODIFIER_PROPERTY_PROJECTILE_NAME,
			MODIFIER_EVENT_ON_DEATH,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS 
			}
end

function modifier_silencer_glaives_of_wisdom_autocast:OnOrder(params)
	if params.unit == self:GetParent() then
		if params.ability == self:GetAbility() and params.order_type == DOTA_UNIT_ORDER_CAST_TARGET then
			self.autocast = true
		else
			self.autocast = false
		end
	end
end

function modifier_silencer_glaives_of_wisdom_autocast:OnAttack(params)
	if params.attacker == self:GetParent() and params.target and (( self:GetAbility():GetAutoCastState() and self:GetAbility():IsFullyCastable() ) or self.autocast) then
		local ability = self:GetAbility()
		if ability.forceGlaivesBehavior then return end
		self.attacks[params.record] = true
		EmitSoundOn( "Hero_Silencer.GlaivesOfWisdom", params.attacker )
		ability:PayManaCost()
	end
end
	
function modifier_silencer_glaives_of_wisdom_autocast:GetModifierProcAttack_BonusDamage_Pure(params)
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if self.attacks[params.record] or ability.forceGlaivesBehavior then
		caster:AddNewModifier( caster, ability, "modifier_silencer_glaives_of_wisdom_intellect_bonus", {duration = self:GetSpecialValueFor("int_steal_duration")} )
		if caster:HasShard() then
			params.target:AddNewModifier( caster, ability, "modifier_silencer_glaives_of_wisdom_shard", {} )
		end
		
		if not ability.forceGlaivesBehavior then -- ignore bounce behavior
			local radius = self:GetSpecialValueFor("bounce_range")
			if radius > 0 then
				for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( params.target:GetAbsOrigin(), radius ) ) do
					if enemy ~= params.target then
						ability:CreateBouncingGlaive( enemy, params.target )
						break
					end
				end
			end
		end
		
		EmitSoundOn( "Hero_Silencer.GlaivesOfWisdom.Damage", params.target )
		
		self.attacks[params.record] = nil
		ability.forceGlaivesBehavior = nil
		return caster:GetIntellect() * self:GetSpecialValueFor("intellect_damage_pct")/100
	end
end

function modifier_silencer_glaives_of_wisdom_autocast:GetModifierProjectileName(params)
	if IsServer() and (self:GetAbility():IsCooldownReady() and self:GetAbility():GetAutoCastState()) or self.autocast then
		return "particles/units/heroes/hero_silencer/silencer_glaives_of_wisdom.vpcf"
	end
end

function modifier_silencer_glaives_of_wisdom_autocast:OnDeath(params)
	local caster = self:GetCaster()
	if not caster:IsSameTeam( params.unit ) and ( params.attacker == caster or CalculateDistance( caster, params.unit ) <= self:GetSpecialValueFor("permanent_int_steal_range") ) then
		if params.unit:IsConsideredHero() then
			self:IncrementStackCount()
		end
	end
end

function modifier_silencer_glaives_of_wisdom_autocast:GetModifierBonusStats_Intellect()
	return self:GetSpecialValueFor("permanent_int_steal_amount") * self:GetStackCount()
end

function modifier_silencer_glaives_of_wisdom_autocast:IsHidden()
	return false
end

modifier_silencer_glaives_of_wisdom_shard = class({})
LinkLuaModifier("modifier_silencer_glaives_of_wisdom_shard", "heroes/hero_silencer/silencer_glaives_of_wisdom", LUA_MODIFIER_MOTION_NONE)

function modifier_silencer_glaives_of_wisdom_shard:OnCreated()
	if IsServer() then self:SetStackCount(1) end
end

function modifier_silencer_glaives_of_wisdom_shard:OnRefresh()
	if IsServer() then self:IncrementStackCount() end
end

function modifier_silencer_glaives_of_wisdom_shard:OnStackCountChanged( previous )
	if IsServer() and self:GetStackCount() == self:GetSpecialValueFor("stacks_for_silence") then
		self:GetAbility():Silence( self:GetParent(), self:GetSpecialValueFor("silence_duration") )
		self:Destroy()
	end
end

modifier_silencer_glaives_of_wisdom_intellect_bonus = class({})
LinkLuaModifier("modifier_silencer_glaives_of_wisdom_intellect_bonus", "heroes/hero_silencer/silencer_glaives_of_wisdom", LUA_MODIFIER_MOTION_NONE)

function modifier_silencer_glaives_of_wisdom_intellect_bonus:OnCreated()
	if IsServer() then
		self:SetStackCount( 1 )
	end
end

function modifier_silencer_glaives_of_wisdom_intellect_bonus:OnRefresh()
	if IsServer() then
		self:AddIndependentStack()
	end
end

function modifier_silencer_glaives_of_wisdom_intellect_bonus:OnStackCountChanged( previous )
	if IsServer() then
		self:GetParent():CalculateStatBonus( false )
	end
end

function modifier_silencer_glaives_of_wisdom_intellect_bonus:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_INTELLECT_BONUS}
end

function modifier_silencer_glaives_of_wisdom_intellect_bonus:GetModifierBonusStats_Intellect()
	return self:GetSpecialValueFor("int_steal") * self:GetStackCount()
end