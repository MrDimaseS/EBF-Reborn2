item_nullifier = class({})

function item_nullifier:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	self:FireTrackingProjectile(self:GetProjectileFXName(), target, self:GetSpecialValueFor("projectile_speed"))
	EmitSoundOn( self:GetCastSoundName(), caster )
end

function item_nullifier:OnProjectileHit( target, position )
	if target then
		local caster = self:GetCaster()
		
		local modifierName = TernaryOperator( self:GetAlliedModifierName(), caster:IsSameTeam( target ), self:GetEnemyModifierName() )
		target:AddNewModifier( caster, self, modifierName, {duration = self:GetSpecialValueFor("duration")} )
		EmitSoundOn( self:GetTargetSoundName(), target )
	end
end

function item_nullifier:GetIntrinsicModifierName()
	return "modifier_item_nullifier_passive"
end

function item_nullifier:GetProjectileFXName()
	return "particles/items4_fx/nullifier_proj.vpcf"
end

function item_nullifier:GetCastSoundName()
	return "DOTA_Item.Nullifier.Cast"
end

function item_nullifier:GetTargetSoundName()
	return  "DOTA_Item.Nullifier.Target"
end

function item_nullifier:GetAlliedModifierName()
	return "modifier_item_nullifier_dispel"
end

function item_nullifier:GetEnemyModifierName()
	return "modifier_item_nullifier_dispel"
end

item_nullifier_2 = class(item_nullifier)
item_nullifier_3 = class(item_nullifier)
item_nullifier_4 = class(item_nullifier)

modifier_item_nullifier_dispel = class({})
LinkLuaModifier( "modifier_item_nullifier_dispel", "items/item_nullifier.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_nullifier_dispel:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink(0.25)
		
		if self.magic_immune then
			local magicFX = ParticleManager:CreateParticle( "particles/items_fx/black_king_bar_avatar.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
			self:AddEffect( magicFX )
		end
	end
end

function modifier_item_nullifier_dispel:OnRefresh()
	self.hard_dispel = self:GetSpecialValueFor("hard_dispel") == 1
	self.magic_immune = self:GetSpecialValueFor("magic_immune") == 1 and self:GetCaster():IsSameTeam( self:GetParent() )
	self.magic_resist = self:GetSpecialValueFor("magic_resist")
end

function modifier_item_nullifier_dispel:OnIntervalThink()
	self:GetParent():Dispel( self:GetCaster(), self.hard_dispel )
end

function modifier_item_nullifier_dispel:CheckState()
	if self.magic_immune then
		return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
	end
end

function modifier_item_nullifier_dispel:DeclareFunctions()
	return {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS}
end

function modifier_item_nullifier_dispel:GetModifierMagicalResistanceBonus()
	return self.magic_resist
end

function modifier_item_nullifier_dispel:GetEffectName()
	return "particles/items4_fx/nullifier_mute_debuff.vpcf"
end

function modifier_item_nullifier_dispel:GetStatusEffectName()
	if self.magic_immune then
		return "particles/status_fx/status_effect_avatar.vpcf"
	else
		return "particles/status_fx/status_effect_nullifier.vpcf"
	end
end

function modifier_item_nullifier_dispel:StatusEffectPriority()
	return 5
end

modifier_item_nullifier_passive = class({})
LinkLuaModifier( "modifier_item_nullifier_passive", "items/item_nullifier.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_nullifier_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_nullifier_passive:OnRefresh()
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.bonus_strength = self:GetSpecialValueFor("bonus_strength")
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
	self.bonus_regen = self:GetSpecialValueFor("bonus_regen")
end

function modifier_item_nullifier_passive:DeclareFunctions()
	return {
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
	}
end

function modifier_item_nullifier_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_nullifier_passive:GetModifierBonusStats_Strength()
	return self.bonus_strength
end

function modifier_item_nullifier_passive:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_item_nullifier_passive:GetModifierConstantHealthRegen()
	return self.bonus_regen
end

function modifier_item_nullifier_passive:IsHidden()
	return true
end

function modifier_item_nullifier_passive:IsPurgable()
	return false
end

function modifier_item_nullifier_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end