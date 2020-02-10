#!/bin/bash
# Small script to report the status of the Java environment on your local computer
# 
# Copyright 2015 Peter Möller, Dept of Copmuter Science, Lund University
# Last change: 2015-09-25
# 
# Version 2.0.3
# 2014-10-29: added information about running java processes
# 2014-12-12: name changed from "java_check.sh" to "java_info.sh"
# 2015-09:    moved to GitHub
# 2020-02-10: Now accepts OpenJDK (string width)
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# 

# (Colors can be found at http://en.wikipedia.org/wiki/ANSI_escape_code, http://graphcomp.com/info/specs/ansi_col.html and other sites)
Reset="\e[0m"
ESC="\e["
RES="0"
BoldFace="1"
ItalicFace="3"
UnderlineFace="4"
SlowBlink="5"

BlackBack="40"
RedBack="41"
GreenBack="42"
YellowBack="43"
BlueBack="44"
CyanBack="46"
WhiteBack="47"

BlackFont="30"
RedFont="31"
GreenFont="32"
YellowFont="33"
BlueFont="34"
CyanFont="36"
WhiteFont="37"


# Find where the script resides (so updates update the correct version) -- without trailing slash
DirName="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# What is the name of the script? (without any PATH)
ScriptName="$(basename $0)"

# Is the file writable?
if [ -w "${DirName}/${ScriptName}" ]; then
  Writable="yes"
else
  Writable="no"
fi

# Who owns the script?
ScriptOwner="$(ls -ls ${DirName}/${ScriptName} | awk '{print $4":"$5}')"

TempFile="/tmp/java_info.$$.txt"

FormatString="%-18s%-18s%-50s"


# Check for update
function CheckForUpdate() {
	NewScriptAvailable=f
	# First, download the script from the server
	/usr/bin/curl -s -f -e "$ScriptName ver:$VER" -o /tmp/"$ScriptName" http://fileadmin.cs.lth.se/cs/Personal/Peter_Moller/scripts/"$ScriptName" 2>/dev/null
	/usr/bin/curl -s -f -e "$ScriptName ver:$VER" -o /tmp/"$ScriptName".sha1 http://fileadmin.cs.lth.se/cs/Personal/Peter_Moller/scripts/"$ScriptName".sha1 2>/dev/null
	ERR=$?
	# Find, and print, errors from curl (we assume both curl's above generate the same errors, if any)
	if [ "$ERR" -ne 0 ] ; then
		# Get the appropriate error message from the curl man-page
		# Start with '       43     Internal error. A function was called with a bad parameter.'
		# end get it down to: ' 43: Internal error.'
		ErrorMessage="$(MANWIDTH=500 man curl | egrep -o "^\ *${ERR}\ \ *[^.]*." | perl -pe 's/[0-9](?=\ )/$&:/;s/  */ /g')"
		echo $ErrorMessage
		echo "The file \"$ScriptName\" could not be fetched from \"http://fileadmin.cs.lth.se/cs/Personal/Peter_Moller/scripts/$ScriptName\""
	fi
	# Compare the checksum of the script with the fetched sha1-sum
	# If they diff, there is a new script available
	if [ "$(openssl sha1 /tmp/"$ScriptName" | awk '{ print $2 }')" = "$(less /tmp/"$ScriptName".sha1)" ]; then
		if [ -n "$(diff /tmp/$ScriptName $DirName/$ScriptName 2> /dev/null)" ] ; then
		NewScriptAvailable=t
		fi
	else
		CheckSumError=t
	fi
	}


