GameUI.Profile = GameUI.Profile || {};
GameUI.ToggleSingleClassInParent = (parent, child, class_name) => {
	parent.Children().forEach((upgrade) => {
		upgrade.RemoveClass(class_name);
	});
	if (child) child.AddClass(class_name);
};

let state = 0;
let mouseCallback = null;

let ToggleProfileShow = () => {
	$.GetContextPanel().ToggleClass("Show_PR");
	if (!$.GetContextPanel().BHasClass("Show_PR")) $.DispatchEvent("DropInputFocus");

	if ($.GetContextPanel().BHasClass("Show_PR")) {
		state = 1;
		mouseCallback = function (eventName, button) {
			if (eventName === "pressed" && button === 0) {
				state = 0;
				$.GetContextPanel().RemoveClass("Show_PR");
				GameUI.SetMouseCallback(null);
			}
		};
		GameUI.SetMouseCallback(mouseCallback);
	}
};

GameUI.Profile.Show = () => {
	$.GetContextPanel().AddClass("Show_PR");
};

(() => {
	GameUI.Custom_ToggleProfile = ToggleProfileShow;
})();


(function() {
	// Function to update the dashboard stats
	function profileUpdate(playerId) {
		playerId = playerId || Game.GetLocalPlayerID();

		const patTable = CustomNetTables.GetTableValue("patrons", playerId.toString());
		const rootPanel = $.GetContextPanel();
		const patreonBadge = rootPanel.FindChildTraverse("badge_tier");
		const badgeType = rootPanel.FindChildTraverse("badge_type");
		const prof_left = rootPanel.FindChildTraverse("prof_top_left");
		const prof_right = rootPanel.FindChildTraverse("prof_top_right");

		const perkColors = [
			"#2f2f37",
			"#ffffff",
			"#ffffff",
			"#ffffff",
			"#ffffff",
			"#ffffff"
		];

		if (patTable?.tier != null && patTable.tier >= 0) {
			patreonBadge?.SetImage(`file://{resources}/images/hud/tier${patTable.tier}.png`);

			const tooltipLocalizationKeys = [
				"#discord_sup",
				"#supporter_1",
				"#supporter_2",
				"#supporter_3",
				"#trs",
				"#dev",
			];
			badgeType.text = $.Localize(tooltipLocalizationKeys[patTable.tier]);

			const perkCount = Math.min(patTable.tier, 5);
			for (let i = 1; i <= 5; i++) {
				const perk = rootPanel.FindChildTraverse("b_perk_" + i);
				perk.style.washColor = perkColors[i <= perkCount ? i : 0];
			}

			if (prof_left) {
				prof_left.style.width = "220px";
				prof_right.style.width = "80px";
			}
		} else {
			badgeType.text = $.Localize("#reg_pl");

			for (let i = 1; i <= 5; i++) {
				const perk = rootPanel.FindChildTraverse("b_perk_" + i);
				perk.style.washColor = "#2f2f37";
			}

			if (prof_left) {
				prof_left.style.width = "300px";
				prof_right.style.width = "0px";
			}
		}
	}

	profileUpdate();
})();
