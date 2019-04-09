IF SHIP:STATUS = "PRELAUNCH" {
    RUN launch_asc(120000). // Launches to 120km
    SET TARGET TO MUN. //We choose go to to the Mun and do the other things!
    RUN transfer.
    // TODO: Do the other things, not because they are easy, but because they are hard!
}
