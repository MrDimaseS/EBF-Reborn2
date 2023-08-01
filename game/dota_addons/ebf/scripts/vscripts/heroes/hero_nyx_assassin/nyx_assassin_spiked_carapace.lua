nyx_assassin_spiked_carapace = class({})

function nyx_assassin_spiked_carapace:IsStealable()
	return true
end

function nyx_assassin_spiked_carapace:GetIntrinsicModifierName()
	return "modifier_nyx_assassin_spiked_carapace_armor"
end

function nyx_assassin_spiked_carapace:GetBehavior()
	local caster = self:GetCaster()
	if caster:HasModifier("modifier_nyx_assassin_burrowed") then
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_UNRESTRICTED
	else
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET
	end
end

function nyx_assassin_spiked_carapace:OnSpellStart()
	local caster = self:GetCaster()
	
	local duration = self:GetSpecialValueFor("reflect_duration")
	caster:AddNewModifier(caster, self, "modifier_nyx_assassin_spiked_carapace_active", {Duration = duration})

	if caster:HasModifier("modifier_nyx_assassin_burrowed") then
		local radius = self:GetSpecialValueFor("burrow_radius")
		local stunDur = self:GetSpecialValueFor("stun_duration")
		EmitSoundOn("Hero_NyxAssassin.SpikedCarapace.Stun", caster)
		ParticleManager:FireParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_spiked_carapace_burrow.vpcf", PATTACH_POINT, caster, {[0]=caster:GetAbsOrigin(), [1]=Vector(radius, 0, 0)})
		local enemies = caster:FindEnemyUnitsInRadius(caster:GetAbsOrigin(), radius)
		for _, enemy in pairs(enemies) do
			if not enemy:TriggerSpellAbsorb(self) then
				self:Stun(enemy, stunDur, "particles/units/heroes/hero_nyx_assassin/nyx_assassin_spiked_carapace_hit.vpcf", {[1]=caster:GetAbsOrigin(), [2]=caster:GetAbsOrigin()})
			end
		end
	end
	EmitSoundOn("Hero_NyxAssassin.SpikedCarapace", caster)
end

modifier_nyx_assassin_spiked_carapace_armor = class({})
LinkLuaModifier( "modifier_nyx_assassin_spiked_carapace_armor", "heroes/hero_nyx_assassin/nyx_assassin_spiked_carapace.lua", LUA_MODIFIER_MOTION_NONE )
function modifier_nyx_assassin_spiked_carapace_armor:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
	}
	return funcs
end

function modifier_nyx_assassin_spiked_carapace_armor:GetModifierPhysicalArmorBonus()
	return self:GetSpecialValueFor("bonus_armor")
end

function modifier_nyx_assassin_spiked_carapace_armor:IsHidden()
	return true
end

function modifier_nyx_assassin_spiked_carapace_armor:IsPurgable()
	return false
end

function modifier_nyx_assassin_spiked_carapace_armor:IsPurgeException()
	return false
end

modifier_nyx_assassin_spiked_carapace_active = class({})
LinkLuaModifier( "modifier_nyx_assassin_spiked_carapace_active", "heroes/hero_nyx_assassin/nyx_assassin_spiked_carapace.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_nyx_assassin_spiked_carapace_active:OnCreated()
	self:OnRefresh()
end

function modifier_nyx_assassin_spiked_carapace_active:OnRefresh()
	self.stun_duration = self:GetSpecialValueFor("stun_duration")
	self.damage_reflect_pct = self:GetSpecialValueFor("damage_reflect_pct") / 100
	
	self.unitsHit = {}
end

function modifier_nyx_assassin_spiked_carapace_active:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
	}
	return funcs
end

function modifier_nyx_assassin_spiked_carapace_active:GetModifierIncomingDamage_Percentage(params)
	if not IsServer() or not params.attacker or not params.target or params.original_damage <= 0 then return end
	
	local ability = self:GetAbility()
	local stunDuration = self:GetTalentSpecialValueFor("stun_duration")
	if not params.attacker:IsMagicImmune() and not self.unitsHit[params.attacker] then
		local damageTaken = params.damage * self.damage_reflect_pct
		
		print("huh")
		ability:Stun(params.attacker, self.stun_duration, "particles/units/heroes/hero_nyx_assassin/nyx_assassin_spiked_carapace_hit.vpcf", {[1]=params.target:GetAbsOrigin(), [2]=params.target:GetAbsOrigin()})
		ability:DealDamage(params.target, params.attacker, damageTaken, {damage_type=params.damageType, damage_flags=DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_REFLECTION})
		
		EmitSoundOn("Hero_NyxAssassin.SpikedCarapace.Stun", params.target)
		
		self.unitsHit[params.attacker] = true
		return -999
	end
end

function modifier_nyx_assassin_spiked_carapace_active:GetEffectName()
	return "particles/units/heroes/hero_nyx_assassin/nyx_assassin_spiked_carapace.vpcf"
end