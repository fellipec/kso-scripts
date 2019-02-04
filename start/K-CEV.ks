IF SHIP:STATUS = "PRELAUNCH" {
    RUN launch_asc(200000). 
    wait 10.
    stage.
    wait 1.
    stage.
    wait 2.
    run deorbitsp(-10).
}
