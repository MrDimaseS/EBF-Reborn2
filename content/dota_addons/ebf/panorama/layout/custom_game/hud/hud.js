const microHud = $.GetContextPanel().GetParent().GetParent().GetParent();
const bottomhud = microHud.FindChildTraverse("CustomUIRoot");

(function() {
	const roundsElement = $("#Rounds"); // Reference to the "Rounds" element
	const timeElement = $("#RoundsTime"); // Reference to the "RoundsTime" element
	const bossRoundElement = $("#BossRound"); // Reference to the "BossRound" element


	let currentRound = 0; // Variable to store the current round number
	let currentLife = 0; // Variable to store the current life value

	GameEvents.Subscribe("UpdateRound", function(msg) {
		if (bossRoundElement) {
			bossRoundElement.visible = true; // Show the "BossRound" element
		}

		const wordToWrite = String(msg.roundNumber);
		let count = 0;

		function updateWord() {
			if (roundsElement) {
				roundsElement.text = wordToWrite.substring(0, count); // Update the displayed round number
			}

			if (count < wordToWrite.length) {
				count++;
				$.Schedule(0, updateWord);
			}
		}

		$.Schedule(wordToWrite.length * 0.2, function() {
			updateWord();
			timeElement.text = ""; // Clear the time text 
		});

		currentRound = msg.roundNumber; // Update the current round number
	});

	GameEvents.Subscribe("UpdateTimeLeft", function(msg) {
		const time = Math.round(msg.Time);
		if (roundsElement) {
			roundsElement.text = String(currentRound); // Display the stored round number
		}
		timeElement.text = String(time); // Update the time text
	});

	GameEvents.Subscribe("UpdateLife", function(msg) {
		currentLife = msg.life; // Update the current life value
		$("#Life").text = String(currentLife); // Update the "Life" text
	});
})();

function Yes() {
	HideButtons();
	const ID = Players.GetLocalPlayer();
	GameEvents.SendCustomGameEventToServer("Vote_Round", {
		pID: ID,
		vote: true
	});
}

function Skip() {
  const checkbox = bottomhud.FindChildTraverse("skipper");
	if (checkbox.checked) {
		// Disable checkbox for 5 seconds to prevent multiple clicks
		checkbox.enabled = false;
		$.Schedule(60, function() {
			checkbox.enabled = true;
		});
		$("#Vote_Yes").visible = false;
		$("#voteStatus").visible = true;
		// Skip waiting time automatically
		var ID = Players.GetLocalPlayer();
		GameEvents.SendCustomGameEventToServer("Vote_Round", {
			pID: ID,
			vote: true
		});
	} else {
		$("#Vote_Yes").visible = true;
	}
}

function HideButtons(text) {
	$("#Vote_Yes").visible = false;
	$("#voteStatus").visible = true;
}

GameEvents.Subscribe("Display_RoundVote", open);
GameEvents.Subscribe("Close_RoundVote", close);

$("#RoundOptions").visible = false;
$("#RoundsTime").visible = false;

function open() {
  if (open) {
		Skip();
	}
	$("#Vote_Yes").visible = true;
	$("#voteStatus").visible = false;
	$("#RoundOptions").visible = true;
	$("#RoundsTime").visible = true;
}

function close() {
	$("#RoundOptions").visible = false;
	$("#RoundsTime").visible = false;
	$("#voteStatus").visible = false;
}

(function() {
    GameEvents.Subscribe("RoundVoteResults", function(data) {
        var playerIDs = Game.GetAllPlayerIDs();
        var connectedPlayerCount = 0;

        for (var i = 0; i < playerIDs.length; i++) {
            var playerID = playerIDs[i];
            var playerInfo = Game.GetPlayerInfo(playerID);

            if (playerInfo && playerInfo.player_connection_state === DOTAConnectionState_t.DOTA_CONNECTION_STATE_CONNECTED) {
                connectedPlayerCount++;
            }
        }
        var votesLeft = connectedPlayerCount - data.Yes;

        const voteStatus = $("#voteStatus");
        voteStatus.text = votesLeft.toString() + " " + $.Localize("#vote_status_label");
    });
})();
