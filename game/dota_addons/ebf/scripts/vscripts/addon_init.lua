
require("templates/persistent_modifier")
require("templates/toggle_modifier_base_class")

LinkLuaModifier( "playerStatRescale", "modifier/playerStatRescale.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "status_immune", "modifier/status_immune.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_silence_generic", "modifier/modifier_silence_generic.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_hidden_generic", "modifier/modifier_hidden_generic.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_hide_healthbar", "modifier/modifier_hide_healthbar.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_last_man_standing", "modifier/modifier_last_man_standing.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_boss_enraged", "modifier/modifier_boss_enraged.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_neutrals_ancestors_rage", "modifier/modifier_neutrals_ancestors_rage.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_special_effect_donator", "/modifiers/modifier_special_effect_donator.lua", LUA_MODIFIER_MOTION_NONE)

if IsClient() then -- Load clientside utility lib
	print("client-side has been initialized")
	require("libraries/client_util")
end