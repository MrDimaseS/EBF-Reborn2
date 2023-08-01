enigma_malefice = class({})

function enigma_malefice:GetCooldown(lvl)
	return self.BaseClass.GetCooldown(self, lvl)
end

function enigma_malefice:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	caster:EmitSound( "Hero_Enigma.Malefice" )
	if target:TriggerSpellAbsorb(self) then return end
	local stun_instances = self:GetSpecialValueFor("stun_instances")
	target:AddNewModifier(caster, self, "modifier_enigma_malefice_debuff", {duration = (stun_instances-1) * self:GetSpecialValueFor("tick_rate")}):SetStackCount( stun_instances )
end

modifier_enigma_malefice_debuff = class({})
LinkLuaModifier("modifier_enigma_malefice_debuff", "heroes/hero_enigma/enigma_malefice", LUA_MODIFIER_MOTION_NONE)

function modifier_enigma_malefice_debuff:OnCreated()
	self:OnRefresh()
end

function modifier_enigma_malefice_debuff:OnStackCountChanged()
	if IsServer() and not self.hasBeenInitialized then
		self.tick = self.tick_rate * self:GetRemainingTime() / ( self.tick_rate * self:GetStackCount() )
		self:StartIntervalThink( 0 )
		self.firstTick = true
		self.hasBeenInitialized = true
	end
end

function modifier_enigma_malefice_debuff:OnRefresh()
	self.damage = self:GetSpecialValueFor("damage")
	self.stun = self:GetSpecialValueFor("stun_duration")
	self.tick_rate = self:GetSpecialValueFor("tick_rate")
	self.radius = TernaryOperator( self:GetSpecialValueFor("shard_spread_radius"), self:GetCaster():HasShard(), 0 )
	self.hasBeenInitialized = false
end

function modifier_enigma_malefice_debuff:OnIntervalThink()
	self:Malefice()
	self:StartIntervalThink( self.tick )
end

function modifier_enigma_malefice_debuff:Malefice()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local parent = self:GetParent()
	
	local position = parent:GetAbsOrigin()
	parent:EmitSound("Hero_Enigma.MaleficeTick")
	local wave = ParticleManager:FireParticle( "particles/units/heroes/hero_enigma/enigma_malefice_talent_mid.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent,{	[0] = position + Vector(0,0,64),
																																						[1] = Vector(5,0.5,self.radius),
																																						[2] = position + Vector(0,0,64)} )
	ability:DealDamage( caster, parent, self.damage )
	ability:Stun( parent, self.stun )
	
	if self.radius > 0 and (self:GetStackCount() - 1) >= 0 and not self.firstTick then
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( position, self.radius ) ) do
			if not enemy:HasModifier("modifier_enigma_malefice_debuff") then
				enemy:AddNewModifier( caster, ability, "modifier_enigma_malefice_debuff", {duration = self:GetStackCount() * self:GetSpecialValueFor("tick_rate")}):SetStackCount( self:GetStackCount() )
				break
			end
		end
	end
	self.firstTick = false
	self:DecrementStackCount()
	if self:GetStackCount() <= 0 then
		self:Destroy()
		return
	end
end

function modifier_enigma_malefice_debuff:GetEffectName()
	return "particles/units/heroes/hero_enigma/enigma_malefice.vpcf"
end

function modifier_enigma_malefice_debuff:GetStatusEffectName()
	return "particles/status_fx/status_effect_enigma_malefice.vpcf"
end

function modifier_enigma_malefice_debuff:StatusEffectPriority()
	return 1
end
