wisp_sacrifice = class({})

function wisp_sacrifice:OnSpellStart()
	local caster = self:GetCaster()
	
	local duration = self:GetSpecialValueFor("invul_duration")
	
	local tether = caster:FindAbilityByName("wisp_tether")
	for _, ally in ipairs( caster:FindFriendlyUnitsInRadius( caster:GetAbsOrigin(), -1 ) ) do
		if ally ~= caster then
			local buff = ally:AddNewModifier( caster, tether, "modifier_wisp_tether_haste", {duration = duration} )
			local tetherFX = ParticleManager:CreateRopeParticle( "particles/units/heroes/hero_wisp/wisp_tether_agh.vpcf", PATTACH_POINT_FOLLOW, caster, ally )
			buff:AddEffect( tetherFX )
		end
	end
	caster:AddNewModifier( caster, self, "modifier_wisp_sacrifice_sacrifice", {duration = duration} )
end

modifier_wisp_sacrifice_sacrifice = class({})
LinkLuaModifier("modifier_wisp_sacrifice_sacrifice", "heroes/hero_wisp/wisp_sacrifice", LUA_MODIFIER_MOTION_NONE)

function modifier_wisp_sacrifice_sacrifice:OnCreated()
	self.sacrifice = 0.1 * (self:GetSpecialValueFor("sacrifice_hp") / 100 ) / self:GetRemainingTime()
	if IsServer() then
		local caster = self:GetCaster()
		EmitSoundOn( "Hero_Wisp.Relocate", caster ) 
		
		self.tether = caster:FindAbilityByName("wisp_tether")
		self.tetherBonus = 1 + self.tether:GetSpecialValueFor("tether_heal_amp") / 100
		
		self.timer = ParticleManager:CreateParticle( "particles/units/heroes/hero_wisp/wisp_relocate_timer.vpcf", PATTACH_OVERHEAD_FOLLOW, caster )
		ParticleManager:SetParticleControl( self.timer, 1, Vector( 0, math.ceil( self:GetRemainingTime() ), 0 ) )
		self:StartIntervalThink(0.1)
	end
end

function modifier_wisp_sacrifice_sacrifice:OnIntervalThink()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local damageTaken = ability:DealDamage( caster, caster, caster:GetMaxHealth() * self.sacrifice, {damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL } )
	
	local manaLoss = caster:GetMaxMana() * self.sacrifice
	caster:SpendMana( manaLoss, ability )
	
	
	ParticleManager:SetParticleControl( self.timer, 1, Vector( 0, math.ceil( self:GetRemainingTime() ), 0 ) )
	
	local overcharge = caster:FindModifierByName("modifier_wisp_overcharge")
	
	local allies = caster:FindFriendlyUnitsInRadius( caster:GetAbsOrigin(), -1 )
	for _, ally in ipairs( allies ) do
		if ally:HasModifier("modifier_wisp_tether_haste") then
			local healing = damageTaken * self.tetherBonus
			ally:HealEvent( healing, ability, caster )
			
			ally:GiveMana( manaLoss * self.tetherBonus )
			
			if overcharge and not ally:HasModifier("modifier_wisp_overcharge") then
				ally:AddNewModifier( caster, overcharge:GetAbility(), "modifier_wisp_overcharge", {duration = math.min( self:GetRemainingTime(), overcharge:GetRemainingTime() )} )
			end
		end
	end
end

function modifier_wisp_sacrifice_sacrifice:OnDestroy()
	if IsServer() then 
		local caster = self:GetCaster()
		EmitSoundOn( "Hero_Wisp.Return", caster ) 
		ParticleManager:ClearParticle( self.timer )
		
		caster:RemoveModifierByName("modifier_wisp_tether")
	end
end

function modifier_wisp_sacrifice_sacrifice:GetEffectName()
	return "particles/units/heroes/hero_wisp/wisp_sacrifice.vpcf"
end