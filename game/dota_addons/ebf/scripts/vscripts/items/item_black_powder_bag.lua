item_black_powder_bag = class({})

function item_black_powder_bag:GetIntrinsicModifierName()
	return "modifier_item_black_powder_bag_passive"
end

function item_black_powder_bag:ShouldUseResources()
	return true
end

modifier_item_black_powder_bag_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_black_powder_bag_passive", "items/item_black_powder_bag.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_black_powder_bag_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_black_powder_bag_passive:OnRefresh()
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
	
	self.radius = self:GetSpecialValueFor("radius")
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.blind_duration = self:GetSpecialValueFor("blind_duration")
end

function modifier_item_black_powder_bag_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_EVENT_ON_ATTACK }
end

function modifier_item_black_powder_bag_passive:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_item_black_powder_bag_passive:OnAttack( params )
	local parent = self:GetParent()
	if params.attacker:IsSameTeam( parent ) then return end
	if CalculateDistance( params.attacker, parent ) > self.radius then return end
	local ability = self:GetAbility()
	if not ability:IsCooldownReady() then return end
	for _, enemy in ipairs( parent:FindEnemyUnitsInRadius( parent:GetAbsOrigin(), self.radius ) ) do
		enemy:AddNewModifier( parent, ability, "modifier_item_black_powder_bag_debuff", {duration = self.blind_duration} )
		ability:DealDamage( parent, enemy, self.bonus_damage, {damage_type = DAMAGE_TYPE_MAGICAL} )
	end
	ParticleManager:FireParticle("particles/items3_fx/black_powder_bag.vpcf", PATTACH_POINT_FOLLOW, parent )
	EmitSoundOn("Item.BlackPowder", parent )
	ability:SetCooldown()
end

modifier_item_black_powder_bag_debuff = class({})
LinkLuaModifier( "modifier_item_black_powder_bag_debuff", "items/item_black_powder_bag.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_black_powder_bag_debuff:OnCreated()
	self:OnRefresh()
end

function modifier_item_black_powder_bag_debuff:OnRefresh()
	self.blind_pct = self:GetSpecialValueFor("blind_pct")
end

function modifier_item_black_powder_bag_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_MISS_PERCENTAGE}
end

function modifier_item_black_powder_bag_passive:GetModifierMiss_Percentage()
	return self.blind_pct
end

function modifier_item_black_powder_bag_debuff:GetEffectName()
	return "particles/items3_fx/black_powder_blind_debuff.vpcf"
end