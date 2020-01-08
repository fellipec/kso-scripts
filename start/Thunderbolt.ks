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

local apo_alt is 80000.

IF ship:status = "PRELAUNCH" {
	
	RUN LAUNCH_ASC(apo_alt).
	IF STAGE:NUMBER > 2 STAGE.
	WAIT 1.
	IF STAGE:NUMBER = 1 BAYS ON.
	sas on.
	rcs on.
	reboot.
}

ELSE IF ship:status = "ORBITING" {
	IF STAGE:NUMBER = 1 BAYS ON.
	rcs on.
	sas on.
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
		if ship:mass < 50 {
			uiBanner("dob","Deobiting empty").
			run deorbitsp(-1,20).
		}
		else {
			uiBanner("dob","Deobiting loaded").
			run deorbitsp(-15,20).
		}
	}
	else if choice = "R" {
		REBOOT.
	}
}
