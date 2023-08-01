GameEvents.Subscribe("epic_boss_fight_ng_vote_update", EvaluateNGPlusVoting);

$("#Vote").visible = false;
$("#Note").visible = false;
// $("#confirmation").visible = true;
// $("#yesheader").visible = true;
// $("#noheader").visible = true;

let NGPlusCurrentActive = false;
let NGPlusCurrentStartTime;

function EvaluateNGPlusVoting( event ){
	$.Msg( event )
	if( NGPlusCurrentActive ){
		if ( event.active != undefined && event.active == 0 ){
			$("#Vote").visible = false;
			$("#Note").visible = false;
			NGPlusCurrentActive = false;
		}
		if( event.endTime ){
			NGPlusCurrentStartTime = event.endTime;
		} 
		EvaluateVotes( event.votes )
	} else {
		if ( event.active != undefined && event.active == 1 ){
			$("#Vote").visible = true;
			$("#Note").visible = true;
			NGPlusCurrentActive = true;
			NGPlusCurrentStartTime = event.endTime;
			EvaluateTimer( );
			EvaluateVotes( event.votes )
		}
	}
}

function EvaluateVotes( voteList ){
	let voteContainers = $("#AllVotes").FindChildrenWithClassTraverse("VoteContainer")
	for(var votes of voteContainers){
		for(var vote of votes.Children()){
			vote.style.visibility = "collapse"
			vote.RemoveAndDeleteChildren()
			vote.DeleteAsync(0)
		}
	}
	var yes = $("#YesContainer")
	var undecided = $("#UndecidedContainer")
	var no = $("#NoContainer")
	for( hero in voteList){
		if( voteList[hero] == 1 ){
			var voteIcon = $.CreatePanel("DOTAHeroImage", yes, "VoteYes"+hero);
			voteIcon.heroname = hero;
			voteIcon.heroimagestyle = "icon";
			voteIcon.AddClass("Vote");
		} else if( voteList[hero] == 0 ) {
			var voteIcon = $.CreatePanel("DOTAHeroImage", no, "VoteNo"+hero);
			voteIcon.heroname = hero;
			voteIcon.heroimagestyle = "icon";
			voteIcon.AddClass("Vote");
		} else {
			var voteIcon = $.CreatePanel("DOTAHeroImage", undecided, "VoteNone"+hero);
			voteIcon.heroname = hero;
			voteIcon.heroimagestyle = "icon";
			voteIcon.AddClass("Vote");
		}
	}
}



function EvaluateTimer( ) {
	if(NGPlusCurrentStartTime != undefined){
		$("#time_nb").text = Math.trunc( NGPlusCurrentStartTime - Game.GetGameTime() + 0.5 )
		$.Schedule( 1, EvaluateTimer )
	}
}

function No() {
	var ID = Players.GetLocalPlayer()
	GameEvents.SendCustomGameEventToServer("epic_boss_fight_ng_voted", {
		pID: ID,
		vote: false
	});
}

function Yes() {
	var ID = Players.GetLocalPlayer()
	GameEvents.SendCustomGameEventToServer("epic_boss_fight_ng_voted", {
		pID: ID,
		vote: true
	});
}