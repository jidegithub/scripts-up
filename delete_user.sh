#/bin/bash
#delete user - automates 4 steps to remove an accoun

#define functions
################
function getAnswer {
 unset ANSWER
 ASK_COUNT=0

 while [ -z "$ANSWER" ] #while no answer is given, keep asking.
  do
  ASK_COUNT=$[ $ASK_COUNT + 1 ]

   case $ASK_COUNT in  #if user gives no answer in time alloted
    2)
    echo
    echo "Please answer the question."
    echo
    ;;
    3)
    echo
    echo "One last try... please answer the question."
    echo
    ;;
    4)
    echo
    echo "Since you refuse to answer the question..."
    echo "exiting program"
    echo
    exit
    ;;
   esac

  echo

  if [ -n "$LINE2" ]
   then  #print 2 lines
    echo $LINE1
    echo -e $LINE2" \c"
   else
    echo -e $LINE1" \c"
  fi

  #allow 0 seconds to answer before time-out
  read -t 60 ANSWER
 done
 #cleanup
 unset LINE1
 unset LINE2
}

###########################
function processAnswer {
 case $ANSWER in
  y|Y|YES|yes|Yes|yEs|yeS|YEs|yES )
  #If user answers "yes", do nothing and proceed further
  ;;
  *)
  #If user answers anything but "yes", exit script
  echo
  echo $EXIT_LINE1
  echo $EXIT_LINE2
  echo
  exit
  ;;
 esac

 #clean-up
 unset EXIT_LINE1
 unset EXIT_LINE2
}

################## Main Script #############
#get name of user account to check
echo "Step #1 - Determine User Account name to Delete "
echo
LINE1="Please enter the username of the user "
LINE2="account you wish to delete from system:"
getAnswer
USER_ACCOUNT=$ANSWER


#Double check with script user that this is the correct User Account
LINE1="Is $USER_ACCOUNT the user account "
LINE2="you wish to delete from the system? [y/n]"
getAnswer


#Call processAnswer function:
#if user answers anything but yes, exit script
EXIT_LINE1="Because the account, $USER_ACCOUNT, is not "
EXIT_LINE2="the one you wish to delete, we are leaving the script..."
processAnswer


################################################################
#Check that USER_ACCOUNT is really an account on the system
USER_ACCOUNT_RECORD=$(cat /etc/passwd | grep -w $USER_ACCOUNT)
#calling the command above returns an exit status, we check the exit status $? as a condition for the if statement
if [ $? -eq 1 ] #If the account is not found, exit script
 then
 echo
 echo "Account, $USER_ACCOUNT, not found. "
 echo "Leaving the script..."
 echo
 exit
fi

echo
echo "I found this record:"
echo $USER_ACCOUNT_RECORD

LINE1="Is this the correct User Account? [y/n]"
getAnswer

#Call processAnswer function:
#if user answers anything but yes, exit script
EXIT_LINE1="Because the account, $USER_ACCOUNT, is not "
EXIT_LINE2="the one you wish to delete, we are leaving the script..."
processAnswer

##################################################################
#Search for any running processes that belong to the User Account
echo
echo "Step #2 - Find process on system belonging to user account"
echo

ps -u $USER_ACCOUNT > /dev/null #Are user processes running?

case $? in
 1)
  #No processes running for this User Account
  echo "There are no processes for this account currently running."
  echo
 ;;
 0)
  #Processes running for this User Account.
  #Ask Script User if wants us to kill the processes.
  echo "$USER_ACCOUNT has the following processes running: "
  echo
  ps -u $USER_ACCOUNT

  LINE1="Would you like me to kill the process(es)? [y/n]"
  getAnswer

  case $ANSWER in
   y|Y|YES|yes|Yes|yEs|yeS|YEs|yES ) # If user answers "yes",
   #kill User Account processes.
   echo
   echo "Killing off process(es)..."

   #List user processes running code in variable, COMMAND_1
   COMMAND_1="ps -u $USER_ACCOUNT --no-heading"

   #Create command to kill proccess in variable, COMMAND_3
   COMMAND_3="xargs -d \\n /usr/bin/sudo /bin/kill -9"

   #Kill processes via piping commands together
   $COMMAND_1 | gawk '{print $1}' | $COMMAND_3

   echo
   echo "Process(es) killed."
  ;;
 *)
  #If user answers anything but "yes", do not kill.
  echo
  echo "Will not kill the process(es)"
  echo
  ;;
 esac
;;
esac

#################################################################
# Create a report of all files owned by User Account
echo
echo "Step #3 - Find files on system belonging to user account"
echo
echo "Creating a report of all files owned by $USER_ACCOUNT."
echo
echo "It is recommended that you backup/archive these files,"
echo "and then do one of two things:"
echo " 1) Delete the files"
echo " 2) Change the files' ownership to a current user account."
echo
echo "Please wait. This may take a while..."
#
REPORT_DATE=$(date +%y%m%d)
REPORT_FILE=$USER_ACCOUNT"_Files_"$REPORT_DATE".rpt"
#
find / -user $USER_ACCOUNT > $REPORT_FILE 2> /dev/null
#
echo
echo "Report is complete."
echo "Name of report: $REPORT_FILE"
echo "Location of report: $(pwd)"
echo
####################################
# Remove User Account
echo
echo "Step #4 - Remove user account finally"
echo

LINE1="Remove $USER_ACCOUNT's account from system? [y/n]"
getAnswer

#Call process_answer function:
#if user answers anything but "yes", exit script
EXIT_LINE1="Since you do not wish to remove the user account,"
EXIT_LINE2="$USER_ACCOUNT at this time, exiting the script..."
processAnswer

userdel $USER_ACCOUNT
#delete user account
echo
echo "User account, $USER_ACCOUNT, has been removed"
echo
exit
