@lazyglobal off.
// FLY.KS 
// Usage: Type 'RUN FLY.' in kOS console for piloting planes.
// For shuttle reentry type 'RUN FLY("SHUTTLE").' in console when shuttle is about 20000 and about over the mountains. Your mileage may vary.

PARAMETER KindOfCraft IS "Plane". // KindOfCraft valid values are "Plane" and "Shuttle". This changes the way the craft lands.
PARAMETER LandingGear IS "Tricycle". // LandingGear valid values are "Tricycle" or "Taildragger". This changes how to handle the plane after touchdown. 
PARAMETER ShuttleGS is 20. // Default ILS Glideslope angle

runoncepath("lib_ui").
runoncepath("lib_parts").

CLEARVECDRAWS().
CLEARGUIS().

local OldIPU is Config:IPU.
if OldIPU < 500 set Config:IPU to 500. 

Local CONSOLEINFO is FALSE.
uiDebug("CONSOLE OUTPUT IS " + CONSOLEINFO).

//////////////////////////////////////////////
// Functions to use exclusive with this script
//////////////////////////////////////////////

FUNCTION Mach {
    PARAMETER SpdMS.
    LOCAL AirTemp IS 288.15.
    IF HasTermometer { SET AirTemp TO SHIP:SENSORS:TEMP.  }.
    RETURN SpdMS / SQRT(1.4*286*AirTemp).
}

FUNCTION YawError {
    LOCAL yaw_error_vec IS VXCL(FACING:TOPVECTOR,ship:srfprograde:vector).
    LOCAL yaw_error_ang IS VANG(FACING:VECTOR,yaw_error_vec).
    IF VDOT(SHIP:FACING:STARVECTOR, SHIP:srfprograde:VECTOR) < 0 {
        RETURN yaw_error_ang.
    }
    ELSE {
        RETURN -yaw_error_ang.
    }
    
}

Function YawAngVel {
    RETURN vdot(facing:topvector, ship:angularvel).
}

FUNCTION AoA {
    LOCAL pitch_error_vec IS VXCL(FACING:STARVECTOR,ship:srfprograde:vector).
    LOCAL pitch_error_ang IS VANG(FACING:VECTOR,pitch_error_vec).
    IF VDOT(SHIP:FACING:TOPVECTOR, SHIP:srfprograde:VECTOR) < 0 {
        RETURN pitch_error_ang.
    }
    ELSE {
        RETURN -pitch_error_ang.
    }
    
}

FUNCTION BankAngle {
    LOCAL starBoardRotation TO SHIP:FACING * R(0,90,0).
    LOCAL starVec TO starBoardRotation:VECTOR.
    LOCAL horizonVec to VCRS(SHIP:UP:VECTOR,SHIP:FACING:VECTOR).
    
    IF VDOT(SHIP:UP:VECTOR, starVec) < 0{
        RETURN VANG(starVec,horizonVec).
    }
    ELSE {
        RETURN -VANG(starVec,horizonVec).
    }    
}

Function BankAngVel {
    RETURN -vdot(facing:vector, ship:angularvel).
}

FUNCTION PitchAngle {
    RETURN -(VANG(ship:up:vector,ship:facing:FOREVECTOR) - 90).
}

Function PitchAngVel {
    RETURN -vdot(facing:starvector, ship:angularvel).
}

FUNCTION ProgradePitchAngle {
    RETURN -(VANG(ship:up:vector,vxcl(ship:facing:starvector,ship:velocity:surface)) - 90).
}

FUNCTION MagHeading {
    local northPole TO latlng(90,0).
    Return mod(360-northPole:bearing, 360).
}

FUNCTION CompassDegrees {
    PARAMETER DEGREES.
    RETURN mod(360-DEGREES, 360).
}

FUNCTION RadarAltimeter {
    Return ship:altitude - ship:geoposition:terrainheight.
}

FUNCTION DeltaHeading {
    PARAMETER tHeading.
    // Heading Control
    LOCAL dHeading to tHeading - magheading().
    if dHeading > 180 {
        SET dHeading TO dHeading - 360.
    }
    else if dHeading < -180 {
        SET dHeading TO dHeading + 360.
    }
    Return dHeading.
}

FUNCTION GroundDistance {
    // Returns distance to a point in ground from the ship's ground position (ignores altitude)
    PARAMETER TgtPos.
    RETURN vxcl(up:vector, TgtPos:Position):mag.
}

FUNCTION Glideslope{
    //Returns the altitude of the glideslope
    PARAMETER Threshold.
    PARAMETER GSAngle IS 5.
    PARAMETER Offset is 20.
    LOCAL KerbinAngle is abs(ship:geoposition:lng) - abs(Threshold:lng).
    LOCAL Correction IS SQRT( (KERBIN:RADIUS^2) + (TAN(KerbinAngle)*KERBIN:RADIUS)^2 ) - KERBIN:Radius. // Why this correction? https://imgur.com/a/CPHnD
    RETURN (tan(GSAngle) * GroundDistance(Threshold)) + Threshold:terrainheight + Correction + Offset.
}

FUNCTION CenterLineDistance {
    //Returns the ground distance of the centerline
    PARAMETER Threshold.
    LOCAL Marker IS latlng(Threshold:lat,Ship:geoposition:lng).
    IF SHIP:geoposition:lat > Threshold:lat {
        RETURN GroundDistance(Marker).
    }
    ELSE {
        RETURN -GroundDistance(Marker).
    }
}

FUNCTION PlaneWeight {
    local g is body:mu / ((body:radius)^2).
    return (Ship:Mass * g).
}

Function PitchLimit {
    local ShipWeight is PlaneWeight().
    if Ship:AvailableThrustAt(1) > ShipWeight return 45.
    uiDebug("TWR: " + Round((Ship:AvailableThrustAt(1) / ShipWeight),2) ).
    return max(10,Ship:AvailableThrustAt(1) / ShipWeight * 30).
}


FUNCTION TakeOff {
    
    local LandedAlt is ship:altitude.
    sas off.
    brakes off.
    lights on.
    ladders off.
    stage.
    lock throttle to 1.
    local P is PitchLimit().
    LOCK STEERING TO HEADING(MagHeading(), 0).
    wait until ship:airspeed > 50.
    LOCK STEERING TO HEADING(MagHeading(), P*0.66).
    wait until ship:altitude > LandedAlt + 30.
    gear off.
    wait until ship:altitude > LandedAlt + 200.
    lights off.
    
    unlock steering.
    wait 0.
    sas on.
    unlock throttle.
}

