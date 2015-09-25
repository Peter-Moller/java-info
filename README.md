# java-info
A bash script for OS X that details information about java on the machine

More details about the script can be found here:
http://cs.lth.se/peter-moller/script/java-info-en/

Overview of the script:
-----------------------

`/usr/libexec/java_home` is the base for the script. This reports all java instances that the system knows about. 

If present, these locations are then processed with all relevant information gathered:
 - `$USER` and `$PID`
 - Command
 - Java version for this
 - What application/process launched this and who is running this?

Finaly, information is presented on:
 - Where you can download Java 6 [from Apple]
 - Where you can download the latest Java-release [from Oracle]
 - How you test if Java works in the web browser

The script deals with spaces in PATH of a running command (was a bit tricky :-)

Assumptions:
------------------
 - Any java is assumed to be named `java` 
 - That “` -`” (space followed by a dash) is the start of the arguments on the process listing and not part of the PATH of the running application or java instance
