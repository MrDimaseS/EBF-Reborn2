(function() {
	var cfg = GameUI.CustomUIConfig().multiteam_top_scoreboard;
	if (cfg) {
		if (cfg.TeamOverlayXMLFile) {
			var teamId = $.GetContextPanel().GetAttributeInt("team_id", -1);
			$("#TeamOverlayXMLFile").SetAttributeInt("team_id", teamId);

			$("#TeamOverlayXMLFile").BLoadLayout(cfg.TeamOverlayXMLFile, false, false);
		}
	}
})();

function PortraitClicked() {
	// TODO: ctrl and alt click support
	Players.PlayerPortraitClicked($.GetContextPanel().GetAttributeInt("player_id", -1), false, false);
}