IF SHIP:STATUS = "PRELAUNCH" {
    RUN launch_asc(200000). // Launches to 200km
    BAYS ON.
    STAGE.

    wait 5.
    RUN DEORBITSP(1).

}
