"use strict";


//=============================================================================
//=============================================================================
function _ScoreboardUpdater_SetTextSafe( panel, childName, textValue )
{
	if ( panel === null )
		return;
	var childPanel = panel.FindChildInLayoutFile( childName )
	
	if ( childPanel === null )
		return;
	childPanel.text = textValue;
}

function GetCurrentMMRForPlayer( playerId ){
	const netTable = CustomNetTables.GetTableValue("mmr", playerId.toString());
	if (netTable != undefined && netTable.mmr != undefined) {
		return netTable.mmr 
	} else { 
		return "N/A"
	}
}

//=============================================================================
//=============================================================================
function _ScoreboardUpdater_UpdatePlayerPanel(scoreboardConfig, playersContainer, playerId, localPlayerTeamId) {
	var playerPanelName = "_dynamic_player_" + playerId;
	var playerPanel = playersContainer.FindChild(playerPanelName);
	if (playerPanel === null) {
		playerPanel = $.CreatePanel("Panel", playersContainer, playerPanelName);
		playerPanel.SetAttributeInt("player_id", playerId);
		playerPanel.BLoadLayout(scoreboardConfig.playerXmlName, false, false);

		const netTable = CustomNetTables.GetTableValue("mmr", playerId.toString());
		const playsTable = CustomNetTables.GetTableValue("plays", playerId.toString());
		var rankMedal = playerPanel.FindChildInLayoutFile("RankMedal");
		$.Msg( netTable )
		let rankMedalClass = "";
		if (netTable != undefined && netTable.mmr != undefined && netTable?.mmr !== null) {
			rankMedalClass = "RankMedal" + MMRToRankMedal(netTable.mmr);
		
			rankMedal.SetPanelEvent("onmouseover", function() {
				$.DispatchEvent("DOTAShowTextTooltip", rankMedal, ("MMR: ") + GetCurrentMMRForPlayer(playerId));
			});
		
			rankMedal.SetPanelEvent("onmouseout", function() {
				$.DispatchEvent("DOTAHideTextTooltip");
			});
		
			if (rankMedal && !rankMedal.BHasClass(rankMedalClass)) {
				rankMedal.SetHasClass(rankMedalClass, true);
			}
		} else {
			rankMedalClass = "RankMedal0";
		
			var calibrationGamesLeft = playsTable?.plays !== undefined ? 10 - playsTable.plays : 10;
			rankMedal.SetPanelEvent("onmouseover", () => {
				$.DispatchEvent("DOTAShowTextTooltip", rankMedal, `Calibration games left: ${calibrationGamesLeft}`);
			});
			rankMedal.SetPanelEvent("onmouseout", () => {
				$.DispatchEvent("DOTAHideTextTooltip");
			});
		
			rankMedal.SetHasClass(rankMedalClass, true); 
		}

		const patTable = CustomNetTables.GetTableValue("patrons", playerId.toString());
		var patreonBadge = playerPanel.FindChildInLayoutFile("PatronBadge");
		if (patTable != undefined && patTable.tier != undefined && patTable.tier !== null) {
			if (patreonBadge) {
				patreonBadge.SetImage("file://{resources}/images/hud/tier" + patTable.tier + ".png");
				var tooltipText = ["Community Badge", "Supporter I Badge", "Supporter II Badge", "Supporter III Badge", "#trs", "#dev"][patTable.tier];
				patreonBadge.SetPanelEvent("onmouseover", function() {
					$.DispatchEvent("DOTAShowTextTooltip", tooltipText);
				});
				patreonBadge.SetPanelEvent("onmouseout", function() {
					$.DispatchEvent("DOTAHideTextTooltip");
				});
			}
		}

	}

	playerPanel.SetHasClass("is_local_player", (playerId == Game.GetLocalPlayerID()));

	var ultStateOrTime = PlayerUltimateStateOrTime_t.PLAYER_ULTIMATE_STATE_HIDDEN; // values > 0 mean on cooldown for that many seconds
	var goldValue = -1;
	var isTeammate = false;

	var playerInfo = Game.GetPlayerInfo(playerId);
	const netTable = CustomNetTables.GetTableValue("game_stats", playerId.toString());
	const mmrTable = CustomNetTables.GetTableValue("mmr", playerId.toString());
	if (playerInfo) {
		isTeammate = (playerInfo.player_team_id == localPlayerTeamId);
		if (isTeammate) {
			ultStateOrTime = Game.GetPlayerUltimateStateOrTime(playerId);
		}
		goldValue = playerInfo.player_gold;

		playerPanel.SetHasClass("player_dead", (playerInfo.player_respawn_seconds >= 0));
		playerPanel.SetHasClass("local_player_teammate", isTeammate && (playerId != Game.GetLocalPlayerID()));

		_ScoreboardUpdater_SetTextSafe(playerPanel, "RespawnTimer", "☠"); // value is rounded down so just add one for rounded-up
		_ScoreboardUpdater_SetTextSafe(playerPanel, "PlayerName", playerInfo.player_name);
		_ScoreboardUpdater_SetTextSafe(playerPanel, "Level", playerInfo.player_level);
		if (netTable == undefined || netTable == null) {
			_ScoreboardUpdater_SetTextSafe(playerPanel, "Kills", 0);
			_ScoreboardUpdater_SetTextSafe(playerPanel, "Deaths", 0);
			_ScoreboardUpdater_SetTextSafe(playerPanel, "Assists", 0);
			_ScoreboardUpdater_SetTextSafe(playerPanel, "PTier", 0);
			_ScoreboardUpdater_SetTextSafe(playerPanel, "MMRWin", 0);
			_ScoreboardUpdater_SetTextSafe(playerPanel, "MMRLoss", 0);
		} else {
			_ScoreboardUpdater_SetTextSafe(playerPanel, "Kills", formatNumber(Math.round(netTable.damage_dealt)));
			_ScoreboardUpdater_SetTextSafe(playerPanel, "Deaths", formatNumber(Math.round(netTable.damage_taken)));
			_ScoreboardUpdater_SetTextSafe(playerPanel, "Assists", formatNumber(Math.round(netTable.damage_healed)));
			if (mmrTable && mmrTable.win) {
				_ScoreboardUpdater_SetTextSafe(playerPanel, "MMRWin", ("+" + mmrTable.win));
			} else {
				_ScoreboardUpdater_SetTextSafe(playerPanel, "MMRWin", 0);
			}
			if (mmrTable && mmrTable.loss) {
				_ScoreboardUpdater_SetTextSafe(playerPanel, "MMRLoss", (mmrTable.loss));
			} else {
				_ScoreboardUpdater_SetTextSafe(playerPanel, "MMRLoss", 0);
			}
		}

		var winner = Game.GetGameWinner();
		if (winner == 2 && mmrTable && mmrTable.win) {
			var mmrChange = mmrTable.win;
			var mmrChangeLabel = playerPanel.FindChildInLayoutFile("MMRChange");
			if (mmrChangeLabel) {
				mmrChangeLabel.text = "+" + mmrChange;
				mmrChangeLabel.SetHasClass("PositiveChange", true);
				mmrChangeLabel.SetHasClass("NegativeChange", false);
			}
		} else if (winner == 3 && mmrTable && mmrTable.loss) {
			var mmrChange = mmrTable.loss;
			var mmrChangeLabel = playerPanel.FindChildInLayoutFile("MMRChange");
			if (mmrChangeLabel) {
				mmrChangeLabel.text = mmrChange;
				mmrChangeLabel.SetHasClass("PositiveChange", false);
				mmrChangeLabel.SetHasClass("NegativeChange", true);
			}
		}

		var playerPortrait = playerPanel.FindChildInLayoutFile("HeroIcon");
		if (playerPortrait) {
			if (playerInfo.player_selected_hero !== "") {
				playerPortrait.SetImage("file://{images}/heroes/" + playerInfo.player_selected_hero + ".png");
			} else {
				playerPortrait.SetImage("file://{images}/custom_game/unassigned.png");
			}
		}

		if (playerInfo.player_selected_hero_id == -1) {
			_ScoreboardUpdater_SetTextSafe(playerPanel, "HeroName", $.Localize("#DOTA_Scoreboard_Picking_Hero"))
		} else {
			_ScoreboardUpdater_SetTextSafe(playerPanel, "HeroName", $.Localize("#" + playerInfo.player_selected_hero))
		}

		var heroNameAndDescription = playerPanel.FindChildInLayoutFile("HeroNameAndDescription");
		if (heroNameAndDescription) {
			if (playerInfo.player_selected_hero_id == -1) {
				heroNameAndDescription.SetDialogVariable("hero_name", $.Localize("#DOTA_Scoreboard_Picking_Hero"));
			} else {
				heroNameAndDescription.SetDialogVariable("hero_name", $.Localize("#" + playerInfo.player_selected_hero));
			}
			heroNameAndDescription.SetDialogVariableInt("hero_level", playerInfo.player_level);
		}

		playerPanel.SetHasClass("player_connection_abandoned", playerInfo.player_connection_state == DOTAConnectionState_t.DOTA_CONNECTION_STATE_ABANDONED);
		playerPanel.SetHasClass("player_connection_failed", playerInfo.player_connection_state == DOTAConnectionState_t.DOTA_CONNECTION_STATE_FAILED);
		playerPanel.SetHasClass("player_connection_disconnected", playerInfo.player_connection_state == DOTAConnectionState_t.DOTA_CONNECTION_STATE_DISCONNECTED);

		var playerAvatar = playerPanel.FindChildInLayoutFile("AvatarImage");
		if (playerAvatar) {
			playerAvatar.steamid = playerInfo.player_steamid;
		}

		var playerColorBar = playerPanel.FindChildInLayoutFile("PlayerColorBar");
		if (playerColorBar !== null && GameUI.CustomUIConfig().team_colors) {
			// TODO: player color not team color?
			var teamColor = GameUI.CustomUIConfig().team_colors[playerInfo.player_team_id];
			if (teamColor) {
				playerColorBar.style.backgroundColor = teamColor;
			}
		}
	}

	var playerItemsContainer = playerPanel.FindChildInLayoutFile("PlayerItemsContainer");
	if (playerItemsContainer) {
		var playerItems = Game.GetPlayerItems(playerId);
		if (playerItems) {
			//		$.Msg( "playerItems = ", playerItems );
			for (var i = playerItems.inventory_slot_min; i < playerItems.inventory_slot_max; ++i) {
				var itemPanelName = "_dynamic_item_" + i;
				var itemPanel = playerItemsContainer.FindChild(itemPanelName);
				if (itemPanel === null) {
					itemPanel = $.CreatePanel("Image", playerItemsContainer, itemPanelName);
					itemPanel.AddClass("PlayerItem");
				}

				var itemInfo = playerItems.inventory[i];
				if (itemInfo) {
					var item_image_name = "file://{images}/items/" + itemInfo.item_name.replace("item_", "") + ".png"
					if (itemInfo.item_name.indexOf("recipe") >= 0) {
						item_image_name = "file://{images}/items/recipe.png"
					}
					itemPanel.SetImage(item_image_name);
				} else {
					itemPanel.SetImage("");
				}
			}
		}
	}

	if (isTeammate) {
		_ScoreboardUpdater_SetTextSafe(playerPanel, "TeammateGoldAmount", goldValue);
	}

	_ScoreboardUpdater_SetTextSafe(playerPanel, "PlayerGoldAmount", goldValue);

	playerPanel.SetHasClass("player_ultimate_ready", (ultStateOrTime == PlayerUltimateStateOrTime_t.PLAYER_ULTIMATE_STATE_READY));
	playerPanel.SetHasClass("player_ultimate_no_mana", (ultStateOrTime == PlayerUltimateStateOrTime_t.PLAYER_ULTIMATE_STATE_NO_MANA));
	playerPanel.SetHasClass("player_ultimate_not_leveled", (ultStateOrTime == PlayerUltimateStateOrTime_t.PLAYER_ULTIMATE_STATE_NOT_LEVELED));
	playerPanel.SetHasClass("player_ultimate_hidden", (ultStateOrTime == PlayerUltimateStateOrTime_t.PLAYER_ULTIMATE_STATE_HIDDEN));
	playerPanel.SetHasClass("player_ultimate_cooldown", (ultStateOrTime > 0));
	_ScoreboardUpdater_SetTextSafe(playerPanel, "PlayerUltimateCooldown", ultStateOrTime);
}

