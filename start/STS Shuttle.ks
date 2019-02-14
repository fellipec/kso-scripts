IF SHIP:STATUS = "PRELAUNCH" {
    RUN launch_asc(200000). // Launches to 200km
    WAIT 5.
    STAGE. // Get rid of the tank
    wait 5.
    RUN DEORBITSP.

}

