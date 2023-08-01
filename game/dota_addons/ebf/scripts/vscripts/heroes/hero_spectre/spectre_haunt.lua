spectre_haunt = class({})

function spectre_haunt:OnUpgrade( )
	local caster = self:GetCaster()
	local reality = caster:FindAbilityByName("spectre_reality")
	if reality and reality:GetLevel() == 0 then
		reality:SetLevel( 1 )
		reality:SetActivated( false )
	end
end

function spectre_haunt:OnSpellStart()
	local caster = self:GetCaster()
	
	local duration = self:GetTalentSpecialValueFor("duration")
	caster:AddNewModifier( caster, self, "modifier_spectre_haunt_active", {duration = duration} )
	ParticleManager:FireParticle( "particles/econ/items/spectre/spectre_arcana/spectre_arcana_haunt_caster.vpcf", PATTACH_POINT_FOLLOW, caster )
	EmitSoundOn( "Hero_Spectre.HauntCast", caster )
end

modifier_spectre_haunt_active = class({})
LinkLuaModifier( "modifier_spectre_haunt_active", "heroes/hero_spectre/spectre_haunt.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_spectre_haunt_active:OnCreated()
	self:OnRefresh()
end

function modifier_spectre_haunt_active:OnRefresh()
	self.debuff_duration = self:GetSpecialValueFor("debuff_duration")
	if IsServer() then
		local reality = self:GetCaster():FindAbilityByName("spectre_reality")
		if reality then
			reality:SetActivated( true )
		end
	end
end

function modifier_spectre_haunt_active:OnDestroy()
	if IsServer() then
		local reality = self:GetCaster():FindAbilityByName("spectre_reality")
		if reality then
			reality:SetActivated( false )
		end
	end
end

function modifier_spectre_haunt_active:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK}
end

function modifier_spectre_haunt_active:OnAttack( params )
	if params.attacker == self:GetParent() then
		if not self.disableForRecursion then
			self.disableForRecursion = true
			for _, enemy in ipairs( params.attacker:FindEnemyUnitsInRadius( params.attacker:GetAbsOrigin(), -1, {type = DOTA_UNIT_TARGET_HERO} ) ) do
				params.attacker:PerformGenericAttack( enemy, true, true )
			end
			self.disableForRecursion = false
		end
		params.target:AddNewModifier( params.attacker, self:GetAbility(), "modifier_spectre_haunt_debuff", {duration = self.debuff_duration} )
	end
end

modifier_spectre_haunt_debuff = class({})
LinkLuaModifier( "modifier_spectre_haunt_debuff", "heroes/hero_spectre/spectre_haunt.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_spectre_haunt_debuff:OnCreated()
	self:OnRefresh()
end

function modifier_spectre_haunt_debuff:OnRefresh()
	self.armor_reduction = self:GetSpecialValueFor("armor_reduction")
end

function modifier_spectre_haunt_debuff:DeclareFunctions()
	return {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS}
end

function modifier_spectre_haunt_debuff:GetModifierPhysicalArmorBonus( params )
	return self.armor_reduction
end

spectre_reality = class({})

function spectre_reality:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	caster:Blink( target:GetAbsOrigin() + target:GetForwardVector() * 150 )
	caster:FaceTowards( target:GetAbsOrigin() )
	
	EmitSoundOn("Hero_Spectre.Reality", caster)
end

spectre_haunt_single = class({})

function spectre_haunt_single:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	caster:Blink( target:GetAbsOrigin() + target:GetForwardVector() * 150 )
	caster:FaceTowards( target:GetAbsOrigin() )
	
	EmitSoundOn("Hero_Spectre.Reality", caster)
	
	local dagger = caster:FindAbilityByName("spectre_spectral_dagger")
	if dagger and dagger:IsTrained() then
		caster:SetCursorPosition( target:GetAbsOrigin() )
		dagger:OnSpellStart()
	end
	
	local haunt = caster:FindAbilityByName("spectre_haunt")
	local duration = self:GetTalentSpecialValueFor("duration")
	caster:AddNewModifier( caster, haunt, "modifier_spectre_haunt_active", {duration = duration} )
	
	ParticleManager:FireParticle( "particles/econ/items/spectre/spectre_arcana/spectre_arcana_haunt_caster.vpcf", PATTACH_POINT_FOLLOW, caster )
	EmitSoundOn( "Hero_Spectre.HauntCast", caster )
end