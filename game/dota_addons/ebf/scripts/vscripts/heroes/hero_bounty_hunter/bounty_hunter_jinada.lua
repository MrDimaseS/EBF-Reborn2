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
	
	self:DealDamage( caster, target, self:GetSpecialValueFor("bonus_damage") )
	if self:IsCooldownReady() or bForceGoldSteal then
		caster:AddGold( self:GetSpecialValueFor("gold_steal") )
	end
	if self:IsCooldownReady() and not bForceGoldSteal then
		self:SetCooldown()
	end
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

		if attacker == caster and ( ( ability:IsCooldownReady() and (self.autocast or self:GetAbility():GetAutoCastState()) )
									or self:GetSpecialValueFor("passive_damage") == 1) then
			ability:TriggerJinada(target, false)
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
