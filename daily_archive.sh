#!/bin/bash
#Daily_archive- Archive designated files & directories
#
#Gather current date
DATE=$(date +%y%m%d)
#
#set archive file name
#
FILE=archive$DATE.tar.gz
#
#set configuration and destination file
#
CONFIG_FILE=/archive/Files_to_Backup
DESTINATION=/archive/$FILE
#
######## main script #########
#

archive_file() {
 #backup the files and compress archive
 echo "starting archive..."
 echo
 #
 tar -czf $DESTINATION $FILE_LIST 2> /dev/null
 #
 echo "archive completed"
 echo "resulting archive is: $DESTINATION"
 echo
 exit
}

# check if backup configuration file exists
if [ -f $CONFIG_FILE ]
then
 echo
else
 echo
 echo "$CONFIG_FILE does not exist."
 echo "backup not completed due to missing configuration file"
 echo
 exit
fi 
#
# build the names of all the files to backup
#
FILE_NO=1  #start on line 1 of config file
exec < $CONFIG_FILE   #redirect std input to name of config file
#
read FILE_NAME  #read first record
#
while [ $? -eq 0 ] #create list of files to backup
do
 #make sure the file or directory exists.
 if [ -f $FILE_NAME -o -d $FILE_NAME ]
 then
   #if file exist, add its name to the list
   FILE_LIST="$FILE_LIST $FILE_NAME"
   echo "file list: $FILE_LIST"
 else
   #if the file doesnt exist, issue warning
   echo
   echo "$FILE_NAME does not exist."
   echo "Obviously, i will not include it in this archive"
   echo "it is listed on the line $FILE_NO of the config file"
   echo "continuing to build archive list..."
   echo
 fi
#
 FILE_NO=$[$FILE_NO + 1] #increase the line/file number by one.
 read FILE_NAME #read next record.
done
#
#########
#
#backup the files and compress archive
archive_file  #call the archive_file function, pass in the destination and the files to be archived
