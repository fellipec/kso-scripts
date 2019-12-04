IF SHIP:STATUS = "PRELAUNCH" {
    RUN launch_asc(2000000). // Launches to 2000km
    SET TARGET TO MUN. //We choose go to to the Mun and do the other things!
    RUN transfer.
    // TODO: Do the other things, not because they are easy, but because they are hard!
}
