#!/bin/bash

########### Splunk Backup Script ##########

# Log timeformat
BACKUP_DATE=`date +"%Y%m%d"`
BACKUP_TIME=`date +"%Y-%m-%d-%T"`

# Log file
LOG_FILE="/$YOUR_LOG_PATH$/backup_incremental_$BACKUP_DATE.log"

# Path to Backup
## ex) CONFIG_BACKUP_PATH="/data1/config_backup"
## ex) INDEX_BACKUP_PATH="/data1/index_backup_incremental"

CONFIG_BACKUP_PATH="$$YOUR-SPLUNK_CONFIG_BACKUP_PATH$$"
INDEX_BACKUP_PATH="$$YOUR-SPLUNK_INDEX_BACKUP_PATH$$"

# TARGET INDEX to BACKUP 
# -1d ago / daily backup
BACKUP_INDEX_DATE=`date -d "24 hours ago" "+%Y-%m-%d"`

# 1. SPLUNK Configuration BACKUP
# ex) CONFIG_PATH="/opt/splunk/etc/"

config_backup_splunk()
{

if [ ! -d $CONFIG_BACKUP_PATH ]; then
    mkdir -p $CONFIG_BACKUP_PATH
fi

CONFIG_PATH="/opt/splunk/etc/"
CONFIG_BACKUP_NAME="${CONFIG_BACKUP_PATH}/backup_config_${BACKUP_DATE}.tar.gz"

echo "[+] BACKUP CONFIG : "$CONFIG_PATH" ====" | tee -a $LOG_FILE
echo "[+] ==== BACKUP PROGRESS ====" | tee -a $LOG_FILE

## Create BACKUP archive for Configuration file
tar zcvPf $CONFIG_BACKUP_NAME ${CONFIG_PATH} | xargs -L 2 | xargs -I@ echo -n "#"

RETN=$?

if [ $RETN -eq 0 ]; then

    CONFIG_BACKUP_SIZE=`du -sh $CONFIG_BACKUP_NAME`
    echo " "
    echo "[+] ==== BACKUP TO : $CONFIG_BACKUP_NAME ====" | tee -a $LOG_FILE
    echo "[+] ==== BACKUP ARCHIVED SIZE: $CONFIG_BACKUP_SIZE ====" | tee -a $LOG_FILE
    echo "[+] ==== OK. ALL SUCCESS.! ====" | tee -a $LOG_FILE

else
    echo " "
    echo "[*] BACKUP FAIL : $CONFIG_BACKUP_NAME ====" | tee -a $LOG_FILE
    echo "[*] ==== ERROR CODE : $RETN ====" | tee -a $LOG_FILE
    echo "[*] ==== CHECK BACKUP SCRIPTS. ====" | tee -a $LOG_FILE
fi

return

}

# 2.SPLUNK Alert scripts Backup
# ex) SCRIPTS_PATH="/opt/splunk/bin/scripts/"

scripts_backup_splunk()
{

SCRIPTS_PATH="/opt/splunk/bin/scripts/"
SCRIPTS_BACKUP_NAME="${CONFIG_BACKUP_PATH}/backup_scripts_${BACKUP_DATE}.tar.gz"

echo "[+] BACKUP SCRIPTS : "$SCRIPTS_PATH" ====" | tee -a $LOG_FILE
echo "[+] ==== BACKUP PROGRESS ====" | tee -a $LOG_FILE

## Create BACKUP archive for Scripts file
tar zcvPf $SCRIPTS_BACKUP_NAME ${SCRIPTS_PATH} | xargs -L 2 | xargs -I@ echo -n "#"

RETN1=$?

if [ $RETN1 -eq 0 ]; then

    SCRIPTS_BACKUP_SIZE=`du -h $SCRIPTS_BACKUP_NAME`
    echo " "
    echo "[+] ==== BACKUP TO : $SCRIPTS_BACKUP_NAME ====" | tee -a $LOG_FILE
    echo "[+] ==== BACKUP ARCHIVED SIZE: $SCRIPTS_BACKUP_SIZE ====" | tee -a $LOG_FILE
    echo "[+] ==== OK. ALL SUCCESS.! ====" | tee -a $LOG_FILE

else
    echo " "
    echo "[*] BACKUP FAIL : $SCRIPTS_BACKUP_NAME ====" | tee -a $LOG_FILE
    echo "[*] ==== ERROR CODE : $RETN1 ====" | tee -a $LOG_FILE
    echo "[*] ==== CHECK BACKUP SCRIPTS. ====" | tee -a $LOG_FILE
fi
echo "========== end $BACKUP_TIME ==============" | tee -a $LOG_FILE

return

}

# 3.index db Backup
# BACKUP TO : /data_splunk/splunk/$index_name/db, colddb

