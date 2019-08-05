@lazyglobal off.

runoncepath("lib_ui").

local OrbitOptions is lexicon(
	"C","Exit to command line",
	"1","Rendez-vous with Skylab",
	"2","Rendez-vous with ISS",
	"X","Return to KSC").


IF SHIP:STATUS = "PRELAUNCH" {
    
    RUN launch_asc(100000). 
    RADIATORS ON.
	reboot.
}
ELSE IF ship:status = "ORBITING" {
	rcs off.
    RADIATORS ON.
	LOCAL Reactor is SHIP:partstagged("atomic")[0].
	LOCAL RControl is Reactor:GETMODULE("FissionReactor").
	For E in RControl:ALLACTIONNAMES {
		If E:CONTAINS("Start Reactor") RControl:DOACTION(E,True).
	}

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
		run deorbitsp(0,20).
	}
}
ELSE IF SHIP:STATUS = "FLYING" {
	run deorbitsp(-8,15).
}