# Update [and quit]
function UpdateScript() {
	CheckForUpdate
	if [ "$CheckSumError" = "t" ]; then
		echo "Checksum of the fetched \"$ScriptName\" does NOT check out. Look into this! No update performed!"
		exit 1
	fi
	# If new script available, update
	if [ "$NewScriptAvailable" = "t" ]; then
		# But only if the script is writable!
		if [ "$Writable" = "yes" ]; then
			/bin/rm -f "$DirName"/"$ScriptName" 2> /dev/null
			/bin/mv /tmp/"$ScriptName" "$DirName"/"$ScriptName"
			chmod 755 "$DirName"/"$ScriptName"
			/bin/rm /tmp/"$ScriptName".sha1 2>/dev/null
			echo "A new version of \"$ScriptName\" was installed successfully!"
			echo "Script updated. Exiting"

			# Send a signal that someone has updated the script
			# This is only to give me feedback that someone is actually using this. I will *not* use the data in any way nor give it away or sell it!
			/usr/bin/curl -s -f -e "$ScriptName ver:$VER" -o /dev/null http://fileadmin.cs.lth.se/cs/Personal/Peter_Moller/scripts/updated 2>/dev/null

			exit 0
		else
			echo "Script cannot be updated!"
			echo "It is located in \"${DirName}\" and is owned by \"${ScriptOwner}\""
			echo "You need to sort this out yourself!!"
			echo "Exiting..."
			exit 1
		fi
	else
		echo "You already have the latest version of \"${ScriptName}\"!"
		exit 0
	fi
	}



# Find out which system version we are running
SoftwareVersion()
{
	SW_VERS="$(sw_vers -productName) $(sw_vers -productVersion)"
	ComputerName="$(networksetup -getcomputername)"
	# Find out if it's a server
	# First step: does the name fromsw_vers include "server"?
	if [ -z "$(echo "$SW_VERS" | grep -i server)" ]; then
	  # If not, it may still be a server. Beginning with OS X 10.8 all versions include the command serverinfo:
	  serverinfo --software 1>/dev/null
	  # Exit code 0 = server; 1 = NOT server
	  ServSoft=$?
	  if [ $ServSoft -eq 0 ]; then
	    # Is it configured?
	    serverinfo --configured 1>/dev/null
	    ServConfigured=$?
	    if [ $ServConfigured -eq 0 ]; then
	      SW_VERS="$SW_VERS ($(serverinfo --productname) $(serverinfo --shortversion))"
	    else
	      SW_VERS="$SW_VERS ($(serverinfo --productname) $(serverinfo --shortversion) - unconfigured)"
	    fi
	  fi
	fi
}


help() {
	echo
	echo "Usage: $0 [-u]"
	echo "-u: Update the script"
	echo
	exit 0
}

#===============================================================
# Set some default values
fetch_new=f

#===============================================================
# Read options
while getopts ":u" opt; do
	case $opt in
		u ) fetch_new="t";;
		\?|H ) help;;
	esac
done

if [ "$fetch_new" = "t" ]; then
	UpdateScript
fi

SoftwareVersion

printf "${ESC}${BlackBack};${WhiteFont}mJava report for:${Reset}${ESC}${WhiteBack};${BlackFont}m $(/usr/sbin/networksetup -getcomputername 2>/dev/null) ${Reset}   ${ESC}${BlackBack};${WhiteFont}mRunning:${ESC}${WhiteBack};${BlackFont}m $SW_VERS ${Reset}   ${ESC}${BlackBack};${WhiteFont}mDate & time:${ESC}${WhiteBack};${BlackFont}m $(date +%F", "%R) ${Reset}\n"
echo
#echo "Safari version: $(defaults read /Applications/Safari.app/Contents/Info CFBundleShortVersionString)"


