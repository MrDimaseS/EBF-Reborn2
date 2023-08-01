visage_gravekeepers_cloak = class({})

function visage_gravekeepers_cloak:IsStealable()
    return false
end

function visage_gravekeepers_cloak:IsHiddenWhenStolen()
    return false
end

function visage_gravekeepers_cloak:GetBehavior()
    local caster = self:GetCaster()
    if caster:HasShard() then
    	return DOTA_ABILITY_BEHAVIOR_NO_TARGET
    end
    return DOTA_ABILITY_BEHAVIOR_PASSIVE
end

function visage_gravekeepers_cloak:GetCooldown(iLevel)
    local caster = self.visage or self:GetCaster()
    if caster:HasShard() then
    	return self:GetSpecialValueFor("shard_cooldown")
    end
end

function visage_gravekeepers_cloak:GetManaCost(iLevel)
    local caster = self.visage or self:GetCaster()
    if caster:HasShard() then
    	return self:GetSpecialValueFor("shard_manacost")
    end
end

function visage_gravekeepers_cloak:GetIntrinsicModifierName()
    return "modifier_visage_gravekeepers_cloak_handle"
end

function visage_gravekeepers_cloak:OnSpellStart()
    local caster = self:GetCaster()
	
	caster:AddNewModifier( caster, self, "modifier_visage_summon_familiars_stone_form_buff", {duration = 6} )
	EmitSoundOn( "Visage_Familar.StoneForm.Cast", caster )
end

modifier_visage_gravekeepers_cloak_handle = class({})
LinkLuaModifier( "modifier_visage_gravekeepers_cloak_handle", "heroes/hero_visage/visage_gravekeepers_cloak", LUA_MODIFIER_MOTION_NONE )

function modifier_visage_gravekeepers_cloak_handle:OnCreated()
	self:OnRefresh()
end

function modifier_visage_gravekeepers_cloak_handle:OnRefresh()
	self.recovery_time = self:GetSpecialValueFor("recovery_time")
	self.max = self:GetSpecialValueFor("max_layers")
	if IsServer() then
		local caster = self:GetCaster()
		local parent = self:GetParent()
		local talentOwner = caster.visage or parent
		parent:AddNewModifier(caster, self:GetAbility(), "modifier_visage_gravekeepers_cloak_passive", {})
		if talentOwner:HasTalent("special_bonus_unique_visage_gravekeepers_cloak_1") then
			parent:AddNewModifier(caster, self:GetAbility(), "modifier_visage_gravekeepers_cloak_talent", {})
		end
	end
end

function modifier_visage_gravekeepers_cloak_handle:PrepareNewLayer(modifierName)
	local caster = self:GetCaster()
	local parent = self:GetParent()

	if parent:IsAlive() then
		local modifier = parent:FindModifierByName(modifierName)
		if modifier then
			modifier:SetDuration( self.recovery_time + 0.1, true )
		end
		Timers:CreateTimer( self.recovery_time, function()
			local modifier = parent:FindModifierByName(modifierName)
			if modifier then
				if modifier:GetStackCount() < self.max then
					modifier:IncrementStackCount()
				end
				if modifier:GetStackCount() == self.max then
					modifier:SetDuration( -1, true )
				end
			else
				parent:AddNewModifier( caster, self:GetAbility(), modifierName, {})
			end
		end)
	end
end

function modifier_visage_gravekeepers_cloak_handle:IsHidden()
	return true
end

modifier_visage_gravekeepers_cloak_passive = class({})
LinkLuaModifier( "modifier_visage_gravekeepers_cloak_passive", "heroes/hero_visage/visage_gravekeepers_cloak", LUA_MODIFIER_MOTION_NONE )

