IF SHIP:STATUS = "PRELAUNCH" {
    run launch.
    WAIT 5.
    REBOOT.
}
ELSE IF SHIP:STATUS = "ORBITING" {
    run test.
}