#!/bin/bash
# ============================================================================
# Title:       網關配置 (訪問SQL Server)
# Description: Automates the installation and configuration of Oracle Gateway
# Author:      UTPInfo
# Created:     2025-08-01
# Version:     1.0
# Document     https://docs.oracle.com/database/121/OTGIS/configsql.htm
# ============================================================================

# 配置odbc訪問sql server (https://docs.oracle.com/database/121/OTGIS/configsql.htm)
assetsdir=/home/oracle/source
ftpassetsdir=ftp://administrator:ginkogsas@192.168.70.22/administrator/OracleDB/assets-12c
cd $assetsdir
wget -r -nH --no-parent --no-directories $ftpassetsdir/linuxx64_12201_gateways.zip -O $assetsdir/linuxx64_12201_gateways.zip 
wget -r -nH --no-parent --no-directories $ftpassetsdir/tg.rsp -O $assetsdir/tg.rsp
unzip $assetsdir/linuxx64_12201_gateways.zip

# GATEWAY 靜默安裝
su - oracle -c "
cd ${assetsdir}/gateways;
./runInstaller -silent -ignorePrereqFailure -ignoreSysPrereqs -showProgress -waitforcompletion -responseFile ${assetsdir}/tg.rsp
"

# 配置網關文件
cd $ORACLE_BASE/ora12cR2/dg4msql/admin
mv initdg4msql.ora initdg4msql.ora.bk

cp initdg4msql.ora.bk initbetg.ora
sed -i 's/betg/betg/' initbetg.ora

cp initdg4msql.ora.bk inithko.ora
sed -i 's/betg/hko/' inithko.ora

cp initdg4msql.ora.bk inithno.ora
sed -i 's/betg/hno/' inithno.ora

cp initdg4msql.ora.bk inithks.ora
sed -i 's/betg/hks/' inithks.ora

cp initdg4msql.ora.bk inithns.ora
sed -i 's/betg/hns/' inithns.ora

cp initdg4msql.ora.bk initoptics.ora
sed -i 's/betg/optics/' initoptics.ora

# (1)配置客戶端 tnsname.ora
cat <<EOF>> $ORACLE_HOME/network/admin/tnsnames.ora
hks  =
  (DESCRIPTION=
    (ADDRESS=(PROTOCOL=tcp)(HOST= 192.168.70.21)(PORT=1521))
    (CONNECT_DATA=(SID=hks))
    (HS=OK)
  )

hko  =
  (DESCRIPTION=
    (ADDRESS=(PROTOCOL=tcp)(HOST= 192.168.70.21)(PORT=1521))
    (CONNECT_DATA=(SID=hko))
    (HS=OK)
  )

hns  =
  (DESCRIPTION=
    (ADDRESS=(PROTOCOL=tcp)(HOST= 192.168.70.21)(PORT=1521))
    (CONNECT_DATA=(SID=hns))
    (HS=OK)
  )

hno  =
  (DESCRIPTION=
    (ADDRESS=(PROTOCOL=tcp)(HOST= 192.168.70.21)(PORT=1521))
    (CONNECT_DATA=(SID=hno))
    (HS=OK)
  )

betg  =
  (DESCRIPTION=
    (ADDRESS=(PROTOCOL=tcp)(HOST= 192.168.70.21)(PORT=1521))
    (CONNECT_DATA=(SID=betg))
    (HS=OK)
  )

optics  =
  (DESCRIPTION=
    (ADDRESS=(PROTOCOL=tcp)(HOST= 192.168.70.21)(PORT=1521))
    (CONNECT_DATA=(SID=optics))
    (HS=OK)
  )  
EOF

# (2)配置服務端 listener.ora
cat <<EOF>> $ORACLE_HOME/network/admin/listener.ora
SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (SID_NAME = hks)
      (ORACLE_HOME = /opt/oracle/ora12cR2)
      (PROGRAM = dg4msql)
    )
    (SID_DESC =
      (SID_NAME = hns)
      (ORACLE_HOME = /opt/oracle/ora12cR2)
      (PROGRAM = dg4msql)
    )
    (SID_DESC =
      (SID_NAME = hko)
      (ORACLE_HOME = /opt/oracle/ora12cR2)
      (PROGRAM = dg4msql)
    )
    (SID_DESC =
      (SID_NAME = hno)
      (ORACLE_HOME = /opt/oracle/ora12cR2)
      (PROGRAM = dg4msql)
    )
    (SID_DESC =
      (SID_NAME = betg)
      (ORACLE_HOME = /opt/oracle/ora12cR2)
      (PROGRAM = dg4msql)
    )
    (SID_DESC =
      (SID_NAME = optics)
      (ORACLE_HOME = /opt/oracle/ora12cR2)
      (PROGRAM = dg4msql)
    )    
  )
EOF

# (3)數據庫重啟
/etc/init.d/dbora start

# (4)建立 DATABASE Link
su oracle
sqlplus -s / as sysdba <<EOF

-- 建立 DB Link
create public database link betg.gs.com.cn
  connect to hs_admin identified by "Sourceway@123"
  using 'betg';

create public database link hko.gs.com.cn
  connect to hs_admin identified by "Sourceway@123"
  using 'hko';

create public database link hno.gs.com.cn
  connect to hs_admin identified by "Sourceway@123"
  using 'hno';  

create public database link hks.gs.com.cn
  connect to hs_admin identified by "Sourceway@123"
  using 'hks';

create public database link hns.gs.com.cn
  connect to hs_admin identified by "Sourceway@123"
  using 'hns';

create public database link optics.gs.com.cn
  connect to hs_admin identified by "Sourceway@123"
  using 'optics';
EOF
exit;