//=============================================================================
//=============================================================================
function _ScoreboardUpdater_UpdateTeamPanel( scoreboardConfig, containerPanel, teamDetails )
{
	if ( !containerPanel )
		return;

	var teamId = teamDetails.team_id;
//	$.Msg( "_ScoreboardUpdater_UpdateTeamPanel: ", teamId );

	var teamPanelName = "_dynamic_team_" + teamId;
	var teamPanel = containerPanel.FindChild( teamPanelName );
	if ( teamPanel === null )
	{
//		$.Msg( "UpdateTeamPanel.Create: ", teamPanelName, " = ", scoreboardConfig.teamXmlName );
		teamPanel = $.CreatePanel( "Panel", containerPanel, teamPanelName );
		teamPanel.SetAttributeInt( "team_id", teamId );
		teamPanel.BLoadLayout( scoreboardConfig.teamXmlName, false, false );

		var logo_xml = GameUI.CustomUIConfig().team_logo_xml;
		if ( logo_xml )
		{
			var teamLogoPanel = teamPanel.FindChildInLayoutFile( "TeamLogo" );
			if ( teamLogoPanel )
			{
				teamLogoPanel.SetAttributeInt( "team_id", teamId );
				teamLogoPanel.BLoadLayout( logo_xml, false, false );
			}
		}
	}
	
	var localPlayerTeamId = -1;
	var localPlayer = Game.GetLocalPlayerInfo();
	if ( localPlayer )
	{
		localPlayerTeamId = localPlayer.player_team_id;
	}
	teamPanel.SetHasClass( "local_player_team", localPlayerTeamId == teamId );
	teamPanel.SetHasClass( "not_local_player_team", localPlayerTeamId != teamId );

	var teamPlayers = Game.GetPlayerIDsOnTeam( teamId )
	var playersContainer = teamPanel.FindChildInLayoutFile( "PlayersContainer" );
	if ( playersContainer )
	{
		for ( var playerId of teamPlayers )
		{
			_ScoreboardUpdater_UpdatePlayerPanel( scoreboardConfig, playersContainer, playerId, localPlayerTeamId )
		}
	}
	
	teamPanel.SetHasClass( "no_players", (teamPlayers.length == 0) )
	teamPanel.SetHasClass( "one_player", (teamPlayers.length == 1) )
	
	const netTable = CustomNetTables.GetTableValue( "game_stats", "team" );
	if( netTable == undefined ){
		_ScoreboardUpdater_SetTextSafe( teamPanel, "TeamScore", 0 )
	} else {
		_ScoreboardUpdater_SetTextSafe( teamPanel, "TeamScore", formatNumber(netTable.midas_gold_earned) )
	}
	_ScoreboardUpdater_SetTextSafe( teamPanel, "TeamName", $.Localize( teamDetails.team_name ) )
	
	if ( GameUI.CustomUIConfig().team_colors )
	{
		var teamColor = GameUI.CustomUIConfig().team_colors[ teamId ];
		var teamColorPanel = teamPanel.FindChildInLayoutFile( "TeamColor" );
		
		teamColor = teamColor.replace( ";", "" );

		if ( teamColorPanel )
		{
			teamNamePanel.style.backgroundColor = teamColor + ";";
		}
		
		var teamColor_GradentFromTransparentLeft = teamPanel.FindChildInLayoutFile( "TeamColor_GradentFromTransparentLeft" );
		if ( teamColor_GradentFromTransparentLeft )
		{
			var gradientText = 'gradient( linear, 0% 0%, 800% 0%, from( #00000000 ), to( ' + teamColor + ' ) );';
//			$.Msg( gradientText );
			teamColor_GradentFromTransparentLeft.style.backgroundColor = gradientText;
		}
	}
	
	return teamPanel;
}

