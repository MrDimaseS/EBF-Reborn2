abaddon_frostmourne = class({})

function abaddon_frostmourne:GetIntrinsicModifierName()
	return "modifier_abaddon_curse_passive"
end

LinkLuaModifier( "modifier_abaddon_curse_passive", "heroes/hero_abaddon/abaddon_frostmourne", LUA_MODIFIER_MOTION_NONE )
modifier_abaddon_curse_passive = class({})

function modifier_abaddon_curse_passive:OnCreated()
	self.duration = self:GetSpecialValueFor("slow_duration")
end

function modifier_abaddon_curse_passive:OnRefresh()
	self.duration = self:GetSpecialValueFor("slow_duration")
end

function modifier_abaddon_curse_passive:IsHidden()
	return true
end

function modifier_abaddon_curse_passive:DeclareFunctions()
	funcs = {
				MODIFIER_EVENT_ON_TAKEDAMAGE
			}
	return funcs
end

function modifier_abaddon_curse_passive:OnTakeDamage(params)
	if IsServer() then
		if params.unit == self:GetParent() then return end
		if params.attacker ~= self:GetParent() then return end
		if params.attacker:PassivesDisabled() then return end
		if params.unit:HasModifier("modifier_abaddon_curse_curse") then return end
		if ( params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK and not params.inflictor ) 
		or ( params.attacker:HasShard() and params.inflictor and params.attacker:HasAbility( params.inflictor:GetName() ) and not HasBit( params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION ) ) then
			params.unit:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_abaddon_curse_debuff", {duration = self.duration} )
		end
	end
end

LinkLuaModifier( "modifier_abaddon_curse_buff", "heroes/hero_abaddon/abaddon_frostmourne", LUA_MODIFIER_MOTION_NONE )
modifier_abaddon_curse_buff = class({})

function modifier_abaddon_curse_buff:OnCreated()
	self.curse_attack_speed = self:GetSpecialValueFor("curse_attack_speed")
end

function modifier_abaddon_curse_buff:DeclareFunctions()
	funcs = {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT}
	return funcs
end

function modifier_abaddon_curse_buff:GetModifierAttackSpeedBonus_Constant()
	return self.curse_attack_speed
end

function modifier_abaddon_curse_buff:GetEffectName()
	return "particles/units/heroes/hero_abaddon/abaddon_frost_buff.vpcf"
end

LinkLuaModifier( "modifier_abaddon_curse_debuff", "heroes/hero_abaddon/abaddon_frostmourne", LUA_MODIFIER_MOTION_NONE )
modifier_abaddon_curse_debuff = class({})

function modifier_abaddon_curse_debuff:OnCreated()
	self.movement_speed = -self:GetSpecialValueFor("movement_speed")
	self.hit_count = self:GetSpecialValueFor("hit_count")
	if IsServer() then
		self:IncrementStackCount()
		self.overheadFX = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/abaddon_curse_counter_stack.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent() )
		ParticleManager:SetParticleControl( self.overheadFX, 1, Vector(self:GetStackCount(), self:GetStackCount(), self:GetStackCount() ) )
		self:AddOverHeadEffect( self.overheadFX )
	end
end

function modifier_abaddon_curse_debuff:OnRefresh()
	self.movement_speed = -self:GetSpecialValueFor("movement_speed")
	self.hit_count = self:GetSpecialValueFor("hit_count")
	self.curse_duration = self:GetSpecialValueFor("curse_duration")
	if IsServer() then
		self:IncrementStackCount()
		ParticleManager:SetParticleControl( self.overheadFX, 1, Vector(self:GetStackCount(), self:GetStackCount(), self:GetStackCount() ) )
		if self:GetStackCount() >= self.hit_count then
			self:Destroy()
			
			local caster =  self:GetCaster()
			local parent = self:GetParent()
			local ability =  self:GetAbility()
			parent:AddNewModifier( caster, ability, "modifier_abaddon_curse_curse", {duration = self.curse_duration})
			
			if caster:HasShard() then
				caster:PerformGenericAttack(parent, true)
			end
		end
	end
end

function modifier_abaddon_curse_debuff:DeclareFunctions()
	funcs = {
				MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			}
	return funcs
end

function modifier_abaddon_curse_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.movement_speed
end

function modifier_abaddon_curse_debuff:GetEffectName()
	return "particles/units/heroes/hero_abaddon/abaddon_frost_slow.vpcf"
end

LinkLuaModifier( "modifier_abaddon_curse_curse", "heroes/hero_abaddon/abaddon_frostmourne", LUA_MODIFIER_MOTION_NONE )
modifier_abaddon_curse_curse = class({})

function modifier_abaddon_curse_curse:OnCreated()
	self.curse_slow = -self:GetSpecialValueFor("curse_slow")
	self.curse_dps = self:GetSpecialValueFor("curse_dps")
	self.tick = 0.5
	
	if IsServer() then
		self:StartIntervalThink( self.tick )
	end
end

function modifier_abaddon_curse_curse:OnIntervalThink()
	self:GetAbility():DealDamage( self:GetCaster(), self:GetParent(), self.curse_dps * self.tick )
end

function modifier_abaddon_curse_curse:DeclareFunctions()
	funcs = {
				MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
				MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
				MODIFIER_PROPERTY_DISABLE_HEALING,
				MODIFIER_EVENT_ON_ATTACK_START 
			}
	return funcs
end

function modifier_abaddon_curse_curse:GetModifierMoveSpeedBonus_Percentage()
	return self.curse_slow
end

function modifier_abaddon_curse_curse:GetModifierPercentageCooldown()
	return self.curse_slow
end

function modifier_abaddon_curse_curse:GetDisableHealing()
	return 1
end

function modifier_abaddon_curse_curse:OnAttackStart( params )
	if not params.attacker:IsSameTeam( params.target ) and params.target == self:GetParent() then
		params.attacker:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_abaddon_curse_buff", {duration = params.attacker:GetSecondsPerAttack() + 0.25})
	end
end

function modifier_abaddon_curse_curse:GetEffectName()
	return "particles/units/heroes/hero_abaddon/abaddon_curse_frostmourne_debuff.vpcf"
end