/////////////////////////////////////////////////////////////////////////////
// Simple ascend-to-orbit boot script.
/////////////////////////////////////////////////////////////////////////////
// Launch and ascend to a fixed altitude.
//
// MUST NOT be used for vessels that will operate out of comms range!!
/////////////////////////////////////////////////////////////////////////////

switch to archive.
cd("ramp").
WAIT 5. 

if ship:status = "prelaunch" {

  IF HOMECONNECTION:ISCONNECTED {
    LOCAL StartupOk is FALSE.
    print "Looking for remote startup script...".
    LOCAL StartupScript is PATH("0:/start/"+SHIP:NAME).
    IF EXISTS(StartupScript) {
      PRINT "Remote startup script found!".
      StartupOk ON.
    }
    ELSE {
      PRINT "No remote startup script found.".
      PRINT "You can create a sample one by typing:". 
      PRINT "RUN UTIL_MAKESTARTUP.".
    }
    IF StartupOk {
      RUNPATH(StartupScript).
    }
  }
  PRINT "Proceed.".
}

if (ship:status = "flying" or ship:status = "sub_orbital") {

}
