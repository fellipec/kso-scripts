IF SHIP:STATUS = "PRELAUNCH" {
    RUN launch_asc(200000). 
    wait 1.
    stage.
    wait 1.
    stage.
    wait 1.
    stage.
    wait 10.
    run deorbitsp.
    
}
