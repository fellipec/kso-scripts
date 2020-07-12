@lazyglobal off.

runoncepath("lib_ui").

local OrbitOptions is lexicon(
	"C","Exit to command line",
	"1","Rendez-vous with Skylab",
	"2","Rendez-vous with ISS",
	"X","Return to KSC").

IF ship:status = "PRELAUNCH" {
	RUN LAUNCH_ASC(200000).
	LOCK STEERING TO PROGRADE.
	WAIT 20.
	STAGE.
	WAIT 1.
	unlock steering.
	reboot.
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
		run deorbitsp(-1.5,20).
	}
}
