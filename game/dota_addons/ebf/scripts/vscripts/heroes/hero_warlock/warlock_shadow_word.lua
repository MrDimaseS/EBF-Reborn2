warlock_shadow_word = class({})

function warlock_shadow_word:ShouldUseResources()
	return true
end

function warlock_shadow_word:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	if not target:IsSameTeam( caster ) and target:TriggerSpellAbsorb( self ) then return end
	
	EmitSoundOn( "Hero_Warlock.Incantations", caster )
	target:AddNewModifier( caster, self, "modifier_warlock_shadow_word_primary", { duration = self:GetSpecialValueFor("duration") })
	EmitSoundOn( TernaryOperator( "Hero_Warlock.ShadowWordCastGood", caster:IsSameTeam(target), "Hero_Warlock.ShadowWordCastBad"), target )
end

LinkLuaModifier("modifier_warlock_shadow_word_primary", "heroes/hero_warlock/warlock_shadow_word", LUA_MODIFIER_MOTION_NONE)
modifier_warlock_shadow_word_primary = class({})

function modifier_warlock_shadow_word_primary:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink( self.tick_interval )
		EmitSoundOn( "Hero_Warlock.ShadowWord", self:GetParent() )
	end
end

function modifier_warlock_shadow_word_primary:OnRefresh()
	self.isSameTeam = self:GetCaster():IsSameTeam( self:GetParent() )
	self.tick_interval = self:GetSpecialValueFor("tick_interval")
	self.damage = self:GetSpecialValueFor("damage") * self.tick_interval
	self.heal = self:GetSpecialValueFor("heal") * self.tick_interval
	self.spell_aoe = self:GetSpecialValueFor("spell_aoe")
	self.allied_armor_bonus = self:GetSpecialValueFor("allied_armor_bonus")
end

function modifier_warlock_shadow_word_primary:OnIntervalThink()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	for _, unit in ipairs( caster:FindAllUnitsInRadius( parent:GetAbsOrigin(), self.spell_aoe ) ) do
		if unit:IsSameTeam( caster ) then
			unit:HealEvent( self.heal, ability, caster )
			if self.allied_armor_bonus > 0 then
				unit:AddNewModifier( caster, ability, "modifier_warlock_shadow_word_chain_pact", { duration = self.tick_interval + 0.1 } )
			end
			ParticleManager:FireRopeParticle("particles/units/heroes/hero_warlock/warlock_shadow_word_heal.vpcf", PATTACH_POINT_FOLLOW, parent, unit )
		else
			ability:DealDamage( caster, unit, self.damage )
			ParticleManager:FireRopeParticle("particles/units/heroes/hero_warlock/warlock_shadow_word_damage.vpcf", PATTACH_POINT_FOLLOW, parent, unit )
		end
	end
end

function modifier_warlock_shadow_word_primary:OnDestroy()
	if IsServer() then
		StopSoundOn( "Hero_Warlock.ShadowWord", self:GetParent() )
		self:GetCaster():SpawnImp( self:GetParent():GetAbsOrigin() + RandomVector( 300 ) )
	end
end

function modifier_warlock_shadow_word_primary:GetEffectName()
	if self:GetCaster():IsSameTeam( self:GetParent() ) then
		return "particles/units/heroes/hero_warlock/warlock_shadow_word_buff.vpcf"
	else
		return "particles/units/heroes/hero_warlock/warlock_shadow_word_debuff.vpcf"
	end
end

LinkLuaModifier("modifier_warlock_shadow_word_chain_pact", "heroes/hero_warlock/warlock_shadow_word", LUA_MODIFIER_MOTION_NONE)
modifier_warlock_shadow_word_chain_pact = class({})

function modifier_warlock_shadow_word_chain_pact:OnCreated()
	self:OnRefresh()
end
function modifier_warlock_shadow_word_chain_pact:OnRefresh()
	if IsClient() then self:SetDuration( -1, false ) end
	self.allied_armor_bonus = self:GetSpecialValueFor("allied_armor_bonus")
end

function modifier_warlock_shadow_word_chain_pact:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end

function modifier_warlock_shadow_word_chain_pact:GetModifierPhysicalArmorBonus()
	return self.allied_armor_bonus 
end