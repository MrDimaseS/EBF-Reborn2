lone_druid_spirit_bear = class({})

function lone_druid_spirit_bear:IsStealable()
    return false
end

function lone_druid_spirit_bear:IsHiddenWhenStolen()
    return false
end

function lone_druid_spirit_bear:Spawn()
	if IsServer() then PrecacheUnitByNameAsync( "npc_dota_lone_druid_bear1", function() print("precache done", self:GetCaster():GetPlayerID()) end ) end
end

function lone_druid_spirit_bear:OnHeroLevelUp()
	if IsEntitySafe( self.bear ) then
		self.bear:HeroLevelUp( true )
		self:BearStats( self.bear ) 
	end
end

function lone_druid_spirit_bear:OnInventoryContentsChanged()
end

function lone_druid_spirit_bear:OnSpellStart()
	local caster = self:GetCaster()

	EmitSoundOn("Hero_LoneDruid.SpiritBear.Cast", caster)

	if IsEntitySafe( self.bear ) then
		self.bear:RespawnUnit()
		local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_lone_druid/lone_druid_bear_spawn.vpcf", PATTACH_POINT, caster)
		ParticleManager:SetParticleControlEnt(nfx, 0, self.bear, PATTACH_POINT_FOLLOW, "attach_hitloc", self.bear:GetAbsOrigin(), true)
		ParticleManager:ReleaseParticleIndex(nfx)

		FindClearSpaceForUnit(self.bear, caster:GetAbsOrigin(), true)
		self:BearStats(self.bear)
	else
		self.bear = CreateUnitByName("npc_dota_lone_druid_bear1", caster:GetAbsOrigin(), true, caster:GetPlayerOwner(), caster:GetPlayerOwner(), caster:GetTeam())
		self.bear:SetControllableByPlayer(caster:GetPlayerID(), false)
		local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_lone_druid/lone_druid_bear_spawn.vpcf", PATTACH_POINT, caster)
					ParticleManager:SetParticleControlEnt(nfx, 0, self.bear, PATTACH_POINT_FOLLOW, "attach_hitloc", self.bear:GetAbsOrigin(), true)
					ParticleManager:ReleaseParticleIndex(nfx)

		self:BearStats(self.bear)
		self.bear:AddItemByName("item_bottle_ebf")
	end
	caster.bear = self.bear
end

function lone_druid_spirit_bear:BearStats(unit)
	local caster = self:GetCaster()

	local dmgScaling = self:GetSpecialValueFor("damage_gain_per_druid_level")
	local armor = self:GetSpecialValueFor("bear_armor")
	local magic_resistance = self:GetSpecialValueFor("bear_magic_resistance")
	local bear_regen = self:GetSpecialValueFor("bear_regen_tooltip")
	
	local bat = self:GetSpecialValueFor("bear_bat")
	local ms = self:GetSpecialValueFor("bear_movespeed")
	unit:SetForwardVector( caster:GetForwardVector() )
	
	unit:SetBaseHealthRegen( bear_regen )
	unit:SetBaseManaRegen( 0.5 )
	unit:SetBaseDamageMax( 200 + dmgScaling * (caster:GetLevel() -1) )
	unit:SetBaseDamageMin( 250 + dmgScaling * (caster:GetLevel() -1) )
	unit:SetBaseMagicalResistanceValue( magic_resistance )
	unit:SetPhysicalArmorBaseValue( armor )
	unit:SetBaseAttackTime(bat)
	unit:SetBaseMoveSpeed(ms)
	
	local scale = 0.65 + self:GetLevel() * 0.05 + caster:GetLevel() * 0.01
	unit:SetModelScale(scale)
	
	if unit:HasAbility("lone_druid_spirit_bear_demolish") then
		local bear_defender = unit:FindAbilityByName("lone_druid_spirit_bear_demolish")
		bear_defender:SetLevel( self:GetLevel() )
	end
	if unit:HasAbility("lone_druid_spirit_bear_entangle") then
		local entangle = unit:FindAbilityByName("lone_druid_spirit_bear_entangle")
		entangle:SetLevel( self:GetLevel() )
	end
	if unit:HasAbility("lone_druid_savage_roar_bear") then
		local bear_roar = unit:FindAbilityByName("lone_druid_savage_roar_bear")
		bear_roar:SetLevel( caster:FindAbilityByName("lone_druid_savage_roar"):GetLevel() )
		if bear_roar:IsHidden() then bear_roar:SetHidden( false ) end
	end
	for i = 1, caster:GetLevel() - unit:GetLevel() do
		self.bear:HeroLevelUp( false )
	end
	unit:SetMana( unit:GetMaxMana() )
	unit:SetBaseAgility( caster:GetBaseAgility() )
	unit:SetBaseStrength( caster:GetBaseStrength() )
	unit:SetBaseIntellect( caster:GetBaseIntellect() )
	
	unit:AddNewModifier( caster, self, "modifier_spirit_bear_scaling_handler", {} )
end

modifier_spirit_bear_scaling_handler = class({})
LinkLuaModifier( "modifier_spirit_bear_scaling_handler", "heroes/hero_lone_druid/lone_druid_spirit_bear", LUA_MODIFIER_MOTION_NONE )

function modifier_spirit_bear_scaling_handler:OnCreated()
	self:OnRefresh()
end

function modifier_spirit_bear_scaling_handler:OnRefresh()
	local baseHealth = self:GetSpecialValueFor("bear_hp")
	local hpScaling = self:GetSpecialValueFor("hp_gain_per_druid_level")
	self.health = baseHealth + hpScaling * (self:GetCaster():GetLevel() - 1)
end

function modifier_spirit_bear_scaling_handler:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEALTH_BONUS}
end

function modifier_spirit_bear_scaling_handler:GetModifierHealthBonus(params)
	return self.health
end

function modifier_spirit_bear_scaling_handler:IsPurgable()
	return false
end

function modifier_spirit_bear_scaling_handler:IsPermanent()
	return true
end