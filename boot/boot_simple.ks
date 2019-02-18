/////////////////////////////////////////////////////////////////////////////
// Simple boot script.
/////////////////////////////////////////////////////////////////////////////
// Try to execute a Startup script remotely
//
// MUST NOT be used for vessels that will operate out of comms range!!
/////////////////////////////////////////////////////////////////////////////

switch to archive.
cd("ramp").
WAIT 5. 

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
  PRINT "Proceed.".
}
ELSE {
  PRINT("No connection. Good luck.").
}

