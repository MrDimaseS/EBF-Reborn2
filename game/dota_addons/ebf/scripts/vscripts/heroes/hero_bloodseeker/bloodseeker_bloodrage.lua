bloodseeker_bloodrage = class({})

function bloodseeker_bloodrage:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	local duration = TernaryOperator( -1, target == caster, self:GetSpecialValueFor("duration") )
	if caster == target and caster:HasModifier("modifier_bloodseeker_bloodrage_buff") then
		caster:RemoveModifierByName("modifier_bloodseeker_bloodrage_buff")
		self:EndCooldown()
	else
		target:AddNewModifier( target, self, "modifier_bloodseeker_bloodrage_buff", { duration = duration} )
	end
	EmitSoundOn( "hero_bloodseeker.bloodRage", target )
end

modifier_bloodseeker_bloodrage_buff = class({})
LinkLuaModifier( "modifier_bloodseeker_bloodrage_buff", "heroes/hero_bloodseeker/bloodseeker_bloodrage", LUA_MODIFIER_MOTION_NONE )

function modifier_bloodseeker_bloodrage_buff:OnCreated()
	self:OnRefresh()
end

function modifier_bloodseeker_bloodrage_buff:OnRefresh()
	self.attack_speed = TernaryOperator( self:GetSpecialValueFor("attack_speed"), self:GetCaster() == self:GetParent(), self:GetSpecialValueFor("allied_attack_speed") )
	self.spell_amp = TernaryOperator( self:GetSpecialValueFor("spell_amp"), self:GetCaster() == self:GetParent(), self:GetSpecialValueFor("allied_spell_amp") )
	
	self.damage_pct = self:GetSpecialValueFor("damage_pct") / 100
	
	self.shard_max_health_dmg = TernaryOperator( self:GetSpecialValueFor("shard_max_health_dmg"), self:GetCaster() == self:GetParent() and self:GetCaster():HasShard(), 0 )
	if IsServer() then
		self:StartIntervalThink( 0.1 )
	end
end

function modifier_bloodseeker_bloodrage_buff:OnIntervalThink()
	local parent = self:GetParent()
	self:GetAbility():DealDamage( self:GetCaster(), parent, 0.1 * parent:GetMaxHealth() * self.damage_pct, {damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY + DOTA_DAMAGE_FLAG_BYPASSES_ALL_BLOCK + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL} )
end

function modifier_bloodseeker_bloodrage_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_bloodseeker_bloodrage_buff:GetModifierMoveSpeedBonus_Percentage()
	if self:GetCaster():GetHealthPercent() < self.min_bonus_pct then
		if not self.NFX and IsServer() then
			self.NFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_bloodseeker/bloodseeker_bloodrage_owner.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster() )
		end
		return self.bonus_movement_speed * ( math.max( self.max_bonus_pct, self:GetCaster():GetHealthPercent() ) - self.min_bonus_pct) / (self.max_bonus_pct - self.min_bonus_pct)
	elseif self.NFX and IsServer() then
		ParticleManager:ClearParticle( self.NFX )
		self.NFX = nil
	end
end

function modifier_bloodseeker_bloodrage_buff:GetModifierAttackSpeedBonus_Constant()
	return self.attack_speed
end

function modifier_bloodseeker_bloodrage_buff:GetModifierSpellAmplify_Percentage()
	return self.spell_amp
end

function modifier_bloodseeker_bloodrage_buff:OnAttackLanded( params )
	if params.attacker == self:GetParent() and self.shard_max_health_dmg > 0 then
		local ability = self:GetAbility()
		ability:DealDamage( params.attacker, params.target, self.shard_max_health_dmg, {damage_type = DAMAGE_TYPE_PURE} )
		params.attacker:HealEvent( self.shard_max_health_dmg, ability, params.attacker )
	end
end

function modifier_bloodseeker_bloodrage_buff:GetEffectName()
	return "particles/units/heroes/hero_bloodseeker/bloodseeker_bloodrage.vpcf"
end

function modifier_bloodseeker_bloodrage_buff:GetStatusEffectName()
	return "particles/status_fx/status_effect_bloodrage.vpcf"
end

function modifier_bloodseeker_bloodrage_buff:StatusEffectPriority()
	return 1
end