index_cp_backup_splunk()
{

## BACKUP TARGET INDEX DATE
# BACKUP_INDEX_DATE="2014-11-07"
#BACKUP_INDEX_DATE=`date -d "24 hours ago" "+%Y-%m-%d"`

# CURRENT Splunk INDEX PATH
INDEX_PATH="/data_splunk/splunk"

# LIST of target index to backup
#BACKUP_TO_TARGET_INDEX=(`ls -d -1 $INDEX_PATH/*/ | awk -F"/" '{ print $4 }' | xargs`)
BACKUP_TO_TARGET_INDEX=`ls -d -1 $INDEX_PATH/*/ | awk -F"/" '{ print $4 }' | xargs`

# Select index type to backup (Cold DB / hotDB)
BACKUP_INDEX_DB=("db" "colddb")

for list in ${BACKUP_TO_TARGET_INDEX[@]}
do
   echo "[+] INDEX : "$list" ====" | tee -a $LOG_FILE
   echo "[+] BACKUP INDEXED DATE : "$BACKUP_INDEX_DATE" ====" | tee -a $LOG_FILE

  for db in ${BACKUP_INDEX_DB[@]}
   do

    BACKUP_CHECK=`ls -ald -1 --time-style="long-iso" $INDEX_PATH/$list/$db/*/ | grep "$BACKUP_INDEX_DATE" | grep "db_" | wc -l`

    if [ $BACKUP_CHECK -eq 0 ]
    #if [ "$BACKUP_CHECK" == "0" ]
      then
        # No target for Backup"
        echo "[+] ==== BACKUP DB : "$list"/"$db" ====" | tee -a $LOG_FILE
        echo "[*] ==== TARGET COUNT : $BACKUP_CHECK ====" | tee -a $LOG_FILE
        echo "[*] ==== NO TARGET to BACKUP ($list > $db) INDEXED TIME AT $BACKUP_INDEX_DATE / ====" | tee -a $LOG_FILE
        echo "[*] ==== QUIT BACKUP SCRIPTS. ====" | tee -a $LOG_FILE

      else
	  # Backup begin"
        # Create Backup Index Directory
    	if [ ! -d $INDEX_BACKUP_PATH/$list/$db ]
          then
       	    mkdir -p $INDEX_BACKUP_PATH/$list/$db
        fi

	INDEX_BACKUP_DIR="$INDEX_BACKUP_PATH/$list/$db/"

        echo "[+] ==== BACKUP DB : "$list"/"$db" ====" | tee -a $LOG_FILE
        echo "[+] ==== TARGET COUNT : $BACKUP_CHECK ====" | tee -a $LOG_FILE
        echo "[+] ==== LIST & SIZE ====" | tee -a $LOG_FILE
        echo "`ls -ald -1 --time-style="long-iso" $INDEX_PATH/$list/$db/*/ | grep "$BACKUP_INDEX_DATE" | grep "db_" | awk -F " " '{ print $8 }' | xargs du -shc`" | tee -a $LOG_FILE

	ls -ald -1 --time-style="long-iso" $INDEX_PATH/$list/$db/*/ | grep "$BACKUP_INDEX_DATE" | grep "db_" | awk -F " " '{ print $8 }' | xargs -n1 -i cp -frav {} "$INDEX_BACKUP_DIR"

	RETN2=$?

	if [ $RETN2 -eq 0 ]; then

	    INDEX_BACKUP_SIZE=`du -sh $INDEX_BACKUP_DIR  | awk -F " " '{ print $1 }'`
	    echo "[+] ==== BACKUP TO : $INDEX_BACKUP_DIR ====" | tee -a $LOG_FILE
            echo "[+] ==== TOTAL BACKUP SIZE : $INDEX_BACKUP_SIZE ==== " | tee -a $LOG_FILE
	    echo "[+] ==== OK. ALL SUCCESS.! ====" | tee -a $LOG_FILE

        else
            echo "[*] ==== BACKUP FAIL : $INDEX_BACKUP_SAVE_NAME ====" | tee -a $LOG_FILE
	    echo "[*] ==== ERROR CODE : $RETN ====" | tee -a $LOG_FILE
            echo "[*] ==== CHECK BACKUP SCRIPTS. ====" | tee -a $LOG_FILE
        fi
    fi
   done

   echo " " | tee -a $LOG_FILE

done

TOTAL_BACKUP_INDEX_SIZE=`du -sh $INDEX_BACKUP_PATH`

echo " " | tee -a $LOG_FILE
echo " " | tee -a $LOG_FILE
echo "----------------------------------------------------------------------------------------------" | tee -a $LOG_FILE
echo "[+] ==== TOTAL BACKUPED SIZE : $TOTAL_BACKUP_INDEX_SIZE ==== " | tee -a $LOG_FILE
echo "`du -shc $INDEX_BACKUP_PATH/*/`" | tee -a $LOG_FILE
echo "========== end $BACKUP_TIME ==============" | tee -a $LOG_FILE
echo " " | tee -a $LOG_FILE

return

}

echo "###########################################"
echo "#####         SPLUNK BACKUP            ####"
echo "###########################################"

echo "[`date +%Y-%m-%d`]" | tee -a $LOG_FILE
echo "========== start $BACKUP_TIME ==============" | tee -a $LOG_FILE
echo "[+] Run : `basename $0`" | tee -a $LOG_FILE
echo "----------------------------------" | tee -a $LOG_FILE
echo "1. CONFIG BACKUP" | tee -a $LOG_FILE
echo "----------------------------------" | tee -a $LOG_FILE
config_backup_splunk
scripts_backup_splunk
echo " " | tee -a $LOG_FILE
echo "----------------------------------" | tee -a $LOG_FILE
echo "2. INDEX BACKUP" | tee -a $LOG_FILE
echo "----------------------------------" | tee -a $LOG_FILE
index_cp_backup_splunk
