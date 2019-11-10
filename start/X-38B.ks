@lazyglobal off.


runoncepath("lib_ui").

local OrbitOptions is lexicon(
	"C","Exit to command line",
	"1","Rendez-vous with Skylab",
	"2","Rendez-vous with ISS",
	"X","Return to KSC",
	"R","Reboot").

IF ship:status = "PRELAUNCH" {
	RUN LAUNCH_ASC(200000).
	IF STAGE:NUMBER > 2 STAGE.
	WAIT 1.
	IF STAGE:NUMBER = 1 BAYS ON.
	reboot.
}

ELSE IF ship:status = "ORBITING" {
	IF STAGE:NUMBER = 1 BAYS ON.
	rcs off.
	local choice is uiTerminalMenu(OrbitOptions).
	if choice = 1 {
		SET TARGET TO VESSEL("Skylab").
		RUN RENDEZVOUS.
	}
	else if choice = 2 {
		SET TARGET TO VESSEL("ISS").
		RUN RENDEZVOUS.
	}
	else if choice = "X" {
		run deorbitsp(-6.5,20).
	}
	else if choice = "R" {
		REBOOT.
	}
}
