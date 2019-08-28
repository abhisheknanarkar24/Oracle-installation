#!/bin/bash
#####################################################################################
# Date            Version            Change
# 01/03/2019      1.0                created (previous)
# 11/04/2019      2.0                backlog fixes and new features (current)
#####################################################################################

#Run this script as redHat user (or any user with sudo access)
# Command line argument : <working-directory-name>


# Create swap space
#dd if=/dev/zero of=/swapfile bs=1024 count=165536
#mkswap /swapfile
#swapon /swapfile
#echo /swapfile        swap            swap    defaults        0 0 >> /etc/fstab


# Creating oracle user and oracle groups, first checks if it already exist
getent group oinstall || groupadd oinstall
getent group dba || groupadd dba
id -u oracle &>/dev/null || useradd -g oinstall -G dba oracle


# Change password for oracle user
echo $2 | passwd oracle --stdin


# Removing old oracle setup if present
rm -rf /stage
mkdir -p /stage
unzip $1/linuxamd64_12102_database_1of2.zip -d /stage/
unzip $1/linuxamd64_12102_database_2of2.zip -d /stage/


# Creating directory for oracle installation
# And assigning owenership and all permissions to oracle groups
mkdir -p /u01
mkdir -p /u02
chown -R oracle:oinstall /u01
chown -R oracle:oinstall /u02
chmod -R 777 /u01
chmod -R 777 /u02
chmod g+s /u01
chmod g+s /u02

mkdir /u01/app
mkdir /u01/app/oracle
mkdir /u01/app/oraInventory
chown -R oracle:oinstall /u01/app/oraInventory
chown -R oracle.oinstall /u01/app/oracle
#chmod -R 775 /u01/app/oraInventory

# Change user to oracle
# Installing oracle as oracle user
sudo -u oracle -s bash <<RUN_AS_ORACLE

# Runs silent installation command with response file
sh /stage/database/runInstaller -ignoreSysPrereqs -ignorePrereq -showProgress -silent -waitforcompletion -responseFile $1/db.rsp


# Runs the script which sets the environtment variables and all
#/u01/app/oraInventory/orainstRoot.sh
#/u01/app/oracle/product/12.2.0/dbhome_1/root.sh


# Runs configToolAllCommands with the provided config response file (property)
/u01/app/oracle/product/12.2.0/dbhome_1/cfgtoollogs/configToolAllCommands RESPONSE_FILE=$1/cfgrsp.properties

RUN_AS_ORACLE


# Set environtment variables
#tee -a /etc/profile.d/bash_profile.sh <<- 'EOF'
read -d '' env << 'EOF'
TMPDIR=$TMP; export TMPDIR
ORACLE_BASE=/u01/app/oracle; export ORACLE_BASE
ORACLE_HOME=$ORACLE_BASE/product/12.2.0/dbhome_1; export ORACLE_HOME
ORACLE_SID=ORCL; export ORACLE_SID
PATH=$ORACLE_HOME/bin:$PATH; export PATH
LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib:/usr/lib64; export LD_LIBRARY_PATH
CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib; export CLASSPATH
EOF
grep -q -F "$env" /etc/profile.d/bash_profile.sh || echo "$env" >> /etc/profile.d/bash_profile.sh

# Run the script to take effect
sh /etc/profile.d/bash_profile.sh


# To allow connections from outside the server exposing the ports
firewall-cmd --zone=public --add-port=1521/tcp --add-port=5500/tcp --add-port=5520/tcp --add-port=3938/tcp --permanent
firewall-cmd --reload
# Run the script to take effect
sh /etc/profile.d/bash_profile.sh


sudo -u oracle -s bash <<RUN_AS_ORACLE
# Add listener for oracle database "ORCL"
tee -a /u01/app/oracle/product/12.2.0/dbhome_1/network/admin/listener.ora <<- 'EOF'


SID_LIST_LISTENER =
    (SID_DESC =
      (GLOBAL_DBNAME = ORCL)
      (ORACLE_HOME = /u01/app/oracle/product/12.2.0/dbhome_1)
      (SID_NAME = ORCL)
    )
  )
EOF


# Start the listener
#lsnrctl start

RUN_AS_ORACLE
#sudo -u oracle -s bash <<RUN_AS_ORACLE
#cd $ORACLE_HOME/bin
#relink all
echo INSTALLATION SUCCESSFUL!!