##
## JDK
# Use /usr/libexec/java_home to display information about java
/usr/libexec/java_home -d 64 -V 2>&1 | grep "^\ " | sed -e 's/^\ *//g' -e 's/, x86_64//' -e 's/"//g' | tr '\t' ':' | sed 's/::/:/' | sort > "$TempFile"
# Sample output:
# Matching Java Virtual Machines (3):
#    1.8.0, x86_64:	"Java SE 8"	/Library/Java/JavaVirtualMachines/jdk1.8.0.jdk/Contents/Home
#    1.7.0_51, x86_64:	"Java SE 7"	/Library/Java/JavaVirtualMachines/jdk1.7.0_51.jdk/Contents/Home
#    1.6.0_65-b14-462, x86_64:	"Java SE 6"	/System/Library/Java/JavaVirtualMachines/1.6.0.jdk/Contents/Home
#
# /Library/Java/JavaVirtualMachines/jdk1.8.0.jdk/Contents/Home
printf "${ESC}${BoldFace}mJava version(s) to use for delevopment in Java:${Reset}\n"
if [ -n "$(ls /Library/Java/JavaVirtualMachines/* 2>/dev/null)" ]; then
	printf "${ESC}${UnderlineFace}m$FormatString${Reset}\n" "Java Version" "Java Name" "File System Loccation"
	# Read the file and print the output
	exec 4<${TempFile}
	while IFS=: read -u 4 "JavaVer" "JavaName" "JavaLoccation"
	do
		printf "$FormatString\n" "$JavaVer" "$JavaName" "$JavaLoccation"
	done
	echo
	echo "Current value of \$JAVA_HOME:   \"$JAVA_HOME\""
	echo "Suggested value of \$JAVA_HOME: \"$(/usr/libexec/java_home 2>/dev/null)\""
	if [ $(wc $TempFile | awk '{print $1}') -gt 1 ]; then
		echo
		printf "${ESC}${BoldFace}mChange Java-version:${Reset}\n"
		printf "${ESC}${BlackFont}mType: \"export JAVA_HOME=\$(/usr/libexec/java_home -v 1.${Reset}${ESC}${GreenFont}mN${Reset}${ESC}${BlackFont}m)\"\nwhere ${Reset}${ESC}${GreenFont}mN${Reset}${ESC}${BlackFont}m is the version you want to run.${Reset}\n"
	echo
	fi
else
	printf "${ESC}${RedFont}mNo java in \"/Library/Java/JavaVirtualMachines\"!!\n$Reset"
fi

echo

##
## Java plugin
printf "${ESC}${BoldFace}mJava Web Browser Plugin${Reset} (in \"/Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin\"):\n"
PluginJavaVer="$(/Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin/Contents/Home/bin/java -version 2>&1 | grep "java version" | cut -d\" -f2)"
if [ -n "$PluginJavaVer" ]; then
	echo "• Java Applet version: $PluginJavaVer"
	TimeStamp="$(defaults read ~/Library/Preferences/.GlobalPreferences com.apple.WebKit.JavaPlugInLastUsedTimestamp 2>/dev/null| cut -d\. -f1)"
	if [ -n "$TimeStamp" ]; then
		echo "• Java applet plugin is enabled for user \"$USER\" and was updated: $(date -r "$(( $(date "+%$TimeStamp") + 978307200 ))" )"
	else
		printf "${ESC}${RedFont}m• Java Applet plugin is NOT allowed for user \"$USER\"!\n$Reset"
	fi
	printf "${ESC}${ItalicFace}m(do ${ESC}${BoldFace}mnot${Reset}${ESC}${ItalicFace}m use this JRE for Java development!!)${Reset}\n"
else
	printf "${ESC}${RedFont}mNo Java plugin detected!!\n$Reset"
fi
echo
echo


##
# Display information about running java processes

# Generate TempFile
# It contains Username, PID, PPID and Command for all running Java-processes (one process per line)
# When running for instance Minecraft, the java process line can be absolutely humongous, such as:
# 'cs-pmo          67802 67799 /Applications/Minecraft 2.app/Contents/runtime/jre-x64/1.8.0_60/bin/java -Xdock:icon=/Users/cs-pmo/Library/Application Support/minecraft/assets/objects/99/991b421dfd401f115241601b2b373140a8d78572 -Xdock:name=Minecraft -Xmx1G -XX:+UseConcMarkSweepGC  and on and on and on...'
# I assume that the relevant part ends just before ' -', i.e. before arguments. 
# This *will* break when someone is running an application that is named 'namepart1 -namepart2.app', but I assume this be extremely rare! :-)
# So, I therefore use the regexp '^.+?(?=\ \-)' to get the interesting part of the line: 
# from the start of the line, take all characters ('?' is non greedy) up until, but not including, ' -'
ps -A -o user,pid,ppid,command | grep [j]ava[^_] | grep -v com.oracle.java.JavaUpdateHelper | perl -ne 'm/(^.+?(?=\ \-))/; print "$1\n"' > $TempFile
# Example: 
# peterm          68101 67991 /Applications/Minecraft 2.app/Contents/runtime/jre-x64/1.8.0_60/bin/java

