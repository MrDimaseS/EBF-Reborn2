GameUI.QuickStats = GameUI.QuickStats || {};
GameUI.ToggleSingleClassInParent = (parent, child, class_name) => {
	parent.Children().forEach((upgrade) => {
		upgrade.RemoveClass(class_name);
	});
	if (child) child.AddClass(class_name);
};

let ToggleQuickStatsShow = () => {
	$.GetContextPanel().ToggleClass("Show_QS");
	if (!$.GetContextPanel().BHasClass("Show_QS")) $.DispatchEvent("DropInputFocus");
};

GameUI.QuickStats.Show = () => {
	$.GetContextPanel().AddClass("Show_QS");
};

(() => {
	GameUI.Custom_ToggleQuickStats = ToggleQuickStatsShow;
})();



(function () {
  var damageDealtLabel = $.GetContextPanel().FindChildTraverse("DamageDealt");
  var damageTakenLabel = $.GetContextPanel().FindChildTraverse("DamageTaken");
  var damageHealedLabel = $.GetContextPanel().FindChildTraverse("DamageHealed");
  var damagePerSecondLabel = $.GetContextPanel().FindChildTraverse("DamagePerSecond");
  
  var prevDamageDealt = 0; // Variable to store the previous damage dealt value
  var runningTotal = 0
  var counter = 0
  var stopper = 0
  // Update the damage values and DPS every second
  function UpdateDamageValues() {
    var playerID = Players.GetLocalPlayer();

    // Fetch the player's game stats from the NetTable
    var gameStats = CustomNetTables.GetTableValue("game_stats", playerID.toString());
    if (gameStats && !Game.IsGamePaused() ) {
      // Update the label texts
      damageDealtLabel.text = FormatNumber(gameStats.damage_dealt || 0);
      damageTakenLabel.text = FormatNumber(gameStats.damage_taken || 0);
      damageHealedLabel.text = FormatNumber(gameStats.damage_healed || 0);
	
	  if(prevDamageDealt == gameStats.damage_dealt){
		  if(stopper === 4){
			  runningTotal = 0;
			  counter = 0;
			  damagePerSecondLabel.text = 0;
		  } else {
			stopper++;
		  }
	  } else {
		// restart counter
		if (stopper > 0){
			prevDamageDealt = gameStats.damage_dealt
			stopper = 0;
		}
		var damageDiff = Math.max( gameStats.damage_dealt - prevDamageDealt, gameStats.last_damage_dealt ); // Calculate DPS
		prevDamageDealt = gameStats.damage_dealt
		runningTotal += damageDiff;
	  }
	  if(runningTotal > 0){
		counter++;
		var damagePerSecond = runningTotal / counter;
		damagePerSecondLabel.text = FormatNumber(damagePerSecond);
	  }
    }

    // Schedule the next update after 1 second
    $.Schedule(1, UpdateDamageValues);
  }

  function FormatNumber(number) {
    const DICTKEY = {
      0: '',
      1: 'K',
      2: 'M',
      3: 'B',
      4: 'T',
      5: 'Q'
    };

    if (isNaN(number) || typeof number !== "number") {
      return "0";
    }

    var parsedInt = Number(number);
    if (parsedInt != null && parsedInt != undefined) {
      var exponent = 0;
      while (parsedInt > 10000) {
        parsedInt = parsedInt / 1000;
        exponent++;
      }

      if (exponent == 0) {
        return Number(parsedInt).toFixed(0);
      } else {
        return Number(parsedInt).toFixed(2) + DICTKEY[exponent];
      }
    } else {
      return number.toFixed(0);
    }
  }

  // Start the periodic updates
  UpdateDamageValues();
})();
