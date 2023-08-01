function ToggleVoiceMute() {
    const panel = $.GetContextPanel();
    const playerId = panel.GetAttributeInt("player_id", -1);
    if (playerId !== -1) {
        const isMuted = panel.BHasClass("player_muted");
        Game?.SetPlayerMutedVoice(playerId, !isMuted);
        panel.SetHasClass("player_muted", !isMuted);
    }
}

function ToggleTextMute() {
    const panel = $.GetContextPanel();
    const playerId = panel.GetAttributeInt("player_id", -1);
    if (playerId !== -1) {
        const isTextMuted = panel.BHasClass("player_text_muted");
        Game?.SetPlayerMutedText(playerId, !isTextMuted);
        panel.SetHasClass("player_text_muted", !isTextMuted);
    }
}



const LOCAL_PLAYER_ID = Game.GetLocalPlayerID();

function CreatePanelForPlayer(player_id) {
    const player_root = $.GetContextPanel().GetParent().FindChildTraverse(`_dynamic_player_${player_id}`);
	$.Msg( player_root );
    if (!player_root) return;

    const disable_help_button = player_root.FindChildTraverse("DisableHelpButton");
    const local_team = Players.GetTeam(LOCAL_PLAYER_ID);
    const team_id = Players.GetTeam(player_id);
	
	if( LOCAL_PLAYER_ID == player_id ) {
		disable_help_button.style.visibility = "collapse";
	}
	
    if (local_team == team_id) {
        disable_help_button.SetPanelEvent("onactivate", () => {
            GameEvents.SendCustomGameEventToServer("set_disable_help", {
                disable: disable_help_button.checked,
                to: player_id,
            });
            $.Msg (disable_help_button);
        });
    }
}

function RefreshDisableHelpList() {
    const disable_help = CustomNetTables.GetTableValue("disable_help", Players.GetLocalPlayer());
    if (!disable_help) return;

    const local_team = Players.GetTeam(LOCAL_PLAYER_ID);
    const players_roots = $.GetContextPanel().GetParent().FindChildrenWithClassTraverse("PlayerRoot");
    players_roots.forEach((player_root) => {
        const player_id = player_root.GetAttributeInt("player_id", -1);
        const team_id = Players.GetTeam(player_id);
        if (local_team == team_id) return;
        const disable_help_button = player_root.FindChildTraverse("DisableHelpButton");
        disable_help_button.checked = Boolean(disable_help[player_id]);
    });
}

(function () {
    const players = Game.GetAllPlayerIDs();
    players.forEach(player_id => CreatePanelForPlayer(player_id));

    GameEvents.Subscribe("set_disable_help_refresh", RefreshDisableHelpList);
})();