local VerticalGTime0 is time:seconds.
local VerticalGSpeed0 is SHIP:VerticalSpeed.
FUNCTION FuncVerticalG {
    local DeltaT is time:seconds - VerticalGTime0.
    local DeltaV is SHIP:VerticalSpeed - VerticalGSpeed0.
    set VerticalGTime0 to time:seconds.
    set VerticalGSpeed0 to SHIP:VerticalSpeed.
    IF DeltaT = 0 {
        return 0.
    }
    else{
        return DeltaV/DeltaT.
    }
}









////////////////////
// Graphic Interface
////////////////////

// GUI FOR TAKE OFF
IF SHIP:STATUS = "LANDED" OR SHIP:STATUS = "PRELAUNCH" {
    LOCAL guiTO IS GUI(300).
    LOCAL labelAutoTakeoff IS guiTO:ADDLABEL("<size=20><b>Auto takeoff?</b></size>").
    SET labelAutoTakeoff:STYLE:ALIGN TO "CENTER".
    SET labelAutoTakeoff:STYLE:HSTRETCH TO True. 

    LOCAL autoTOYes TO guiTO:ADDBUTTON("Yes").
    LOCAL autoTONo  TO guiTO:ADDBUTTON("No").
    guiTO:SHOW().
    LOCAL atdone to false.
    SET autoTOYes:ONCLICK TO { guiTO:hide. takeoff().  set atdone to true. }.
    SET autoTONo:ONCLICK TO { guiTO:hide. wait until ship:altitude > 1000. set atdone to true. }.
    wait until atdone.
}

//Waypoint Selection screen
LOCAL guiWP IS GUI(200).
SET guiWP:x TO 360.
SET guiWP:y TO 100.
LOCAL labelSelectWaypoint IS guiWP:ADDLABEL("<size=20><b>Select waypoint:</b></size>").
SET labelSelectWaypoint:STYLE:ALIGN TO "CENTER".
SET labelSelectWaypoint:STYLE:HSTRETCH TO True. 

LOCAL buttonWP01 TO guiWP:ADDBUTTON("KSC Runway 09").
SET buttonWP01:ONCLICK TO 
    {
        set TargetCoord to latlng(-0.0483334,-74.724722). // RWY 09
        set TGTAltitude to 1000.
        SET LNAVMODE TO "TGT".
        SET LabelWaypoint:TEXT to "KSC Runway 09".
        guiWP:hide.
    }.

LOCAL buttonWP02 TO guiWP:ADDBUTTON("RNAV RWY09 Waypoint 1").
SET buttonWP02:ONCLICK TO 
    {
        set TargetCoord to latlng(-2,-77.7). 
        set TGTAltitude to 2500.
        SET LNAVMODE TO "TGT".
        SET LabelWaypoint:TEXT to "RNAV RWY09 Waypoint 1".
        guiWP:hide.
    }.

LOCAL buttonWP03 TO guiWP:ADDBUTTON("Begin of glideslope").
SET buttonWP03:ONCLICK TO 
    {
        set TargetCoord to latlng(-0.0483334,-77). // Glideslope
        set TGTAltitude to 4000.
        SET LNAVMODE TO "TGT".
        SET LabelWaypoint:TEXT to "Begin of glideslope".
        guiWP:hide.
    }.

LOCAL buttonWP04 TO guiWP:ADDBUTTON("Moutains").
SET buttonWP04:ONCLICK TO 
    {
        set TargetCoord to latlng(-0.0483334,-79.5). // Mountains
        set TGTAltitude to 8000.
        SET LNAVMODE TO "TGT".
        SET LabelWaypoint:TEXT to "Moutains".
        guiWP:hide.
    }.

LOCAL buttonWP05 TO guiWP:ADDBUTTON("Far west").
SET buttonWP05:ONCLICK TO 
    {
        set TargetCoord to latlng(-0.0483334,-85). // Far west
        set TGTAltitude to 9000.
        SET LNAVMODE TO "TGT".
        SET LabelWaypoint:TEXT to "Far west".
        guiWP:hide.
    }.

LOCAL buttonWP06 TO guiWP:ADDBUTTON("Old Airfield").
SET buttonWP06:ONCLICK TO 
    {
        set TargetCoord to latlng(-1.54084,-71.91). // Far west
        set TGTAltitude to 1500.
        SET LNAVMODE TO "TGT".
        SET LabelWaypoint:TEXT to "Old Airfield".
        guiWP:hide.
    }.

LOCAL buttonWP07 TO guiWP:ADDBUTTON("RNAV Old Airfield Waypoint 1").
SET buttonWP07:ONCLICK TO 
    {
        set TargetCoord to latlng(-1.3,-74.5). 
        set TGTAltitude to 2000.
        SET LNAVMODE TO "TGT".
        SET LabelWaypoint:TEXT to "RNAV Old Airfield Waypoint 1".
        guiWP:hide.
    }.

LOCAL buttonWP08 TO guiWP:ADDBUTTON("Baikerbanur").
SET buttonWP08:ONCLICK TO 
    {
        set TargetCoord to latlng(20.6572,-146.4205). 
        set TGTAltitude to 2000.
        SET LNAVMODE TO "TGT".
        SET LabelWaypoint:TEXT to "Baikerbanur".
        guiWP:hide.
    }.


// Main Window
LOCAL gui IS GUI(300).
SET gui:x TO 30.
SET gui:y TO 100.

LOCAL labelMode IS gui:ADDLABEL("<b>AP Mode</b>").
SET labelMode:STYLE:ALIGN TO "CENTER".
SET labelMode:STYLE:HSTRETCH TO True. 

LOCAL baseselectbuttons TO gui:ADDHBOX().
LOCAL radiobuttonKSC to baseselectbuttons:ADDRADIOBUTTON("Space Center",True).
LOCAL radiobuttonOAF to baseselectbuttons:ADDRADIOBUTTON("Old airfield",False).
LOCAL checkboxVectors to baseselectbuttons:ADDBUTTON("HoloILS™").
SET radiobuttonKSC:Style:HEIGHT TO 25.
SET radiobuttonOAF:Style:HEIGHT TO 25.
SET checkboxVectors:TOGGLE TO True.

SET baseselectbuttons:ONRADIOCHANGE TO {
    PARAMETER B.

    IF B:TEXT = "Space Center" {
        SET TGTRunway to RWYKSC.
    }
    IF B:TEXT = "Old airfield" {
        SET TGTRunway to RWYOAF.
    }
}.

