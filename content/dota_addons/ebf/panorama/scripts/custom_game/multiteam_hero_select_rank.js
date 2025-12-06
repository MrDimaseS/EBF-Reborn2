"use strict";


const pickScreenHud = $.GetContextPanel().GetParent().GetParent().GetParent();
const mainHud = pickScreenHud.FindChildTraverse("PreGame");

(function() {
	// setup map system
	const dotaMap = mainHud.FindChildTraverse("HeroPickMinimap")
	if (dotaMap !== null && dotaMap !== undefined) {
		const mapData = CustomNetTables.GetTableValue("game_state", "map_properties");
		if(mapData.map == "peaks_of_screeauk"){
			dotaMap.style.backgroundImage = 'url("s2r://materials/overviews/peaks_of_screeauk_tga_fee32dc3.vtex")';
		} else if(mapData.map == "narrow_mazes"){
			dotaMap.style.backgroundImage = 'url("s2r://materials/overviews/narrow_mazes_tga_1c8cdefd.vtex")';
		} else if(mapData.map == "fields_of_carnage"){
			dotaMap.style.backgroundImage = 'url("s2r://materials/overviews/fields_of_carnage_tga_98ff0b56.vtex")';
		} else if(mapData.map == "immortal_halls"){
			dotaMap.style.backgroundImage = 'url("s2r://materials/overviews/immortal_halls_tga_ef9f79b2.vtex")';
		}
		dotaMap.style.border = '2px solid silver';
		dotaMap.style.saturation = "0.8";
		dotaMap.style.brightness = "0.4";
		const dotaMapClutter = dotaMap.Children();
		// hide clutter
		for (let clutter of dotaMapClutter) {
			clutter.style.opacity = "0";
		}
		
		const mapParent = dotaMap.GetParent()
		let dotaTitle = mapParent.FindChildTraverse("HeroPickMinimapTitle");
		if (dotaTitle === null) {
			dotaTitle = $.CreatePanel("Label", $.GetContextPanel(), "HeroPickMinimapTitle");
			dotaTitle.SetParent(dotaMap) 
		} 
		if (dotaTitle !== null)
		{
			dotaTitle.text = $.Localize("#ebf_"+mapData.map);
			dotaTitle.style.fontSize = "24px"
			dotaTitle.style.color = "white"
			dotaTitle.style.horizontalAlign = "center"
			dotaTitle.style.verticalAlign = "top"
			dotaTitle.style.textShadow = "3px 3px 0 #000, -3px 3px 0 #000, -3px -3px 0 #000, 3px -3px 0 #000";
			dotaTitle.style.opacity = "1.0"
		}
		
		// setup diff vote system
		
		OnUpdateDifficultyVotes();
		GameEvents.Subscribe("dota_player_difficulty_voted", OnUpdateDifficultyVotes);
    }
})();

