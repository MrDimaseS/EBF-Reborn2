pugna_nether_ward = class({})

function pugna_nether_ward:GetCooldown(iLvl)
	return self.BaseClass.GetCooldown(self, iLvl) + self:GetCaster():FindTalentValue("special_bonus_unique_pugna_nether_ward_1")
end

if IsServer() then
	function pugna_nether_ward:OnSpellStart()
		local caster = self:GetCaster()
		local point =  self:GetCursorPosition()
		
		local netherward = caster:CreateSummon( "npc_dota_pugna_nether_ward_1", point, self:GetDuration() )	
		netherward:AddNewModifier(self:GetCaster(), self, "modifier_pugna_nether_ward_thinker", {})
		
		local hp = self:GetSpecialValueFor("attacks_to_destroy_tooltip") * 4
		netherward:SetBaseMaxHealth( hp )
		netherward:SetMaxHealth( hp )
		netherward:SetHealth( hp )
		
		local nFX = ParticleManager:CreateParticle("particles/units/heroes/hero_pugna/pugna_ward_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, netherward)
			ParticleManager:SetParticleControl(nFX, 0, netherward:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(nFX)
		EmitSoundOn("Hero_Pugna.NetherWard", netherward)
	end
end

modifier_pugna_nether_ward_thinker = class({})
LinkLuaModifier( "modifier_pugna_nether_ward_thinker", "heroes/hero_pugna/pugna_nether_ward" ,LUA_MODIFIER_MOTION_NONE )

function modifier_pugna_nether_ward_thinker:OnCreated( kv )
	self.radius = self:GetAbility():GetTalentSpecialValueFor( "radius" )
	self.dmg_mult = self:GetAbility():GetTalentSpecialValueFor( "int_multiplier" )
	self.base_damage = self:GetAbility():GetTalentSpecialValueFor( "base_damage" )
end

function modifier_pugna_nether_ward_thinker:CheckState()
	return {[MODIFIER_STATE_ROOTED] = true,
			[MODIFIER_STATE_DISARMED] = true,
			[MODIFIER_STATE_SILENCED] = true,
			[MODIFIER_STATE_MAGIC_IMMUNE] = true}
end


function modifier_pugna_nether_ward_thinker:DeclareFunctions()
	funcs = {
				MODIFIER_EVENT_ON_ABILITY_START,
				MODIFIER_EVENT_ON_ATTACK_LANDED,
				MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
				MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
				MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
			}
	return funcs
end

function modifier_pugna_nether_ward_thinker:OnAbilityStart(params)
	if IsServer() then
		if self.alreadyZapping then return end
		if params and params.unit and not params.unit:IsNull() and params.unit:IsAlive() then
			local ward = self:GetParent()
			if params.unit:GetTeam() ~= ward:GetTeam() and CalculateDistance( params.unit, ward ) <= self.radius then
				self.alreadyZapping = true
				ParticleManager:FireRopeParticle("particles/units/heroes/hero_pugna/pugna_ward_attack.vpcf", PATTACH_ABSORIGIN_FOLLOW, params.unit, ward)
		
				params.unit:EmitSound("Hero_Pugna.NetherWard.Target")
				ward:EmitSound("Hero_Pugna.NetherWard.Attack")
				
				self:GetAbility():DealDamage( self:GetCaster(), params.unit, self.base_damage +  self:GetCaster():GetIntellect()*self.dmg_mult, {damage_type = DAMAGE_TYPE_MAGICAL} )
				self.alreadyZapping = false
			end
		end
	end
end

function modifier_pugna_nether_ward_thinker:OnAttackLanded(params)
	if IsServer() then
		if params and params.target == self:GetParent() then
			local hp = params.target:GetHealth()
			local damage = TernaryOperator( 4, params.attacker:IsConsideredHero(), 1 )
			if hp <= damage then
				params.target:ForceKill( false )
			else
				params.target:SetHealth( params.target:GetHealth() - 4 )
			end
		end
	end
end

function modifier_pugna_nether_ward_thinker:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_pugna_nether_ward_thinker:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_pugna_nether_ward_thinker:GetAbsoluteNoDamagePure()
	return 1
end

function modifier_pugna_nether_ward_thinker:IsAura()
	return true
end

function modifier_pugna_nether_ward_thinker:GetModifierAura()
	return "modifier_pugna_nether_ward_aura"
end

function modifier_pugna_nether_ward_thinker:GetAuraRadius()
	return self.radius
end

function modifier_pugna_nether_ward_thinker:GetAuraDuration()
	return 0.5
end

function modifier_pugna_nether_ward_thinker:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_pugna_nether_ward_thinker:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_pugna_nether_ward_thinker:IsHidden()
	return true
end

function modifier_pugna_nether_ward_thinker:IsPurgable()
    return false
end