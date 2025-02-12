nyx_assassin_parasitize = class({})

function nyx_assassin_parasitize:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	EmitSoundOn("Hero_NyxAssassin.Vendetta", caster)
	ParticleManager:FireParticle("particles/units/heroes/hero_nyx_assassin/nyx_loadout.vpcf", PATTACH_POINT, caster, {})
	
	local parasitize = target:AddNewModifier(caster, self, "modifier_nyx_assassin_parasitize_host", {Duration = self:GetSpecialValueFor("duration")})
	caster:AddNewModifier(caster, self, "modifier_nyx_assassin_parasitize_parasite", {Duration = parasitize:GetRemainingTime()})
end

modifier_nyx_assassin_parasitize_host = class({})
LinkLuaModifier( "modifier_nyx_assassin_parasitize_host", "heroes/hero_nyx_assassin/nyx_assassin_parasitize.lua" ,LUA_MODIFIER_MOTION_NONE )
function modifier_nyx_assassin_parasitize_host:OnCreated(table)
    self.gain_control = self:GetSpecialValueFor("gain_control") == 1
    self.dmg_reduction = self:GetSpecialValueFor("dmg_reduction")
	
	if not IsServer() then return end
	local parent = self:GetParent()
	local caster = self:GetCaster()
	self._previousTeam = parent:GetTeamNumber()
	parent:SetTeam( DOTA_TEAM_BADGUYS )
	parent:SetOwner( caster )
	if self.gain_control then
		parent:SetControllableByPlayer(caster:GetPlayerID(), true)
	end
	self:StartIntervalThink( 0 )
end

function modifier_nyx_assassin_parasitize_host:OnDestroy()
	if not IsServer() then return end
	local parent = self:GetParent()
	local caster = self:GetCaster()
	
	parent:SetTeam( self._previousTeam )
	parent:SetOwner( nil )
	FindClearSpaceForUnit(caster, parent:GetAbsOrigin(), true )
	caster:RemoveModifierByName("modifier_nyx_assassin_parasitize_host")
	if self.gain_control then
		parent:SetControllableByPlayer(-1, true)
	end
end

function modifier_nyx_assassin_parasitize_host:OnIntervalThink()
	local parent = self:GetParent()
	local caster = self:GetCaster()
	
	caster:SetAbsOrigin( parent:GetAbsOrigin() )
	if not caster:HasModifier("modifier_nyx_assassin_parasitize_parasite") then
		self:Destroy()
	end
end

function modifier_nyx_assassin_parasitize_host:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_SPENT_MANA,
		MODIFIER_EVENT_ON_ABILITY_EXECUTED,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
	}
	return funcs
end

function modifier_nyx_assassin_parasitize_host:OnSpentMana(params)
	if params.unit ~= self:GetCaster() then return end
	local drain = math.min( self:GetParent():GetMana(), params.cost )
	if drain < 1 then return end
	self:GetParent():ReduceMana( drain )
	params.unit:GiveMana( drain )
end

function modifier_nyx_assassin_parasitize_host:OnAbilityExecuted(params)
	if params.unit == self:GetCaster() then
		if params.ability:GetAbilityName() == "nyx_assassin_impale" then
			params.ability:OnProjectileHit( self:GetParent(), params.unit:GetAbsOrigin() )
		elseif params.ability:GetAbilityName() == "nyx_assassin_jolt" then
			params.ability:Jolt( self:GetParent() )
		elseif params.ability:GetAbilityName() == "nyx_assassin_spiked_carapace" then
			params.ability:SpikedCarapaceStun( self:GetParent() )
		end
	end
end

function modifier_nyx_assassin_parasitize_host:GetModifierIncomingDamage_Percentage()
    return self.dmg_reduction
end

function modifier_nyx_assassin_parasitize_host:IsPurgable()
    return false
end

function modifier_nyx_assassin_parasitize_host:IsPurgeException()
    return false
end

function modifier_nyx_assassin_parasitize_host:IsDebuff()
    return true
end

modifier_nyx_assassin_parasitize_parasite = class({})
LinkLuaModifier( "modifier_nyx_assassin_parasitize_parasite", "heroes/hero_nyx_assassin/nyx_assassin_parasitize.lua" ,LUA_MODIFIER_MOTION_NONE )
function modifier_nyx_assassin_parasitize_parasite:OnCreated(table)
    if not IsServer() then return end
	self:GetCaster():AddNoDraw()
end

function modifier_nyx_assassin_parasitize_parasite:OnDestroy()
	if not IsServer() then return end
	self:GetCaster():RemoveNoDraw()
end

function modifier_nyx_assassin_parasitize_parasite:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_FLYING] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_UNTARGETABLE] = true
	}
end

function modifier_nyx_assassin_parasitize_parasite:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ORDER}
end

function modifier_nyx_assassin_parasitize_parasite:OnOrder( params )
	if params.unit == self:GetCaster() and (params.order_type == DOTA_UNIT_ORDER_STOP or params.order_type == DOTA_UNIT_ORDER_HOLD_POSITION) then
		self:Destroy()
	end
end

function modifier_nyx_assassin_parasitize_parasite:IsPurgable()
    return false
end

function modifier_nyx_assassin_parasitize_parasite:IsPurgeException()
    return false
end