function OnUpdateDifficultyVotes()
{
	const mapData = CustomNetTables.GetTableValue("game_state", "map_properties");
	const rightContainer = mainHud.FindChildTraverse("RightContainer");
	if (rightContainer !== null && rightContainer !== undefined) {
		rightContainer.style.visibility = "visible";
		const navBar = rightContainer.FindChildTraverse("HeroLockedNav");
		const tabsToHide = navBar.FindChildTraverse("GuidesTabButton");
		tabsToHide.style.visibility = "collapse";
		const tabsSeperator = navBar.GetChild( navBar.GetChildIndex(tabsToHide)-1 );
		tabsSeperator.style.visibility = "collapse";
		
		const strategyTab = rightContainer.FindChildTraverse("StrategyTab");
		const strategyMap = strategyTab.FindChildTraverse("StrategyMinimap");
		if(mapData.map == "peaks_of_screeauk"){
			strategyMap.style.backgroundImage = 'url("s2r://materials/overviews/peaks_of_screeauk_tga_fee32dc3.vtex")';
		} else if(mapData.map == "narrow_mazes"){
			strategyMap.style.backgroundImage = 'url("s2r://materials/overviews/narrow_mazes_tga_1c8cdefd.vtex")';
		} else if(mapData.map == "fields_of_carnage"){
			strategyMap.style.backgroundImage = 'url("s2r://materials/overviews/fields_of_carnage_tga_98ff0b56.vtex")';
		} else if(mapData.map == "immortal_halls"){
			strategyMap.style.backgroundImage = 'url("s2r://materials/overviews/immortal_halls_tga_ef9f79b2.vtex")';
		}
		const startingItems = strategyTab.FindChildTraverse("StartingItems");
		startingItems.style.visibility = "collapse";
		
		// implement voting row
		let main = strategyTab.FindChildTraverse("StrategyMapControls");
		let container = main.FindChildTraverse("DifficultySelectionControl");
		
		if(container == undefined){
			container = $.CreatePanel("Panel", main, "DifficultySelectionControl");
			container.SetParent(main)
			container.AddClass( "StrategyControl" )
			let header = $.CreatePanel("Panel", container, "DifficultySelectionHeader");
			header.AddClass( "StrategyControlHeader" )
			let title = $.CreatePanel("Label", header, "DifficultySelectionTitle");
			title.AddClass( "StrategyControlTitle" )
			title.text = "VOTE FOR DIFFICULTY"
			let filler = $.CreatePanel("Label", header, "DifficultySelectionFiller");
			filler.AddClass( "FillWidth" )
			let tally = $.CreatePanel("Label", header, "DifficultySelectionStatusText");
			tally.AddClass( "StrategyControlStatusText" )
			mapData.difficulty
			tally.text = "0/" + Object.keys(mapData.difficulty).length
			let body = $.CreatePanel("Panel", container, "DifficultySelectionList");
			body.style.flowChildren = "right";
			for(let i = 1;i<=4;i++){
				let difficultyIcon = $.CreatePanel("Image", body, "DifficultyButton" + i);
				$.Msg( difficultyIcon )
				difficultyIcon.style.width = "40px";
				difficultyIcon.style.height = "40px";
				difficultyIcon.SetImage('file://{images}/rank_tier_icons/mini/rank'+(i*2)+'_psd.vtex');
				
				difficultyIcon._saturation = 1;
				difficultyIcon._brightness = 1;
				let descriptionText = $.Localize("#ebf_difficulty_" + i + "_Description") + $.Localize("#ebf_" + mapData.gamemode + "_difficulty_" + i + "_Description")
				difficultyIcon.SetPanelEvent("onmouseover", () => {
				$.DispatchEvent("DOTAShowTextTooltip", difficultyIcon, );
					$.DispatchEvent( "DOTAShowTitleTextTooltip", difficultyIcon, $.Localize("#ebf_difficulty_" + i), descriptionText )
					difficultyIcon.style.saturation = difficultyIcon._saturation * 0.7;
					difficultyIcon.style.brightness = difficultyIcon._brightness * 2;
				});
				difficultyIcon.SetPanelEvent("onmouseout", () => {
					$.DispatchEvent("DOTAHideTitleTextTooltip");
					difficultyIcon.style.saturation = difficultyIcon._saturation;
					difficultyIcon.style.brightness = difficultyIcon._brightness;
				});
				difficultyIcon.SetPanelEvent("onactivate", function(){
					GameEvents.SendCustomGameEventToServer( "player_voted_difficulty", {pID : Players.GetLocalPlayer(), vote : i} )
				})
			}
		} else {
			const tally = container.FindChildTraverse("DifficultySelectionStatusText");
			let votes = 0
			for (const [key, value] of Object.entries(mapData.difficulty)) {
				if(value > 0 ){
					votes++;
					if(key == Players.GetLocalPlayer()){
						for(let i = 1;i<=4;i++){
							const difficultyIcon = container.FindChildTraverse("DifficultyButton" + i );

							if (value == i){
								difficultyIcon._saturation = 1;
								difficultyIcon._brightness = 1;
							} else {
								difficultyIcon._saturation = 0.2;
								difficultyIcon._brightness = 0.2;
							}
							difficultyIcon.style.saturation = difficultyIcon._saturation;
							difficultyIcon.style.brightness = difficultyIcon._brightness;
						}
					}
				}
			}
			tally.text = votes + "/" + Object.keys(mapData.difficulty).length
		}
	}
}

