#!/bin/bash
OLDGET=microsoft-oldGet.txt
CURRENTGET=microsoft-currentGet.txt
MINIMUMSIZE=500
INBOUNDLIST=`curl https://www.microsoft.com/en-us/download/confirmation.aspx?id=53602 2>&1  | sed -n 's/.*href="\([^"]*\).*/\1/p' |grep -m1 msft-public-ips.csv`
LISTNAME=msft-public-ips.txt
LOG=msft-public-ips.log
DATE=`date`

if [ "$1" == "--forceupdate" ] || [ "$1" == "-f" ];then
echo "Forcing List Update..."
echo "### FORCE UPDATE $DATE ###" >> $LOG
echo "INBOUND LIST URL = $INBOUNDLIST" >> $LOG
rm $OLDGET 2>>$LOG
fi

echo "Starting script at $DATE" >> $LOG
if [  -f ./$OLDGET ]
 then
echo "File Exists. Checking current version" >> $LOG
echo "INBOUND LIST URL = $INBOUNDLIST" >> $LOG
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
cp $CURRENTGET $LISTNAME 2>> $LOG
cat $LISTNAME | cut -d, -f1 > /opt/xxx/www/current/msft-public-ips.txt 2>> $LOG
\mv -f $CURRENTGET $OLDGET 2>> $LOG
rm -rf $LISTNAME 2>>$LOG
else
echo "File $CURRENTGET does not have enough content. Please, check content and verify source." >> $LOG
fi
fi

echo "Exiting Script at $DATE" >> $LOG
echo "###########################################" >> $LOG
echo "###########################################" >> $LOG
