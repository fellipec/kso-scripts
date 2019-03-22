@lazyglobal off.

runoncepath("lib_ui").
runoncepath("lib_parts").

CLEARVECDRAWS().
CLEARGUIS().

// PID VSpeed
local VSpeedPID is PIDLOOP(0.15,0.05,0.005,-20,20). 
SET VSpeedPID:SETPOINT TO 0.

//PID Throttle
local ThrottlePID is PIDLOOP(0.10,0.02,0.50,0,1). 
SET ThrottlePID:SETPOINT TO 0. 

local TGTAlt is 300.
local TVal is 0.
local TGTVS is 0.
lock throttle to TVal.

local T0 is time:seconds.

RCS ON.
STAGE.

LOCK Steering to SHIP:UP.

UNTIL Time:Seconds > T0 + 60 {
    set TGTVs to VSpeedPID:UPDATE(Time:Seconds,SHIP:ALTITUDE - TGTAlt).
    set TVal to ThrottlePID:UPDATE(Time:Seconds,SHIP:verticalspeed - TGTVs).
    
}
UNTIL SHIP:STATUS = "LANDED" {
    set TGTVS to -1.
    set TVal to ThrottlePID:UPDATE(Time:Seconds,SHIP:verticalspeed - TGTVs).
}