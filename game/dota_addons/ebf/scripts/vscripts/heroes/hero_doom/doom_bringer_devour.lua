doom_bringer_devour = class({})

function doom_bringer_devour:IsStealable()
	return true
end

function doom_bringer_devour:IsHiddenWhenStolen()
	return false
end

function doom_bringer_devour:OnUpgrade()
	if IsServer() then
		if self:GetLevel() == 1 then
			self:ToggleAutoCast()
		elseif self.currentlyDevouredAbilities then
			for _, ability in ipairs( self.currentlyDevouredAbilities  ) do
				ability:SetLevel( self:GetLevel() )
			end
		end
	end
end

function doom_bringer_devour:CastFilterResultTarget( target )
	return UnitFilter(target, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, TernaryOperator( DOTA_UNIT_TARGET_FLAG_NONE, self:GetSpecialValueFor("targets_ancients") > 0, DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS ), self:GetCaster():GetTeamNumber() )
end

function doom_bringer_devour:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local damage = self:GetSpecialValueFor("damage")
	
	if target:TriggerSpellAbsorb( self ) then return end
	
	caster:RemoveModifierByName( "modifier_doom_bringer_devour_eating" )
	caster:AddNewModifier( caster, self, "modifier_doom_bringer_devour_eating", {duration = self:GetCooldown(self:GetLevel())} )
	if target:IsNeutralUnitType() and self:GetAutoCastState() then
		self.currentlyDevouredAbilities = {}
		local abilitiesToAdd = {}
		for i = 1, 10 do
			local neutralAbility = target:GetAbilityByIndex( i-1 )
			if neutralAbility and neutralAbility:IsStealable() and neutralAbility:GetAbilityName() ~= "neutral_upgrade" then
				if #abilitiesToAdd < 2 then
					table.insert( abilitiesToAdd, neutralAbility:GetAbilityName() )
				end
			else
				table.insert( abilitiesToAdd, "doom_bringer_empty"..i )
			end
		end
		for index, abilityName in ipairs( abilitiesToAdd ) do
			local currentAbility = caster:GetAbilityByIndex( index+2 )
			if currentAbility and currentAbility:GetAbilityName() ~= abilityName then
				local newAbility = caster:AddAbility( abilityName )
				if newAbility then
					caster:SwapAbilities( currentAbility:GetAbilityName(), abilityName, false, true )
					for _, modifier in ipairs( caster:FindAllModifiers() ) do
						if modifier:GetAbility() == currentAbility then
							modifier:Destroy()
						end
					end
					caster:RemoveAbilityByHandle(currentAbility)
					
					newAbility:SetLevel( self:GetLevel() )
					newAbility:SetStolen( true )
					table.insert( self.currentlyDevouredAbilities, newAbility )
				end
			end
		end
	end
	self:DealDamage(caster, target, damage, { damage_type = DAMAGE_TYPE_PURE })
end

modifier_doom_bringer_devour_eating = class({})
LinkLuaModifier( "modifier_doom_bringer_devour_eating", "heroes/hero_doom/doom_bringer_devour", LUA_MODIFIER_MOTION_NONE )

function modifier_doom_bringer_devour_eating:OnCreated()
	self:OnRefresh()
end
function modifier_doom_bringer_devour_eating:OnRefresh()
	self.bonus_gold = self:GetSpecialValueFor("bonus_gold")
	self.armor = self:GetSpecialValueFor("armor")
	self.magic_resist = self:GetSpecialValueFor("magic_resist")
	self.attack_damage = self:GetSpecialValueFor("attack_damage")
	self.cleave = self:GetSpecialValueFor("cleave") / 100
	self.cleave_ending_width = self:GetSpecialValueFor("cleave_ending_width")
	self.cleave_distance = self:GetSpecialValueFor("cleave_distance")
	self.mana_regen = self:GetSpecialValueFor("mana_regen")
	self.cast_speed = self:GetSpecialValueFor("cast_speed")

	if self.cast_speed ~= 0 then
		self:GetParent().cooldownModifiers = self:GetParent().cooldownModifiers or {}
		self:GetParent().cooldownModifiers[self] = true
	end
end
function modifier_doom_bringer_devour_eating:OnDestroy()
	if self.cast_speed ~= 0 then
		self:GetParent().cooldownModifiers[self] = nil
	end
	if IsServer() and self:GetParent():IsAlive() then
		self:GetCaster():AddGold( self.bonus_gold )
	end
end
function modifier_doom_bringer_devour_eating:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT
	}
end
function modifier_doom_bringer_devour_eating:GetModifierPhysicalArmorBonus()
	return self.armor
end
function modifier_doom_bringer_devour_eating:GetModifierMagicalResistanceBonus()
	return self.magic_resist
end
function modifier_doom_bringer_devour_eating:GetModifierPreAttack_BonusDamage()
	return self.attack_damage
end
function modifier_doom_bringer_devour_eating:OnAttackLanded(params)
	if params.attacker == self:GetParent() and not params.attacker:IsIllusion() and not params.attacker:IsCleaveSuppressed() then
		local ability = self:GetAbility()
		local units = 0
		local direction = CalculateDirection( params.target, params.attacker)
		local splash = params.attacker:FindEnemyUnitsInCone( direction, params.target:GetAbsOrigin(), self.cleave_ending_width, self.cleave_distance)
		local splashFX = ParticleManager:CreateParticle( "particles/items_fx/battlefury_cleave.vpcf", PATTACH_POINT, params.attacker )
		ParticleManager:SetParticleControl( splashFX, units, params.attacker:GetAbsOrigin() ) 
		ParticleManager:SetParticleControlTransformForward( splashFX, units, params.attacker:GetAbsOrigin(), direction ) 
		
		local splashDamage = params.original_damage * self.cleave
		for _, unit in ipairs( splash ) do
			if unit ~= params.target then
				units = units + 1
				ParticleManager:SetParticleControl( splashFX, units, unit:GetAbsOrigin() )
				ability:DealDamage( params.attacker, unit, splashDamage, { damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL } )
			end
		end
		ParticleManager:ReleaseParticleIndex( splashFX )
	end
end
function modifier_doom_bringer_devour_eating:GetModifierConstantManaRegen()
	return self.mana_regen
end
function modifier_doom_bringer_devour_eating:GetModifierCastSpeed( params )
	if params.ability and not params.ability:IsItem() then return self.cast_speed end 
end