(function () {
	var mmrLeaderboard = $.GetContextPanel().FindChildTraverse("mmr_leaderboard");

	// Function to update the leaderboard
	function updateLeaderboard() {
		// Get the leaderboard data from the net table
		var leaderboardData_mmr = CustomNetTables.GetTableValue("game_state", "leaderboard_mmr");
		// Iterate over the leaderboard data
		for (var index in leaderboardData_mmr) {
			if (leaderboardData_mmr.hasOwnProperty(index)) {
				var data = leaderboardData_mmr[index];
				var panel = mmrLeaderboard.FindChildTraverse(index);
				var losses = data.plays - data.wins;
				var winrate = (data.wins / data.plays) * 100;
				winrate = winrate.toFixed(2);

				if (!panel) {
					panel = $.CreatePanel("Panel", mmrLeaderboard, index);
					panel.BLoadLayoutSnippet("RankInfoPanel");
					panel.SetAttributeInt("index", parseInt(index)); // Convert index to number
				}

				panel.FindChildTraverse("lblRank").text = panel.GetAttributeInt("index", -1).toString();
				panel.FindChildTraverse("imgAvatar").steamid = data.steamID;
				panel.FindChildTraverse("SteamName").steamid = data.steamID;
				panel.FindChildTraverse("mmr").text = data.mmr;
				panel.FindChildTraverse("plays").text = data.plays;
				panel.FindChildTraverse("wins").text = data.wins;
				panel.FindChildTraverse("losses").text = losses;
				panel.FindChildTraverse("winrate").text = winrate + "%";
			}
		}
	}

	// Function to start the script after a short delay
	function startScript() {
		UpdatePlayer();
		$.Schedule(0.1, function () {
			updateLeaderboard();

			// Set up a periodic timer to update the leaderboard every 5 seconds (adjust as needed)
			$.Schedule(5, function () {
				updateLeaderboard();

			});
		});
	}

	// Start the script
	startScript();
})();


