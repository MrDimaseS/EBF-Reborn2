GameUI.Options = GameUI.Options || {};
GameUI.ToggleSingleClassInParent = (parent, child, class_name) => {
	parent.Children().forEach((upgrade) => {
		upgrade.RemoveClass(class_name);
	});
	if (child) child.AddClass(class_name);
};

let state = 0;
let mouseCallback = null;

let ToggleOptionsShow = () => {
	$.GetContextPanel().ToggleClass("Show_OP");
	if (!$.GetContextPanel().BHasClass("Show_OP")) $.DispatchEvent("DropInputFocus");

	if ($.GetContextPanel().BHasClass("Show_OP")) {
		state = 1;
		mouseCallback = function (eventName, button) {
			if (eventName === "pressed" && button === 0) {
				state = 0;
				$.GetContextPanel().RemoveClass("Show_OP");
				GameUI.SetMouseCallback(null);
			}
		};
		GameUI.SetMouseCallback(mouseCallback);
	}
};

GameUI.Options.Show = () => {
	$.GetContextPanel().AddClass("Show_OP");
};

(() => {
	GameUI.Custom_ToggleOptions = ToggleOptionsShow;
})();

// Get the parent panels and find the boss info panels
const microHud = $.GetContextPanel().GetParent().GetParent().GetParent();
const bottomhud = microHud.FindChildTraverse("CustomUIRoot");

// Immediately-invoked function expression (IIFE) to encapsulate the code
(function() {
  // Find the checkbox element
  const checkbox = bottomhud.FindChildTraverse("minimapvis");

  // Function to handle checkbox change
  function handleCheckboxChange() {
    // Check if the checkbox is selected
    const isChecked = checkbox.IsSelected();

    // Toggle the minimap visibility based on the checkbox state
    GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_MINIMAP, !isChecked);
  }

  // Attach event listener to the checkbox's "onactivate" event
  checkbox.SetPanelEvent("onactivate", handleCheckboxChange);

  // Execute the function when the page loads
  handleCheckboxChange();
})();


(function() {
	// Find the checkbox element
	const checkbox = $.GetContextPanel().FindChildTraverse("topuivis");
	const bottomhud = $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse("CustomUIRoot");
  
	// Function to handle checkbox change
	function handleCheckboxChange() {
	  // Check if the checkbox is selected
	  const isChecked = checkbox.IsSelected();
  
	  const topbar = bottomhud.FindChildTraverse("CustomUIContainer_HudTopBar");
	  if (topbar !== null && topbar !== undefined) {
		topbar.style.visibility = isChecked ? "collapse" : "visible";
	  }
  
	  const somehud = $.GetContextPanel().GetParent().GetParent().GetParent();
	  const clock_in_hud = somehud.FindChildTraverse("HUDElements");
  
	  const clock_element = clock_in_hud.FindChildTraverse("topbar");
	  if (clock_element !== null && clock_element !== undefined) {
		clock_element.style.marginTop = isChecked ? "0px" : "105px";
	  }
	}
  
	// Attach event listener to the checkbox's "onactivate" event
	checkbox.SetPanelEvent("onactivate", handleCheckboxChange);
  
	// Execute the function when the page loads
	handleCheckboxChange();
  })();
  

  (function() {
	// Function to handle checkbox change
	function handleCheckboxChange(isChecked) {
	  const bottomhud = $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse("CustomUIRoot");
	  const hudTopButtons = bottomhud.FindChildTraverse("HUDTopButtons_menu");
  
	  // Check if hudTopButtons is found before accessing its style properties
	  if (hudTopButtons !== null && hudTopButtons !== undefined) {
		hudTopButtons.style["horizontal-align"] = isChecked ? "right" : "left";
	  }
	}
  
	// Find the checkbox element after a delay of 1 second
	$.Schedule(1, function() {
	  const checkbox = $.GetContextPanel().FindChildTraverse("rightsideui");
  
	  // Attach event listener to the checkbox's "onactivate" event
	  checkbox.SetPanelEvent("onactivate", function() {
		// Check if the checkbox is selected
		const isChecked = checkbox.IsSelected();
		handleCheckboxChange(isChecked);
	  });
  
	  // Execute the function when the page loads
	  handleCheckboxChange(checkbox.IsSelected());
	});
  })();
  