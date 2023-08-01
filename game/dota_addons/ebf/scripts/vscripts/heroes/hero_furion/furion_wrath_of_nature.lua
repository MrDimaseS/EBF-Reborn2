furion_wrath_of_nature = class({})

function furion_wrath_of_nature:IsStealable()
	return true
end

function furion_wrath_of_nature:IsHiddenWhenStolen()
	return false
end

function furion_wrath_of_nature:OnSpellStart()
	local caster = self:GetCaster()
	local point = caster:GetAbsOrigin()

	local previousEnemy = caster

	local damage = self:GetTalentSpecialValueFor("damage")
	local bonusDamagePerHit = damage * self:GetTalentSpecialValueFor("damage_percent_add") / 100
	local bounces = self:GetTalentSpecialValueFor("max_targets")
	local jump_delay = self:GetTalentSpecialValueFor("jump_delay")
	
	local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_furion/furion_wrath_of_nature_cast.vpcf", PATTACH_POINT_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(nfx, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(nfx, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)

	EmitSoundOn("Hero_Furion.WrathOfNature_Cast.Self", caster)
	
	local hitTable = {}
	local trackHits = {}
	local entangleDuration = TernaryOperator( self:GetSpecialValueFor("scepter_min_entangle_duration"), caster:HasScepter(), 0 )
	local entangleDurationPerHit = (entangleDuration - TernaryOperator( self:GetSpecialValueFor("scepter_max_entangle_duration"), caster:HasScepter(), 0 )) / bounces
	
	local atLeastOneEnemy = false
	
	caster:RemoveModifierByName("modifier_furion_wrath_of_nature_damage")
	local buff = caster:AddNewModifier( caster, self, "modifier_furion_wrath_of_nature_damage", {duration = self:GetSpecialValueFor("kill_damage_duration")})
	
	Timers:CreateTimer(0,function()
		if bounces <= 0 then
			StopSoundOn("Hero_Furion.WrathOfNature_Cast.Self", caster)
			return nil
		end
		local enemies = self:GetCaster():FindEnemyUnitsInRadius(previousEnemy:GetAbsOrigin(), FIND_UNITS_EVERYWHERE, {order = FIND_CLOSEST})
		for _,enemy in pairs(enemies) do
			atLeastOneEnemy = true
			if not hitTable[enemy:entindex()] then -- only hit every target once
				--Spare ourselves sound complaints
				--EmitSoundOn("Hero_Furion.WrathOfNature_Damage.Creep", enemy)
				hitTable[enemy:entindex()] = true

				local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_furion/furion_wrath_of_nature.vpcf", PATTACH_POINT_FOLLOW, caster)
				ParticleManager:SetParticleControlEnt(particle, 0, previousEnemy, PATTACH_POINT_FOLLOW, "attach_hitloc", previousEnemy:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(particle, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(particle, 2, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(particle, 3, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(particle, 4, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
				ParticleManager:ReleaseParticleIndex(particle)
				
				
				self:DealDamage(caster, enemy, damage, {}, 0)
				buff:IncrementStackCount()
				if entangleDuration > 0 then
					enemy:AddNewModifier(caster, self, "modifier_furion_wrath_of_nature_root", {duration = entangleDuration})
				end
				if not trackHits[enemy:entindex()] then
					damage = damage + bonusDamagePerHit
					entangleDuration = entangleDuration + entangleDurationPerHit
					trackHits[enemy:entindex()] = true
				end

				previousEnemy = enemy
				bounces = bounces-1

				return jump_delay
			end -- no valid targets found
		end
		if atLeastOneEnemy then
			hitTable = {} -- clear hitTable to reset
			return 0
		else
			bounces = bounces-1
			return jump_delay
		end
	end)
end


modifier_furion_wrath_of_nature_damage = class({})
LinkLuaModifier( "modifier_furion_wrath_of_nature_damage", "heroes/hero_furion/furion_wrath_of_nature",LUA_MODIFIER_MOTION_NONE )

function modifier_furion_wrath_of_nature_damage:OnCreated()
	self.damage = self:GetSpecialValueFor("kill_damage")
end

function modifier_furion_wrath_of_nature_damage:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE}
end

function modifier_furion_wrath_of_nature_damage:GetModifierPreAttack_BonusDamage()
	return self.damage * self:GetStackCount()
end

modifier_furion_wrath_of_nature_root = class({})
LinkLuaModifier( "modifier_furion_wrath_of_nature_root", "heroes/hero_furion/furion_wrath_of_nature",LUA_MODIFIER_MOTION_NONE )

function modifier_furion_wrath_of_nature_root:CheckState()
	return {[MODIFIER_STATE_ROOTED] = true}
end

function modifier_furion_wrath_of_nature_root:GetEffectName()
	return "particles/units/heroes/hero_treant/treant_bramble_root.vpcf"
end