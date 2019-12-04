/////////////////////////////////////////////////////////////////////////////
// Land
/////////////////////////////////////////////////////////////////////////////
// Make groundfall. Try to avoid a rapid unplanned disassemble. 
// Warranty void if used with air
//
// Usage: RUN LANDVAC(<mode>,<latitude>,<longitude>).
//
//       Parameters:
//          <mode>: Can be TARG, COOR or SHIP.
//                  -TARG (default) will try to land on the selected target. 
//                  If has no valid target falls back to SHIP.
//                  -COOR will try to land on <latitude> and <longitude>. 
//                  -SHIP will try to land in the coordinates that ship is
//                  flying over when the program start.
/////////////////////////////////////////////////////////////////////////////


// General logic:
// 0) Be in a circular, zero inclination orbit.
// 1) Calculate a Hohmann Transfer with:
//    - Target altitude = 1% of body radius above ground
// 2) Calculate a phase angle so the periapsis of the new orbit will be right over the landing site
// 3) Take a point 270º before the landing site and do the plane change 
// 4) Do the deorbit burn

// LandMode defines how this program will work
PARAMETER LandMode is "TARG".
PARAMETER LandLat is ship:geoposition:lat.  
PARAMETER LandLng is ship:geoposition:lng.


LOCAL MaxHVel is 1.
LOCAL FinalBurnHeight is 20.

runoncepath("lib_ui").
runoncepath("lib_util").
runoncepath("lib_parts").
runoncepath("lib_land").

SAS OFF.
BAYS OFF.
GEAR OFF.
LADDERS OFF.

DrawDebugVectors on.



// ************
// MAIN PROGRAM
// ************


// DEORBIT SEQUENCE
if ship:status = "ORBITING" {

    if NOT body:atm:exists uiWarning("Deorbit","Warning: This program works best with atmosphere.").

    // Zero the orbit inclination
    IF abs(OBT:INCLINATION) > 0.1 {
        uiBanner("Deorbit","Setting an equatorial orbit").
        RUNPATH("node_inc_equ.ks",0).
        RUNPATH("node.ks").
    }
    // Circularize the orbit
    if obt:eccentricity > 0.01 {
        uiBanner("Deorbit","Circularizing the orbit").
        run circ.
    }

    // Find where to land
    if LandMode:contains("TARG") { 
        if hastarget and TARGET:BODY = SHIP:BODY { // Make sure have a target in the same planet at least! Note it doesn't check if target is landed/splashed, will just use it's position, for all it cares.
            set LandLat to utilLongitudeTo360(TARGET:GEOPOSITION:LAT).
            set LandLng to utilLongitudeTo360(TARGET:GEOPOSITION:LNG).
        }
        else { //KSC Coordinates
            set LandLat to -0.0483334.
            set LandLng to -74.724722.
        }
    }
    else if LandMode:contains("COOR") {
        set LandLat to utilLongitudeTo360(LandLat).
        set LandLng to utilLongitudeTo360(LandLng).
    }
    else if LandMode:contains("SHIP") {
        set LandLat to utilLongitudeTo360(ship:geoposition:lat).
        set LandLng to utilLongitudeTo360(ship:geoposition:lng).
    }
    else {
        uiFatal("Land","Invalid mode").
    }

    SET LandingSite to LATLNG(LandLat,LandLng).

    //Define the deorbit periapsis
    local DeorbitRad to ship:body:radius*1.05.

    // Find a phase angle for the landing
    // The landing burning is like a Hohmann transfer, but to an orbit close to the body surface
    local r1 is ship:orbit:semimajoraxis.                               //Orbit now
    local r2 is DeorbitRad .                                            // Target orbit
    local pt is 0.5 * ((r1+r2) / (2*r2))^1.5.                           // How many orbits of a target in the target (deorbit) orbit will do.
    local sp is sqrt( ( 4 * constant:pi^2 * r2^3 ) / body:mu ).         // Period of the target orbit.
    local DeorbitTravelTime is pt*sp.                                   // Transit time 
    local phi is (DeorbitTravelTime/ship:body:rotationperiod) * 360.    // Phi in this case is not the angle between two orbits, but the angle the body rotates during the transit time
    local IncTravelTime is ship:obt:period / 4. // Travel time between change of inclinationa and lower perigee
    local phiIncManeuver is (IncTravelTime/ship:body:rotationperiod) * 360.

    // Deorbit and plane change longitudes
    Set Deorbit_Long to utilLongitudeTo360(LandLng - 176).
    Set PlaneChangeLong to utilLongitudeTo360(LandLng - 266).

    // Plane change for landing site
    local vel is velocityat(ship, landTimeToLong(PlaneChangeLong)):orbit.
    local inc is LandingSite:lat.
    local TotIncDV is 2 * vel:mag * sin(inc / 2).
    local nDv is vel:mag * sin(inc).
    local pDV is vel:mag * (cos(inc) - 1 ).

    if TotIncDV > 0.1 { // Only burn if it matters.
        uiBanner("Deorbit","Burning dV of " + round(TotIncDV,1) + " m/s @ anti-normal to change plane.").
        LOCAL nd IS NODE(time:seconds + landTimeToLong(PlaneChangeLong+phiIncManeuver), 0, -nDv, pDv).
        add nd. run node.
    }

    // Lower orbit over landing site
    local Deorbit_dV is landDeorbitDeltaV(DeorbitRad-body:radius).
    uiBanner("Deorbit","Burning dV of " + round(Deorbit_dV,1) + " m/s retrograde to deorbit.").
    LOCAL nd IS NODE(time:seconds + landTimeToLong(Deorbit_Long+phi) , 0, 0, Deorbit_dV).
    add nd. run node. 
    uiBanner("Deorbit","Deorbit burn done"). 
    wait 5. // Let's have some time to breath and look what's happening 

    // Warp to ATM
    uiBanner("Deorbit","Time warping until atmosphere"). 
    SAS OFF.
    SET KUNIVERSE:TIMEWARP:MODE TO "RAILS".
    SET KUNIVERSE:TIMEWARP:WARP to 2.
    WAIT UNTIL SHIP:ALTITUDE < BODY:ATM:HEIGHT * 1.2.
    KUNIVERSE:TIMEWARP:CANCELWARP().
    wait until kuniverse:timewarp:issettled.
    uiBanner("Deorbit","Going butt first"). 
    SAS OFF.    
    WAIT 3.    
    LOCK steering TO RETROGRADE.
    SET NAVMODE TO "SURFACE".
    uiBanner("Deorbit","Retrograde"). 
    PANELS OFF.
    RADIATORS OFF.
    LADDERS OFF.
    BAYS OFF.
    DEPLOYDRILLS OFF.
    LEGS OFF.
    partsRetractAntennas().    
}


