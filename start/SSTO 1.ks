@lazyglobal off.

runoncepath("lib_ui").

local OrbitOptions is lexicon(
	"C","Exit to command line",
	"1","Rendez-vous with Skylab",
	"2","Rendez-vous with ISS",
	"X","Return to KSC").

local LaunchOptions is lexicon(
	"C","Exit to command line",
	"1","Launch to Orbit",
	"2","Simple take-off").

IF ship:status = "PRELAUNCH" or ship:status = "LANDED" {
    brakes on.
    local choice is uiTerminalMenu(LaunchOptions).
	if choice = 1 {
        brakes off.
        RUN LAUNCH(80000).
        reboot.
	}
	else if choice = 2 {
        brakes off.
        RUN FLY.
	}
    else if choice = "C" {
        Print("Proceed...").
    }
}

ELSE IF ship:status = "ORBITING" {
	IF STAGE:NUMBER > 0 STAGE.
	rcs off.
	local choice is uiTerminalMenu(OrbitOptions).
	if choice = 1 {
		SET TARGET TO VESSEL("Skylab").
		RUN RENDEZVOUS.
	}
	if choice = 2 {
		SET TARGET TO VESSEL("ISS").
		RUN RENDEZVOUS.
	}
	else if choice = "X" {
		run deorbitsp(-15,15).
	}
}
