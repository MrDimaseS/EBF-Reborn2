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
	self.barrier_block = 0
	self:SetHasCustomTransmitterData(true)
	self:OnRefresh()
end

function modifier_bloodseeker_bloodrage_buff:OnRefresh()
	self.attack_speed = TernaryOperator( self:GetSpecialValueFor("attack_speed"), self:GetCaster() == self:GetParent(), self:GetSpecialValueFor("allied_attack_speed") )
	self.spell_amp = TernaryOperator( self:GetSpecialValueFor("spell_amp"), self:GetCaster() == self:GetParent(), self:GetSpecialValueFor("allied_spell_amp") )
	
	self.damage_pct = self:GetSpecialValueFor("damage_pct") / 100
	
	self.tick_interval = 0.33
	self.ticks_per_second = 1/self.tick_interval
	
	self.bonus_pure_dmg = self:GetSpecialValueFor("bonus_pure_dmg")
	self.solo_bonus = 1 + self:GetSpecialValueFor("solo_bonus") / 100
	self.solo_range = self:GetSpecialValueFor("solo_range")
	self.aoe_bonus = self:GetSpecialValueFor("aoe_bonus")
	self:GetParent()._aoeModifiersList = self:GetParent()._aoeModifiersList or {}
	self:GetParent()._aoeModifiersList[self] = true
	
	if IsServer() then
		self:StartIntervalThink( 0.33 )
		self:SendBuffRefreshToClients()
	end
end

function modifier_bloodseeker_bloodrage_buff:OnIntervalThink()
	local parent = self:GetParent()
	local caster = self:GetCaster()
	
	if parent:GetHealth() > 1 then
		parent:ModifyHealth( parent:GetHealth() - (0.33 * parent:GetMaxHealth() * self.damage_pct), self:GetAbility(), false, DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY + DOTA_DAMAGE_FLAG_BYPASSES_ALL_BLOCK + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL )
	end
	if self.solo_bonus > 1 and parent == caster then
		self.enemies = #parent:FindEnemyUnitsInRadius( parent:GetAbsOrigin(), self.solo_range )
		self:SetStackCount( self.enemies )
	end
end

function modifier_bloodseeker_bloodrage_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_AOE_BONUS_CONSTANT_STACKING,
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
	return self.attack_speed * TernaryOperator( self.solo_bonus, self:GetStackCount() < 2, 1 )
end

function modifier_bloodseeker_bloodrage_buff:OnAttackLanded( params )
	if params.attacker ~= self:GetParent() then return end
	if params.target:IsSameTeam( params.attacker ) then return end
	self:GetAbility():DealDamage( params.attacker, params.target, self.bonus_pure_dmg * TernaryOperator( self.solo_bonus, self:GetStackCount() < 2, 1 ), {damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION} )
end

function modifier_bloodseeker_bloodrage_buff:GetModifierSpellAmplify_Percentage()
	return self.spell_amp * TernaryOperator( self.solo_bonus, self:GetStackCount() < 2, 1 )
end

function modifier_bloodseeker_bloodrage_buff:GetModifierAoEBonusConstantStacking( params )
	return self.aoe_bonus
end

function modifier_bloodseeker_bloodrage_buff:AddCustomTransmitterData()
	return {barrier_block = self.barrier_block}
end

function modifier_bloodseeker_bloodrage_buff:HandleCustomTransmitterData(data)
	self.barrier_block = data.barrier_block
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