LOCAL apbuttons TO gui:ADDHBOX().
LOCAL ButtonNAV   TO apbuttons:addbutton("HLD").
LOCAL ButtonILS   TO apbuttons:addbutton("ILS").
LOCAL ButtonAPOFF TO apbuttons:addbutton("OFF").

SET ButtonNAV:ONCLICK   TO { 
    SET APMODE TO "NAV".
    SET VNAVMODE TO "ALT".
    SET LNAVMODE TO "HDG".
    SET TGTAltitude TO ROUND(SHIP:ALTITUDE).
    SET TGTHeading TO ROUND(MagHeading()).
 }.
SET ButtonILS:ONCLICK   TO { SET APMODE TO "ILS". SET GSLocked TO FALSE. }.
SET ButtonAPOFF:ONCLICK TO { SET APMODE TO "OFF". }.

//Autopilot settings
LOCAL apsettings to gui:ADDVBOX().

//HDG Settings
LOCAL hdgsettings to apsettings:ADDHLAYOUT().
LOCAL ButtonHDG TO hdgsettings:ADDBUTTON("HDG").
SET ButtonHDG:Style:WIDTH TO 40.
SET ButtonHDG:Style:HEIGHT TO 25.
LOCAL ButtonHDGM TO hdgsettings:ADDBUTTON("◀").
SET ButtonHDGM:Style:WIDTH TO 40.
SET ButtonHDGM:Style:HEIGHT TO 25.
LOCAL LabelHDG TO hdgsettings:ADDLABEL("").
SET LabelHDG:Style:HEIGHT TO 25.
SET LabelHDG:STYLE:ALIGN TO "CENTER".
LOCAL ButtonHDGP TO hdgsettings:ADDBUTTON("▶").
SET ButtonHDGP:Style:WIDTH TO 40.
SET ButtonHDGP:Style:HEIGHT TO 25.

SET ButtonHDG:ONCLICK   TO { SET LNAVMODE TO "HDG". }.
SET ButtonHDGM:ONCLICK  TO { 
    SET TGTHeading TO ((ROUND(TGTHeading/5)*5) -5).
    IF TGTHeading < 0 {
        SET TGTHeading TO TGTHeading + 360.
    }
}.
SET ButtonHDGP:ONCLICK  TO { 
    SET TGTHeading TO ((ROUND(TGTHeading/5)*5) +5).
    IF TGTHeading > 360 {
        SET TGTHeading TO TGTHeading - 360.
    }
}.

//BNK Settings
LOCAL bnksettings to apsettings:ADDHLAYOUT().
LOCAL ButtonBNK TO bnksettings:ADDBUTTON("BNK").
SET ButtonBNK:Style:WIDTH TO 40.
SET ButtonBNK:Style:HEIGHT TO 25.
LOCAL ButtonBNKM TO bnksettings:ADDBUTTON("◀").
SET ButtonBNKM:Style:WIDTH TO 40.
SET ButtonBNKM:Style:HEIGHT TO 25.
LOCAL LabelBNK TO bnksettings:ADDLABEL("").
SET LabelBNK:Style:HEIGHT TO 25.
SET LabelBNK:STYLE:ALIGN TO "CENTER".
LOCAL ButtonBNKP TO bnksettings:ADDBUTTON("▶").
SET ButtonBNKP:Style:WIDTH TO 40.
SET ButtonBNKP:Style:HEIGHT TO 25.

SET ButtonBNK:ONCLICK TO { SET LNAVMODE TO "BNK". SET TGTBank TO BankAngle(). }.
SET ButtonBNKM:ONCLICK  TO { SET TGTBank TO ROUND(TGTBank) - 1. }.
SET ButtonBNKP:ONCLICK  TO { SET TGTBank TO ROUND(TGTBank) + 1. }.

//ALT Settings
LOCAL altsettings to apsettings:ADDHLAYOUT().
LOCAL ButtonALT TO altsettings:ADDBUTTON("ALT").
SET ButtonALT:Style:WIDTH TO 40.
SET ButtonALT:Style:HEIGHT TO 25.
LOCAL ButtonALTM TO altsettings:ADDBUTTON("▼").
SET ButtonALTM:Style:WIDTH TO 40.
SET ButtonALTM:Style:HEIGHT TO 25.
LOCAL LabelALT TO altsettings:ADDLABEL("").
SET LabelALT:Style:HEIGHT TO 25.
SET LabelALT:STYLE:ALIGN TO "CENTER".
LOCAL ButtonALTP TO altsettings:ADDBUTTON("▲").
SET ButtonALTP:Style:WIDTH TO 40.
SET ButtonALTP:Style:HEIGHT TO 25.

SET ButtonALT:ONCLICK   TO { SET VNAVMODE TO "ALT". }.
SET ButtonALTM:ONCLICK  TO { SET TGTAltitude TO (ROUND(TGTAltitude/100)*100) -100 .}.
SET ButtonALTP:ONCLICK  TO { SET TGTAltitude TO (ROUND(TGTAltitude/100)*100) +100 .}.

//PIT Settings
LOCAL pitsettings to apsettings:ADDHLAYOUT().
LOCAL ButtonPIT TO pitsettings:ADDBUTTON("PIT").
SET ButtonPIT:Style:WIDTH TO 40.
SET ButtonPIT:Style:HEIGHT TO 25.
LOCAL ButtonPITM TO pitsettings:ADDBUTTON("▼").
SET ButtonPITM:Style:WIDTH TO 40.
SET ButtonPITM:Style:HEIGHT TO 25.
LOCAL LabelPIT TO pitsettings:ADDLABEL("").
SET LabelPIT:Style:HEIGHT TO 25.
SET LabelPIT:STYLE:ALIGN TO "CENTER".
LOCAL ButtonPITP TO pitsettings:ADDBUTTON("▲").
SET ButtonPITP:Style:WIDTH TO 40.
SET ButtonPITP:Style:HEIGHT TO 25.

SET ButtonPIT:ONCLICK   TO { SET VNAVMODE TO "PIT". }.
SET ButtonPITM:ONCLICK  TO { SET TGTPitch TO ROUND(TGTPitch) -1 .}.
SET ButtonPITP:ONCLICK  TO { SET TGTPitch TO ROUND(TGTPitch) +1 .}.

// Waypoints selection
LOCAL ButtonWAYPOINTS TO apsettings:ADDBUTTON("Select waypoint").
LOCAL wpsettings to apsettings:ADDHLAYOUT().
LOCAL LabelWaypoint to wpsettings:ADDLABEL("No waypoint selected").
LOCAL LabelWaypointDist to wpsettings:ADDLABEL("").
SET LabelWaypointDist:STYLE:ALIGN TO "RIGHT".
SET ButtonWAYPOINTS:ONCLICK TO { guiWP:SHOW. }.

