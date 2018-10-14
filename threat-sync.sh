#!/bin/bash
OLDGET=ipv4-old-XXX.txt
CURRENTGET=ipv4-current-XXX.txt
INBOUNDLIST="http://XXX.XXXnetworks.local/feeds/XXXTest?tr=1"
LOG=ipv4-db.log
EXPANDEDFILE=/var/lib/mysql-files/maliciousIPV4expanded.csv
DATE=`date`
MINIMUMSIZE=500
echo "Starting synchronization..."
touch /var/lib/mysql-files/maliciousIPV4expanded.csv
echo "Compile Prips..."

cd /usr/share/XXX/application/bin/prips/

make install

cd /usr/share/XXX/application/bin/

echo "Starting script at $DATE" >> $LOG
if [  -f ./$OLDGET ]
then
   echo "File Exists. Checking current version..." >> $LOG
   curl -X GET $INBOUNDLIST 2>> $LOG  > $CURRENTGET
else
   echo "oldGet file does not exist. Creating file..." 2>> $LOG
   curl -X GET $INBOUNDLIST > $OLDGET 2>> $LOG
   \cp -f $OLDGET $CURRENTGET 2>> $LOG
   echo "old" >> $OLDGET
fi


if [ "$(md5sum $OLDGET |cut -f 1 -d " ")" == "$(md5sum $CURRENTGET |cut -f 1 -d " ")" ]; then
   echo "Files have the same hash. Cancelling Upload..." >> $LOG
   rm $CURRENTGET 2>>$LOG
else
   echo "New List Detected (Hashes do not match)." >> $LOG
   rm $EXPANDEDFILE
   if [ "$(wc -c <"$CURRENTGET")" -gt $MINIMUMSIZE ]; then
   echo "Starting PRIPS  at `date +"%T.%3N"`"
   for i in $(cat $CURRENTGET); do
      prips $i >> $EXPANDEDFILE
   done
   echo "Subnet PRIPS completed  at `date`"
   echo "Starting MYSQL SYNC"
mysql << EOF
SET profiling = 1;
SET foreign_key_checks=0;
SET sql_log_bin=0;
SET unique_checks=0;
USE XXX;
CREATE TABLE IF NOT EXISTS  maliciousIP(
    ip varchar(15) NOT NULL,
    malicious varchar(10) not null,
    PRIMARY KEY (ip)
);
CREATE TABLE IF NOT EXISTS  maliciousIP_temp(
    ip varchar(15) NOT NULL,
    malicious varchar(10) not null,
    PRIMARY KEY (ip)
);
LOAD DATA INFILE '/var/lib/mysql-files/maliciousIPV4expanded.csv'
INTO TABLE maliciousIP_temp
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';
SHOW PROFILES;
EOF

mysql << EOF
DROP TABLE IF EXISTS maliciousIP_old;
RENAME Table maliciousIP TO maliciousIP_old, maliciousIP_temp TO maliciousIP;
EOF


\mv -f $CURRENTGET $OLDGET 2>> $LOG
echo "Completed at `date`"
else
echo "File $CURRENTGET does not have enough content. Please, check content and verify source." >> $LOG
fi
fi
echo "Exiting Script at $DATE" >> $LOG
echo "###########################################" >> $LOG
echo "###########################################" >> $LOGf
