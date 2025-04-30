item_cloak_of_flames = class({})

function item_cloak_of_flames:GetIntrinsicModifierName()
	return "modifier_item_cloak_of_flames_passive"
end

modifier_item_cloak_of_flames_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_cloak_of_flames_passive", "items/item_cloak_of_flames.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_cloak_of_flames_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_cloak_of_flames_passive:OnRefresh()
	self.armor = self:GetSpecialValueFor("armor")
	self.magic_resistance = self:GetSpecialValueFor("magic_resistance")
	
	self.radius = self:GetSpecialValueFor("radius")
	self.duration = self:GetSpecialValueFor("duration")
end

function modifier_item_cloak_of_flames_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end

function modifier_item_cloak_of_flames_passive:GetModifierMagicalResistanceBonus()
	return self.magic_resistance
end

function modifier_item_cloak_of_flames_passive:GetModifierPhysicalArmorBonus()
	return self.armor
end

function modifier_item_cloak_of_flames_passive:GetModifierIncomingDamage_Percentage( params )
	if params.target ~= self:GetParent() then return end
	local ability = self:GetAbility()
	for _, enemy in ipairs( params.target:FindEnemyUnitsInRadius( params.target:GetAbsOrigin(), self.radius ) ) do
		local buff = enemy:FindModifierByNameAndCaster( "modifier_item_cloak_of_flames_burn", params.target )
		if buff then
			buff:ForceRefresh()
			buff:SetDuration( self.duration, true )
		else
			enemy:AddNewModifier( params.target, ability, "modifier_item_cloak_of_flames_burn", {duration = self.duration} )
		end
	end
	if (self._lastEruptionFX or 0) < GameRules:GetGameTime() then
		ParticleManager:FireParticle("particles/fire_ball_explosion.vpcf", PATTACH_POINT_FOLLOW, params.target, {[0] = "attach_hitloc"})
		self._lastEruptionFX = GameRules:GetGameTime() + 0.5
	end
end

modifier_item_cloak_of_flames_burn = class({})
LinkLuaModifier( "modifier_item_cloak_of_flames_burn", "items/item_cloak_of_flames.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_cloak_of_flames_burn:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:OnIntervalThink()
		self:StartIntervalThink( self.tick )
	end
end

function modifier_item_cloak_of_flames_burn:OnRefresh()
	self.damage_illusions = self:GetSpecialValueFor("damage_illusions")
	self.damage = self:GetSpecialValueFor("damage")
	self.tick = 0.5
end

function modifier_item_cloak_of_flames_burn:OnIntervalThink()
	local caster = self:GetCaster()
	local damage = TernaryOperator( self.damage, caster:IsRealHero(), self.damage_illusions ) * self.tick
	
	self:GetAbility():DealDamage( caster, self:GetParent(), damage, {damage_type = DAMAGE_TYPE_MAGICAL} )
end

function modifier_item_cloak_of_flames_burn:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_cloak_of_flames_burn:GetEffectName()
	return "particles/units/heroes/hero_batrider/batrider_slow_burn.vpcf"
end