// Autothrottle
LOCAL atbuttons TO gui:ADDHBOX().
LOCAL ButtonSPD   TO atbuttons:addbutton("SPD").
LOCAL ButtonMCT   TO atbuttons:addbutton("MCT").
LOCAL ButtonATOFF TO atbuttons:addbutton("OFF").

SET ButtonSPD:ONCLICK   TO { SET ATMODE TO "SPD". }.
SET ButtonMCT:ONCLICK   TO { SET ATMODE TO "MCT". }.
SET ButtonATOFF:ONCLICK TO { SET ATMODE TO "OFF". }.

LOCAL spdctrl TO gui:ADDHBOX().
LOCAL ButtonSPDM TO spdctrl:ADDBUTTON("▼"). 
SET ButtonSPDM:Style:WIDTH TO 45.
SET ButtonSPDM:Style:HEIGHT TO 25.
LOCAL LabelSPD TO spdctrl:ADDLABEL("").
SET LabelSPD:Style:HEIGHT TO 25.
SET LabelSPD:STYLE:ALIGN TO "CENTER".
LOCAL ButtonSPDP TO spdctrl:ADDBUTTON("▲").
SET ButtonSPDP:Style:WIDTH TO 45.
SET ButtonSPDP:Style:HEIGHT TO 25.
//Adjust speed.
SET ButtonSPDM:ONCLICK TO { SET TGTSpeed TO (ROUND(TGTSpeed/5)*5) -5. }.
SET ButtonSPDP:ONCLICK TO { SET TGTSpeed TO (ROUND(TGTSpeed/5)*5) +5. }.

LOCAL labelAirspeed IS gui:ADDLABEL("<b>Airspeed</b>").
SET labelAirspeed:STYLE:ALIGN TO "LEFT".
SET labelAirspeed:STYLE:HSTRETCH TO True. 

LOCAL labelVSpeed IS gui:ADDLABEL("<b>Vertical speed</b>").
SET labelVSpeed:STYLE:ALIGN TO "LEFT".
SET labelVSpeed:STYLE:HSTRETCH TO True. 

LOCAL labelLAT IS gui:ADDLABEL("<b>LAT</b>").
SET labelLAT:STYLE:ALIGN TO "LEFT".
SET labelLAT:STYLE:HSTRETCH TO True.
SET labelLAT:STYLE:TEXTCOLOR TO YELLOW. 
LOCAL labelLNG IS gui:ADDLABEL("<b>LNG</b>").
SET labelLNG:STYLE:ALIGN TO "LEFT".
SET labelLNG:STYLE:HSTRETCH TO True. 
SET labelLNG:STYLE:TEXTCOLOR TO YELLOW. 

LOCAL ButtonReboot TO gui:ADDBUTTON("Reboot").

SET ButtonReboot:ONCLICK TO {
    gui:HIDE().
    SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
    reboot.
}.

gui:SHOW().

// ABORT!
ON ABORT {
    SET APATEnabled TO FALSE.
    uiWarning("Fly","Your controls!!!").
    PRESERVE.
}








// ////////////////
// SET UP PID LOOPS
// ////////////////
// Arguments = Kp, Ki, Kd, MinOutput, MaxOutput


//PITCH



// PID GS
local GSPID is PIDLOOP(3,0.40,0.10,-30,30). 
SET GSPID:SETPOINT TO 0.

// PID LOC
local LOCPID is PIDLOOP(0.8,0.10,0.05,-35,35). 
SET LOCPID:SETPOINT TO 0.

// PID Pitch Angle
local PitchAnglePID is PIDLOOP(2.00,1.0,0.00,-20,20). 
SET PitchAnglePID:SETPOINT TO 0.

// PID PitchAngVel
local PitchAngVelPID is PIDLOOP(0.045,0.008,0.000,-0.08,0.08). 
SET PitchAngVelPID:SETPOINT TO 0. 

// PID VSpeed
local VSpeedPID is PIDLOOP(0.15,0.05,0.005,-20,20). 
SET VSpeedPID:SETPOINT TO 0.

//PID Elevator 
local ElevatorPID is PIDLOOP(1.3,0.90,0.005,-1,1).
SET ElevatorPID:SETPOINT TO 0. 

// PID BankAngle
local BankAnglePID is PIDLOOP(2.0,0.50,0.75,-33,33). 
SET BankAnglePID:SETPOINT TO 0. 

// PID BankVel
local BankVelPID is PIDLOOP(0.0450,0.0008,0.0010,-0.5,0.5). 
SET BankVelPID:SETPOINT TO 0. 

//PID Aileron  
local AileronPID is PIDLOOP(0.12,0.008,0.001,-1,1). 
SET AileronPID:SETPOINT TO 0. 

//PID Yaw Damper
local YawDamperPID is PIDLOOP(1,0.3,0.1,-1,1). 
SET YawDamperPID:SETPOINT TO 0. 

// PID YawVel
local YawVelPID is PIDLOOP(0.04,0.02,0.01,-0.2,0.2). 
SET YawVelPID:SETPOINT TO 0. 

//PID Throttle
local ThrottlePID is PIDLOOP(0.10,0.02,0.50,0,1). 
SET ThrottlePID:SETPOINT TO 0. 

//Control surface variables
local Elevator is 0.
local Aileron is 0.
local Rudder is 0.

//Runways coordinates
//global RWYKSC is latlng(-0.04807,-74.65). Original value
global RWYKSC is latlng(-0.04807,-74.72).
global RWYKSC_SHUTTLE is latlng(-0.04807,-74.82).
global RWYOAF is latlng(-1.51764918920989,-71.9565681001265).

// Defauts
local APATEnabled is TRUE.
local APMODE is "NAV".
local APSHUTDOWN is FALSE.
local ATMODE is "SPD".
local AUTOTHROTTLE is TRUE.
local CLDist is 0.
local dAlt is 0.
local dHeading is 0.
local FLAREALT is 150.
local GSAng is 5.
local GSProgAng is 0.
local GSLocked is False.
local HasTermometer is partsHasTermometer().
local ILSHOLDALT is 0.
local LNAVMODE is "HDG".
local ManModePitchT0 is 0.
local ManModeRollT0 is 0.
local MaxAoA is 20.
local MaxGAllowed is 7.
local MaxGProt is False.
local PitchingDown is 1.
local PPA is 0.
local PREVIOUSAP is "".
local PREVIOUSAT is "".
local PREVIOUSLNAV is "".
local PREVIOUSVNAV is "".
local RA is RadarAltimeter().
local RCSEnableAlt is 12500.
local ShipStatus is Ship:Status.
local ShipResources is "".
local ShuttleWithJets is False.
local TargetCoord is RWYKSC.
local TGTAltitude is 1000.
local TGTBank is 0.
local TGTHeading is 90.
local TGTPitch is 0.
local TGTRunway is RWYKSC.
local TGTSpeed is 150.
local TimeOfLanding is 0.
local VNAVMODE is "ALT".
local VALUETHROTTLE is 0.

