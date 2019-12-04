print("Waiting until Atmosphere...").
rcs on.
set s to retrograde.
set t to 0.
lock steering to s.
lock throttle to t. 
set kuniverse:timewarp:warp to 3.
wait until ship:altitude < 71000.
set kuniverse:timewarp:warp to 0.
print("Waiting for breaking burn.").
brakes on.
set s to retrograde.
wait 60.
set s to retrograde.
until ship:velocity:orbit:mag < 800{
    set t to 1.
    set s to retrograde.
}
set t to 0.

unlock steering.
unlock throttle.

sas on. wait 1.
chutes on.
runpath("land").