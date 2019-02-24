@lazyglobal off.

runoncepath("lib_ui").

local OrbitOptions is lexicon(
	"C","Exit to command line",
	"1","Rendez-vous with Skylab",
	"2","Rendez-vous with ISS",
	"X","Return to KSC").


LOCAL STOPEXEC IS FALSE.

UNTIL STOPEXEC { 
    IF SHIP:STATUS = "PRELAUNCH" {
        RUN launch_asc(200000). 
        rcs off.
        radiators on.
    }
    ELSE IF SHIP:STATUS = "ORBITING" {
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
            run circ_alt(80000).
            set target to body.
            run land.
        } 
        else if choice = "C" {
            wait 0.
            STOPEXEC on. 
        } 
    }
    ELSE IF SHIP:STATUS = "SUB_ORBITAL" OR SHIP:STATUS = "FLYING" {
        abort on.
        run land.
    }
    ELSE IF SHIP:STATUS = "LANDED" OR SHIP:STATUS = "SPLASHED" {
        SHUTDOWN.
    }
    ELSE IF SHIP:STATUS = "ESCAPING" OR SHIP:STATUS = "DOCKED"{
        BREAK.
    }
    IF NOT STOPEXEC REBOOT.
}
PRINT("PROCEED.").