IF KindOfCraft = "Shuttle" {
    SET APMODE TO "ILS".
    SET TGTAltitude to 6000.
    SET TGTHeading to MagHeading().
    SET GSAng to ShuttleGS.
    SET TGTRunway TO RWYKSC_SHUTTLE.
    SET TargetCoord TO TGTRunway.
    SET LabelWaypoint:Text TO "Kerbin Space Center Runway 09".
    SET FLAREALT TO 275.
    // Pitch 
    SET GSPID:MAXOutput to -GSAng +25.
    SET GSPID:MINOutput to -GSAng -25.
    SET PitchAnglePID:MaxOutput to 15.
    SET PitchAnglePID:MinOutput to -ShuttleGS - 15.
    SET PitchAnglePID:KP to 2.000.
    SET PitchAnglePID:KI to 0.500.
    SET PitchAnglePID:KD to 0.001.
    SET ElevatorPID:KP TO 1.000. 
    SET ElevatorPID:KI TO 0.300. 
    SET ElevatorPID:KD TO 0.015. 

    //Roll
    SET AileronPID:KP TO 0.15.
    SET AileronPID:KI TO 0.01.
    SET AileronPID:KD TO 0.05.
    SET BankAnglePID:KP to 3.0.
    SET BankAnglePID:KI to 0.25.
    SET BankAnglePID:KD to 0.15.

    //Yaw Damper
    SET YawDamperPID:KP to 0.80. 
    SET YawDamperPID:KI to 0.1.
    SET YawDamperPID:KD to 0.25.
    SET YawVelPID:KP to 0.050. 
    SET YawVelPID:KI to 0.005.
    SET YawVelPID:KD to 0.005.

    //Air engine detection
    LIST Resources IN ShipResources.
    ShuttleWithJets OFF.
    FOR rsr IN ShipResources {
        IF rsr:name = "IntakeAir" ShuttleWithJets ON.
    }

    uiChime().
}
ELSE IF KindOfCraft = "Plane" {
    SET PitchAnglePID:MaxOutput to PitchLimit().
    SET PitchAnglePID:MinOutput to -PitchLimit().    
    // Adjust for high performance planes (TWR > 1)
    if Ship:AvailableThrustAt(1) > PlaneWeight()*1.1 {
        SET BankVelPID:MaxOutput to 1.5.
        SET BankVelPID:MinOutput to -1.5.
        SET BankAnglePID:MaxOutput to 50.
        SET BankAnglePID:MinOutput to -50.
        SET PitchAngVelPID:MaxOutput to 0.12.
        SET PitchAngVelPID:MinOutput to -0.12.        
        SET VSpeedPID:MaxOutput to 30.
        SET VSpeedPID:MinOutput to -30.    
        uiBanner("Fly","High Performance!").    
    }

    if ship:altitude < 1000 set TGTAltitude to 1000.
    else SET TGTAltitude to SHIP:Altitude.
    SET TGTHeading to MagHeading().
    SET GSAng TO 4.
    SET TGTRunway TO RWYKSC.
    SET TargetCoord TO TGTRunway.
    SET LabelWaypoint:Text TO "KSC Runway 09".
    SET FLAREALT TO 100.
    uiChime().
}

local AileronBaseKP is AileronPID:KP.
local AileronBaseKI is AileronPID:KP.
local AileronBaseKD is AileronPID:KP.

//Holo ILS Variables
local RAMPEND is 0.
local RAMPENDALT is 0.
local ILSVEC is 0.

// *********
// MAIN LOOP
// *********

partsDisarmsChutes(). //We don't want any chute deploing while flying, right?
local AirSPD is ship:airspeed.
local t0 is Time:Seconds.
local TimeNow is Time:seconds - t0.
local BaroAltitude is ship:altitude.
local SafeToExit is false.
local FlareAltMSL is flarealt + tgtrunway:terrainheight().