//=============================================================================
//=============================================================================
function _ScoreboardUpdater_ReorderTeam( scoreboardConfig, teamsParent, teamPanel, teamId, newPlace, prevPanel )
{
//	$.Msg( "UPDATE: ", GameUI.CustomUIConfig().teamsPrevPlace );
	var oldPlace = null;
	if ( GameUI.CustomUIConfig().teamsPrevPlace.length > teamId )
	{
		oldPlace = GameUI.CustomUIConfig().teamsPrevPlace[ teamId ];
	}
	GameUI.CustomUIConfig().teamsPrevPlace[ teamId ] = newPlace;
	
	if ( newPlace != oldPlace )
	{
//		$.Msg( "Team ", teamId, " : ", oldPlace, " --> ", newPlace );
		teamPanel.RemoveClass( "team_getting_worse" );
		teamPanel.RemoveClass( "team_getting_better" );
		if ( newPlace > oldPlace )
		{
			teamPanel.AddClass( "team_getting_worse" );
		}
		else if ( newPlace < oldPlace )
		{
			teamPanel.AddClass( "team_getting_better" );
		}
	}

	teamsParent.MoveChildAfter( teamPanel, prevPanel );
}

// sort / reorder as necessary
function compareFunc( a, b ) // GameUI.CustomUIConfig().sort_teams_compare_func;
{
	if ( a.team_score < b.team_score )
	{
		return 1; // [ B, A ]
	}
	else if ( a.team_score > b.team_score )
	{
		return -1; // [ A, B ]
	}
	else
	{
		return 0;
	}
};

