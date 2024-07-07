GameUI.VoiceChat = GameUI.VoiceChat || {};
GameUI.ToggleSingleClassInParent = (parent, child, class_name) => {
    parent.Children().forEach((upgrade) => {
        upgrade.RemoveClass(class_name);
    });
    if (child) child.AddClass(class_name);
};

let ToggleVoiceChatShow = () => {
	$.GetContextPanel().ToggleClass("Show_VC");
	if (!$.GetContextPanel().BHasClass("Show_VC")) $.DispatchEvent("DropInputFocus");

	if ($.GetContextPanel().BHasClass("Show_VC")) {
		state = 1;
		mouseCallback = function (eventName, button) {
			if (eventName === "pressed" && button === 0) {
				state = 0;
				$.GetContextPanel().RemoveClass("Show_VC");
				GameUI.SetMouseCallback(null);
			}
		};
		GameUI.SetMouseCallback(mouseCallback);
	}
};



GameUI.VoiceChat.Show = () => {
    $.GetContextPanel().AddClass("Show_VC");
};


function OnPhraseSelected(phraseId) {
    const playerName = Game.GetLocalPlayerInfo().player_name;
    const soundNames = {
        1: "Lakad Matataaag! Normalin, Normalin.",
        2: "The next level play!",
		3: "А ну-ка иди-ка сюда. А вот все. Все.",
		4: "Absolutely Perfect",
		5: "They're all dead!",
		6: "唉唉唉！唉？唉 …",
		7: "Brutal. Savage. Rekt",
		8: "Ceeeeeeeeeb!",
		9: "Что это?! Какая жесть!",
		10: "Crash and burn",
		11: "Crowd Groan",
		12: "Сrybaby",
		13: "Ding Ding Ding Mother******",
		14: "It's a disastah!",
		15: "啊，队友呢？队友呢？队友呢？！队友呢？！？！",
		16: "Easiest money of my life!",
		17: "Echo Slamma Jamma!",
		18: "Это ГГ",
		19: "Это уже попахивает фидом",
		20: "Это. Просто. Нечто.",
		21: "Holy Moly!",
		22: "10억짜리 꿈의 고리! 15억짜리 꿈의 고리!",
		23: "Резать Резать Резать Резать",
		24: "你行你行，你上你上",
		25: "This guy has no chill",
		26: "Ouch",
		27: "Ой-ой-ой-ой-ой, бежать!",
		28: "Patience from Zhou",
		29: "See you later nerds",
		30: "Monkey Business",
		31: "What the **** just happened?",
		32: "Wow!",
		33: "Ай-ай-ай-ай-ай, что сейчас произошло!"
    };
    const soundName = soundNames[phraseId];

    // Localize the sound name
    const localizedSoundName = $.Localize(`${soundName}`);

    GameEvents.SendCustomGameEventToServer("emit_sound_for_all_players", { phraseId: phraseId, playerName: playerName, soundName: localizedSoundName });
}

(() => {
    GameUI.Custom_ToggleVoiceChat = ToggleVoiceChatShow;
})();