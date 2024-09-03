axe_coat_of_blood = class({})

function axe_coat_of_blood:ShouldUseResources()
	return true
end

function axe_coat_of_blood:GetIntrinsicModifierName()
	return "modifier_axe_coat_of_blood_handler"
end

modifier_axe_coat_of_blood_handler = class({})
LinkLuaModifier( "modifier_axe_coat_of_blood_handler", "heroes/hero_axe/axe_coat_of_blood", LUA_MODIFIER_MOTION_NONE )

function modifier_axe_coat_of_blood_handler:OnCreated()
	self:OnRefresh()
end

function modifier_axe_coat_of_blood_handler:OnRefresh()
	self.armor_per_hero = self:GetSpecialValueFor("armor_per_hero")
	self.atk_bonus_per_hero = self:GetSpecialValueFor("atk_bonus_per_hero")
	self.spell_amp_per_hero = self:GetSpecialValueFor("spell_amp_per_hero")
	self.duration = self:GetSpecialValueFor("duration")
	self.multiplier_during_berserkers_call = self:GetSpecialValueFor("multiplier_during_berserkers_call")
end

function modifier_axe_coat_of_blood_handler:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
	}
	return funcs
end

function modifier_axe_coat_of_blood_handler:OnDeath( params )
	if IsServer() then
		if params.unit:HasModifier("modifier_axe_culling_blade_grace_period") then
			if params.unit:IsConsideredHero() then
				self:IncrementStackCount()
			end
		end
	end
end

function modifier_axe_coat_of_blood_handler:OnTakeDamage( params )
	if IsServer() then
		if params.damage <= 0 then return end
		if ( params.attacker == self:GetCaster() and ( not params.inflictor or ( params.inflictor and params.attacker:HasAbility( params.inflictor:GetAbilityName() ) ) ) )
		or params.unit == self:GetCaster() then
			local unitToCheck = TernaryOperator( params.unit, params.attacker == self:GetCaster(), params.attacker )
			self:GetParent():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_axe_coat_of_blood_buff", {duration = self.duration, hero = #unitToCheck:IsConsideredHero(), stacks = 1 } )
		end
	end
end

function modifier_axe_coat_of_blood_handler:GetModifierPhysicalArmorBonus( params )
	return ( self.armor_per_hero * self:GetStackCount() ) * TernaryOperator( self.multiplier_during_berserkers_call, self:GetParent():HasModifier("modifier_axe_berserkers_call_aura"), 1 )
end

function modifier_axe_coat_of_blood_handler:GetModifierTotalDamageOutgoing_Percentage( params )
	return ( self.atk_bonus_per_hero * self:GetStackCount() ) * TernaryOperator( self.multiplier_during_berserkers_call, self:GetParent():HasModifier("modifier_axe_berserkers_call_aura"), 1 )
end

function modifier_axe_coat_of_blood_handler:GetModifierSpellAmplify_Percentage( params )
	return ( self.spell_amp_per_hero * self:GetStackCount() ) * TernaryOperator( self.multiplier_during_berserkers_call, self:GetParent():HasModifier("modifier_axe_berserkers_call_aura"), 1 )
end

function modifier_axe_coat_of_blood_handler:IsHidden()
	return self:GetStackCount() <= 0
end

function modifier_axe_coat_of_blood_handler:IsPurgable()
	return false
end

function modifier_axe_coat_of_blood_handler:IsPermanent()
	return true
end

function modifier_axe_coat_of_blood_handler:DestroyOnExpire()
	return false
end

modifier_axe_coat_of_blood_buff = class({})
LinkLuaModifier( "modifier_axe_coat_of_blood_buff", "heroes/hero_axe/axe_coat_of_blood", LUA_MODIFIER_MOTION_NONE )

function modifier_axe_coat_of_blood_buff:OnCreated(kv)
	if IsServer() then 
		self.heroStacks = {}
		self.heroStackCount = self.heroStackCount or 0
		self.creepStacks = {}
		self.creepStackCount = self.heroStackCount or 0
		self:StartIntervalThink(0.1)
		self:SetHasCustomTransmitterData(true)
	end
	
	self:OnRefresh(kv)
