#!/bin/bash
OLDGET=ipv4-oldGet.txt
CURRENTGET=ipv4-currentGet.txt
DATE=`date`
MINIMUMSIZE=500
INBOUNDLIST="http://localhost/feeds/XXXX_processed_IPv4_output"
LISTNAME=ipv4
LOG=ipv4-appspot.log
if [ "$1" == "--forceupdate" ] || [ "$1" == "-f" ];then
echo "Forcing List Update..."
echo "### FORCE UPDATE $DATE ###" >> $LOG
rm $OLDGET 2>>$LOG
fi

echo "Starting script at $DATE" >> $LOG
if [  -f ./$OLDGET ]
 then
echo "File Exists. Checking current version" >> $LOG
curl -X GET $INBOUNDLIST 2>> $LOG  > $CURRENTGET
else
echo "oldGet.txt does not exist. Creating file" 2>> $LOG
curl -X GET $INBOUNDLIST > $OLDGET 2>> $LOG
\cp -f $OLDGET $CURRENTGET 2>> $LOG
echo "old" >> $OLDGET
fi


if [ "$(md5sum $OLDGET |cut -f 1 -d " ")" == "$(md5sum $CURRENTGET |cut -f 1 -d " ")" ]; then
echo "Files have the same hash. Cancelling Upload" >> $LOG
rm $CURRENTGET 2>>$LOG
else
echo "New List Detect (Hashes do not match). Checking Current Size..." >> $LOG
if [ "$(wc -c <"$CURRENTGET")" -gt $MINIMUMSIZE ]; then
echo "Size greater than 500 bytes. Starting upload...." >> $LOG
GOOGLEACCESSTOKEN=`curl --request POST --data 'client_id=[client_id]&client_secret=[client_secret]&grant_type=refresh_token' https://accounts.google.com/o/oauth2/token | awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'access_token'\042/){print $(i+1)}}}' | tr -d '"' | sed -n 1p  2>> $LOG`
cp $CURRENTGET $LISTNAME 2>> $LOG
sed -i "1s|^|$(wc -l < $LISTNAME) \n|" $LISTNAME 2>> $LOG
sed -i '1s/^/ Entries: /' $LISTNAME 2>>$LOG
sed -i "1s|^|$(date) |" $LISTNAME 2>> $LOG
sed -i '1s/^/# XXXX DROP (c) Do not use after 2 days. Retrieved: /' $LISTNAME 2>>$LOG
curl --header "Content-Type:text/plain"  -v --upload-file $LISTNAME -H "Authorization: Bearer $GOOGLEACCESSTOKEN" 'https://storage.googleapis.com/edl.appspot.com/'$LISTNAME'' 2>> $LOG
\mv -f $CURRENTGET $OLDGET 2>> $LOG
rm -rf $LISTNAME 2>>$LOG
else
echo "File $CURRENTGET does not have enough content. Please, check content and verify source." >> $LOG
fi
fi

echo "Exiting Script at $DATE" >> $LOG
echo "###########################################" >> $LOG
echo "###########################################" >> $LOG
