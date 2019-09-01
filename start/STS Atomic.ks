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
	"X","Return to KSC").


IF SHIP:STATUS = "PRELAUNCH" {
    
    RUN launch_asc(90000). 
    RADIATORS ON.
	reboot.
}
ELSE IF ship:status = "ORBITING" {
	rcs off.
    RADIATORS ON.

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
ELSE IF SHIP:STATUS = "FLYING" {
	run deorbitsp(-10,15).
}