function stableCompareFunc( a, b )
{
	var unstableCompare = compareFunc( a, b );
	if ( unstableCompare != 0 )
	{
		return unstableCompare;
	}
	
	if ( GameUI.CustomUIConfig().teamsPrevPlace.length <= a.team_id )
	{
		return 0;
	}
	
	if ( GameUI.CustomUIConfig().teamsPrevPlace.length <= b.team_id )
	{
		return 0;
	}
	
//			$.Msg( GameUI.CustomUIConfig().teamsPrevPlace );

	var a_prev = GameUI.CustomUIConfig().teamsPrevPlace[ a.team_id ];
	var b_prev = GameUI.CustomUIConfig().teamsPrevPlace[ b.team_id ];
	if ( a_prev < b_prev ) // [ A, B ]
	{
		return -1; // [ A, B ]
	}
	else if ( a_prev > b_prev ) // [ B, A ]
	{
		return 1; // [ B, A ]
	}
	else
	{
		return 0;
	}
};

const DICTKEY = {
			0: '',
			1: 'K',
			2: 'M',
			3: 'B',
			4: 'T',
			5: 'Q'
		};
		
function formatNumber( textValue ){
	var parsedInt = Number( textValue );
	if( parsedInt != null && parsedInt != undefined ){
		var exponent = 0;
		while( parsedInt > 10000 ){
			parsedInt = parsedInt / 1000;
			exponent++;
		}
		if( exponent == 0 ) {
			return Number(parsedInt).toFixed(0);
		} else {
			return Number(parsedInt).toFixed(2) + DICTKEY[exponent];
		}
	} else {
		return textValue;
	}
};

