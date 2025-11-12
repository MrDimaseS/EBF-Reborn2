lycan_summon_wolves = class({})

function lycan_summon_wolves:OnSpellStart()
	local caster = self:GetCaster()
	caster.summonedWolves = caster.summonedWolves or {}
	for _, wolf in ipairs( caster.summonedWolves ) do
		if IsEntitySafe( wolf ) and wolf:IsAlive() then
            wolf:ForceKill(true)
        end
	end
	
	
	local startPos = caster:GetAbsOrigin()
	local wolfCount = self:GetSpecialValueFor("wolf_count")
	
	
	local distance = 200 or self:GetSpecialValueFor("spawn_distance")
	EmitSoundOn("Hero_Lycan.SummonWolves", caster)
	ParticleManager:FireParticle("particles/units/heroes/hero_lycan/lycan_summon_wolves_cast.vpcf", PATTACH_POINT_FOLLOW, caster)
	
	caster.summonedWolves = {}
	for i = 1, wolfCount do
		local angPoint = QAngle(0, ((-1)^i)*30, 0)
		local fv = caster:GetForwardVector()*((-1)^( math.ceil( i/2 ) -1 ) )
		local spawnOrigin = startPos + fv * distance
		local position = RotatePosition(startPos, angPoint, spawnOrigin)

		self:CreateWolf(position)
	end
end

function lycan_summon_wolves:CreateWolf(position, duration)
	local caster = self:GetCaster()
	local fDur = duration or self:GetSpecialValueFor("wolf_duration")
	local wolfIndex = self:GetSpecialValueFor("wolf_index")
	local wolf = caster:CreateSummon("npc_dota_lycan_wolf"..wolfIndex, position, fDur)
	wolf:SetForwardVector(caster:GetForwardVector())
	table.insert(caster.summonedWolves, wolf)
	
	self:ScaleWolf( wolf )
end

function lycan_summon_wolves:ScaleWolf( wolf )
	local wolfHP = self:GetSpecialValueFor("wolf_hp")
	local wolfDamage = self:GetSpecialValueFor("wolf_damage")
	
	wolf:SetCoreHealth(wolfHP)
	wolf:SetAverageBaseDamage(wolfDamage, 15)
	wolf:AddNewModifier(self:GetCaster(), self, "modifier_lycan_summon_wolves_handler",  {})
	wolf:AddNewModifier(self:GetCaster(), self, "modifier_generic_level_scaling_for_summons",  {})
	
	ParticleManager:FireParticle("particles/units/heroes/hero_lycan/lycan_summon_wolves_spawn.vpcf", PATTACH_POINT_FOLLOW, wolf)
end

modifier_lycan_summon_wolves_handler = class({})
LinkLuaModifier("modifier_lycan_summon_wolves_handler", "heroes/hero_lycan/lycan_summon_wolves", LUA_MODIFIER_MOTION_NONE)

function modifier_lycan_summon_wolves_handler:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self.hightail = self:GetParent():FindAbilityByName("lycan_summon_wolves_hightail")
		self.hamstring = self:GetParent():FindAbilityByName("lycan_summon_wolves_hamstring")
		self:StartIntervalThink( 0.25 )
	end
end

function modifier_lycan_summon_wolves_handler:OnRefresh()
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
end

function modifier_lycan_summon_wolves_handler:OnIntervalThink()
	if not self:GetAbility():GetAutoCastState() then return end
	local parent = self:GetParent()
	local caster = self:GetCaster()
	local target = caster:GetAggroTarget()
	if parent:GetAggroTarget() then 
		if self.hightail and self.hightail:IsFullyCastable() then
			parent:CastAbilityNoTarget( self.hightail, parent:GetPlayerOwnerID() )
			return 
		end
	end
	if target then
		parent:MoveToTargetToAttack( target )
		parent:SetAggroTarget( target )
	else
		parent:MoveToNPC( caster )
	end
end

function modifier_lycan_summon_wolves_handler:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end

function modifier_lycan_summon_wolves_handler:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_lycan_summon_wolves_handler:IsHidden()
	return true
end