# Display output if there are any running java processes
if [ -s $TempFile ]; then
	NumProc="$(wc -l $TempFile | awk '{print $1}')"
	if [ $NumProc -gt 1 ]; then
		printf "${ESC}${BoldFace}mThere are $NumProc java processes currently running:${Reset}\n"
	else
		printf "${ESC}${BoldFace}mThere is one java process currently running:${Reset}\n"
	fi

    # Display output
    exec 4<"$TempFile"
    while read -u 4 UserID ProcessID ParentPID COMMAND
    do
      PPIDCommand="$(basename "/$(ps -o command -p $ParentPID | grep -v COMMAND | awk '{print $1}')")"
      #PPIDApp="$(ps -o command -p $ParentPID | grep -v COMMAND | awk '{print $1}' | grep -o "/[A-z][a-z]*.app\/" | sed 's;/;;g')"
      PPIDApp="$(ps -o command -p $ParentPID | grep -v COMMAND | egrep -o "^(.*?).app/" | head -1)"
      # Example:
      #  PPIDCommand=com.apple.WebKit.Plugin.64
      PPIDUser="$(ps -o user -p $ParentPID | grep -v ^USER)"
      # Example:
      #  PPIDUser=cs-pmo
      echo "• User: \"$UserID\" (PID: $ProcessID)"
      echo "• Command: $COMMAND"
      echo "• Java version: $("$(echo $COMMAND)" -version 2>&1 | awk '/version/{print $NF}')"
      if [ -n "$PPIDApp" ]; then
      	printf "${ESC}${ItalicFace}m• Launched by: \"$PPIDApp\" (PID=$ParentPID, run by \"$PPIDUser\")${Reset}\n"
      else
      	# Neat fix: replace '/System/Library/Frameworks/WebKit.framework.*WebKit.*' with 'Safari'
      	printf "${ESC}${ItalicFace}m• Launched by: \"$(ps -o command -p $ParentPID | grep -v COMMAND | awk '{print $1}' | sed -e 's;/Contents/MacOS/.*$;;' -e 's;/System/Library/Frameworks/WebKit.framework.*WebKit.*;Safari;')\" (PID=$ParentPID, run by \"$PPIDUser\")${Reset}\n"
      fi
      echo
    done
else
	printf "${ESC}${BoldFace}mThere are no currently running java-processes${Reset}\n\n"
fi

echo
echo


##
## Obtaining Java
printf "${ESC}${BoldFace}mObtaining Java:${Reset}\n"
echo "1. Java 6 can be fetched from Apple at this address:"
echo "   http://support.apple.com/kb/DL1572"
echo "2. Newer Java can be fetched from Oracle at this address:"
echo "   http://www.oracle.com/technetwork/java/javase/downloads/index.html"
echo "3. Functionality of web browser plugin can be tested at this address:"
echo "   http://www.java.com/en/download/testjava.jsp"
echo
echo

#echo "Do you want to go to any of these addresses? Answer with number or [q/n] to not go there:"
#read Svar
#case $Svar in
#	1 ) open http://support.apple.com/kb/DL1572;;
#	2 ) open http://www.oracle.com/technetwork/java/javase/downloads/index.html;;
#	3 ) open http://www.java.com/en/download/testjava.jsp;;
#esac

/bin/rm $TempFile

exit 0
