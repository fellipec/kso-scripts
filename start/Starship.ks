@lazyglobal off.

runoncepath("lib_ui").
runoncepath("lib_util").
runoncepath("lib_parts").
runoncepath("lib_land").

local OrbitOptions is lexicon(
	"C","Exit to command line",
	"1","Rendez-vous with Skylab",
	"2","Rendez-vous with ISS",
	"X","Return to KSC").

IF ship:status = "PRELAUNCH" {
	RUN LAUNCH_ASC(110000).
	LOCK STEERING TO PROGRADE.
	WAIT 20.
	STAGE.
	WAIT 1.
	unlock steering.
	reboot.
}

ELSE IF ship:status = "ORBITING" {
	IF STAGE:NUMBER > 0 STAGE.
	rcs off.
	local choice is uiTerminalMenu(OrbitOptions).
	if choice = 1 {
		SET TARGET TO VESSEL("Skylab").
		RUN RENDEZVOUS.
	}
	if choice = 2 {
		SET TARGET TO VESSEL("ISS").
		RUN RENDEZVOUS.
	}
	else if choice = "X" {
		landstarship().
	}
}

declare function landstarship {
    run circ_alt(100000).
    SAS OFF.
    BAYS OFF.
    GEAR OFF.
    LADDERS OFF.

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
    //DESERT
    local LandLat is 0.0.
    local LandLng is -100.
    LOCAL LandingSite is LATLNG(LandLat,LandLng).

    //Define the deorbit periapsis
    local DeorbitRad to ship:body:radius*1.0.

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
    local Deorbit_Long is utilLongitudeTo360(LandLng - 176).
    local PlaneChangeLong is utilLongitudeTo360(LandLng - 266).

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
    WAIT UNTIL SHIP:ALTITUDE < BODY:ATM:HEIGHT * 1.05.
    KUNIVERSE:TIMEWARP:CANCELWARP().
    wait until kuniverse:timewarp:issettled.
    uiBanner("Deorbit","Wait until 17Km"). 
    PANELS OFF.
    RADIATORS OFF.
    LADDERS OFF.
    BAYS OFF.
    DEPLOYDRILLS OFF.
    LEGS OFF.
    GEAR OFF.
    BRAKES ON.
    RCS OFF.
    partsRetractAntennas().
    
    LOCK orbitnormVec to VCRS(SHIP:BODY:POSITION,SHIP:VELOCITY:ORBIT).  // Cross-product these for a normal vector
    
    LOCK STEERING TO LOOKDIRUP( VCRS(orbitnormVec,SHIP:VELOCITY:SURFACE), up:vector).

    until ship:ALTITUDE < 17000 {
        wait 1.
    }
    RCS ON.
    run land.

}