night_stalker_hunter_in_the_night = class({})

function night_stalker_hunter_in_the_night:GetCastRange( target, position )
	if self:GetCaster():HasShard() then
		return self:GetSpecialValueFor("shard_cast_range")
	end
end

function night_stalker_hunter_in_the_night:GetCooldown( iLvl )
	if self:GetCaster():HasShard() then
		return self:GetSpecialValueFor("shard_cooldown")
	end
end

function night_stalker_hunter_in_the_night:GetBehavior()
	if self:GetCaster():HasShard() then
		return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
	else
		return DOTA_ABILITY_BEHAVIOR_PASSIVE
	end
end

function night_stalker_hunter_in_the_night:GetIntrinsicModifierName()
	return "modifier_night_stalker_hunter_in_the_night_passive"
end

function night_stalker_hunter_in_the_night:CastFilterResultTarget( target )
	local caster = self:GetCaster()
	local flags = DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO
	if caster:GetCurrentVisionRange() == caster:GetNightTimeVisionRange() or caster:HasModifier("modifier_night_stalker_void_zone") then
	else
		flags = flags + DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS 
	end
	return UnitFilter( target, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, flags, caster:GetTeamNumber() )
end

function night_stalker_hunter_in_the_night:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	ParticleManager:FireRopeParticle( "particles/units/heroes/hero_night_stalker/nightstalker_shard_hunter.vpcf", PATTACH_POINT_FOLLOW, target, caster )
	EmitSoundOn( "Hero_Nightstalker.Hunter.Target", target )
	target:Kill( self, caster )
	
	caster:HealEvent( caster:GetMaxHealth() * self:GetSpecialValueFor("shard_hp_restore_pct") / 100, self, caster )
	caster:GiveMana( caster:GetMaxMana() * self:GetSpecialValueFor("shard_mana_restore_pct") / 100 )
end

modifier_night_stalker_hunter_in_the_night_passive = class({})
LinkLuaModifier("modifier_night_stalker_hunter_in_the_night_passive", "heroes/hero_night_stalker/night_stalker_hunter_in_the_night", LUA_MODIFIER_MOTION_NONE)

function modifier_night_stalker_hunter_in_the_night_passive:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink(0.2)
	end
end

function modifier_night_stalker_hunter_in_the_night_passive:OnRefresh()
	self.ms = self:GetSpecialValueFor("bonus_movement_speed_pct_night")
	self.as = self:GetSpecialValueFor("bonus_attack_speed_night")
	self.daytime_pct = self:GetSpecialValueFor("daytime_pct") / 100
end

function modifier_night_stalker_hunter_in_the_night_passive:OnIntervalThink()
	local caster = self:GetCaster()
	if GameRules:IsDaytime() and not self.daytime then
		self:ForceRefresh()
		self.daytime = true
		caster:ManageModelChanges()
	elseif not GameRules:IsDaytime() and self.daytime then
		self:ForceRefresh()
		self.daytime = false
		caster:ManageModelChanges()
	end
end

function modifier_night_stalker_hunter_in_the_night_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, 
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, 
			-- MODIFIER_PROPERTY_MODEL_CHANGE, 
			-- MODIFIER_EVENT_ON_MODEL_CHANGED, 
			-- MODIFIER_PROPERTY_PRESERVE_PARTICLES_ON_MODEL_CHANGE,
			MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING }
end


function modifier_night_stalker_hunter_in_the_night_passive:GetModifierMoveSpeedBonus_Percentage()
	local caster = self:GetParent()
	local multiplier = TernaryOperator( 1, caster:GetCurrentVisionRange() == caster:GetNightTimeVisionRange() or self:GetCaster():HasModifier("modifier_night_stalker_void_zone"), self.daytime_pct )
	return self:GetSpecialValueFor("bonus_movement_speed_pct_night") * multiplier
end

function modifier_night_stalker_hunter_in_the_night_passive:GetModifierAttackSpeedBonus_Constant()
	local caster = self:GetParent()
	local multiplier = TernaryOperator( 1, caster:GetCurrentVisionRange() == caster:GetNightTimeVisionRange() or self:GetCaster():HasModifier("modifier_night_stalker_void_zone"), self.daytime_pct )
	return self:GetSpecialValueFor("bonus_attack_speed_night") * multiplier
end

function modifier_night_stalker_hunter_in_the_night_passive:GetModifierStatusResistanceStacking()
	local caster = self:GetParent()
	local multiplier = TernaryOperator( 1, caster:GetCurrentVisionRange() == caster:GetNightTimeVisionRange() or self:GetCaster():HasModifier("modifier_night_stalker_void_zone"), self.daytime_pct )
	return self:GetSpecialValueFor("bonus_status_resist_night") * multiplier
end

-- function modifier_night_stalker_hunter_in_the_night_passive:GetModifierModelChange()
	-- local caster = self:GetParent()
	-- if caster:GetCurrentVisionRange() == caster:GetNightTimeVisionRange() or caster:HasModifier("modifier_night_stalker_void_zone") then
		-- return "models/heroes/nightstalker/nightstalker_night.vmdl"
	-- else
		-- return "models/heroes/nightstalker/nightstalker.vmdl"
	-- end
-- end

-- function modifier_night_stalker_hunter_in_the_night_passive:PreserveParticlesOnModelChanged()
	-- return 1
-- end

-- MODEL_TO_NIGHT = {
-- ["models/items/nightstalker/black_nihility/black_nihility_arms.vmdl"] = "models/items/nightstalker/black_nihility/black_nihility_night_arms.vmdl",
-- ["models/items/nightstalker/black_nihility/black_nihility_back.vmdl"] = "models/items/nightstalker/black_nihility/black_nihility_night_back.vmdl",
-- ["models/items/nightstalker/black_nihility/black_nihility_head.vmdl"] = "models/items/nightstalker/black_nihility/black_nihility_night_head.vmdl",
-- ["models/items/nightstalker/black_nihility/black_nihility_legs.vmdl"] = "models/items/nightstalker/black_nihility/black_nihility_night_legs.vmdl",
-- ["models/items/nightstalker/black_nihility/black_nihility_tail.vmdl"] = "models/items/nightstalker/black_nihility/black_nihility_night_tail.vmdl"}

-- function modifier_night_stalker_hunter_in_the_night_passive:OnModelChanged()
	-- local caster = self:GetParent()
	-- if IsServer() then
		-- if caster:GetCurrentVisionRange() == caster:GetNightTimeVisionRange() or caster:HasModifier("modifier_night_stalker_void_zone") then
			-- self.bones = {}
			-- local modelNames = {}
			-- for _, child in ipairs( caster:GetChildren() ) do
				-- if child:GetModelName() ~= "" then
					-- local modelName = MODEL_TO_NIGHT[child:GetModelName()] or child:GetModelName():match("(.*)%.vmdl") .. "_night.vmdl"
					-- if not modelNames[modelName] then
						-- local boneMerge = SpawnEntityFromTableSynchronous("prop_dynamic", { model = modelName })
						-- boneMerge:FollowEntity( caster, true )
						
						-- self.bones[boneMerge] = true
						-- modelNames[modelName] = true 
					-- end
				-- end
			-- end
		-- elseif self.bones then
			-- for boneMerge, active in pairs( self.bones ) do
				-- UTIL_Remove( boneMerge )
				-- self.bones[boneMerge] = nil
			-- end
		-- end
	-- end
-- end

function modifier_night_stalker_hunter_in_the_night_passive:IsHidden()
	return true
end