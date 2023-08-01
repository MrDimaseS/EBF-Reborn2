GameUI.Board = GameUI.Board || {};
GameUI.ToggleSingleClassInParent = (parent, child, class_name) => {
	parent.Children().forEach((upgrade) => {
		upgrade.RemoveClass(class_name);
	});
	if (child) child.AddClass(class_name);
};

const TABS = {
	leaderboard: true,
	leaderboard_wr: true,
};

let InitContent = () => {
	$("#C_Tabs").RemoveAndDeleteChildren();
	$("#C_Content").RemoveAndDeleteChildren();

	Object.entries(TABS).forEach(([tab_name, b_create], index) => {
		if (!b_create) return;

		let tab = $.CreatePanel("Button", $("#C_Tabs"), `Tab_${tab_name}`);
		tab.BLoadLayoutSnippet("Tab");
		tab.SetDialogVariable(`tab_name`, $.Localize(`#tab_${tab_name}`, tab));

		let bp_panel = $.CreatePanel("Panel", $("#C_Content"), `BoardContent_${tab_name}`);
		bp_panel.BLoadLayout(`file://{resources}/layout/custom_game/board/${tab_name}/${tab_name}.xml`, false, false);

		let activate_content = (b_skip_flag) => {
			if (tab.BHasClass("BActive")) return;

			Game.EmitSound("Item.PickUpRecipeShop");
			GameUI.ToggleSingleClassInParent($("#C_Tabs"), tab, "BActive");
			GameUI.ToggleSingleClassInParent($("#C_Content"), bp_panel, "BActive");
			if (!b_skip_flag) tab.RemoveClass("BShowFlag");
		};

		if (index == 0) activate_content(true);

		tab.SetPanelEvent("onactivate", activate_content);
		tab.Open = activate_content;
	});
}; 

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
  

  let state = 0;
  let mouseCallback = null;
  
  let ToggleBoardShow = () => {
	  $.GetContextPanel().ToggleClass("Show");
	  if (!$.GetContextPanel().BHasClass("Show")) $.DispatchEvent("DropInputFocus");
	  dashStatUpdate();
	  if ($.GetContextPanel().BHasClass("Show")) {
		  state = 1;
		  mouseCallback = function (eventName, button) {
			  if (eventName === "pressed" && button === 0) {
				  state = 0;
				  $.GetContextPanel().RemoveClass("Show");
				  GameUI.SetMouseCallback(null);
			  }
		  };
		  GameUI.SetMouseCallback(mouseCallback);
	  }
  };

GameUI.Board.OpenSpecificTab = (tab_name, b_skip_open_collection) => {
	const tab = $(`#Tab_${tab_name}`);
	if (!tab || !tab.Open) return;
	if (!b_skip_open_collection) $.GetContextPanel().AddClass("Show");
	tab.Open();
};
GameUI.Board.ShowTabFlag = (tab_name) => {
	const tab = $(`#Tab_${tab_name}`);
	if (!tab || tab.BHasClass("BActive")) return;
	tab.AddClass("BShowFlag");
};
GameUI.Board.HideTab = (tab_name) => {
	const tab = $(`#Tab_${tab_name}`);
	if (!tab) return;
	tab.AddClass("Hide");
};

GameUI.Board.Show = () => {
	$.GetContextPanel().AddClass("Show");
	GameUI.Board.CloseSubPanels();
};

(() => {
	$.Msg("============Leaderboards init complete============");
	GameUI.Custom_ToggleBoard = ToggleBoardShow;
	InitContent();
})();