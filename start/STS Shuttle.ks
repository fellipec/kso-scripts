@lazyglobal off.

SET STEERINGMANAGER:MAXSTOPPINGTIME TO 10.
SET STEERINGMANAGER:PITCHPID:KD TO 2.
SET STEERINGMANAGER:YAWPID:KD TO 2.
SET STEERINGMANAGER:ROLLPID:KD TO 2.


runoncepath("lib_ui").

local OrbitOptions is lexicon(
	"C","Exit to command line",
	"1","Rendez-vous with Skylab",
	"2","Rendez-vous with ISS",
	"X","Return to KSC",
	"R","Reboot").

IF ship:status = "PRELAUNCH" {
	RUN LAUNCH_ASC(140000).
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
		run deorbitsp(-2,20).
	}
	else if choice = "R" {
		REBOOT.
	}
}
