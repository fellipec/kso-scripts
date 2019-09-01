@lazyglobal off.

SET STEERINGMANAGER:MAXSTOPPINGTIME TO 5.
SET STEERINGMANAGER:PITCHPID:KD TO 1.
SET STEERINGMANAGER:YAWPID:KD TO 1.
SET STEERINGMANAGER:ROLLPID:KD TO 1.

runoncepath("lib_ui").

local OrbitOptions is lexicon(
	"C","Exit to command line",
	"1","Rendez-vous with Skylab",
	"2","Rendez-vous with ISS",
	"X","Return to KSC").

IF ship:status = "PRELAUNCH" {
	RUN LAUNCH_ASC(180000).
    IF STAGE:NUMBER > 1 STAGE. // Discard the tank
	BAYS ON.
	reboot.
}

ELSE IF ship:status = "ORBITING" {
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
		run deorbitsp(-1,20).
	}
}
ELSE IF SHIP:STATUS = "FLYING" {
	run deorbitsp(-10,15).
}