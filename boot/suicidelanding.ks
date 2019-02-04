DECLARE FUNCTION AboutToLand {
    if ship:status = "FLYING" AND SHIP:Altitude < 6000 and SHIP:verticalspeed < 0 AND RA < 1000 {
        return True.
    }
    else {
        return False.
    }
}.

FUNCTION RA {
    Return ship:altitude - ship:geoposition:terrainheight.
}.

When AboutToLand Then {
    Abort ON.
}.


print "No commands here. Press CTRL+D and choose another CPU".


Until abouttoland {
    wait 1.
}
RCS ON.
Print "LANDING SEQUENCE ACTIVATED".

Until SHIP:status = "LANDED" {
    wait 5.
}