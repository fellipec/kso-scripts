IF SHIP:STATUS = "PRELAUNCH" {
    RUN launch_asc(200000). 
    REBOOT.
}
ELSE IF SHIP:STATUS = "ORBITING" {
    run test.
}