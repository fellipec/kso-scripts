@lazyglobal off.

SET STEERINGMANAGER:MAXSTOPPINGTIME TO 5.

runoncepath("lib_ui").

local OrbitOptions is lexicon(
	"C","Exit to command line",
	"1","Rendez-vous with Skylab",
	"2","Rendez-vous with ISS",
	"X","Return to KSC",
	"R","Reboot").

IF ship:status = "PRELAUNCH" {
	RUN LAUNCH_ASC(110000).
	IF STAGE:NUMBER > 0 STAGE.
	WAIT 1.
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
		run deorbitsp(-6,20).
	}
	else if choice = "R" {
		REBOOT.
	}
}
