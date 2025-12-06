boss_troll_warlord_flexible_warrior = class({})

function boss_troll_warlord_flexible_warrior:GetIntrinsicModifierName()
	return "modifier_boss_troll_warlord_flexible_warrior"
end

modifier_boss_troll_warlord_flexible_warrior = class({})
LinkLuaModifier( "modifier_boss_troll_warlord_flexible_warrior", "bosses/boss_troll_warlord/boss_troll_warlord_flexible_warrior", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_troll_warlord_flexible_warrior:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink( 0 )
	end
end

function modifier_boss_troll_warlord_flexible_warrior:OnRefresh()
	self.melee_armor = self:GetSpecialValueFor("melee_armor")
	self.melee_magic_resist = self:GetSpecialValueFor("melee_magic_resist")
	self.pacifist_bonus_movespeed = self:GetSpecialValueFor("pacifist_bonus_movespeed")
	
	self.melee_range = self:GetSpecialValueFor("melee_range")
	
	self.proc_chance = self:GetSpecialValueFor("proc_chance")
	self.fervor_bonus_proc_chance = self:GetSpecialValueFor("fervor_bonus_proc_chance")
end

function modifier_boss_troll_warlord_flexible_warrior:OnIntervalThink()
	local parent = self:GetParent() 
	local attackTarget = parent:GetAttackTarget()
	if not attackTarget then -- pacifist
		self:SetStackCount( 0 )
	elseif CalculateDistance( attackTarget, parent ) <= self.melee_range then -- melee
		self:SetStackCount( 1 )
	else -- ranged
		self:SetStackCount( 2 )
	end
end

function modifier_boss_troll_warlord_flexible_warrior:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_EVENT_ON_ATTACK }
end

function modifier_boss_troll_warlord_flexible_warrior:GetModifierMoveSpeedBonus_Percentage()
	if self:GetStackCount( ) == 0 then return self.pacifist_bonus_movespeed end
end

function modifier_boss_troll_warlord_flexible_warrior:GetModifierMagicalResistanceBonus()
	if self:GetStackCount( ) == 1 then return self.melee_magic_resist end
end

function modifier_boss_troll_warlord_flexible_warrior:GetModifierPhysicalArmorBonus()
	if self:GetStackCount( ) == 1 then return self.melee_armor end
end

function modifier_boss_troll_warlord_flexible_warrior:OnAttack( params )
	local parent = self:GetParent()
	if params.attacker ~= parent then return end
	local fervorStacks = 0
	local fervor = parent:FindModifierByName("modifier_boss_troll_warlord_fervor_attack_speed")
	if fervor then
		fervorStacks = fervor:GetStackCount()
	end
	local procChance = self.proc_chance + fervorStacks * self.fervor_bonus_proc_chance
	local proc = self:RollPRNG( procChance )
	if proc then
		if self:GetStackCount( ) == 1 then
			parent.dance:SummonWhirlingAxe( )
		elseif self:GetStackCount( ) == 2 then
			parent.hurl:HurlAxe( params.target )
		end
	end
end