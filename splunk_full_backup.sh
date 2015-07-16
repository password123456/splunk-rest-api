########### Splunk Backup Script ##########
# created by password123456

#!/bin/bash

BACKUP_TIME=`date +%Y-%m-%d-%T`
BACKUP_DATE=`date +%Y%m%d`

# Backup Path
INDEX_BACKUP_PATH="/splunk_backup/${BACKUP_DATE}/index_backup_full"

# 1.index db Backup

# SPLUNK INDEX PATH
INDEX_PATH="/data_splunk/splunk"

# BACKUP LIST OF ALL INDEX
BACKUP_TO_TARGET_INDEX=(`ls -d -1 $INDEX_PATH/*/ | awk -F"/" '{ print $4 }' | xargs`)

# BACKUP TARGET INDEX Except Hot Bucket DB
BACKUP_INDEX_DB=("db" "colddb")

echo "###########################################"
echo "#####    SPLUNK Full BACKUP            ####"
echo "###########################################"
echo "[+] LIST OF INDEX : "`ls -d -1 $INDEX_PATH/*/ | awk -F"/" '{ print $4 }' | xargs`""

for list in ${BACKUP_TO_TARGET_INDEX[@]}
do
   echo "[+] INDEX : "$list" ===="

  for db in ${BACKUP_INDEX_DB[@]}
   do

    BACKUP_CHECK=`ls -d -1 ${INDEX_PATH}/$list/$db/*/ | grep "db_" | wc -l`

    if [ $BACKUP_CHECK -eq 0 ]
      then
        echo "[+] ==== BACKUP DB : "$list"/"$db" ===="
        echo "[*] ==== TARGET COUNT : $BACKUP_CHECK"
	echo "[*] ==== QUIT BACKUP SCRIPTS. ===="

      else
        # Create Backup Index Directory
    	if [ ! -d $INDEX_BACKUP_PATH/$list ]
          then
       	    mkdir -p $INDEX_BACKUP_PATH/$list
        fi
    
        INDEX_BACKUP_SAVE_NAME="${INDEX_BACKUP_PATH}/${list}/${list}_${db}_${BACKUP_INDEX_DATE}.tar.gz"

        echo "[+] ==== BACKUP DB : "$list"/"$db" ===="
        echo "[+] ==== TARGET COUNT : $BACKUP_CHECK"
        echo "[+] ==== BACKUP NAME : $INDEX_BACKUP_SAVE_NAME ===="
        echo "[+] ==== LIST & SIZE ===="
        echo "`ls -d -1 ${INDEX_PATH}/$list/$db/*/ | grep "db_" | xargs du -shc`"
	echo "[+] ==== BACKUP PROGRESS ===="

	ls -d -1 ${INDEX_PATH}/$list/$db/*/ | grep "db_" | xargs tar zcvPf ${INDEX_BACKUP_SAVE_NAME} | xargs -L 2 | xargs -I@ echo -n "#"
	echo " "
        RETN=$?

	if [ $RETN -eq 0 ]; then

            INDEX_BACKUP_SIZE=`du -sh $INDEX_BACKUP_SAVE_NAME  | awk -F " " '{ print $1 }'`
	    echo "[+] ==== BACKUP TO : $INDEX_BACKUP_SAVE_NAME ===="
            echo "[+] ==== TOTAL ARCHIVED SIZE : $INDEX_BACKUP_SIZE ==== "
	    echo "[+] ==== OK. ALL SUCCESS.! ===="

        else
            echo "[*] ==== BACKUP FAIL : $INDEX_BACKUP_SAVE_NAME ===="
	    echo "[*] ==== ERROR CODE : $RETN ===="
            echo "[*] ==== CHECK BACKUP SCRIPTS. ===="
        fi
    fi
   done
done
echo "========== end $BACKUP_TIME =============="
