@lazyglobal off.

runoncepath("lib_ui").


IF CORE:TAG = "fadec" {

    WAIT 10.

    PRINT("FADEC On-line.").    
    
    WAIT UNTIL STATUS = "ORBITING".

    LIST ENGINES IN AllEngs.
    FOR eng IN AllEngs {
        if eng:maxthrust > 200 SET eng:THRUSTLIMIT TO 15.
    }

    WAIT 1.
    CORE:DEACTIVATE.
}
ELSE { 
    SET STEERINGMANAGER:MAXSTOPPINGTIME TO 10.
    SET STEERINGMANAGER:PITCHPID:KD TO 1.
    SET STEERINGMANAGER:YAWPID:KD TO 1.
    SET STEERINGMANAGER:ROLLPID:KD TO 1.

    local OrbitOptions is lexicon(
        "C","Exit to command line",
        "1","Rendez-vous with Skylab",
        "2","Rendez-vous with ISS",
        "X","Return to KSC").

    IF ship:status = "PRELAUNCH" {
        RUN LAUNCH_ASC(200000).
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
            run deorbitsp(-4,15).
        }
    }
}