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

	local damage = self:GetSpecialValueFor("damage")
	local bonusDamagePerHit = damage * self:GetSpecialValueFor("damage_percent_add") / 100
	local bounces = self:GetSpecialValueFor("max_targets")
	local jump_delay = self:GetSpecialValueFor("jump_delay")
	
	local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_furion/furion_wrath_of_nature_cast.vpcf", PATTACH_POINT_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(nfx, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(nfx, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)

	EmitSoundOn("Hero_Furion.WrathOfNature_Cast.Self", caster)
	
	local hitTable = {}
	local trackHits = {}
	local entangleDuration = self:GetSpecialValueFor("entangle_duration")
	local entangleDurationPerHit = entangleDuration * self:GetSpecialValueFor("damage_percent_add") / 100
	local damageBonusDuration = self:GetSpecialValueFor("damage_bonus_duration")
	local tree_destroy_radius = self:GetSpecialValueFor("tree_destroy_radius")
	
	if tree_destroy_radius > 0 then
		for _, tree in ipairs( GridNav:GetAllTreesAroundPoint( caster:GetAbsOrigin(), 3000, false ) ) do
			if not tree:IsStanding() then
				bounces = bounces + 1
			elseif CalculateDistance( caster, tree ) <= tree_destroy_radius then
				bounces = bounces + 1
				tree:CutDown( caster:GetTeamNumber() )
			end
		end
	end
	local atLeastOneEnemy = false
	
	-- caster:RemoveModifierByName("modifier_furion_wrath_of_nature_arboriculturist")
	-- local buff = caster:AddNewModifier( caster, self, "modifier_furion_wrath_of_nature_arboriculturist", {duration = self:GetSpecialValueFor("kill_damage_duration")})
	
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
				
				
				self:DealDamage(caster, enemy, damage)
				-- buff:IncrementStackCount()
				if entangleDuration > 0 then
					enemy:AddNewModifier(caster, self, "modifier_furion_wrath_of_nature_naturopath", {duration = entangleDuration})
				end
				if damageBonusDuration > 0 then
					for _, treant in ipairs( caster:FindFriendlyUnitsInRadius( caster:GetAbsOrigin(), FIND_UNITS_EVERYWHERE ) ) do
						if treant == caster or treant:GetUnitLabel() == "treants" then
							treant:AddNewModifier(caster, self, "modifier_furion_wrath_of_nature_arboriculturist", {duration = damageBonusDuration})
						end
					end
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


modifier_furion_wrath_of_nature_arboriculturist = class({})
LinkLuaModifier( "modifier_furion_wrath_of_nature_arboriculturist", "heroes/hero_furion/furion_wrath_of_nature",LUA_MODIFIER_MOTION_NONE )

function modifier_furion_wrath_of_nature_arboriculturist:OnCreated()
	self:OnRefresh()
	if IsServer() then self:SetHasCustomTransmitterData(true) end
end

function modifier_furion_wrath_of_nature_arboriculturist:OnRefresh()
	self.base_damage_bonus = self:GetSpecialValueFor("base_damage_bonus") / 100
	if IsServer() then
		self.damage = self:GetParent():GetBaseDamageMax()
		self:IncrementStackCount()
		self:SendBuffRefreshToClients()
	end
end

function modifier_furion_wrath_of_nature_arboriculturist:DeclareFunctions()
	return {MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE}
end

function modifier_furion_wrath_of_nature_arboriculturist:GetModifierBaseAttack_BonusDamage()
	if self.damage then
		return self.damage * self.base_damage_bonus * self:GetStackCount()
	end
end

function modifier_furion_wrath_of_nature_arboriculturist:AddCustomTransmitterData()
	return {damage = self.damage}
end

function modifier_furion_wrath_of_nature_arboriculturist:HandleCustomTransmitterData(data)
	self.damage = data.damage
end

modifier_furion_wrath_of_nature_naturopath = class({})
LinkLuaModifier( "modifier_furion_wrath_of_nature_naturopath", "heroes/hero_furion/furion_wrath_of_nature",LUA_MODIFIER_MOTION_NONE )

function modifier_furion_wrath_of_nature_naturopath:CheckState()
	return {[MODIFIER_STATE_ROOTED] = true}
end

function modifier_furion_wrath_of_nature_naturopath:GetEffectName()
	return "particles/units/heroes/hero_treant/treant_bramble_root.vpcf"
end