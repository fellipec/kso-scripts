/////////////////////////////////////////////////////////////////////////////
// Ascent phase of launch.
/////////////////////////////////////////////////////////////////////////////
// Ascend from a planet, performing a gravity turn and staging as necessary.
// Achieve circular orbit with desired apoapsis.
/////////////////////////////////////////////////////////////////////////////

// Final apoapsis (m altitude)
parameter apo is 200000.
parameter hdglaunch is 90. 
parameter deployfairing is true.

runoncepath("lib_parts.ks"). 
runoncepath("lib_ui.ks").
runoncepath("lib_util").

local Liftoff_Time is time:seconds.

//Abort sequence
ON Abort {
  unlock throttle.
  unlock steering.
  set ship:control:pilotmainthrottle to 1. 
  wait 3.
  partsEnableReactionWheels().
  until stage:number = 0 stage.
  wait until ship:verticalspeed < -20.
  REBOOT.
}

uiBanner("Launch","Launching to an orbit of " + round(apo/1000) + "km and heading of " + hdglaunch + "º"). 

// Number of seconds to sleep during ascent loop
global launch_tick is 1.

// Time of SRB separation
global launch_tSrbSep is 0.

// Time of last stage
global launch_tStage is time:seconds.

// Starting/ending height of gravity turn
// TODO adjust for atmospheric pressure; this works for Kerbin
global launch_gt0 is body:atm:height * 0.002. // About 140m in Kerbin
global launch_gt1 is body:atm:height * 0.857. // About 60000m in Kerbin

/////////////////////////////////////////////////////////////////////////////
// Steering function.
/////////////////////////////////////////////////////////////////////////////

function ascentSteering {
  // How far through our gravity turn are we? (0..1)
  local gtPct is (ship:altitude - launch_gt0) / (launch_gt1 - launch_gt0).

  // Ideal gravity-turn azimuth (inclination) and facing at present altitude.
  //local inclin is min(90, max(0, arccos(min(1,max(0,gtPct))))).
  local inclin is min(90, max(0, arcsin(1-(min(1,max(0,gtPct)))))).
  local gtFacing is heading ( hdglaunch, inclin) * r(0,0,180). //180 for shuttles, doesn't matter for rockets.

  if time:seconds - Liftoff_Time <= 10 {
    return heading (ship:heading,90).
  }
  else if gtPct <= 0 {
    return heading (hdglaunch,90) + r(0,0,180). //Straight up.
  } else {
    return gtFacing.
  }
}

/////////////////////////////////////////////////////////////////////////////
// Throttle function.
/////////////////////////////////////////////////////////////////////////////

function ascentThrottle {
  // how far through the soup are we?
  local atmPct is ship:q.
  local spd is ship:airspeed.

  // TODO adjust cutoff for atmospheric pressure; this works for kerbin
  local cutoff is 200 + (400 * max(0, (atmPct*3))).

  if spd > cutoff and launch_tSrbSep = 0 {
    // going too fast during SRB ascent; avoid overheat or
    // aerodynamic catastrophe by limiting throttle
    return 1 - (1 * (spd - cutoff) / cutoff).
  } else {
    // Ease thottle when near the Apoapsis
    local ApoPercent is ship:obt:apoapsis/apo.
    local ApoCompensation is 0.
    if ApoPercent > 0.9 set ApoCompensation to (ApoPercent - 0.9) * 10.
    return 1 - min(0.9,max(0,ApoCompensation)).
  }
}

/////////////////////////////////////////////////////////////////////////////
// Auto-stage and auto-warp logic -- performs its work as side effects vs.
// returning a value; must be called in a loop to have any effect!
/////////////////////////////////////////////////////////////////////////////

