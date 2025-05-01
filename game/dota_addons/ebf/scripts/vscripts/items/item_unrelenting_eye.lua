item_vindicators_axe = class({})

function item_vindicators_axe:GetIntrinsicModifierName()
	return "modifier_item_vindicators_axe_passive"
end

function item_vindicators_axe:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	if target.IsStanding and target:IsStanding() then
		local cd = self:GetSpecialValueFor("alternative_cooldown")
		tree:CutDown()
		self:EndCooldown()
		self:SetCooldown( cd )
	else
		local damage = target:GetMaxHealth() * self:GetSpecialValueFor("creep_damage_pct") / 100
		self:DealDamage( caster, target, damage, {damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_HPLOSS} )
	end
end

modifier_item_vindicators_axe_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_vindicators_axe_passive", "items/item_vindicators_axe.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_vindicators_axe_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_vindicators_axe_passive:OnRefresh()
	self.bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
	
	self.ruthless_cdr = self:GetSpecialValueFor("ruthless_cdr")
	self.ruthless_cdr_creep = self:GetSpecialValueFor("ruthless_cdr_creep")
end

function modifier_item_vindicators_axe_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_EVENT_ON_DEATH }
end

function modifier_item_vindicators_axe_passive:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

function modifier_item_vindicators_axe_passive:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_item_vindicators_axe_passive:OnDeath( params )
	if params.attacker ~= self:GetParent() then return end
	local activeAbilities = {}
	for i = 0, params.attacker:GetAbilityCount() do
		local ability = params.attacker:GetAbilityByIndex( i )
		if ability and ability:GetCooldownTimeRemaining() > 0 then
			table.insert( activeAbilities, ability )
		end
	end
	local randomAbility = activeAbilities[RandomInt(1, #activeAbilities)]
	if randomAbility then
		randomAbility:ModifyCooldown( -TernaryOperator( self.ruthless_cdr, params.unit:IsConsideredHero(), self.ruthless_cdr_creep ) )
	end
end