(function() {
	// Function to update the dashboard stats
	function dashStatUpdate(playerId) {
	  playerId = playerId || Game.GetLocalPlayerID();
  
	  const playsTable = CustomNetTables.GetTableValue("plays", playerId.toString());
	  const winTable = CustomNetTables.GetTableValue("wins", playerId.toString());
  
	  if (playsTable != undefined && playsTable.plays != undefined) {
		const dashTotalPlays = $.GetContextPanel().FindChildInLayoutFile("lb_total");
		if (dashTotalPlays) {
		  dashTotalPlays.text = playsTable.plays;
		}
	  }
  
	  if (winTable != undefined && winTable.wins != undefined) {
		const dashWins = $.GetContextPanel().FindChildInLayoutFile("lb_wins");
		if (dashWins) {
		  dashWins.text = winTable.wins;
		}
  
		const plays = playsTable != undefined && playsTable.plays != undefined ? parseInt(playsTable.plays) : 0;
		const wins = parseInt(winTable.wins);
		const losses = plays - wins;
		const winRate = plays > 0 ? ((wins / plays) * 100).toFixed(2) : 0;
  
		const dashLosses = $.GetContextPanel().FindChildInLayoutFile("lb_losses");
		if (dashLosses) {
		  dashLosses.text = losses.toString();
		}
  
		const dashWinRate = $.GetContextPanel().FindChildInLayoutFile("lb_winrate");
		if (dashWinRate) {
		  dashWinRate.text = winRate.toString() + "%";
		}
	  }
	}
  
	// Schedule the function to be executed every 10 seconds
	$.Schedule(1, function() {
	  dashStatUpdate();
	  // Schedule the function again after 10 seconds
	  $.Schedule(1, arguments.callee);
	});
  })();

  function UpdatePlayer(playerId) {
	playerId = playerId || Game.GetLocalPlayerID();
    var playerPanel = $.GetContextPanel();

    var heroMedal = playerPanel.FindChildInLayoutFile("HeroRank");
    var heroMedalStars = playerPanel.FindChildInLayoutFile("HeroRankStars");
    var rankPosLabel = playerPanel.FindChildInLayoutFile("RankPos");
	var rankTextLabel = playerPanel.FindChildInLayoutFile("RankExist");

	const heroTable = CustomNetTables.GetTableValue("mmr", playerId.toString());
	const playsTable = CustomNetTables.GetTableValue("plays", playerId.toString());
	const steamIDData = CustomNetTables.GetTableValue("steamID", playerId.toString());
	const steamID = steamIDData ? steamIDData.steamid : "";
	const leaderboardTable = CustomNetTables.GetTableValue("game_state", "leaderboard_mmr");
	const leaderboardArray = leaderboardTable ? Object.values(leaderboardTable) : [];

	if (heroMedal) {
		$.Schedule(0.1, function() {
		  if (heroTable && playsTable && playsTable.plays !== undefined && playsTable.plays > 10) {
			const mmr = heroTable.mmr;
			const playerInLeaderboard = leaderboardArray.some(item => item.steamID === steamID);

			if (playerInLeaderboard && heroTable.mmr > 5420) {
			  const lb_playerRank = leaderboardArray.findIndex(item => item.steamID === steamID);
			  if (lb_playerRank !== -1) {
				const playerPosition = lb_playerRank + 1;
				rankPosLabel.text = playerPosition.toString();
				rankTextLabel.text = "";
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
			  rankTextLabel.text = $.Localize("#lb_nx");
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
		  } else {
			heroMedal.SetImage(`file://{images}/hero_selection/rank0.png`);
			rankTextLabel.text = "";
			var calibrationGamesLeft = playsTable ? Math.max(0, 10 - playsTable.plays) : 10;
			const calibrationTooltipText = calibrationGamesLeft === 0 ? "Calibration completed" : `Calibration games left: ${calibrationGamesLeft}`;
			
			heroMedal.SetPanelEvent("onmouseover", () => {
			  $.DispatchEvent("DOTAShowTextTooltip", heroMedal, calibrationTooltipText);
			});
			heroMedal.SetPanelEvent("onmouseout", () => {
			  $.DispatchEvent("DOTAHideTextTooltip");
			});
		  }
		});
	  }

}



function GetCurrentMMRForPlayer(playerId) {
	const netTable = CustomNetTables.GetTableValue("mmr", playerId.toString());
	if (netTable != undefined && netTable.mmr != undefined) {
		return netTable.mmr;
	} else {
		return "N/A";
	}
}

function MMRToRankMedal(mmr) {
	if (mmr == undefined) {
		return "0";
	} else {
		if (mmr < 650) {
			return "1";
		} else if (mmr < 1400) {
			return "2";
		} else if (mmr < 2150) {
			return "3";
		} else if (mmr < 2950) {
			return "4";
		} else if (mmr < 3700) {
			return "5";
		} else if (mmr < 4450) {
			return "6";
		} else if (mmr < 5450) {
			return "7";
		} else {
			return "8";
		}
	}
}




function GetStarCount(mmr) {
	if (mmr === undefined) {
		return "0";
	} else {
		const thresholds = [
			81.25, 162.5, 243.75, 325, 406.25, 487.5, 568.75, 650,
			743.75, 837.5, 931.25, 1025, 1118.75, 1212.5, 1306.25, 1400,
			1493.75, 1587.5, 1681.25, 1775, 1868.75, 1962.5, 2056.25, 2150,
			2250, 2350, 2450, 2550, 2650, 2750, 2850, 2950,
			3043.75, 3137.5, 3231.25, 3325, 3418.75, 3512.5, 3606.25, 3700,
			3793.75, 3887.5, 3981.25, 4075, 4168.75, 4262.5, 4356.25, 4450,
			4575, 4700, 4825, 4950, 5075, 5200, 5325, 5450,
			5543.75, 5637.5, 5731.25, 5825, 5918.75, 6012.5, 6106.25, 9999
		];

		for (let i = 0; i < thresholds.length; i++) {
			if (mmr < thresholds[i]) {
				return (i % 8).toString();
			}
		}

		return "0";
	}
}