end

function modifier_axe_coat_of_blood_buff:OnRefresh(kv)
	self.armor_per_hero = self:GetSpecialValueFor("armor_per_hero")
	self.atk_bonus_per_hero = self:GetSpecialValueFor("atk_bonus_per_hero")
	self.spell_amp_per_hero = self:GetSpecialValueFor("spell_amp_per_hero")
	self.armor_per_creep = self:GetSpecialValueFor("armor_per_creep")
	self.atk_bonus_per_creep = self:GetSpecialValueFor("atk_bonus_per_creep")
	self.spell_amp_per_creep = self:GetSpecialValueFor("spell_amp_per_creep")
	self.duration = self:GetSpecialValueFor("duration")
	self.multiplier_during_berserkers_call = self:GetSpecialValueFor("multiplier_during_berserkers_call")
	
	if not IsServer() then return end
	if kv then
		if tonumber(kv.hero) == 1 then
			for i = 1, kv.stacks or 1 do
				table.insert( self.heroStacks, GameRules:GetGameTime() + self:GetRemainingTime() )
			end
		else
			for i = 1, kv.stacks or 1 do
				table.insert( self.creepStacks, GameRules:GetGameTime() + self:GetRemainingTime() )
			end
		end
	end
	self.heroStackCount = #self.heroStacks
	self.creepStackCount = #self.creepStacks
	self:SetStackCount( self.heroStackCount + self.creepStackCount )
end

function modifier_axe_coat_of_blood_buff:OnIntervalThink( )
	while self.heroStacks[1] and self.heroStacks[1] <= GameRules:GetGameTime() do
		table.remove( self.heroStacks, 1 )
		self.heroStackCount = #self.heroStacks
		stackRemoved = true
	end
	while self.creepStacks[1] and  self.creepStacks[1] <= GameRules:GetGameTime() do
		table.remove( self.creepStacks, 1 )
		self.creepStackCount = #self.creepStacks
		stackRemoved = true
	end
	if stackRemoved then
		self:SetStackCount( self.heroStackCount + self.creepStackCount )
	end
	if self:GetDuration() <= 0 then
		self:SetDuration( -1, true )
	end
end

function modifier_axe_coat_of_blood_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
	}
	return funcs
end

function modifier_axe_coat_of_blood_buff:AddCustomTransmitterData()
	return {heroStackCount = tonumber(self.heroStackCount),
			creepStackCount = tonumber(self.creepStackCount)}
end

function modifier_axe_coat_of_blood_buff:HandleCustomTransmitterData(data)
	self.heroStackCount = tonumber(data.heroStackCount)
	self.creepStackCount = tonumber(data.creepStackCount)
end


function modifier_axe_coat_of_blood_buff:GetModifierPhysicalArmorBonus( params )
	return ( self.armor_per_hero * self.heroStackCount + self.armor_per_creep * self.creepStackCount ) * TernaryOperator( self.multiplier_during_berserkers_call, self:GetParent():HasModifier("modifier_axe_berserkers_call_aura"), 1 )
end

function modifier_axe_coat_of_blood_buff:GetModifierDamageOutgoing_Percentage( params )
	return ( self.atk_bonus_per_hero * self.heroStackCount + self.atk_bonus_per_creep * self.creepStackCount ) * TernaryOperator( self.multiplier_during_berserkers_call, self:GetParent():HasModifier("modifier_axe_berserkers_call_aura"), 1 )
end

function modifier_axe_coat_of_blood_buff:GetModifierSpellAmplify_Percentage( params )
	return ( self.spell_amp_per_hero * self.heroStackCount + self.spell_amp_per_creep * self.creepStackCount ) * TernaryOperator( self.multiplier_during_berserkers_call, self:GetParent():HasModifier("modifier_axe_berserkers_call_aura"), 1 )
end

function modifier_axe_coat_of_blood_buff:IsPurgable()
	return true
end