function modifier_visage_gravekeepers_cloak_passive:OnCreated()
	local caster = self:GetCaster()
	local parent = self:GetParent()

	if IsServer() then		
		self.nfx =  ParticleManager:CreateParticle("particles/units/heroes/hero_visage/visage_cloak_ambient.vpcf", PATTACH_ABSORIGIN, caster)
					ParticleManager:SetParticleAlwaysSimulate(self.nfx)
					ParticleManager:SetParticleControlEnt(self.nfx, 0, parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
					ParticleManager:SetParticleControlEnt(self.nfx, 1, parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
					ParticleManager:SetParticleControl(self.nfx, 2, Vector(1,1,0))
					ParticleManager:SetParticleControl(self.nfx, 3, Vector(0,0,0))
					ParticleManager:SetParticleControl(self.nfx, 4, Vector(0,0,0))
					ParticleManager:SetParticleControl(self.nfx, 5, Vector(0,0,0))

		self:AddEffect(self.nfx)
	end
	self:OnRefresh()
end

function modifier_visage_gravekeepers_cloak_passive:OnRefresh()
	self.instances = self:GetSpecialValueFor("max_layers")
	self.radius = self:GetSpecialValueFor("radius")
	self.block = self:GetSpecialValueFor("damage_reduction")
	self.max_block = self:GetSpecialValueFor("max_damage_reduction")
	if IsServer() then
		self:SetStackCount(self.instances)
	end
end

function modifier_visage_gravekeepers_cloak_passive:OnStackCountChanged(iStackCount)
	local caster = self:GetCaster()
	local parent = self:GetParent()
	if not IsServer() then return end
	local stacks = self:GetStackCount()
	for i = 1, self.max_block do
		if i <= stacks then
			ParticleManager:SetParticleControl(self.nfx, 1+i, Vector(1,0,0))
		else
			ParticleManager:SetParticleControl(self.nfx, 1+i, Vector(0,0,0))
		end
	end
end

function modifier_visage_gravekeepers_cloak_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, 
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_visage_gravekeepers_cloak_passive:GetModifierIncomingDamage_Percentage(params)
	return -math.min( self.max_block, self.block * self:GetStackCount() )
end

function modifier_visage_gravekeepers_cloak_passive:GetModifierPhysicalArmorBonus(params)
	return self:GetSpecialValueFor("bonus_armor")
end

function modifier_visage_gravekeepers_cloak_passive:OnTakeDamage(params)
	if IsServer() then
		local caster = self:GetCaster()
		local parent = self:GetParent()
		local unit = params.unit
		
		if unit == parent then
			if self:GetStackCount() > 0 then
				if parent == caster then
					parent:FindModifierByName("modifier_visage_gravekeepers_cloak_handle"):PrepareNewLayer(self:GetName())
				end
				self:DecrementStackCount()
			end
		end
	end
end

function modifier_visage_gravekeepers_cloak_passive:IsAura()
	return self:GetStackCount() > 0
end

function modifier_visage_gravekeepers_cloak_passive:GetModifierAura()
	return "modifier_visage_gravekeepers_cloak_aura"
end

function modifier_visage_gravekeepers_cloak_passive:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_visage_gravekeepers_cloak_passive:GetAuraSearchType()
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_visage_gravekeepers_cloak_passive:GetAuraRadius()
	return self.radius
end

function modifier_visage_gravekeepers_cloak_passive:GetAuraEntityReject( target )
	if target:GetClassname() == "npc_dota_visage_familiar" then
		return false
	end
	return true
end

function modifier_visage_gravekeepers_cloak_passive:IsHidden()
	return false
end

function modifier_visage_gravekeepers_cloak_passive:IsPurgable()
	return false
end

function modifier_visage_gravekeepers_cloak_passive:RemoveOnDeath()
	return false
end

function modifier_visage_gravekeepers_cloak_passive:DestroyOnExpire()
	return false
end

modifier_visage_gravekeepers_cloak_aura = class({})
LinkLuaModifier( "modifier_visage_gravekeepers_cloak_aura", "heroes/hero_visage/visage_gravekeepers_cloak", LUA_MODIFIER_MOTION_NONE )

function modifier_visage_gravekeepers_cloak_aura:OnCreated()
	if IsServer() then
		self:StartIntervalThink( 0.25 )
	end
	self:OnRefresh()
end

function modifier_visage_gravekeepers_cloak_aura:OnRefresh()
	self.block = self:GetSpecialValueFor("damage_reduction")
	self.max_block = self:GetSpecialValueFor("max_damage_reduction")
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
end

function modifier_visage_gravekeepers_cloak_aura:OnIntervalThink()
	self:SetStackCount( self:GetCaster():FindModifierByName("modifier_visage_gravekeepers_cloak_passive"):GetStackCount() )
end

function modifier_visage_gravekeepers_cloak_aura:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end

function modifier_visage_gravekeepers_cloak_aura:GetModifierIncomingDamage_Percentage(params)
	return -math.min( self.max_block, self.block * self:GetStackCount() )
end

function modifier_visage_gravekeepers_cloak_aura:GetModifierPhysicalArmorBonus(params)
	return self:GetSpecialValueFor("bonus_armor")
end