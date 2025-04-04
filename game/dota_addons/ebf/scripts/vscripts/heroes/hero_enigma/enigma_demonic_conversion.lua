enigma_demonic_conversion = class({})

function enigma_demonic_conversion:GetIntrinsicModifierName()
	return "modifier_enigma_demonic_conversion_splitter"
end

function enigma_demonic_conversion:Spawn()
	if IsServer() then
		local splitting = self:GetCaster():FindAbilityByName("enigma_splitting_image")
		if splitting then
			self:GetCaster():RemoveAbilityByHandle( splitting )
		end
	end
end

function enigma_demonic_conversion:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	local eidolons = self:GetSpecialValueFor("spawn_count")
	local eidolon_hp = self:GetSpecialValueFor("eidelon_max_health")
	if target:IsConsideredHero() then
		self:DealDamage( caster, target, eidolon_hp * eidolons, { damage_type = DAMAGE_TYPE_PURE } )
	else
		self:DealDamage( caster, target, target:GetMaxHealth() + eidolon_hp * eidolons, { damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL } )
	end
	for i = 1, eidolons do
		local eidolon = self:CreateEidolon( target:GetAbsOrigin() + RandomVector( 128 ) )
		eidolon:AddNewModifier( caster, self, "modifier_enigma_demonic_conversion_eidolon", {duration = self:GetDuration()} )
	end
	ResolveNPCPositions( target:GetAbsOrigin(), 150 )
	
	EmitSoundOn( "Hero_Enigma.Demonic_Conversion", target )
end

function enigma_demonic_conversion:CreateEidolon( position, duration )
	local caster = self:GetCaster()
	local eidolon = caster:CreateSummon( "npc_dota_eidolon", position or caster:GetAbsOrigin() + RandomVector( 64 ), duration or self:GetDuration() )
	
	local eidolon_hp = self:GetSpecialValueFor("eidelon_max_health") + caster:GetHealth() * self:GetSpecialValueFor("current_health_pct")/100
	local eidolon_dmg = self:GetSpecialValueFor("eidelon_base_damage")
	local eidolon_dmg_spread = self:GetSpecialValueFor("eidolon_damage_spread")
	
	eidolon:SetBaseMaxHealth( eidolon_hp )
	eidolon:SetMaxHealth( eidolon_hp )
	eidolon:SetHealth( eidolon_hp )
	eidolon:SetAverageBaseDamage( eidolon_dmg, eidolon_dmg_spread )
		
	FindClearSpaceForUnit( eidolon, eidolon:GetAbsOrigin(), true )
	return eidolon
end

modifier_enigma_demonic_conversion_splitter = class({})
LinkLuaModifier("modifier_enigma_demonic_conversion_splitter", "heroes/hero_enigma/enigma_demonic_conversion", LUA_MODIFIER_MOTION_NONE )

function modifier_enigma_demonic_conversion_splitter:OnCreated()
	self.damage_threshold = self:GetSpecialValueFor("damage_threshold") / 100
	self.damage_reset_interval = self:GetSpecialValueFor("damage_reset_interval")
	self.eidolon_spawns = self:GetSpecialValueFor("eidolon_spawns")
	
	self.currentDamageTaken = 0
end

function modifier_enigma_demonic_conversion_splitter:OnIntervalThink()
	self.currentDamageTaken = 0
	self:StartIntervalThink( -1 )
end

function modifier_enigma_demonic_conversion_splitter:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_enigma_demonic_conversion_splitter:OnTakeDamage( params )
	if params.unit == self:GetParent() and self.damage_reset_interval > 0 then
		self:StartIntervalThink( self.damage_reset_interval )
		self.currentDamageTaken = self.currentDamageTaken + params.damage
		
		if self.currentDamageTaken >= params.unit:GetMaxHealth() * self.damage_threshold then
			self.currentDamageTaken = 0
			
			for i = 1, self.eidolon_spawns do
				self:GetAbility():CreateEidolon( )
			end
		end
	end
end

function modifier_enigma_demonic_conversion_splitter:IsHidden()
	return true
end

modifier_enigma_demonic_conversion_eidolon = class({})
LinkLuaModifier("modifier_enigma_demonic_conversion_eidolon", "heroes/hero_enigma/enigma_demonic_conversion", LUA_MODIFIER_MOTION_NONE )

function modifier_enigma_demonic_conversion_eidolon:OnCreated()
	self.attacks = 0
	self.attacks_to_split = self:GetSpecialValueFor("split_attack_count")
	self.life_extension = self:GetSpecialValueFor("life_extension")
	
	self.bat = self:GetSpecialValueFor("eidolon_base_attack_time")
end

function modifier_enigma_demonic_conversion_eidolon:OnRefresh()
	self.attacks = 0
	self.attacks_to_split = self:GetSpecialValueFor("split_attack_count")
	self.life_extension = self:GetSpecialValueFor("life_extension")
	
	self.bat = self:GetSpecialValueFor("eidolon_base_attack_time")
end

function modifier_enigma_demonic_conversion_eidolon:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED, MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT}
end

function modifier_enigma_demonic_conversion_eidolon:OnAttackLanded(params)
	if params.attacker == self:GetParent() then
		self.attacks = self.attacks + 1
		self:SetStackCount(self.attacks)
		if self.attacks >= self.attacks_to_split then
			self:GetAbility():CreateEidolon( self:GetParent():GetAbsOrigin(), self:GetRemainingTime() + self.life_extension )
			self:GetAbility():CreateEidolon( self:GetParent():GetAbsOrigin(), self:GetRemainingTime() + self.life_extension )
			
			params.attacker:ForceKill( false )
		end
	end
end

function modifier_enigma_demonic_conversion_eidolon:GetModifierBaseAttackTimeConstant()
	return self.bat
end

function modifier_enigma_demonic_conversion_eidolon:IsHidden()
	return true
end

function modifier_enigma_demonic_conversion_eidolon:GetPriority()
	return MODIFIER_PRIORITY_SUPER_ULTRA
end