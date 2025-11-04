tiny_toss_tree = class({})
LinkLuaModifier("modifier_tiny_toss_tree", "heroes/hero_tiny/tiny_toss_tree", LUA_MODIFIER_MOTION_NONE)

function tiny_toss_tree:IsStealable()
    return false
end

function tiny_toss_tree:IsHiddenWhenStolen()
    return false
end

function tiny_toss_tree:Spawn()
	if IsServer() then self:SetActivated( false ) end
end

function tiny_toss_tree:GetBehavior()
	if self:GetSpecialValueFor("channel_think") > 0 then
		return DOTA_ABILITY_BEHAVIOR_CHANNELLED + DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE
	else
		return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE
	end
end

function tiny_toss_tree:OnSpellStart()
    local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local position = self:GetCursorPosition()
	
	local speed = self:GetSpecialValueFor("speed")
	local radius = self:GetSpecialValueFor("splash_radius")
	local distance = CalculateDistance( caster, position )
	local direction = CalculateDirection( position, caster )
	self._projectiles = {}
	if caster:HasModifier("modifier_tiny_tree_grab") then
		local projectile = self:FireLinearProjectile("particles/units/heroes/hero_tiny/tiny_tree_linear_proj.vpcf", speed * direction, distance, radius )
		self._projectiles[projectile] = {tree = true}
	elseif caster:HasModifier("modifier_tiny_tree_grab_creep") then
		local projectile = self:FireLinearProjectile("", speed * direction, distance, caster._treeGrabUnit:GetPaddedCollisionRadius() * 2 )
		self._projectiles[projectile] = {tree = false, target = caster._treeGrabUnit}
	end
	
	caster:RemoveModifierByName("modifier_tiny_tree_grab")
	caster:RemoveModifierByName("modifier_tiny_tree_grab_creep")
	if IsEntitySafe( caster._treeGrabUnit ) then caster._treeGrabUnit:RemoveModifierByName("modifier_tiny_tree_grab_creep_stun") end
	self:SetActivated( false )
	
	caster:RemoveGesture( ACT_DOTA_CAST_ABILITY_4 )
	caster:StartGesture( ACT_DOTA_CAST_ABILITY_4 )
	if self:GetSpecialValueFor("channel_think") == 0 then
		Timers:CreateTimer( 0.66, function() caster:RemoveGesture( ACT_DOTA_CAST_ABILITY_4 ) end )
	else
		self._channelLastThink = 0
		self._channelFirePosition = position
	end
	caster:StartGesture( ACT_DOTA_CAST_ABILITY_4_END )
end

function tiny_toss_tree:OnChannelThink( dt )
	if self._channelLastThink > self:GetSpecialValueFor("channel_think") then
		self._channelLastThink = 0
		
		local caster = self:GetCaster()
	
		local speed = self:GetSpecialValueFor("speed")
		local radius = self:GetSpecialValueFor("splash_radius")
		
		local trees = GridNav:GetAllTreesAroundPoint(caster:GetAbsOrigin(), self:GetSpecialValueFor("grab_radius"), true)
		for _, tree in ipairs( trees ) do
			if tree:IsStanding() then
				tree:CutDown( caster:GetTeamNumber() )
				local distance = CalculateDistance( tree, self._channelFirePosition )
				local direction = CalculateDirection( self._channelFirePosition, tree )
				
				local projectile = self:FireLinearProjectile("particles/units/heroes/hero_tiny/tiny_tree_linear_proj.vpcf", speed * direction, distance, radius, {source = tree} )
				self._projectiles[projectile] = {tree = true}
				
				break
			end
			self:EndChannel( true )
		end
		
	end
	self._channelLastThink = self._channelLastThink + dt
end

function tiny_toss_tree:OnChannelFinish( interrupted )
	self:GetCaster():RemoveGesture( ACT_DOTA_CAST_ABILITY_4 ) 
end

function tiny_toss_tree:OnProjectileThinkHandle( projectileID )
	local projectile = self._projectiles[projectileID]
	if not projectile then return end
	if IsEntitySafe( projectile.target ) then
		projectile.target:SetAbsOrigin( GetGroundPosition(ProjectileManager:GetLinearProjectileLocation( projectileID ), projectile.target ) )
	end
end

function tiny_toss_tree:OnProjectileHitHandle( target, position, projectileID )
	local caster = self:GetCaster()
	local projectile = self._projectiles[projectileID]
	if not projectile then return end
	if IsEntitySafe( projectile.target ) and target == projectile.target then return end
	if target then
		caster:PerformGenericAttack(target, true, {neverMiss = true, bonusDamage = self:GetSpecialValueFor("bonus_damage"), suppressCleave = true} )
		if IsEntitySafe( projectile.target ) then
			self:DealDamage( caster, target, projectile.target:GetHealth(), {damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION} )
		end
	elseif IsEntitySafe( projectile.target ) then
		projectile.target:AttemptKill( self, caster )
	end
end