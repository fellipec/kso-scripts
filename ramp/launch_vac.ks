@lazyglobal off.

//Simple launch from a body without atmosphere, eastbound

WAIT UNTIL KUniverse:CANQUICKSAVE.
KUniverse:QUICKSAVETO("RAMP-Before Launch from "+ SHIP:body:name).

LOCAL T is 1.
LOCAL LOCK S to UP.

SAS OFF.

LOCK STEERING TO S.
LOCK throttle TO T.
WAIT UNTIL alt:apoapsis > 5000.
LEGS OFF. GEAR OFF.
SET T TO 0.
LOCAL LOCK S TO heading(90,45,0).
WAIT UNTIL alt:radar > 1000.
SET T TO 1.
WAIT UNTIL alt:apoapsis > 10000.
LOCAL LOCK S TO heading(90,0,0).
WAIT UNTIL alt:apoapsis > 20000.
SET T TO 0. 

UNLOCK throttle.
UNLOCK steering.

RUN CIRC.