//=============================================================================
//=============================================================================
function _ScoreboardUpdater_UpdateAllTeamsAndPlayers( scoreboardConfig, teamsContainer )
{
//	$.Msg( "_ScoreboardUpdater_UpdateAllTeamsAndPlayers: ", scoreboardConfig );
	
	var teamsList = [];
	for ( var teamId of Game.GetAllTeamIDs() )
	{
		var team = Game.GetTeamDetails( teamId );

		// Replace score value with the combined player level
		team.team_score = 0;
		for ( var player of Game.GetPlayerIDsOnTeam( teamId ) )
		{
			team.team_score += Players.GetLevel( player ) - 1;
		}

		teamsList.push( team );
	}

	// update/create team panels
	var panelsByTeam = [];
	for ( var i = 0; i < teamsList.length; ++i )
	{
		var teamPanel = _ScoreboardUpdater_UpdateTeamPanel( scoreboardConfig, teamsContainer, teamsList[i] );
		if ( teamPanel )
		{
			panelsByTeam[ teamsList[i].team_id ] = teamPanel;
		}
	}
	
	if ( teamsList.length > 1 )
	{
//		$.Msg( "panelsByTeam: ", panelsByTeam );

		// sort
		teamsList.sort( stableCompareFunc );		

//		$.Msg( "POST: ", teamsAndPanels );

		// reorder the panels based on the sort
		var prevPanel = panelsByTeam[ teamsList[0].team_id ];
		for ( var i = 0; i < teamsList.length; ++i )
		{
			var teamId = teamsList[i].team_id;
			var teamPanel = panelsByTeam[ teamId ];
			_ScoreboardUpdater_ReorderTeam( scoreboardConfig, teamsContainer, teamPanel, teamId, i, prevPanel );
			prevPanel = teamPanel;
		}
//		$.Msg( GameUI.CustomUIConfig().teamsPrevPlace );
	}

//	$.Msg( "END _ScoreboardUpdater_UpdateAllTeamsAndPlayers: ", scoreboardConfig );
}