function ascentStaging {
  local Neng is 0.
  local Nsrb is 0.
  local Nlfo is 0.
  local ThisStage is stage:Number.

  list engines in engs.
  for eng in engs {
    if eng:ignition {
      set Neng to Neng + 1.
      if not eng:allowshutdown and eng:flameout {
        set Nsrb to Nsrb + 1.
      }
      if eng:flameout {
        set Nlfo to Nlfo + 1.
        eng:shutdown. 
      }
    }
  }

  if Nsrb > 0 {
    wait 1.
    stage.
    set launch_tSrbSep to time:seconds.
    set launch_tStage to launch_tSrbSep.
    uiBanner("Launch","Stage " + ThisStage + " separated. " + Nsrb + " SRBs discarded.").
  } else if (Nlfo > 0) {
    wait until stage:ready.
    wait 1.
    stage. 
    set launch_tStage to time:seconds.
    uiBanner("Launch","Stage " + ThisStage + " separated. " + Nlfo + " Engines out.").
  } else if Neng = 0 {
    wait until stage:ready.
    wait 1.
    stage. 
    set launch_tStage to time:seconds.
    uiBanner("Launch","Stage " + ThisStage + " activated").
  }
  else if Nsrb = 0 and launch_tSrbSep = 0 {
    set launch_tSrbSep to time:seconds. // If there is no SRB, set them to already separeted 
  }
  

}

function ascentFairing {
  if deployfairing and ship:altitude > ship:body:atm:height {
    if partsDeployFairings() uiBanner("Launch","Discard fairings").    
  }
}

/////////////////////////////////////////////////////////////////////////////
// Perform initial setup; trim ship for ascent.
/////////////////////////////////////////////////////////////////////////////

sas off.
bays off.
panels off.
radiators off.


if ship:status <> "PRELAUNCH" and stage:solidfuel = 0 {
  // note that there's no SRB
  set launch_tSrbSep to time:seconds.
}

lock steering to ascentSteering().
lock throttle to ascentThrottle().

/////////////////////////////////////////////////////////////////////////////
// Enter ascent loop.
/////////////////////////////////////////////////////////////////////////////

until ship:obt:apoapsis >= apo {
  ascentStaging().
  ascentFairing().
  wait launch_tick.
}

unlock throttle.

/////////////////////////////////////////////////////////////////////////////
// Coast to apoapsis and hand off to circularization program.
/////////////////////////////////////////////////////////////////////////////

// Get rid of ascent stage if less that 10% fuel remains ... bit wasteful, but
// keeps our burn calculations from being erroneous due to staging mid-burn.
if stage:resourceslex:haskey("LiquidFuel") {
  if stage:resourceslex["LiquidFuel"]:capacity > 0 { // Checks to avoid NaN error
    if stage:resourceslex["LiquidFuel"]:amount / stage:resourceslex["LiquidFuel"]:capacity < 0.02 {
      wait 1. stage.
      uiBanner("Launch","Discarding tank").
      wait until stage:ready.
    }
  }
}
// Corner case: circularization stage is not bottom most (i.e. there is an
// aeroshell ejection in a lower stage).
until ship:availablethrust > 0 {
  wait 1. stage.
  uiBanner("Launch","Discard non-propulsive stage").
  wait until stage:ready.
}

// Roll with top up.
lock steering to heading (hdglaunch,0). //Horizon, ceiling up.
wait until utilIsShipFacing(heading(hdglaunch,0):vector). 

// Warp to end of atmosphere
local AdjustmentThrottle is 0.
lock throttle to AdjustmentThrottle.
until ship:altitude > body:atm:height {
  if ship:obt:apoapsis < apo set AdjustmentThrottle to ascentThrottle().
  else set AdjustmentThrottle to 0.
  wait launch_tick.
}
// Discard fairings, if they aren't yet.
ascentFairing(). wait launch_tick.

// Give power and communication to the ship
fuelcells on.
panels on.
radiators on.
wait 10.
partsExtendAntennas().
partsEnableFissionReactors().
wait launch_tick.
// Release controls. Turn on RCS to help steer to circularization burn.
unlock steering.
unlock throttle.
rcs on.
run circ.
