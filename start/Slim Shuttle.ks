@lazyglobal off.

runoncepath("lib_ui").

local OrbitOptions is lexicon(
	"C","Exit to command line",
	"1","Rendez-vous with Skylab",
	"2","Rendez-vous with ISS",
	"X","Return to KSC").

IF ship:status = "PRELAUNCH" {
	RUN LAUNCH(120000).
	reboot.
}

ELSE IF ship:status = "ORBITING" {
	UNTIL STAGE:NUMBER = 0 {
		STAGE.
		WAIT 1.
	}
	rcs off. sas on.
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
		run deorbitsp(-10,20).
	}
}
