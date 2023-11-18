pugna_nether_ward = class({})

function pugna_nether_ward:OnSpellStart()
	local caster = self:GetCaster()
	local point =  self:GetCursorPosition()
	
	local netherward = caster:CreateSummon( "npc_dota_pugna_nether_ward_1", point, self:GetDuration() )	
	netherward:AddNewModifier(self:GetCaster(), self, "modifier_pugna_nether_ward_thinker", {})
	
	local hp = self:GetSpecialValueFor("attacks_to_destroy_tooltip") * 4
	netherward:SetBaseMaxHealth( hp )
	netherward:SetMaxHealth( hp )
	netherward:SetHealth( hp )
	
	caster.netherwards = caster.nether_wards or {}
	caster.netherwards[netherward] = self:GetSpecialValueFor( "radius" )
	
	EmitSoundOn("Hero_Pugna.NetherWard", netherward)
end

modifier_pugna_nether_ward_thinker = class({})
LinkLuaModifier( "modifier_pugna_nether_ward_thinker", "heroes/hero_pugna/pugna_nether_ward" ,LUA_MODIFIER_MOTION_NONE )

function modifier_pugna_nether_ward_thinker:OnCreated( kv )
	self.radius = self:GetSpecialValueFor( "radius" )
	self.base_damage = self:GetSpecialValueFor( "base_damage" )
	self.attack_rate = self:GetSpecialValueFor( "attack_rate" )
	self.debuff_duration = self:GetSpecialValueFor( "debuff_duration" )
	self.pips = self:GetSpecialValueFor("attacks_to_destroy_tooltip")
	
	if IsServer() then
		self:StartIntervalThink( self.attack_rate )
		
		
		local nFX = ParticleManager:CreateParticle("particles/units/heroes/hero_pugna/pugna_ward_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControl(nFX, 0, self:GetParent():GetAbsOrigin())
		self:AddEffect( nFX )
	end
end

function modifier_pugna_nether_ward_thinker:OnIntervalThink()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	parent:EmitSound("Hero_Pugna.NetherWard.Attack")
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( parent:GetAbsOrigin(), self.radius ) ) do
		ability:DealDamage( caster, enemy, self.base_damage )
		enemy:AddNewModifier( caster, ability, "modifier_pugna_nether_ward_aura", {duration = self.debuff_duration} )
		ParticleManager:FireRopeParticle("particles/units/heroes/hero_pugna/pugna_ward_attack.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent, enemy)
		if enemy:IsConsideredHero() then enemy:EmitSound("Hero_Pugna.NetherWard.Target") end
	end
end

function modifier_pugna_nether_ward_thinker:OnDestroy()
	if IsServer() then
		self:GetCaster().netherwards[self:GetParent()] = nil
	end
end

function modifier_pugna_nether_ward_thinker:CheckState()
	return {[MODIFIER_STATE_ROOTED] = true,
			[MODIFIER_STATE_DISARMED] = true,
			[MODIFIER_STATE_SILENCED] = true,
			[MODIFIER_STATE_MAGIC_IMMUNE] = true}
end


function modifier_pugna_nether_ward_thinker:DeclareFunctions()
	local funcs = { MODIFIER_EVENT_ON_ATTACK_LANDED,
					MODIFIER_PROPERTY_HEALTHBAR_PIPS,
					MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
					MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
					MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
					MODIFIER_PROPERTY_DISABLE_HEALING }
	return funcs
end

function modifier_pugna_nether_ward_thinker:GetDisableHealing()
	return 1
end

function modifier_pugna_nether_ward_thinker:OnAttackLanded(params)
	if IsServer() then
		if params and params.target == self:GetParent() then
			local hp = params.target:GetHealth()
			local damage = TernaryOperator( 4, params.attacker:IsConsideredHero(), 1 )
			if hp <= damage then
				params.target:ForceKill( false )
			else
				params.target:SetHealth( params.target:GetHealth() - damage )
			end
		end
	end
end

function modifier_pugna_nether_ward_thinker:GetModifierHealthBarPips()
	return self.pips
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

function modifier_pugna_nether_ward_thinker:IsHidden()
	return true
end

function modifier_pugna_nether_ward_thinker:IsPurgable()
    return false
end