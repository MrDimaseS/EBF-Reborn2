warlock_fatal_bonds = class({})

function warlock_fatal_bonds:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	local count = self:GetSpecialValueFor("count")
	count = TernaryOperator( math.ceil(count), RollPercentage( (count % math.floor( count )) * 100 ), math.floor(count) )
	local radius = self:GetSpecialValueFor("search_aoe")
	local duration = self:GetSpecialValueFor("duration")
	local binds_to_imps = self:GetSpecialValueFor("binds_to_imps") == 1
	
	self._currentRedirectTableForCopy = {[target] = true}
	count = count - 1
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), radius ) ) do
		if count > 0 and enemy ~= target then
			self._currentRedirectTableForCopy[enemy] = true
			count = count - 1
		else
			break
		end
	end
	
	if binds_to_imps then
		local impsCounted = 0
		for _, imp in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), -1 ) ) do
			if imp:GetUnitName() == "npc_dota_warlock_minor_imp" then
				self._currentRedirectTableForCopy[imp] = true
				impsCounted = impsCounted + 1
			end
		end
		if impsCounted == 0 then
			local newImp = caster:SpawnImp( caster:GetAbsOrigin() + RandomVector( 150 ) )
			self._currentRedirectTableForCopy[newImp] = true
		end
	end
	
	for target, _ in pairs( self._currentRedirectTableForCopy ) do
		target:AddNewModifier( caster, self, "modifier_warlock_fatal_bonds_handler", {duration = duration})
	end
	EmitSoundOn( "Hero_Warlock.FatalBonds", caster )
	self._currentRedirectTableForCopy = nil
end

function warlock_fatal_bonds:ShouldUseResources()
	return true
end

LinkLuaModifier("modifier_warlock_fatal_bonds_handler", "heroes/hero_warlock/warlock_fatal_bonds", LUA_MODIFIER_MOTION_NONE)
modifier_warlock_fatal_bonds_handler = class({})

function modifier_warlock_fatal_bonds_handler:OnCreated()
	self:OnRefresh()
end

function modifier_warlock_fatal_bonds_handler:OnRefresh()
	self.damage_share_percentage = self:GetSpecialValueFor("damage_share_percentage") / 100
	self.attack_speed_bonus = self:GetSpecialValueFor("attack_speed_bonus")
	if IsServer() then
		self._unitsToRedirect = table.copy( self:GetAbility()._currentRedirectTableForCopy )
	end
end

function modifier_warlock_fatal_bonds_handler:OnDestroy()
	if IsServer() and not self:GetParent():IsSameTeam( self:GetParent() ) then
		self:GetCaster():SpawnImp( self:GetParent():GetAbsOrigin() + RandomVector( 300 ) )
	end
end

function modifier_warlock_fatal_bonds_handler:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE, MODIFIER_EVENT_ON_ATTACK_RECORD }
end

function modifier_warlock_fatal_bonds_handler:OnTakeDamage( params )
	local parent = self:GetParent()
	if params.unit ~= self:GetParent() then return end
	if HasBit( params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION ) then return end
	local ability = self:GetAbility()
	if params.inflictor == ability then return end
	local caster = self:GetCaster()
	EmitSoundOn( "Hero_Warlock.FatalBondsDamage", parent )
	for target, _ in pairs( self._unitsToRedirect ) do
		if target ~= parent and not target:IsSameTeam( caster ) then
			ability:DealDamage( caster, target, params.original_damage * self.damage_share_percentage, {damage_type = params.damage_type, damage_flags = params.damage_flags + DOTA_DAMAGE_FLAG_REFLECTION} )
			ParticleManager:FireRopeParticle("particles/units/heroes/hero_warlock/warlock_fatal_bonds_hit.vpcf", PATTACH_POINT_FOLLOW, parent, target )
		end
	end
end

function modifier_warlock_fatal_bonds_handler:OnAttackRecord(params)
	if params.target ~= self:GetParent() then return end
	if self.attack_speed_bonus == 0 then return end
	params.attacker:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_warlock_fatal_bonds_wand_pact", {} )
end

function modifier_warlock_fatal_bonds_handler:GetEffectName()
	return "particles/units/heroes/hero_warlock/warlock_fatal_bonds_icon.vpcf"
end

function modifier_warlock_fatal_bonds_handler:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW 
end

function modifier_warlock_fatal_bonds_handler:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE 
end

LinkLuaModifier("modifier_warlock_fatal_bonds_wand_pact", "heroes/hero_warlock/warlock_fatal_bonds", LUA_MODIFIER_MOTION_NONE)
modifier_warlock_fatal_bonds_wand_pact = class({})

function modifier_warlock_fatal_bonds_wand_pact:OnCreated()
	self:OnRefresh()
end

function modifier_warlock_fatal_bonds_wand_pact:OnRefresh()
	self.attack_speed_bonus = self:GetSpecialValueFor("attack_speed_bonus")
end

function modifier_warlock_fatal_bonds_wand_pact:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_RECORD, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

function modifier_warlock_fatal_bonds_wand_pact:OnAttackRecord(params)
	if params.target:HasModifier("modifier_warlock_fatal_bonds_handler") then return end
	self:Destroy()
end

function modifier_warlock_fatal_bonds_wand_pact:GetModifierAttackSpeedBonus_Constant(params)
	return self.attack_speed_bonus
end
