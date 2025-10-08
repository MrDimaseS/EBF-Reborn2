arc_warden_tempest_double = class({})

function arc_warden_tempest_double:IsStealable()
    return false
end --NO STEALING

function arc_warden_tempest_double:OnHeroLevelUp()
    if IsServer() then
        if IsEntitySafe(self.double) then
            self.double:HeroLevelUp( false )
            self.double:SetAbilityPoints(-1)
        else
            self.double:SetAbilityPoints(-1)
        end
    end
end

function arc_warden_tempest_double:OnSpellStart()
    local caster = self:GetCaster()
    EmitSoundOn("Hero_ArcWarden.TempestDouble", caster)

    if IsEntitySafe (self.double) then
        self.double:RespawnUnit()
        ParticleManager:CreateParticle("particles/units/heroes/hero_arc_warden/arc_warden_tempest_cast.vpcf", PATTACH_ABSORIGIN, caster)

        FindClearRandomPositionAroundUnit(self.double, caster, 81)

        for itemSlot=0,5 do
            local item = self.double:GetItemInSlot(itemSlot)
            self.double:RemoveItem(item)
        end

        self.double:RemoveItem(self.double:GetItemInSlot(DOTA_ITEM_NEUTRAL_ACTIVE_SLOT))
        self.double:RemoveItem(self.double:GetItemInSlot(DOTA_ITEM_NEUTRAL_PASSIVE_SLOT))

        self:DoubleStats(self.double)
    else
        self.double = CreateUnitByName(caster:GetUnitName(), caster:GetAbsOrigin(), true, caster:GetPlayerOwner(), caster:GetPlayerOwner(), caster:GetTeam())
        self.double:SetControllableByPlayer(caster:GetPlayerID(), false)
        ParticleManager:CreateParticle("particles/units/heroes/hero_arc_warden/arc_warden_tempest_cast.vpcf", PATTACH_ABSORIGIN, caster)

        self:DoubleStats(self.double)
    end
    caster.double = self.double
end

function arc_warden_tempest_double:DoubleStats(unit)
    local caster = self:GetCaster()
    self.duration = self:GetSpecialValueFor("duration")
    self.amplify_damage = self:GetSpecialValueFor("amplify_damage_rune")

    if self:GetSpecialValueFor("longer_rune") < 1 then
        self.rune_duration = self:GetSpecialValueFor("rune_duration")
    else
        self.rune_duration = self.duration
    end

    unit:SetMaxHealth(caster:GetMaxHealth())
    unit:SetMana( caster:GetMaxMana() )
	unit:SetBaseAgility( caster:GetBaseAgility() )
	unit:SetBaseStrength( caster:GetBaseStrength() )
	unit:SetBaseIntellect( caster:GetBaseIntellect() )

    unit:AddNewModifier(caster, self, "modifier_arc_warden_tempest_double_handler")
    --unit:AddNewModifier(caster,self,"modifier_arc_warden_tempest_double")
    unit:AddNewModifier(caster, self, "modifier_special_bonus_attributes_stat_rescaling")
    unit:AddNewModifier(caster, self, "modifier_kill", {duration = self.duration})

    if self.amplify_damage == 1 then
        caster:AddNewModifier(caster, nil, "modifier_rune_doubledamage", {duration = self.rune_duration})
        unit:AddNewModifier(unit, nil, "modifier_rune_doubledamage", {duration = self.rune_duration})
    else
        caster:AddNewModifier(caster, nil, "modifier_rune_arcane", {duration = self.rune_duration})
        unit:AddNewModifier(unit, nil, "modifier_rune_arcane", {duration = self.rune_duration})
    end

    unit:SetForwardVector(caster:GetForwardVector())
    unit:SetRenderColor(0, 0, 190)

    unit:SetCanSellItems(false)

    for ability=0,24 do
        local ogAbility = caster:GetAbilityByIndex(ability)
		if ogAbility ~= nil and not ogAbility:IsInnateAbility() then
			local abilityLevel = ogAbility:GetLevel()
			local abilityName = ogAbility:GetAbilityName()
            local doubleAbility = unit:FindAbilityByName(abilityName)
            if not doubleAbility then
				doubleAbility = unit:AddAbility(abilityName)
			end
			if doubleAbility then
				doubleAbility:SetLevel( abilityLevel )
            end
        end
    end
    if unit:HasAbility("arc_warden_tempest_double") then
        local ult = unit:FindAbilityByName("arc_warden_tempest_double")
        ult:SetActivated(false)
    end

    for itemSlot=0,5 do
        local item = caster:GetItemInSlot(itemSlot)
        if item ~= nil and not ( item.IsConsumable and item:IsConsumable() ) then
            local itemName = item:GetName()
            local itemLevel = item:GetLevel()
            local newItem = unit:AddItemByName(itemName)
            if newItem then
                newItem:SetLevel(itemLevel)
                newItem:SetCooldown( item:GetCooldownTimeRemaining() )
                newItem:SetSellable(false)
                newItem:SetDroppable(false)
                newItem:SetShareability( ITEM_FULLY_SHAREABLE )
                newItem:SetPurchaser( nil )
            end
        end
    end

    local artifact = caster:GetItemInSlot(DOTA_ITEM_NEUTRAL_ACTIVE_SLOT)
    local enchantment = caster:GetItemInSlot(DOTA_ITEM_NEUTRAL_PASSIVE_SLOT)

    if artifact ~= nil then
        local artifactName = artifact:GetName()
        local artifactLevel = artifact:GetLevel()
        local enchantmentName = enchantment:GetName()
        local enchantmentLevel = enchantment:GetLevel()

        local cloneArtifact = unit:AddItemByName(artifactName)
        local cloneEnchantment = unit:AddItemByName(enchantmentName)

        if cloneArtifact and cloneEnchantment then
            cloneArtifact:SetLevel(artifactLevel)
            cloneEnchantment:SetLevel(enchantmentLevel)
        end
    end
end

modifier_arc_warden_tempest_double_handler = class({})
LinkLuaModifier("modifier_arc_warden_tempest_double_handler", "heroes/hero_arc_warden/arc_warden_tempest_double", LUA_MODIFIER_MOTION_NONE)

function modifier_arc_warden_tempest_double_handler:OnCreated()
	if IsServer() then
		local eyes = ParticleManager:CreateParticle("particles/units/heroes/hero_arc_warden/arc_warden_tempest_eyes.vpcf", PATTACH_ABSORIGIN, self:GetParent())
		local body = ParticleManager:CreateParticle("particles/units/heroes/hero_arc_warden/arc_warden_tempest_buff.vpcf", PATTACH_ABSORIGIN, self:GetParent())
		ParticleManager:SetParticleControlEnt(eyes, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_head", self:GetParent():GetAbsOrigin(), true)

		self:AddEffect( eyes )
		self:AddEffect( body )
    end
end

function modifier_arc_warden_tempest_double_handler:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_TEMPEST_DOUBLE
    }
end

function modifier_arc_warden_tempest_double_handler:IsClone()
    return true
end

function modifier_arc_warden_tempest_double_handler:IsMainHero()
    return false
end

function modifier_arc_warden_tempest_double_handler:IsTempestDouble()
    return true
end

function modifier_arc_warden_tempest_double_handler:GetModifierTempestDouble()
    return 1
end