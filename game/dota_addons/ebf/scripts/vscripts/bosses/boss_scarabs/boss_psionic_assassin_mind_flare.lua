boss_psionic_assassin_mind_flare = class({})

function boss_psionic_assassin_mind_flare:GetIntrinsicModifierName()
	return "modifier_boss_psionic_assassin_mind_flare_handler"
end

function boss_psionic_assassin_mind_flare:OnSpellStart()
	local target = self:GetCursorTarget()
	
	EmitSoundOn( "Hero_NyxAssassin.Jolt.Cast", self:GetCaster() )
	self:MindFlare( target )
end

function boss_psionic_assassin_mind_flare:MindFlare( target )
	local caster = self:GetCaster()
	
	local damage = self:GetSpecialValueFor("base_damage")
	local jolt = caster:FindModifierByName(self:GetIntrinsicModifierName())
	if jolt then
		if not jolt.damage_tracker then jolt.damage_tracker = {} end
		if not jolt.damage_tracker[target:entindex()] then jolt.damage_tracker[target:entindex()] = {0} end
		for _, addedDamage in ipairs( jolt.damage_tracker[target:entindex()] ) do
			damage = damage + addedDamage
			jolt.damage_tracker[target:entindex()] = {0}
			print( damage, addedDamage )
		end
	end
	
	self:DealDamage( caster, target, damage )
	
	ParticleManager:FireRopeParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_jolt.vpcf", PATTACH_POINT_FOLLOW, caster, target)
	EmitSoundOn( "Hero_NyxAssassin.Jolt.Target", target )
end

modifier_boss_psionic_assassin_mind_flare_handler = class({})
LinkLuaModifier( "modifier_boss_psionic_assassin_mind_flare_handler", "bosses/boss_scarabs/boss_psionic_assassin_mind_flare.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_boss_psionic_assassin_mind_flare_handler:OnCreated()
	self:OnRefresh()
	if IsServer() then
		print("created!")
		self:StartIntervalThink( 1 )
	end
end

function modifier_boss_psionic_assassin_mind_flare_handler:OnRefresh()
	self.damage_tracker = {}
	self.damage_echo_duration = self:GetSpecialValueFor("damage_echo_duration")
end

function modifier_boss_psionic_assassin_mind_flare_handler:OnIntervalThink()
	print("dathinky")
	for enemy, damageTable in pairs( self.damage_tracker ) do
		table.insert( damageTable, 0, 1 )
		if #self.damage_tracker >= self.damage_echo_duration then
			table.remove( damageTable, 15 )
		end
	end
end

function modifier_boss_psionic_assassin_mind_flare_handler:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_boss_psionic_assassin_mind_flare_handler:OnTakeDamage( params )
	if params.attacker:HasAbility("boss_psionic_assassin_mind_flare") then
		if params.ability and params.ability:GetAbilityName() == "boss_psionic_assassin_mind_flare" then return end
		self.damage_tracker = self.damage_tracker or {}
		self.damage_tracker[params.unit:entindex()] = self.damage_tracker[params.unit:entindex()] or {0}
		self.damage_tracker[params.unit:entindex()][1] = self.damage_tracker[params.unit:entindex()][1] + params.damage
	end
end