function OnUpdateHeroSelection() {
	for (var teamId of Game.GetAllTeamIDs()) {
		UpdateTeam(teamId);
	}
}

function UpdateTeam(teamId) {
	var teamPanelName = "team_" + teamId;
	var teamPanel = $("#" + teamPanelName);
	var teamPlayers = Game.GetPlayerIDsOnTeam(teamId);
	teamPanel.SetHasClass("no_players", (teamPlayers.length == 0));
	for (var playerId of teamPlayers) {
		UpdatePlayer(teamPanel, playerId);
	}
}

function UpdatePlayer(teamPanel, playerId) {
	var playerContainer = teamPanel.FindChildInLayoutFile("PlayersContainer");
	var playerPanelName = "player_" + playerId;
	var playerPanel = playerContainer.FindChild(playerPanelName);

	if (playerPanel === null) {
		playerPanel = $.CreatePanel("Image", playerContainer, playerPanelName);
		playerPanel.BLoadLayout("file://{resources}/layout/custom_game/multiteam_hero_select_overlay_player.xml", false, false);
		playerPanel.AddClass("PlayerPanel");
	}

	var heroMedal = playerPanel.FindChildInLayoutFile("HeroRank");
	var heroMedalStars = playerPanel.FindChildInLayoutFile("HeroRankStars");
	var rankPosLabel = playerPanel.FindChildInLayoutFile("RankPos");

	const heroTable = CustomNetTables.GetTableValue("mmr", playerId.toString());
	// const playsTable = CustomNetTables.GetTableValue("plays", playerId.toString());
	const steamIDData = CustomNetTables.GetTableValue("steamID", playerId.toString());
	const steamID = steamIDData ? steamIDData.steamid : "";
	const leaderboardTable = CustomNetTables.GetTableValue("game_state", "leaderboard_mmr");
	const leaderboardArray = leaderboardTable ? Object.values(leaderboardTable) : [];


	if (heroMedal) {
		$.Schedule(0.1, function() {
		  if (heroTable) {
			const mmr = heroTable.mmr;
			const playerInLeaderboard = leaderboardArray.some(item => item.steamID === steamID);

			if (playerInLeaderboard && heroTable.mmr > 9000) {
			  const lb_playerRank = leaderboardArray.findIndex(item => item.steamID === steamID);
			  if (lb_playerRank !== -1) {
				const playerPosition = lb_playerRank + 1;
				rankPosLabel.text = playerPosition.toString();
				if (playerPosition <= 10) {
				  heroMedal.SetImage(`file://{images}/hero_selection/rank8c_psd.png`);
				  heroMedal.SetPanelEvent("onmouseover", () => {
					$.DispatchEvent("DOTAShowTextTooltip", heroMedal, `MMR: ${GetCurrentMMRForPlayer(playerId)}`);
				  });
				  heroMedal.SetPanelEvent("onmouseout", () => {
					$.DispatchEvent("DOTAHideTextTooltip");
				  });
				} else if (playerPosition <= 100) {
				  heroMedal.SetImage(`file://{images}/hero_selection/rank8b_psd.png`);
				  heroMedal.SetPanelEvent("onmouseover", () => {
					$.DispatchEvent("DOTAShowTextTooltip", heroMedal, `MMR: ${GetCurrentMMRForPlayer(playerId)}`);
				  });
				  heroMedal.SetPanelEvent("onmouseout", () => {
					$.DispatchEvent("DOTAHideTextTooltip");
				  });
				}
			  }
			} else {
			  heroMedal.SetImage(`file://{images}/hero_selection/rank${MMRToRankMedal(mmr)}.png`);
			  heroMedal.SetPanelEvent("onmouseover", () => {
				$.DispatchEvent("DOTAShowTextTooltip", heroMedal, `MMR: ${GetCurrentMMRForPlayer(playerId)}`);
			  });
			  heroMedal.SetPanelEvent("onmouseout", () => {
				$.DispatchEvent("DOTAHideTextTooltip");
			  });
			}
	  
			if (heroMedalStars) {
			  heroMedalStars.SetImage(`file://{images}/hero_selection/star_${GetStarCount(mmr)}.png`);
			  heroMedalStars.imageHasBeenSet = true;
			}
		  }
		});
	  }
	  

	var playerInfo = Game.GetPlayerInfo(playerId);
	if (!playerInfo)
		return;

	var localPlayerInfo = Game.GetLocalPlayerInfo();
	if (!localPlayerInfo)
		return;

	var localPlayerTeamId = localPlayerInfo.player_team_id;
	var playerPortrait = playerPanel.FindChildInLayoutFile("PlayerPortrait");

	if (playerId == localPlayerInfo.player_id) {
		playerPanel.AddClass("is_local_player");
	}

	if (playerInfo.player_selected_hero !== "") {
		playerPortrait.SetImage("file://{images}/heroes/" + playerInfo.player_selected_hero + ".png");
		playerPanel.SetHasClass("hero_selected", true);
		playerPanel.SetHasClass("hero_highlighted", false);
	} else if (playerInfo.possible_hero_selection !== "" && (playerInfo.player_team_id == localPlayerTeamId)) {
		playerPortrait.SetImage("file://{images}/heroes/npc_dota_hero_" + playerInfo.possible_hero_selection + ".png");
		playerPanel.SetHasClass("hero_selected", false);
		playerPanel.SetHasClass("hero_highlighted", true);
	} else {
		playerPortrait.SetImage("file://{images}/custom_game/unassigned.png");
	}

	var playerName = playerPanel.FindChildInLayoutFile("PlayerName");
	playerName.text = playerInfo.player_name;

	playerPanel.SetHasClass("is_local_player", (playerId == Game.GetLocalPlayerID()));
}