// Try to land
if ship:status = "SUB_ORBITAL" or ship:status = "FLYING" {
    local TouchdownSpeed is 2.
    local BurnStarted is false.

    //PID Throttle
    SET ThrottlePID to PIDLOOP(0.10,0.08,0.02). // Kp, Ki, Kd
    SET ThrottlePID:MAXOUTPUT TO 1.
    SET ThrottlePID:MINOUTPUT TO 0.
    SET ThrottlePID:SETPOINT TO 0. 

    //Fuel Burning Time
    DECLARE function AverageISP {
        LIST ENGINES IN myVariable.
        LOCAL N is 0.
        LOCAL TIsp is 0.
        FOR eng IN myVariable {
            SET TIsp to TIsp + eng:ISP.
            SET N TO N + 1.
        }
        return TIsp/N.
    }

    DECLARE function FuelTime {
        Local FuelMass IS SHIP:MASS - SHIP:DRYMASS.
        If FuelMass > 0 and Ship:AvailableThrustat(1) > 0 {
            return FuelMass / (Ship:AvailableThrustat(1) / (AverageISP() * Constant:g0)).
        }
        Else {
            Return 0.
        }
    }

    // Math and parameters
    Lock fTime to FuelTime().
    local g is body:mu / ((body:radius)^2).
    lock ShipVelocity to SHIP:velocity:surface.
    lock ShipWeight to (Ship:Mass * g).
    lock accl to (Ship:AvailableThrustat(1) - ShipWeight) / Ship:Mass.
    lock dTime to ShipVelocity:MAG / accl.
    lock BurnDist to (ShipVelocity:MAG * dTime) - (0.5*accl*(dTime^2)).
    lock BurnAlt to BurnDist + FinalBurnHeight.

    //Check Stages   

    until Ship:AvailableThrustat(1) > ShipWeight or stage:number = 0 {
        uiBanner("Suicide burn","Staging rocket for landing."). 
        if stage:ready Stage.      
        wait 1.
    }

    If stage:number = 0 and Ship:AvailableThrustat(1) < ShipWeight {
        uiBanner("Suicide burn","This ship can't do a propulsive landing. Good luck."). 
        chutes on.
        wait until chutes and landRadarAltimeter() < 1000.
    }

    Until dTime < fTime {
        if DrawDebugVectors {
            PRINT "Needed burn time     " + dTime + "                           " at (0,0).
            Print "Available burn time  " + fTime + "                           " at (0,1).
        }
        WAIT 0.
    }
    uiBanner("Suicide burn","Steering and waiting for burn."). 

    UNLOCK STEERING.
    LIGHTS ON. //We want the Kerbals to see where they are going right?
    LEGS OFF. 

    // Throttle and Steering
    local tVal is 0.
    lock Throttle to tVal.
    local sDir is ship:up.
    lock steering to sDir.

    // Main landing loop
    UNTIL SHIP:STATUS = "LANDED" OR SHIP:STATUS = "SPLASHED" {

        WAIT 0.
        //******************
        // Steer the rocket
        //******************
        SET ShipVelocity TO SHIP:velocity:surface.
        SET ShipHVelocity to vxcl(SHIP:UP:VECTOR,ShipVelocity).

        // Default scenario, try to compensate for horizontal velocity while brake
        SET SteerVector to -ShipVelocity - ShipHVelocity. 

        // Put the ship upright if slow enough.
        IF SHIP:VERTICALSPEED > -TouchdownSpeed {
            SET SteerVector to SHIP:UP:VECTOR.
        }

        // Near touchdown make sure the ship is pointed straight up.
        IF landRadarAltimeter() <  FinalBurnHeight*2 {
            SET SteerVector to SHIP:UP:VECTOR.
        }        
        // If the horizontal velocity is low enough, just compensate for ship velocity.
        ELSE IF ShipHVelocity:MAG < MaxHVel {
            SET SteerVector to -ShipVelocity.
        }
       
 
        set sDir TO SteerVector:Direction. 

        //*********************
        // Throttle the rocket 
        //*********************   
        if landRadarAltimeter() < FinalBurnHeight {
            set TargetVSpeed to TouchdownSpeed.
        }
        else {
            // Torricelli Equation (Limited to 2G Accl)
            set TargetVSpeed to max(sqrt(2 * min(abs(Accl),19.6) * (landRadarAltimeter() - FinalBurnHeight)),TouchdownSpeed). 
        }
        IF Not BurnStarted and landRadarAltimeter() < BurnAlt {
            uiBanner("Suicide burn","Burning!"). 
            BurnStarted On.            
        }
        ELSE IF BurnStarted
        {
            set tVal TO ThrottlePID:UPDATE(TIME:seconds,(SHIP:VERTICALSPEED + TargetVSpeed)).
        }

        // Use RCS to help remove horizontal velocity
        if BurnStarted AND ShipHVelocity:mag > MaxHVel {
            RCS ON.
            local sense is ship:facing.
            local dirV is V(
            vdot(ShipHVelocity, sense:starvector),
            vdot(ShipHVelocity, sense:upvector),
            vdot(ShipHVelocity, sense:vector)
            ).
            set ship:control:translation to -dirV:normalized.
        }
        else {
            set ship:control:translation to v(0,0,0).
        }

        // Check for fuel
        if BurnStarted and fTime < 1 {
            chutes on.
        }
        // Check for Accl
        if Accl < 0 {
            chutes on.
        }


        // Deploy Legs
        IF BurnStarted AND dTime < 5 OR landRadarAltimeter() < FinalBurnHeight LEGS ON.

        if DrawDebugVectors {
            SET DRAWSV TO VECDRAW(v(0,0,0),SteerVector, red, "", 1, true, 1). // Steering
            SET DRAWV TO VECDRAW(v(0,0,0),ShipVelocity, green, "", 1, true, 1). // Velocity
            SET DRAWHV TO VECDRAW(v(0,0,0),ShipHVelocity, YELLOW, "", 1, true, 1). //Horizontal Velocity
            //SET DRAWTV TO VECDRAW(v(0,0,0),TargetVector, Magenta, "Target", 1, true, 1).

            PRINT "Vertical speed " + abs(Ship:VERTICALSPEED) + "                           " at (0,0).
            Print "Target Vspeed  " + TargetVSpeed            + "                           " at (0,1).
            print "Throttle       " + tVal                    + "                           " at (0,2).
            print "Ship Velocity  " + ShipVelocity:MAG        + "                           " at (0,3).
            print "Ship height    " + landRadarAltimeter()    + "                           " at (0,4).
            print "                                                                         " at (0,5).
            Print "Burn Alt       " + BurnAlt                 + "                           " at (0,6).
            Print "Burn Time      " + dTime                   + "                           " at (0,7).
            Print "accl           " + accl                    + "                           " at (0,8).
            Print "Fuel Time      " + FTime                   + "                           " at (0,9).
        }
    }

    // Release controls
    UNLOCK THROTTLE. UNLOCK STEERING.
    SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
    clearvecdraws().
    LADDERS ON.
    SAS ON. // Helps to don't tumble after landing
}
else if ship:status = "ORBITING" uiError("Land","This ship is still in orbit!?").
else if ship:status = "LANDED" or ship:status = "SPLASHED" uiError("Land","We are already landed, nothing to do here, move along").
else uiError("Land","Can't land from " + ship:status).
