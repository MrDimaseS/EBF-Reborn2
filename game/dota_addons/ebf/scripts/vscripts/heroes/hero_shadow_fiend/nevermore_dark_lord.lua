nevermore_dark_lord = class({})

function nevermore_dark_lord:GetIntrinsicModifierName()
	return "modifier_nevermore_dark_lord_passive"
end

modifier_nevermore_dark_lord_passive = class({})
LinkLuaModifier( "modifier_nevermore_dark_lord_passive","heroes/hero_shadow_fiend/nevermore_dark_lord.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_nevermore_dark_lord_passive:OnCreated()
	self:OnRefresh()
end

function modifier_nevermore_dark_lord_passive:OnRefresh()
	self.radius = self:GetSpecialValueFor("presence_radius")
	if IsServer() then
		for _, unit in ipairs( self:GetCaster():FindAllUnitsInRadius( self:GetCaster():GetAbsOrigin(), self.radius ) ) do
			if unit:HasModifier("modifier_nevermore_dark_lord_passive_aura") then
				unit:RemoveModifierByName("modifier_nevermore_dark_lord_passive_aura")
			end
		end
	end
end

function modifier_nevermore_dark_lord_passive:IsAura()
	return true
end

function modifier_nevermore_dark_lord_passive:GetModifierAura()
	return "modifier_nevermore_dark_lord_passive_aura"
end

function modifier_nevermore_dark_lord_passive:GetAuraRadius()
	return self.radius
end

function modifier_nevermore_dark_lord_passive:GetAuraDuration()
	return 0.5
end

function modifier_nevermore_dark_lord_passive:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_ENEMY + TernaryOperator(DOTA_UNIT_TARGET_TEAM_FRIENDLY, self:GetSpecialValueFor("affects_allies") == 1, 0 )
end

function modifier_nevermore_dark_lord_passive:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_nevermore_dark_lord_passive:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_nevermore_dark_lord_passive:IsHidden()
	return true
end

modifier_nevermore_dark_lord_passive_aura = class({})
LinkLuaModifier( "modifier_nevermore_dark_lord_passive_aura","heroes/hero_shadow_fiend/nevermore_dark_lord.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_nevermore_dark_lord_passive_aura:OnCreated()
	self:OnRefresh()
end

function modifier_nevermore_dark_lord_passive_aura:OnRefresh()
	self.presence_armor_reduction = self:GetSpecialValueFor("presence_armor_reduction")
	self.negator = TernaryOperator( -1, self:GetParent():IsSameTeam( self:GetCaster() ), 1 )
	
	if IsServer() then
		self:StartIntervalThink(0.25)
	end
end

function modifier_nevermore_dark_lord_passive_aura:OnDestroy()
	if IsServer() then
		if not self:GetParent():IsAlive() then
			local duration = self:GetSpecialValueFor("kill_buff_duration")
			local creepDur = self:GetSpecialValueFor("creep_buff_duration")
			
			local stacks = TernaryOperator( self:GetSpecialValueFor("bonus_armor_per_stack"), self:GetParent():IsConsideredHero(), self:GetSpecialValueFor("creep_armor_per_stack") )
			local stackDur = TernaryOperator( duration, self:GetParent():IsConsideredHero(), creepDur )
			local buff = self:GetCaster():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_nevermore_dark_lord_kill_buff", {duration = stackDur} )
			for i = 1, stacks do
				buff:AddIndependentStack(stackDur)
			end
		end
	end
end

function modifier_nevermore_dark_lord_passive_aura:OnIntervalThink()
	local buff = self:GetCaster():FindModifierByName("modifier_nevermore_dark_lord_kill_buff")
	if buff and buff:GetStackCount() ~= self:GetStackCount() then
		self:SetStackCount( buff:GetStackCount() )
	elseif not buff and self:GetStackCount() > 0 then
		self:SetStackCount(0)
	end
end

function modifier_nevermore_dark_lord_passive_aura:DeclareFunctions()
	return {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end

function modifier_nevermore_dark_lord_passive_aura:GetModifierPhysicalArmorBonus()
	return ( self.presence_armor_reduction - self:GetStackCount() ) * self.negator
end

modifier_nevermore_dark_lord_kill_buff = class({})
LinkLuaModifier( "modifier_nevermore_dark_lord_kill_buff","heroes/hero_shadow_fiend/nevermore_dark_lord.lua",LUA_MODIFIER_MOTION_NONE )