function GetCurrentMMRForPlayer(playerId) {
	const netTable = CustomNetTables.GetTableValue("mmr", playerId.toString());
	if (netTable != undefined && netTable.mmr != undefined) {
		return netTable.mmr;
	} else {
		return "N/A";
	}
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

function GetStarCount(mmr) {
	if (mmr === undefined) {
		return "0";
	} else {
		return Math.floor( 1 + (mmr % 1000) / 200 ).toString();
	}
}

function UpdateTimer() {
	var gameTime = Game.GetGameTime();
	var transitionTime = Game.GetStateTransitionTime();

	var timerValue = Math.max(0, Math.floor(transitionTime - gameTime));

	if (Game.GameStateIsAfter(DOTA_GameState.DOTA_GAMERULES_STATE_HERO_SELECTION)) {
		timerValue = 0;
	}
	$("#TimerPanel").SetDialogVariableInt("timer_seconds", timerValue);

	var banPhaseInstructions = $("#BanPhaseInstructions");
	var pickPhaseInstructions = $("#PickPhaseInstructions");

	var bIsInBanPhase = Game.IsInBanPhase();

	banPhaseInstructions.SetHasClass("Visible", bIsInBanPhase == true);
	pickPhaseInstructions.SetHasClass("Visible", bIsInBanPhase == false);

	$.Schedule(0.1, UpdateTimer);
}

function UpdateHeroCards(){
	const heroFacetData = CustomNetTables.GetTableValue("game_state", "reworked_heroes");
	let heroGrid = mainHud.FindChildTraverse("HeroGrid").FindChildTraverse("GridCategories")
	if (heroGrid.Children().length <= 0){
		$.Schedule( 0.03, UpdateHeroCards )
		return;
	}
	for (let gridCategory of heroGrid.Children() ) {
		let heroList = gridCategory.FindChildTraverse("HeroList")
		for (let heroCard of heroList.Children() ) {
			let heroImage = heroCard.FindChildTraverse("HeroImage")
			let heroFacetRank = heroFacetData["npc_dota_hero_" + heroImage.heroname]
			if ( heroFacetRank != undefined ){
				heroImage.style.border = "2px";
				heroImage.style.borderStyle = "solid";
					heroImage.style.borderRadius = "5px";
				if (heroFacetRank == 1){
					heroImage.style.borderColor = "#e6e6e6";
				} else if (heroFacetRank == 2){
					heroImage.style.borderColor = "#d3af37";
				}
			}
		}
	}
}

(function() {
	var bLargeGame = Game.GetAllPlayerIDs().length >= 12;

	var localPlayerTeamId = Game.GetLocalPlayerInfo().player_team_id;
	var first = true;
	var teamsContainer = $("#HeroSelectTeamsContainer");
	var teamsContainer2 = $("#HeroSelectTeamsContainer2");
	$.CreatePanel("Panel", teamsContainer, "EndSpacer");
	$.CreatePanel("Panel", teamsContainer2, "EndSpacer");

	var timerPanel = $.CreatePanel("Panel", $.GetContextPanel(), "TimerPanel");
	timerPanel.BLoadLayout("file://{resources}/layout/custom_game/multiteam_hero_select_overlay_timer.xml", false, false);

	var nTeamsCreated = 0;
	var nTeams = Game.GetAllTeamIDs().length
	for (var teamId of Game.GetAllTeamIDs()) {
		var teamPanelToUse = null;
		if (bLargeGame && nTeamsCreated >= (nTeams / 2)) {
			teamPanelToUse = teamsContainer2;
		} else {
			teamPanelToUse = teamsContainer;

		}

		$.CreatePanel("Panel", teamPanelToUse, "Spacer");

		var teamPanelName = "team_" + teamId;
		var teamPanel = $.CreatePanel("Panel", teamPanelToUse, teamPanelName);
		teamPanel.BLoadLayout("file://{resources}/layout/custom_game/multiteam_hero_select_overlay_team.xml", false, false);
		var teamName = teamPanel.FindChildInLayoutFile("TeamName");
		if (teamName) {
			teamName.text = $.Localize(Game.GetTeamDetails(teamId).team_name);
		}

		var logo_xml = GameUI.CustomUIConfig().team_logo_xml;
		if (logo_xml) {
			var teamLogoPanel = teamPanel.FindChildInLayoutFile("TeamLogo");
			teamLogoPanel.SetAttributeInt("team_id", teamId);
			teamLogoPanel.BLoadLayout(logo_xml, false, false);
		}

		var teamGradient = teamPanel.FindChildInLayoutFile("TeamGradient");
		if (teamGradient && GameUI.CustomUIConfig().team_colors) {
			var teamColor = GameUI.CustomUIConfig().team_colors[teamId];
			teamColor = teamColor.replace(";", "");
			var gradientText = 'gradient( linear, 0% 0%, 0% 100%, from( ' + teamColor + '40  ), to( #00000000 ) );';
			teamGradient.style.backgroundColor = gradientText;
		}

		if (teamName) {
			teamName.text = $.Localize(Game.GetTeamDetails(teamId).team_name);
		}
		teamPanel.AddClass("TeamPanel");

		if (teamId === localPlayerTeamId) {
			teamPanel.AddClass("local_player_team");
		} else {
			teamPanel.AddClass("not_local_player_team");
		}
		nTeamsCreated = nTeamsCreated + 1;
	}

	$.CreatePanel("Panel", teamsContainer, "EndSpacer");
	$.CreatePanel("Panel", teamsContainer2, "EndSpacer");

	OnUpdateHeroSelection();
	GameEvents.Subscribe("dota_player_hero_selection_dirty", OnUpdateHeroSelection);
	CustomNetTables.SubscribeNetTableListener("mmr", OnUpdateHeroSelection);
	GameEvents.Subscribe("dota_player_update_hero_selection", OnUpdateHeroSelection);

	UpdateTimer();
	
	// facet reworks
	UpdateHeroCards()
})();