until SafeToExit {

    // Make sure cooked controls are off before engaging autopilot
    SAS OFF. 
    set RCS to ship:altitude > 18000.
    partsDisableReactionWheels().
    UNLOCK steering.
    UNLOCK THROTTLE.
    set TimeOfLanding to 0.

    until ShipStatus = "LANDED" or ShipStatus = "SPLASHED" {
        wait 0. // Skip a physics tick 

        set AirSPD to ship:airspeed.
        set TimeNow to Time:seconds -t0.
        set BaroAltitude to ship:altitude.
        set RA to RadarAltimeter().
        set PPA To ProgradePitchAngle().

        IF APATEnabled {
            IF SAS { SAS OFF. }

            // ********
            // ILS MODE
            // ********

            ELSE IF APMODE = "ILS" {
                SET TargetCoord TO TGTRunway.                
                SET TGTAltitude to Glideslope(TGTRunway,GSAng).
                IF KindOfCraft = "SHUTTLE" {
                    local GSProgAngSignal is 1.
                    IF VDOT(SHIP:UP:VECTOR,vxcl(ship:facing:starvector,ship:velocity:surface):normalized) < VDOT(SHIP:UP:VECTOR,TGTRunway:AltitudePosition(FlareAltMSL):normalized) {
                        SET GSProgAngSignal TO -1.
                    }
                    set GSProgAng to VANG(TGTRunway:Position,vxcl(ship:facing:starvector,ship:velocity:surface)) * GSProgAngSignal.
                    SET VNAVMODE TO "GS".
                }
                else {
                    //Checks if below GS
                    IF (NOT GSLocked) AND (BaroAltitude < TGTAltitude) {                
                        IF KindOfCraft = "SHUTTLE" { 
                            SET TGTPitch TO -GSAng/4. 
                            SET VNAVMODE TO "PIT".
                        }
                        ELSE { 
                            SET TGTAltitude TO (BaroAltitude + TGTAltitude) / 2.
                            SET VNAVMODE TO "ALT".
                        } 
                    }
                    ELSE {
                        SET VNAVMODE TO "ALT".
                        GSLocked ON.
                    }
                }


                //Checks distance from centerline
                local GDist to GroundDistance(TargetCoord).
                local AllowedDeviation is GDist * sin(0.3).
                SET CLDist TO CenterLineDistance(TGTRunway).
                IF ABS(CLDist) < AllowedDeviation {
                    SET LNAVMODE TO "HDG".
                    SET TGTHeading to 90.
                } 
                ELSE IF abs(CLDist) < GDist/3 {
                    SET TGTHeading TO ABS(90 + arcsin(CLDist/(GDist/3))).
                    SET LNAVMODE TO "HDG". 
                }
                ELSE {
                    SET TGTHeading TO 90 + ((CLDist/ABS(CLDist))*90). // 0 or 180 heading, depending if ship is north or south of runway.
                    SET LNAVMODE TO "HDG".
                } 


                // Checks for excessive airspeed on final. 
                IF KindOfCraft = "Plane" {
                    SET TGTSpeed to min(180,max(SQRT(TGTAltitude)*4,90)).
                    IF ATMODE <> "OFF" {
                        SET ATMODE to "SPD".
                    }
                    if      AirSPD > TGTSpeed*1.01 
                            and ship:control:pilotmainthrottle < 0.1 brakes on.
                    else if AirSPD < TGTSpeed 
                            or  ship:control:pilotmainthrottle > 0.4 brakes off. 
                }
                ELSE IF KindOfCraft = "Shuttle" { 
                    IF SHUTTLEWITHJETS {
                        SET TGTSpeed to max(SQRT(TGTAltitude)*6,100).
                        If AirSPD < 300 or TGTSpeed < 300 SET ATMODE TO "SPD".
                        IF ATMODE = "SPD" SET TGTSpeed to min(SQRT(TGTAltitude)*6,340).
                    }
                    ELSE {
                        SET TGTSpeed to max(SQRT(TGTAltitude)*9,100).
                        SET ATMODE to "OFF".
                    }
                    SET BRAKES to AirSPD > TGTSpeed.
                }
            }
            // **********
            // FLARE MODE
            // **********
            ELSE IF APMODE = "FLR" {
                // Configure Flare mode
                IF VNAVMODE <> "PIT" {
                    SET VNAVMODE TO "PIT".
                    SET TGTHeading TO 90.
                    SET PitchAngVelPID:MaxOutput to 0.5.
                    SET PitchAngVelPID:MinOutput to -0.3.
                    SET PitchAnglePID:KP TO 1.5.
                    SET PitchAnglePID:Ki TO 0.2.
                    SET PitchAnglePID:Kd TO 0.05.
                    SET PitchAnglePID:SETPOINT to 0.
                    IF KindOfCraft = "Shuttle" SET TGTSpeed TO  90.
                    ELSE                       SET TGTSpeed TO  70.

                }           
                // Adjust craft flight
                IF RA > 30 {
                    SET TGTPitch to PitchAnglePID:UPDATE(TimeNow,SHIP:VERTICALSPEED + 7).
                    SET BRAKES TO AirSPD > 80.
                }
                ELSE {
                    SET TGTPitch to PitchAnglePID:UPDATE(TimeNow,SHIP:VERTICALSPEED + 1).
                    IF BRAKES {BRAKES OFF.}
                    SET LNAVMODE TO "BNK".
                    SET TGTBank TO 0.
                    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
                    SET ATMODE TO "OFF".
                }

            }

            // **************************
            // MANUAL MODE WITH AUTO TRIM
            // **************************

            ELSE IF APMODE = "OFF" {
                IF SHIP:CONTROL:PILOTPITCH <> 0 {
                    SET TGTPitch to PitchAngle().
                    if ManModePitchT0 = 0 set ManModePitchT0 to timenow - 1.
                    SET ElevatorPID:Setpoint to SHIP:CONTROL:PILOTPITCH * (TimeNow - ManModePitchT0).
                }
                ELSE {
                    SET PitchAngVelPID:SETPOINT to TGTPitch.
                    SET ElevatorPID:Setpoint to PitchAngVelPID:UPDATE(TimeNow,PitchAngle()).
                    SET ManModePitchT0 TO 0.
                }
                IF SHIP:CONTROL:PILOTYAW <> 0 {
                    if ManModeRollT0 = 0 Set ManModeRollT0 to TimeNow - 1.
                    if      BankAngle() >  40 AND SHIP:CONTROL:PILOTYAW > 0 SET AileronPID:SETPOINT to 0.
                    else if BankAngle() < -40 AND SHIP:CONTROL:PILOTYAW < 0 SET AileronPID:SETPOINT to 0.
                    else SET AileronPID:SETPOINT TO SHIP:CONTROL:PILOTYAW * min((TimeNow - ManModeRollT0),2).
                }
                ELSE {
                    if      BankAngle() >  35 set AileronPID:SETPOINT to -1.0.
                    else if BankAngle() < -35 set AileronPID:SETPOINT to  1.0.
                    else SET AileronPID:SETPOINT to 0.
                    set ManModeRollT0 to 0.
                }
                
                SET Elevator TO ElevatorPID:UPDATE(TimeNow,pitchangvel()).
                SET Aileron TO AileronPID:UPDATE(TimeNow, BankAngVel()).
            }

            // *********************
            // COMMON AUTOPILOT CODE
            // *********************

            
            IF APMODE <> "OFF" {


                // DEAL WITH VNAV
                IF VNAVMODE = "GS"{ // Glideslope follow mode
                    SET GSPID:MAXOutput to -GSAng +25.
                    SET GSPID:MINOutput to -GSAng -25.
                    SET PitchAngVelPID:SETPOINT to min(PPA+30,max(PPA-15,GSPID:UPDATE(TimeNow, GSProgAng+1))).
                }
                ELSE IF VNAVMODE = "ALT" {
                    SET dAlt to BaroAltitude - TGTAltitude.
                    SET PitchAnglePID:Setpoint to VSpeedPID:UPDATE(TimeNow,dalt).
                    SET PitchAngVelPID:SETPOINT TO min(PPA+20,max(PPA-15,PitchAnglePID:UPDATE(TimeNow,Ship:verticalspeed()))).
                }
                ELSE IF VNAVMODE = "PIT" {
                    SET PitchAngVelPID:SETPOINT to  min(PPA+30,max(PPA-15,TGTPitch)).
                }
                ELSE IF VNAVMODE = "SPU" {
                    SET PitchAngVelPID:SETPOINT to PPA.
                }
                

                SET ElevatorPID:Setpoint to PitchAngVelPID:UPDATE(TimeNow,PitchAngle()).
                SET Elevator TO ElevatorPID:UPDATE(TimeNow,pitchangvel()).
                
                // DEAL WITH LNAV

                IF LNAVMODE = "TGT" {
                    SET dHeading TO -TargetCoord:bearing.
                    set tgtheading to dheading + magheading().
                    SET BankVelPID:SETPOINT to BankAnglePID:UPDATE(TimeNow,dHeading).
                    
                }
                ELSE IF LNAVMODE = "HDG" {
                    SET dHeading TO -DeltaHeading(TGTHeading).
                    SET BankVelPID:SETPOINT to BankAnglePID:UPDATE(TimeNow,dHeading).
                }
                ELSE IF LNAVMODE = "BNK" {
                    SET BankVelPID:SETPOINT TO min(45,max(-45,TGTBank)).
                }
                ELSE IF LNAVMODE = "LOC"{
                    SET TGTBank to LOCPID:Update(TimeNow,CLDist).
                    SET BankVelPID:SETPOINT to TGTBank.
                }

                Set AileronPID:SETPOINT to BankVelPID:UPDATE(TimeNow,BankAngle()).
                SET Aileron TO AileronPID:UPDATE(TimeNow, BankAngVel()).

                // RESET TRIM
                SET SHIP:CONTROL:ROLLTRIM TO 0.
                SET SHIP:CONTROL:PITCHTRIM TO 0.

            }
            // Stall Protection (Stick pusher!)
            IF KindOfCraft = "PLANE" {
                IF AoA() > MaxAoA {
                    IF VNAVMODE <> "SPU" {
                        SET PREVIOUSVNAV TO VNAVMODE.
                        SET PREVIOUSLNAV TO LNAVMODE.
                        SET PREVIOUSAT TO ATMODE.
                        SET PREVIOUSAP TO APMODE.
                        SET APMODE TO "NAV".
                        SET VNAVMODE TO "SPU".
                        SET ATMODE TO "MCT".
                        SET LNAVMODE TO "SPU".
                        uiAlarm().
                    }
                    uiWarning("Fly","Stick pusher!").
                }
                ELSE {
                    IF VNAVMODE = "SPU" {
                        SET VNAVMODE TO PREVIOUSVNAV.
                        SET LNAVMODE TO PREVIOUSLNAV.
                        SET ATMODE TO PREVIOUSAT.
                        SET APMODE TO PREVIOUSAP.
                    }
                }
            }

            // Yaw Damper
            SET yawdamperpid:setpoint to yawvelpid:Update(TimeNow,YawError()).
            SET Rudder TO YawDamperPID:UPDATE(TimeNow, yawangvel()).
           

                PRINT "T Bank:             " + round(BankVelPID:Setpoint,3) +   "       " at (0,1).
                PRINT "Bank:               " + ROUND(BankAngle(),2)         +   "       " At (0,2).

                PRINT "T Bank Vel:         " + round(AileronPID:SETPOINT,3) +   "       " At (0,3).
                PRINT "Bank Vel:           " + ROUND(BankAngVel(),2) +          "       " at (0,4).

                PRINT "Aileron:            " + ROUND(Aileron,2) +               "       " At (0,5).

                Print "GS Angle:           " + Round(GSProgAng,3)+              "       " At (0,6).

                Print "Yaw Error:          " + Round(yawerror(),3) +            "       " At (0,8).
                Print "T Yaw Vel:          " + Round(yawdamperpid:setpoint,3) + "       " At (0,9).
                Print "Yaw Vel:            " + Round(yawangvel(),3) +           "       " At (0,10).

                Print "Target VSpeed       " + Round(PitchAnglePID:setpoint,3)+ "       " At (0,11).
                Print "VSpeed              " + Round(Ship:verticalspeed(),3)+ "       " At (0,12).
                Print "Target Pitch:       " + Round(pitchangvelpid:Setpoint,3)+"       " At (0,13).
                Print "T Pitch Vel:        " + Round(ElevatorPID:setpoint,3)+   "       " At (0,14).
                Print "Pitch Vel:          " + Round(pitchangvel(),3) +         "       " At (0,15).

                Print "Center Line Dist:   " + Round(CLDist,3) +               "       " At (0,17).

                // LOG TimeNow + ";" +
                //     GSPID:input + ";" +
                //     GSPID:output TO "0:/PID.CSV".


            // APPLY CONTROLS
            SET SHIP:CONTROL:ROLL TO Aileron. 
            SET SHIP:CONTROL:PITCH TO Elevator.
            SET SHIP:CONTROL:YAW TO Rudder.
            

            // ************
            // AUTOTHROTTLE
            // ************

            IF ATMODE = "SPD" {
                IF NOT AUTOTHROTTLE { SET AUTOTHROTTLE TO TRUE .}
                SET VALUETHROTTLE TO ThrottlePID:UPDATE(TimeNow,AirSPD - TGTSpeed).
                SET SHIP:CONTROL:PILOTMAINTHROTTLE TO VALUETHROTTLE.
            }
            ELSE IF ATMODE = "MCT" {
                IF NOT AUTOTHROTTLE { SET AUTOTHROTTLE TO TRUE .}
                SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.
            }
            ELSE IF ATMODE = "OFF" {
                IF AUTOTHROTTLE {
                    UNLOCK THROTTLE.
                    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
                    SET AUTOTHROTTLE TO FALSE.
                }
            }

            // ******************
            // COMMON FLIGHT CODE
            // ******************

            // Auto raise/low gear and detect time to flare when landing.
            IF RA < FLAREALT {
                IF NOT GEAR { GEAR ON .}
                IF NOT LIGHTS { LIGHTS ON. }
                // CHANGE TO FLARE MODE.
                IF APMODE = "ILS" AND BaroAltitude < FlareAltMSL {
                    SET APMODE TO "FLR".
                }
            }
            ELSE {
                IF GEAR GEAR OFF. 
            }
            // RCS Controls.
            SET RCS TO BaroAltitude > RCSEnableAlt.

        }
        ELSE { 
            // *****************************************
            // TOTAL AUTOPILOT SHUTDOWN. SHOW INFO ONLY.
            // *****************************************
            IF NOT APSHUTDOWN {
                SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
                UNLOCK THROTTLE.
                SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
                IF NOT SAS {SAS ON.}
                SET APSHUTDOWN TO TRUE.
            }
        }


        // *********************
        // USER INTERFACE UPDATE
        // *********************

        wait 0.
        //ILS VECTORS
        IF checkboxVectors:PRESSED  {
            SET RAMPEND TO latlng(TGTRunway:LAT,TGTRunway:LNG-10).
            SET RAMPENDALT TO TGTRunway:TERRAINHEIGHT + TAN(GSAng) * 10 * (Kerbin:RADIUS * 2 * constant:Pi / 360).
            SET ILSVEC TO VECDRAW(TGTRunway:POSITION(),RAMPEND:ALTITUDEPOSITION(RAMPENDALT+9256),magenta,"",1,true,30).
            // Why +9256? https://imgur.com/a/CPHnD 
        }
        ELSE {
            SET ILSVEC TO VECDRAW().
            PRINT "                            " AT (0,30).
        }

        //GUI ELEMENTS

        IF APSHUTDOWN {
            SET labelMode:text     to "<b><size=17>INP | INP | INP | INP</size></b>".
            SET LabelWaypointDist:text to "".
            SET LabelHDG:TEXT  TO "".
            SET LabelALT:TEXT  TO "".
            SET LabelBNK:TEXT TO "".
            SET LabelPIT:TEXT TO "". 
            SET LabelSPD:TEXT TO "".
        }
        ELSE {
            SET labelMode:text     to "<b><size=17>" + APMODE +" | " + VNAVMODE + " | " + LNAVMODE + " | " + ATMODE +"</size></b>".
            SET LabelWaypointDist:text to ROUND(GroundDistance(TargetCoord)/1000,1) + " km".
            SET LabelHDG:TEXT  TO "<b>" + ROUND(TGTHeading,2):TOSTRING + "º</b>".
            SET LabelALT:TEXT  TO "<b>" + ROUND(TGTAltitude,2):TOSTRING + " m</b>".
            SET LabelBNK:TEXT TO  "<b>" + ROUND(BankVelPID:Setpoint,2) + "º</b>".
            SET LabelPIT:TEXT TO  "<b>" + ROUND(PitchAngVelPID:SETPOINT,2) + "º</b>".
            SET LabelSPD:TEXT TO  "<b>" + ROUND(TGTSpeed) + " m/s | " + ROUND(uiMSTOKMH(TGTSpeed),2) + " km/h</b>".
        }
        SET labelAirspeed:text to "<b>Airspeed:</b> " + ROUND(uiMSTOKMH(AirSPD)) + " km/h" +
                                " | Mach " + Round(Mach(AirSPD),3). 
        SET labelVSpeed:text to "<b>Vertical speed:</b> " + ROUND(SHIP:VERTICALSPEED) + " m/s".
        SET labelLAT:text to "<b>LAT:</b> " + ROUND(SHIP:geoposition:LAT,4) + " º".
        SET labelLNG:text to "<b>LNG:</b> " + ROUND(SHIP:geoposition:LNG,4) + " º".
        
        //CONSOLE INFO
        IF CONSOLEINFO {
            PRINT "MODE:" + LNAVMODE AT (0,0). PRINT "YWD ERR:" + ROUND(YawError(),2) + "    " AT (20,0).
            IF APATEnabled {PRINT APMODE + "   " AT (10, 0).} ELSE {PRINT "MANUAL" AT (10,0).}
            PRINT "Pitch angle         " + ROUND(PitchAngle(),2) +          "       "at (0,1).
            PRINT "Target pitch:       " + ROUND(ElevatorPID:SETPOINT,2) +  "       " At (0,2).
            PRINT "AoA:                " + ROUND(AoA(),2) +                 "       " At (0,3).

            PRINT "Bank angle          " + ROUND(BankAngle(),2)          +  "     " AT (0,6).
            PRINT "Target bank:        " + ROUND(AileronPID:SETPOINT,2)  +  "     " At (0,7).
            PRINT "Target bearing:     " + ROUND(-dHeading,2)             +  "     " At (0,8).
            
            PRINT "Ship: Latitude:     " + SHIP:geoposition:LAT AT (0,10).
            PRINT "Ship: Longitude:    " + SHIP:geoposition:LNG AT (0,11).
            PRINT "Ship: Altitude:     " + BaroAltitude AT (0,12).
            PRINT "GS Altitude: " + ROUND(Glideslope(TGTRunway,GSAng),2) AT (0,30).
        }
        WAIT 0. //Next loop only in next physics tick 
        set ShipStatus to ship:status.        
    }
    
    // Takes care of ship after autopilot ends it's work.
    local SteerDir is heading(90,0).
    SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

    until ship:status = "SPLASHED" or SafeToExit { 
        if TimeOfLanding = 0 {
            // Set up ship for runway roll
            set TimeOfLanding to time:seconds.
            uiBanner("Fly","Landed!").
            // Neutralize RAW controls
            SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
            SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.            
            partsEnableReactionWheels().
            wait 0.
            lock steering to SteerDir.
        }
        if time:seconds < TimeOfLanding + 3 {                 
            // Try to keep the ship on ground
            IF LandingGear = "Tricycle" { // With tricycle landing gear is safe to pitch down while on ground. This helps prevents bounces and improve braking.
                set SteerDir to heading(90,-1).
            }
            ELSE IF LandingGear = "Taildragger" { // With taildraggers is better to keep the nose a little up to avoid a nose-over accident.
                set SteerDir to heading(90,1).
            }
            SET SHIP:CONTROL:WHEELSTEER to SHIP:CONTROL:YAW.
        }
        else {
            uiBanner("Fly","Braking!").
            // We didn't bounce, apply brakes
            brakes on.
            chutes on.
            SET SHIP:CONTROL:WHEELSTEER to SHIP:CONTROL:YAW.
            if partsReverseThrust() set ship:control:pilotmainthrottle to 1.
            if ship:groundspeed < 10 set ship:control:pilotmainthrottle to 0.
            // Don't let tail-dragger to nose-over when braking
            if LandingGear = "Taildragger" and PitchAngle() < 0 brakes OFF.
            // Now it's really safe to exit the autopilot.
            if ship:groundspeed < 1 SafeToExit ON.
        }
        wait 0.
    }
    
    if ship:status = "SPLASHED" {
        SafeToExit ON.
        uiBanner("Fly","Splash!!!").
    }
}

CLEARGUIS().
CLEARVECDRAWS().
BRAKES ON.
SAS ON.
SET Config:IPU TO OldIPU.
partsEnableReactionWheels().
partsForwardThrust().
uiBanner("Fly","Thanks to flying with RAMP. Remember to take your belongings.",2).