bounty_hunter_jinada = class({})

function bounty_hunter_jinada:IsStealable()
	return false
end

function bounty_hunter_jinada:IsHiddenWhenStolen()
	return false
end

function bounty_hunter_jinada:ShouldUseResources()
	return true
end

function bounty_hunter_jinada:GetCastRange( position, target )
	return self:GetCaster():GetAttackRange() - self:GetCaster():GetCastRangeBonus()
end

function bounty_hunter_jinada:GetIntrinsicModifierName()
	return "modifier_bounty_hunter_jinada_handler"
end

function bounty_hunter_jinada:TriggerJinada(target, bForceGoldSteal )
	local caster = self:GetCaster()
	EmitSoundOn("Hero_BountyHunter.Jinada", target)

	local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_bounty_hunter/bounty_hunter_jinda_slow.vpcf", PATTACH_POINT, caster)
				ParticleManager:SetParticleControl(nfx, 0, target:GetAbsOrigin())
				ParticleManager:ReleaseParticleIndex(nfx)
	
	self:DealDamage( caster, target, self:GetSpecialValueFor("bonus_damage"), {damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_ATTACK_MODIFIER } )
	if not target._jinadaTriggered then
		caster:AddGold( TernaryOperator( self:GetSpecialValueFor("gold_steal_hero"), target:IsConsideredHero(), self:GetSpecialValueFor("gold_steal") ) )
		target._jinadaTriggered = true
	end
	
	local ccDuration = self:GetSpecialValueFor("cc_duration")
	if ccDuration > 0 then
		local ccs = self:GetSpecialValueFor("random_cc")
		local ccTable = {"silence", "disarm", "break"}
		for i = 1, ccs do
			local selectedCCIndex = RandomInt( 1, #ccTable )
			local selectedCC = ccTable[selectedCCIndex]
			table.remove( ccTable, selectedCCIndex )
			if selectedCC == "silence" then
				self:Silence( target, ccDuration )
			elseif selectedCC == "disarm" then
				self:Disarm( target, ccDuration )
			elseif selectedCC == "break" then
				self:Break( target, ccDuration )
			end
		end
	end
	local bleedDuration = self:GetSpecialValueFor("bleed_duration")
	if bleedDuration > 0 then
		target:AddNewModifier( caster, self, "modifier_bounty_hunter_jinada_specialist", {duration = bleedDuration} )
	end
end
modifier_bounty_hunter_jinada_specialist = class({})
LinkLuaModifier("modifier_bounty_hunter_jinada_specialist", "heroes/hero_bounty_hunter/bounty_hunter_jinada", LUA_MODIFIER_MOTION_NONE)

function modifier_bounty_hunter_jinada_specialist:OnCreated()
	if IsServer() then
		self:OnRefresh()
		self:StartIntervalThink( self.tick )
	end
end

function modifier_bounty_hunter_jinada_specialist:OnRefresh()
	self.bleed_max_hp_loss = self:GetSpecialValueFor("bleed_max_hp_loss") * self:GetParent():GetMaxHealthDamageResistance() / 100
	self.tick = 0.5
end

function modifier_bounty_hunter_jinada_specialist:OnIntervalThink()
	local parent = self:GetParent()
	self:GetAbility():DealDamage( self:GetCaster(), parent, self.bleed_max_hp_loss * parent:GetMaxHealth() * self.tick, {damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION } )
end

modifier_bounty_hunter_jinada_handler = class({})
LinkLuaModifier("modifier_bounty_hunter_jinada_handler", "heroes/hero_bounty_hunter/bounty_hunter_jinada", LUA_MODIFIER_MOTION_NONE)

function modifier_bounty_hunter_jinada_handler:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED, 
			MODIFIER_EVENT_ON_ORDER}
end

function modifier_bounty_hunter_jinada_handler:OnAttackLanded(params)
	if IsServer() then
		local caster = self:GetCaster()
		local attacker = params.attacker
		local target = params.target
		local ability = self:GetAbility()

		if attacker == caster and ( ability:IsCooldownReady() and (self.autocast or self:GetAbility():GetAutoCastState()) ) then
			ability:TriggerJinada(target, false)
			local noCD = target:HasModifier("modifier_bounty_hunter_track_debuff_mark") and self:GetSpecialValueFor("track_jinada_no_cd") == 1
			if not noCD then
				ability:SetCooldown()
			end
		end
	end
end

function modifier_bounty_hunter_jinada_handler:OnOrder(params)
	if params.unit == self:GetParent() then
		if params.ability == self:GetAbility() and params.order_type == DOTA_UNIT_ORDER_CAST_TARGET then
			self.autocast = true
		else
			self.autocast = false
		end
	end
end

function modifier_bounty_hunter_jinada_handler:IsHidden() return true end
