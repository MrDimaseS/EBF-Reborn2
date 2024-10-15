
require("templates/persistent_modifier")
require("templates/toggle_modifier_base_class")

LinkLuaModifier( "status_immune", "modifier/status_immune.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_level_scaling_for_summons", "modifier/modifier_generic_level_scaling_for_summons.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_silence_generic", "modifier/modifier_silence_generic.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_hidden_generic", "modifier/modifier_hidden_generic.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_hide_healthbar", "modifier/modifier_hide_healthbar.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_last_man_standing", "modifier/modifier_last_man_standing.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_boss_enraged", "modifier/modifier_boss_enraged.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_hero_rage_system", "modifier/modifier_hero_rage_system.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_hero_stamina_system", "modifier/modifier_hero_stamina_system.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_thinker_hero_regeneration", "modifier/modifier_thinker_hero_regeneration.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_neutrals_ancestors_rage", "modifier/modifier_neutrals_ancestors_rage.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_special_effect_donator", "/modifiers/modifier_special_effect_donator.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier( "modifier_generic_attack_bonus", "libraries/modifiers/modifier_generic_attack_bonus.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_attack_bonus_pct", "libraries/modifiers/modifier_generic_attack_bonus_pct.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_suppress_cleave", "libraries/modifiers/modifier_generic_suppress_cleave.lua", LUA_MODIFIER_MOTION_NONE )

LinkLuaModifier( "bossHealthRescale", "modifier/bossHealthRescale.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "bossPowerScale", "modifier/bossPowerScale.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "healthBooster", "modifier/healthBooster.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_healthbar_dummy", "modifier/modifier_healthbar_dummy.lua", LUA_MODIFIER_MOTION_NONE )

if IsClient() then -- Load clientside utility lib
	print("client-side has been initialized")
	require("libraries/client_util")
end