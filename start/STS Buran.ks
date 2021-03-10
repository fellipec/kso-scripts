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

IF CORE:TAG = "RETURN" {
	PRINT("WAITING FOR ORBIT...").
	WAIT UNTIL NOT CORE:messages:empty.
	LOCAL RECEIVED IS CORE:messages:POP.
	IF RECEIVED:CONTENT = "GO" {
		SET KUNIVERSE:DEFAULTLOADDISTANCE:ORBIT:UNLOAD TO 30000.
		SET KUNIVERSE:DEFAULTLOADDISTANCE:ORBIT:LOAD TO 29500.
		wait 1.
		SET KUNIVERSE:DEFAULTLOADDISTANCE:ORBIT:PACK TO 29999.
		SET KUNIVERSE:DEFAULTLOADDISTANCE:ORBIT:UNPACK TO 29000.
		PRINT("RETURNING TO HOME...").
		STAGE.		
		WAIT 10.
		SAS OFF.
		RCS ON.
		WAIT 1.
		LOCK steering TO RETROGRADE.
		WAIT 10.
		LOCK throttle TO 0.1.		
		WAIT UNTIL periapsis < 5000.
		lock throttle to 0.
		unlock throttle.
		unlock steering.

	}

}
ELSE {
	IF ship:status = "PRELAUNCH" {
		RUN LAUNCH_ASC(180000).
		UNTIL STAGE:NUMBER <= 2 { STAGE. WAIT 1.} // Discard the tank
		BAYS ON.
		WAIT 5.
		runOncePath("lib_parts").
		partsExtendAntennas().
		SAS ON.
		LOCAL P IS PROCESSOR("RETURN").
		P:CONNECTION:SENDMESSAGE("GO").
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
			run deorbitsp(-2,20).
		}
	}
	ELSE IF SHIP:STATUS = "FLYING" {
		run deorbitsp(-10,15).
	}
}