doom_bringer_infernal_blade = class({})

function doom_bringer_infernal_blade:GetIntrinsicModifierName()
	return "modifier_doom_bringer_infernal_blade_autocast"
end

function doom_bringer_infernal_blade:IsStealable()
	return false
end

function doom_bringer_infernal_blade:ShouldUseResources()
	return true
end

function doom_bringer_infernal_blade:GetAOERadius()
	return self:GetSpecialValueFor("shard_radius")
end

function doom_bringer_infernal_blade:GetCastRange( position, target )
	return self:GetCaster():GetAttackRange() - self:GetCaster():GetCastRangeBonus()
end

function doom_bringer_infernal_blade:StartInfernalBlade()
	-- ParticleManager:FireParticle("particles/units/heroes/hero_doom_bringer/doom_infernal_blade.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster())
	EmitSoundOn("Hero_DoomBringer.InfernalBlade.PreAttack", self:GetCaster())
end

function doom_bringer_infernal_blade:InfernalBlade(target)
	local caster = self:GetCaster()
	
	if not target:IsConsideredHero() then
		-- instakill, as per Lvl? Pain.
		self:DealDamage(caster, target, target:GetMaxHealth() + 1, { damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS })
	else
		target:AddNewModifier(caster, self, "modifier_doom_bringer_infernal_blade_debuff", {duration = self:GetSpecialValueFor("burn_duration")})
		self:Stun(target, self:GetSpecialValueFor("ministun_duration"))
	end

	ParticleManager:FireParticle("particles/units/heroes/hero_doom_bringer/doom_infernal_blade_impact.vpcf", PATTACH_POINT_FOLLOW, enemy)
	if caster:HasShard() then
		local startPos = target:GetAbsOrigin()
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( startPos, self:GetSpecialValueFor("shard_radius") ) ) do
			enemy:AddNewModifier(caster, self, "modifier_doom_bringer_infernal_blade_debuff", {duration = self:GetSpecialValueFor("burn_duration")})
			self:Stun( enemy, self:GetSpecialValueFor("ministun_duration") )
		end
		ParticleManager:FireParticle("particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf", PATTACH_ABSORIGIN, caster, {[0] = startPos} )
	end
	EmitSoundOn("Hero_DoomBringer.InfernalBlade.Target", target)
	self:SetCooldown(  )
	self:PayManaCost(  )
end

modifier_doom_bringer_infernal_blade_autocast = class({})
LinkLuaModifier("modifier_doom_bringer_infernal_blade_autocast", "heroes/hero_doom/doom_bringer_infernal_blade", LUA_MODIFIER_MOTION_NONE)

function modifier_doom_bringer_infernal_blade_autocast:IsHidden()
	return true
end

function modifier_doom_bringer_infernal_blade_autocast:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK, 
			MODIFIER_EVENT_ON_ORDER, 
			MODIFIER_EVENT_ON_ATTACK_START, 
			MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS}
end

function modifier_doom_bringer_infernal_blade_autocast:OnAttackStart(params)
	if params.attacker == self:GetParent() and params.target and (( self:GetAbility():GetAutoCastState() and self:GetAbility():IsFullyCastable() ) or self.autocast) then
		self:GetAbility():StartInfernalBlade()
	end
end

function modifier_doom_bringer_infernal_blade_autocast:OnOrder(params)
	if params.unit == self:GetParent() then
		if params.ability == self:GetAbility() and params.order_type == DOTA_UNIT_ORDER_CAST_TARGET then
			self.autocast = true
		else
			self.autocast = false
		end
	end
end

function modifier_doom_bringer_infernal_blade_autocast:OnAttack(params)
	if params.attacker == self:GetParent() and params.target and (( self:GetAbility():GetAutoCastState() and self:GetAbility():IsFullyCastable() ) or self.autocast) then
		self:GetAbility():InfernalBlade(params.target)
		self.autocast = false
	end
end
	
function modifier_doom_bringer_infernal_blade_autocast:GetActivityTranslationModifiers(params)
	if IsServer() and (self:GetAbility():IsCooldownReady() and self:GetAbility():GetAutoCastState()) or self.autocast then
		return "infernal_blade"
	end
end

modifier_doom_bringer_infernal_blade_debuff = class({})
LinkLuaModifier("modifier_doom_bringer_infernal_blade_debuff", "heroes/hero_doom/doom_bringer_infernal_blade", LUA_MODIFIER_MOTION_NONE)

function modifier_doom_bringer_infernal_blade_debuff:GetEffectName()
	return "particles/units/heroes/hero_doom_bringer/doom_infernal_blade_debuff.vpcf"
end
function modifier_doom_bringer_infernal_blade_debuff:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink(1)
	end
end
function modifier_doom_bringer_infernal_blade_debuff:OnRefresh()
	self.damage = self:GetSpecialValueFor("burn_damage_pct") / 100
	self.baseDamage = self:GetSpecialValueFor("burn_damage")
	self.life_leech = self:GetSpecialValueFor("life_leech") / 100
	if IsServer() then
		self:OnIntervalThink()
	end
end
function modifier_doom_bringer_infernal_blade_debuff:OnIntervalThink()
	local parent = self:GetParent()
	self:GetAbility():DealDamage(self:GetCaster(), parent, parent:GetMaxHealth() * self.damage * parent:GetMaxHealthDamageResistance() + self.baseDamage * (1 + self:GetCaster():GetSpellAmplification( false )), {damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION}, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE)
end
function modifier_doom_bringer_infernal_blade_debuff:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}
end
function modifier_doom_bringer_infernal_blade_debuff:OnTakeDamage(params)
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if params.attacker:IsSameTeam(caster) and params.unit == self:GetParent() then
		local heal = params.damage * self.life_leech
		params.attacker:HealEvent(heal, ability, caster, false)
	end
end