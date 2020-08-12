@lazyglobal off.

SET STEERINGMANAGER:MAXSTOPPINGTIME TO 15.
SET STEERINGMANAGER:PITCHPID:KD TO 0.3.
SET STEERINGMANAGER:YAWPID:KD TO 0.3.
SET STEERINGMANAGER:ROLLPID:KD TO 1.


runoncepath("lib_ui").

local OrbitOptions is lexicon(
	"C","Exit to command line",
	"1","Rendez-vous with Skylab",
	"2","Rendez-vous with ISS",
	"X","Return to KSC",
	"R","Reboot").

local apo_alt is 150000.

if core:tag = "1stage" {

    IF ship:status = "PRELAUNCH" {
        
        RUN LAUNCH_ASC(apo_alt).
        lights on.
        WAIT 5.
        STAGE.
        SET STEERINGMANAGER:MAXSTOPPINGTIME TO 20.
        SET STEERINGMANAGER:PITCHPID:KD TO 1.
        SET STEERINGMANAGER:YAWPID:KD TO 1.
        SET STEERINGMANAGER:ROLLPID:KD TO 1.
        SET STEERINGMANAGER:PITCHTS TO 10.
        SET STEERINGMANAGER:YAWTS TO 10.
        brakes on.
        lights off.
        run land.
    }
}
ELSE IF ship:status = "ORBITING" {	
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
		run deorbitsp(0,15).
	}
	else if choice = "R" {
		REBOOT.
	}
}
ELSE IF ship:status = "PRELAUNCH" {
    PRINT("Waiting first stage deliver to orbit.").
}

