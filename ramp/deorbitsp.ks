PARAMETER DeorbitLongOffset IS 0. // Diference from the default deorbit longitude.
PARAMETER Slope is 20.

runoncepath("lib_ui").
runoncepath("lib_parts").
runoncepath("lib_util").
runoncepath("lib_terrain").

SAS OFF.
SET SteeringManager:ROLLCONTROLANGLERANGE to 180. //Make the cooked controls work better with space planes.

local DeorbitSPKSCRW09 is latlng(-0.04807,-74.82).

FUNCTION LngToDegrees { 
    //From youtube.com/cheerskevin
    PARAMETER lng.
    RETURN MOD(lng + 360, 360).
}

FUNCTION TimeToLong {
    PARAMETER lng.

    LOCAL SDAY IS BODY("KERBIN"):ROTATIONPERIOD. // Duration of Kerbin day in seconds
    LOCAL KAngS IS 360/SDAY. // Rotation angular speed.
    LOCAL P IS SHIP:ORBIT:PERIOD.
    LOCAL SAngS IS (360/P) - KAngS. // Ship angular speed acounted for Kerbin rotation.
    LOCAL TgtLong IS LngToDegrees(lng).
    LOCAL ShipLong is LngToDegrees(SHIP:LONGITUDE). 
    LOCAL DLong IS TgtLong - ShipLong. 
    IF DLong < 0 {
        RETURN (DLong + 360) / SAngS. 
    }
    ELSE {
        RETURN DLong / SAngS.
    }
}

FUNCTION deorbitspGroundDistance {
    // Returns distance to a point in ground from the ship's ground position (ignores altitude)
    PARAMETER TgtPos.
    RETURN vxcl(up:vector, TgtPos:Position):mag.
}


FUNCTION deorbitspGlideslope{
    //Returns the altitude of the glideslope
    PARAMETER GSAngle IS 20.
    PARAMETER Threshold IS latlng(-0.04807,-74.82).
    PARAMETER Offset is -4000. // So we move to fly program under the slope
    LOCAL KerbinAngle is abs(ship:geoposition:lng) - abs(Threshold:lng).
    LOCAL Correction IS SQRT( (KERBIN:RADIUS^2) + (TAN(KerbinAngle)*KERBIN:RADIUS)^2 ) - KERBIN:Radius. // Why this correction? https://imgur.com/a/CPHnD
    RETURN (tan(GSAngle) * deorbitspGroundDistance(Threshold)) + Threshold:terrainheight + Correction + Offset.
}



//SET Deorbit_Long TO -149.8 + DeorbitLongOffset.
SET Deorbit_Long TO -146.8 + DeorbitLongOffset.
SET Deorbit_dV TO -110. 
SET Deorbit_Inc to 0.
SET Deorbit_Alt to 80000.

SAS OFF.
SET ORBITOK TO FALSE.
SET INCOK TO FALSE.

IF ship:status = "ORBITING" {

    UNTIL ORBITOK AND INCOK {

        // Check if orbit is acceptable and correct if needed.

        IF NOT (OBT:INCLINATION < (Deorbit_Inc + 0.1) AND 
                OBT:INCLINATION > (Deorbit_Inc - 0.1)) {
                    uiBanner("Deorbit","Changing inclination from " + round(OBT:INCLINATION,2) + 
                    "º to " + round(Deorbit_Inc,2) + "º").
                    RUNPATH("node_inc_equ",Deorbit_Inc).
                    RUNPATH("node").
                }
        ELSE { SET INCOK TO TRUE.}

        IF NOT (OBT:APOAPSIS < (Deorbit_Alt + Deorbit_Alt*0.05) AND 
                OBT:APOAPSIS > (Deorbit_Alt - Deorbit_Alt*0.05) AND
                OBT:eccentricity < 0.1 ) {
                    uiBanner("Deorbit","Establishing a new orbit at " + round(Deorbit_Alt/1000) + "km" ).
                    RUNPATH("circ_alt",Deorbit_Alt).
        }
        ELSE { SET ORBITOK TO TRUE. }

    }
    UNLOCK STEERING. UNLOCK THROTTLE. WAIT 5.

    // Add Deorbit maneuver node.
    uiBanner("Deorbit","Doing the deorbit burn").
    LOCAL nd IS NODE(time:seconds + TimeToLong(Deorbit_Long), 0, 0, Deorbit_dV).
    WAIT UNTIL KUniverse:CANQUICKSAVE.
    KUniverse:QUICKSAVETO("RAMP-Before Reenter").
    ADD nd. RUN NODE.

    // Configure the ship to reenter.
    PANELS OFF.
    BAYS OFF.
    GEAR OFF.
    LADDERS OFF.
    SAS OFF.
    RCS ON.
    partsDisarmsChutes().
    partsRetractAntennas().
    partsRetractRadiators().
}

LOCK THROTTLE TO 0.
uiBanner("Deorbit","Holding 40º Pitch until ready for atmospheric flight").
LOCK STEERING TO HEADING(90,40).
WAIT Until utilIsShipFacing(HEADING(90,40):Vector).
SET KUNIVERSE:TIMEWARP:MODE TO "RAILS".
SET KUNIVERSE:TIMEWARP:WARP to 2.
WAIT UNTIL SHIP:ALTITUDE < 71000.
KUNIVERSE:TIMEWARP:CANCELWARP().
WAIT UNTIL SHIP:ALTITUDE > deorbitspGlideslope(Slope) OR ship:airspeed < 340 OR TerrainGroundDistance(DeorbitSPKSCRW09) < 60000.
PRINT(TerrainGroundDistance(DeorbitSPKSCRW09)).
uiBanner("Deorbit","Preparing for atmospheric flight...").
//LOCK STEERING TO HEADING(90,-Slope-5).
LOCK STEERING TO LOOKDIRUP(DeorbitSPKSCRW09:POSITION(),SHIP:UP:VECTOR).
WAIT UNTIL SHIP:ALTITUDE < 12000 OR SHIP:VELOCITY:SURFACE:MAG < 900 OR TerrainGroundDistance(DeorbitSPKSCRW09) < 40000.
uiBanner("Deorbit","Activating atmospheric autopilot...").
UNLOCK THROTTLE.
UNLOCK STEERING.
SAS ON.
run fly("SHUTTLE","Tricycle",Slope).