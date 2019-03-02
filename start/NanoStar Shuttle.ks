@lazyglobal off.

runoncepath("lib_ui").
SET STEERINGMANAGER:MAXSTOPPINGTIME TO 3.

local OrbitOptions is lexicon(
	"C","Exit to command line",
	"1","Rendez-vous with Skylab",
	"2","Rendez-vous with ISS",
	"X","Return to KSC").

IF ship:status = "PRELAUNCH" {
	RUN LAUNCH_ASC(200000).
	RCS ON.
	reboot.
}
ELSE IF ship:status = "ORBITING" {
	RCS ON.
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
		STAGE. // Activate jet engines before reentry
		run deorbitsp(-6,10).
	}
}