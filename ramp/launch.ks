@lazyglobal off.
/////////////////////////////////////////////////////
// Launch.ks just try to decide if is better to use
// launch_asc.ks or launch_ssto.ks or launch_vac.ks
/////////////////////////////////////////////////////
parameter Apo is 200000.
parameter hdg is 90.

WAIT UNTIL KUniverse:CANQUICKSAVE.
KUniverse:QUICKSAVETO("RAMP-Before Launch").

if ship:body = body("KERBIN") {

    if KUniverse:ORIGINEDITOR = "SPH" or Ship:Name:Contains("SSTO") {
        runpath("launch_ssto",apo,hdg).
    }
    else runpath("launch_asc",apo,hdg).

}
else{
    runpath("launch_vac").
}