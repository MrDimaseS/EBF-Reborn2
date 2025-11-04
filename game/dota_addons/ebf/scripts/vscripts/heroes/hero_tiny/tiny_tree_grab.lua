tiny_tree_grab = class({})

function tiny_tree_grab:IsStealable()
    return false
end

function tiny_tree_grab:IsHiddenWhenStolen()
    return false
end

function tiny_tree_grab:CastFilterResultTarget( target )
	if target.CutDown then
		return UF_SUCCESS
	else
		return UnitFilter( target, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, self:GetCaster():GetTeamNumber() )
	end
end

function tiny_tree_grab:OnSpellStart()
    local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	EmitSoundOn("Hero_Tiny.Tree.Grab", caster)

	duration = self:GetSpecialValueFor("tree_duration")
	if target.IsCreep and target:IsCreep() then
		caster:AddNewModifier(caster, self, "modifier_tiny_tree_grab_creep", {duration = duration})
		target:AddNewModifier(caster, self, "modifier_tiny_tree_grab_creep_stun", {duration = duration})
		caster._treeGrabUnit = target
		self:EndCooldown()
	else
		caster:AddNewModifier(caster, self, "modifier_tiny_tree_grab", {duration = duration})
		target:CutDown(caster:GetTeam())
	end
	self:SetActivated( false )
	local treeToss = caster:FindAbilityByName("tiny_toss_tree")
	if IsEntitySafe( treeToss ) then
		treeToss:SetActivated( true )
	end
	Timers:CreateTimer( 0.1, function()
		if not ( caster:HasModifier("modifier_tiny_tree_grab") or  caster:HasModifier("modifier_tiny_tree_grab_creep") ) then
			self:SetActivated( true )
			treeToss:SetActivated( false )
			return
		end
		return 0.1
	end)
end

modifier_tiny_tree_grab_creep_stun = class({})
LinkLuaModifier("modifier_tiny_tree_grab_creep_stun", "heroes/hero_tiny/tiny_tree_grab", LUA_MODIFIER_MOTION_NONE)

function modifier_tiny_tree_grab_creep_stun:OnCreated()
	if IsClient() then return end
	local caster = self:GetCaster()
	local parent = self:GetParent()
	parent:SetParent( caster, "attach_attack2" )
	parent:SetLocalOrigin( Vector(75, 40, -140) )
end

function modifier_tiny_tree_grab_creep_stun:OnDestroy()
	if IsClient() then return end
	self:GetParent():SetParent( nil, "" )
	self:GetCaster()._treeGrabUnit = nil
end

function modifier_tiny_tree_grab_creep_stun:CheckState()
	return {[MODIFIER_STATE_STUNNED] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true}
end

function modifier_tiny_tree_grab_creep_stun:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION, MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_tiny_tree_grab_creep_stun:OnTakeDamage( params )
	if params.attacker ~= self:GetCaster() then return end
	local parent = self:GetParent()
	if params.target == parent then return end
	if params.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK then return end
	self:GetAbility():DealDamage( params.attacker, parent, params.damage, {damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL } )
	if IsEntitySafe( parent) and parent:IsAlive() then return end
	params.attacker:RemoveModifierByName("modifier_tiny_tree_grab_creep")
	self:GetAbility():EndCooldown()
	self:Destroy()
end

function modifier_tiny_tree_grab_creep_stun:GetOverrideAnimation()
	return ACT_DOTA_FLAIL
end

modifier_tiny_tree_grab_creep = class({})
LinkLuaModifier("modifier_tiny_tree_grab_creep", "heroes/hero_tiny/tiny_tree_grab", LUA_MODIFIER_MOTION_NONE)

function modifier_tiny_tree_grab_creep:OnCreated()
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.attack_range = self:GetSpecialValueFor("attack_range")
	
	self.splash_width = self:GetSpecialValueFor("splash_width")
	self.splash_range = self:GetSpecialValueFor("splash_range")
	self.splash_pct = self:GetSpecialValueFor("splash_pct")
end

function modifier_tiny_tree_grab_creep:OnDestroy()
	if IsClient() then return end
	self:GetAbility():SetCooldown()
end

function modifier_tiny_tree_grab_creep:DeclareFunctions()
	return {MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
			MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_tiny_tree_grab_creep:OnAttackLanded(params)
	if IsServer() then
		if params.attacker == self:GetParent() then
			if not params.attacker:IsIllusion() and not params.attacker:IsCleaveSuppressed() then
				local ability = self:GetAbility()
				local units = 0
				local direction = CalculateDirection( params.target, params.attacker)
				local splash = params.attacker:FindEnemyUnitsInCone( direction, params.target:GetAbsOrigin(), self.splash_width, self.splash_range)
				local splashFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_tiny/tiny_craggy_cleave.vpcf", PATTACH_POINT, params.attacker )
				ParticleManager:SetParticleControlTransformForward( splashFX, units, params.attacker:GetAbsOrigin(), direction ) 
				
				local splashDamage = params.original_damage * self.splash_pct
				for _, unit in ipairs( splash ) do
					if unit ~= params.target and not unit:HasModifier("modifier_tiny_tree_grab_creep_stun") then
						units = units + 1
						ParticleManager:SetParticleControl( splashFX, units, unit:GetAbsOrigin() )
						ability:DealDamage( params.attacker, unit, splashDamage, {damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL } )
					end
				end
				ParticleManager:ReleaseParticleIndex( splashFX )
			end
		end
	end
end

function modifier_tiny_tree_grab_creep:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_tiny_tree_grab_creep:GetModifierAttackRangeBonus()
	return self.attack_range
end

function modifier_tiny_tree_grab_creep:GetActivityTranslationModifiers()
	return "tree"
end