//=============================================================================
//=============================================================================
function ScoreboardUpdater_InitializeScoreboard( scoreboardConfig, scoreboardPanel )
{
	GameUI.CustomUIConfig().teamsPrevPlace = [];
	_ScoreboardUpdater_UpdateAllTeamsAndPlayers( scoreboardConfig, scoreboardPanel );
	return { "scoreboardConfig": scoreboardConfig, "scoreboardPanel":scoreboardPanel }
}


//=============================================================================
//=============================================================================
function ScoreboardUpdater_SetScoreboardActive( scoreboardHandle, isActive )
{
	if ( scoreboardHandle.scoreboardConfig === null || scoreboardHandle.scoreboardPanel === null )
	{
		return;
	}
	
	if ( isActive )
	{
		_ScoreboardUpdater_UpdateAllTeamsAndPlayers( scoreboardHandle.scoreboardConfig, scoreboardHandle.scoreboardPanel );
	}
}

//=============================================================================
//=============================================================================
function ScoreboardUpdater_GetTeamPanel( scoreboardHandle, teamId )
{
	if ( scoreboardHandle.scoreboardPanel === null )
	{
		return;
	}
	
	var teamPanelName = "_dynamic_team_" + teamId;
	return scoreboardHandle.scoreboardPanel.FindChild( teamPanelName );
}

//=============================================================================
//=============================================================================
function ScoreboardUpdater_GetSortedTeamInfoList( scoreboardHandle )
{
	var teamsList = [];
	for ( var teamId of Game.GetAllTeamIDs() )
	{
		teamsList.push( Game.GetTeamDetails( teamId ) );
	}

	if ( teamsList.length > 1 )
	{
		teamsList.sort( stableCompareFunc );		
	}
	
	return teamsList;
}

function MMRToRankMedal( mmr )
{
	if ( mmr == undefined ){
		return "0"
	} else {
		let medal = Math.min( 9, 1 + Math.floor(mmr / 1000) )
		if (medal == 9 ) {
			return "8c_psd"
		} else {
			return medal.toString()
		}
	}
}