# 配置AP Server FTP賬號密碼
cat << 'EOF' >> /root/.192_168_70_22_cifs
username=administrator
password=ginkogsas
EOF
# 配置開機自動mount
cat << 'EOF' >> /etc/fstab
//192.168.70.22/excel_tmp_dir /backup/excel_tmp cifs credentials=/root/.192_168_70_22_cifs,uid=oracle,gid=oinstall,rw 0 0
//192.168.70.22/mis_file$ /misfile cifs credentials=/root/.192_168_70_22_cifs,uid=oracle,gid=oinstall,rw 0 0
EOF

# 關閉防火墻
service iptables save
service iptables stop
chkconfig iptables off
#關閉SELINUX
setenforce 0
cat << 'EOF' >> /etc/sysconfig/selinux
SELINUX=enforcing --> SELINUX=disabled
EOF
# 配置本地yum 源(記得重新連接CD/DVD)
mount /dev/cdrom /mnt
mkdir -p /source/oracleLinux6
cp -rf /mnt/* /source/oracleLinux6/
cd /etc/yum.repos.d
mkdir bak
mv public* bak
cat << 'EOF' >>local.repo
[OLINUX]
name=Oracle Linux 6 x86_64
baseurl=file:///source/oracleLinux6/Server
enabled=1
gpgcheck=0
EOF
# 下載遠程yum 源
sudo wget http://public-yum.oracle.com/public-yum-ol6.repo

# 檢查源
#yum repolist all

# 清除原有的yum信息
yum clean all

# Oracle预安装包，它会自动安装 Oracle 数据库 11gR2 所需要的依赖库、配置环境、系统调整(如内核参数、用户和组等)
# ****  若使用此包可跳至153行[修改密碼], 並繼續以下操作
yum install oracle-rdbms-server-11gR2-preinstall -y

# 修改内核参数配置kernel.shmall,kernel.shmmax
memTotal=$(grep MemTotal /proc/meminfo | awk '{print $2}')
totalMemory=$((memTotal / 2048))
	shmall=$((memTotal / 4))
if [ $shmall -lt 2097152 ]; then
	shmall=2097152
fi
shmmax=$((memTotal * 1024 - 1))
if [ "$shmmax" -lt 4294967295 ]; then
	shmmax=4294967295
fi
sed -i "s/^kernel.shmall.*/kernel.shmall = $shmall/" /etc/sysctl.conf
sed -i "s/^kernel.shmmax.*/kernel.shmmax = $shmmax/" /etc/sysctl.conf

# 加载并应用系统内核参数配置
/sbin/sysctl -p

# 修改密碼(passwd oracle)
echo oracle7695 | passwd --stdin oracle


# 用户最大进程数限制的配置
# vim /etc/security/limits.d/90-nproc.conf
# soft    nproc    1024

# 目錄權限分配
chown oracle.oinstall /db
chmod 755 /db
chmod 777 /opt
mkdir -p /db/oracle/MIS
chown -R oracle.oinstall /db
chmod -R 755 /db
mkdir -p /opt/oracle
chown -R oracle.oinstall /opt/oracle
chmod -R 755 /opt/oracle
chown oracle.oinstall /backup
chmod 755 /backup

# 配置HOST
cat << 'EOF' >> /etc/hosts
127.0.0.1               localhost.localdomain localhost
192.168.70.22           gsas.gs.com.cn       gsas
192.168.50.21           gsdb9.gs.com.cn      gsdb9
EOF

# 配置DNS主機
cat << 'EOF' >> /etc/resolv.conf
search gs.com.cn
nameserver  202.96.209.133
nameserver  8.8.8.8
EOF



# 定义用户登录时的身份验证规则和配置。
cat << 'EOF' >> /etc/pam.d/login
session required /lib/security/pam_limits.so
EOF

# 全局用户环境变量和初始化脚本
cat << 'EOF' >> /etc/profile
ORACLE_HOSTNAME=gsdb9.gs.com.cn; export ORACLE_HOSTNAME
ORACLE_UNQNAME=MIS; export ORACLE_UNQNAME
ORACLE_BASE=/opt/oracle; export ORACLE_BASE
ORACLE_HOME=$ORACLE_BASE/ora11gR2; export ORACLE_HOME
ORACLE_SID=MIS; export ORACLE_SID
PATH=/usr/sbin:$PATH; export PATH
PATH=$ORACLE_HOME/bin:$PATH; export PATH
LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib; export LD_LIBRARY_PATH
CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib; export CLASSPATH
EOF
source /etc/profile

# 定义用户登录时的环境变量和初始化脚本
cat << 'EOF' >> /etc/csh.login
if ( $USER == "oracle" ) then
 limit maxproc 16384
 limit descriptors 101062
 umask 022
endif
EOF

# 上傳檔案/home/oracle/source
mkdir -p /home/oracle/source
chmod 777 /home/oracle/source


echo '進度:50%'

1.p13390677_112040_Linux-x86-64_1of7.zip
2.p13390677_112040_Linux-x86-64_2of7.zip
3.db.rsp
4.dbca.rsp
5.netca.rsp


#############################################################################################
## 解壓縮
cd /home/oracle/source
unzip p13390677_112040_Linux-x86-64_1of7.zip
unzip p13390677_112040_Linux-x86-64_2of7.zip

# 配置VNC
su oracle
vncserver
#############################################################################################

# 開始安裝(用戶:oracle) | CORE  11.2.0.4.0  Production
su - oracle -c "
export LC_ALL=\"C\";
cd ~/source/database;
./runInstaller -silent -waitForCompletion -noconfig -showProgress -ignorePrereq -responseFile /home/oracle/source/db.rsp
"
sh /opt/oraInventory/orainstRoot.sh
sh /opt/oracle/ora11gR2/root.sh

# DBCA (Global DB Name=MIS.GS.COM.CN, SID=MIS)
su - oracle -c "dbca -silent -responseFile /home/oracle/source/dbca.rsp"
# NETCA (Listener=LISTENER)
su - oracle -c "netca -silent -responseFile /home/oracle/source/netca.rsp"

# 設置作業系統, 自啓動
cat << 'EOF' >> /etc/oratab
mis:/opt/oracle/ora11gR2:Y
EOF

# 控制用户登录时用户名的大小写敏感性(不区分用户名的大小写)
su - oracle -c "
echo '
alter system set sec_case_sensitive_logon=false scope=both;
shutdown immediate
startup' | 
sqlplus -S / as sysdba
"

# 設置TNSNAME
cat << 'EOF' >> $ORACLE_HOME/network/admin/tnsnames.ora
MIS =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.50.21)(PORT = 1521))
    (CONNECT_DATA =
      (SID = MIS)
    )
  )

GSDB3 =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.201.21)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = mis.gs.com.cn)
    )
  )

TBM =
   (DESCRIPTION =
     (ADDRESS = (PROTOCOL = TCP)(HOST = 60.249.24.173)(PORT = 1521))
     (ADDRESS = (PROTOCOL = TCP)(HOST = 60.249.24.175)(PORT = 1521))
     (ADDRESS = (PROTOCOL = TCP)(HOST = 59.125.63.181)(PORT = 1521))
     (ADDRESS = (PROTOCOL = TCP)(HOST = 59.125.63.182)(PORT = 1521))
     (LOAD_BALANCE = yes)
     (CONNECT_DATA =
       (SERVER = DEDICATED)
       (SERVICE_NAME = ORCL)
       (FAILOVER_MODE =
         (TYPE = SELECT)
         (METHOD = BASIC)
         (RETRIES = 180)
         (DELAY = 5)
       )
     )
   )

MISHT =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 60.14.40.104)(PORT = 1521))
    )
    (CONNECT_DATA =
      (SID = mis)
    )
  )

MIS.GINKO.COM.TW =
   (DESCRIPTION =
     (ADDRESS = (PROTOCOL = TCP)(HOST = 60.249.24.173)(PORT = 1521))
     (ADDRESS = (PROTOCOL = TCP)(HOST = 60.249.24.175)(PORT = 1521))
     (ADDRESS = (PROTOCOL = TCP)(HOST = 59.125.63.181)(PORT = 1521))
     (ADDRESS = (PROTOCOL = TCP)(HOST = 59.125.63.182)(PORT = 1521))
     (LOAD_BALANCE = yes)
     (CONNECT_DATA =
       (SERVER = DEDICATED)
       (SERVICE_NAME = ORCL)
       (FAILOVER_MODE =
         (TYPE = SELECT)
         (METHOD = BASIC)
         (RETRIES = 180)
         (DELAY = 5)
       )
     )
   )

MIS.GINKO.COM.CN =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 218.3.91.210)(PORT = 1521))
    )
    (CONNECT_DATA =
      (SERVICE_NAME = mis.ginko.com.cn)
    )
  )

EXTPROC_CONNECTION_DATA =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC0))
    )
    (CONNECT_DATA =
      (SID = PLSExtProc)
      (PRESENTATION = RO)
    )
  )
EOF

# 定義脚本(启动、停止、管理数据库的操作)
cat << 'EOF' >> /etc/init.d/dbora
#!/bin/bash
export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=/opt/oracle/ora11gR2
export ORACLE_SID=MIS
export NLS_LANG=american_america.UTF8
export PATH=/bin:/usr/bin:$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=/lib:/usr/lib:/usr/lib64:$ORACLE_HOME/lib


start() {
        su  oracle -c "lsnrctl start"
        su  oracle -c "emctl start dbconsole"
        su  oracle -c "isqlplusctl start"
        su  oracle -c "dbstart $ORACLE_HOME"
}

stop() {
        su  oracle -c "lsnrctl stop"
        su  oracle -c "emctl stop dbconsole"
        su  oracle -c "isqlplusctl stop"
        su  oracle -c "dbshut $ORACLE_HOME"
}

restart() {
        stop
        start
}

reload() {
        stop
        start
}

case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  restart)
        restart
        ;;
  reload)
        reload
        ;;
  *)
        echo $"Usage: $0 {start|stop|restart|reload}"
        exit 1
esac

exit $?
EOF

chmod 755 /etc/init.d/dbora
ln -s /etc/init.d/dbora /etc/rc.d/rc3.d/K70dbora
ln -s /etc/init.d/dbora /etc/rc.d/rc3.d/S99dbora
ln -s /etc/init.d/dbora /etc/rc.d/rc5.d/K70dbora
ln -s /etc/init.d/dbora /etc/rc.d/rc5.d/S99dbora

# 存储网络应用程序（如FTP、HTTP等）的身份验证信息
cat << EOF >> /home/oracle/.netrc
machine dyas login backup password backupoptical
machine twas login backupcn password backupoptical
machine gsas2 login backup password backupoptical
EOF
chmod 600 /home/oracle/.netrc
chown oracle.oinstall /home/oracle/.netrc

# 定義脚本(數據庫備份)
cat << 'EOF' >> /backup/backup_gs.sh
export NLS_LANG=american_america.UTF8
export ORACLE_HOME=/opt/oracle/ora11gR2
#export ORACLE_HOME=/opt/oracle/Ora11gR2Client
export PATH=$ORACLE_HOME/bin:$PATH
export ORACLE_SID=MIS
export FILE_NAME=expdp_gs`date +%Y%m%d`
echo "lcd /backup" > /backup/ftp_dmp
echo "cd /backup" > /backup/ftp_dmp
echo "bin" >> /backup/ftp_dmp
echo "prompt off" >> /backup/ftp_dmp
echo "mput $FILE_NAME*" >> /backup/ftp_dmp
echo "bye" >> /backup/ftp_dmp
echo "start export:`/bin/date`" >> /backup/runtime.log
cd /backup
##exp userid=system/ginkogsdb file=$FILE_NAME.dmp full=y log=$FILE_NAME.log
#exp userid="'/ as sysdba'" file=$FILE_NAME.dmp full=y log=$FILE_NAME.log
expdp userid="'/ as sysdba'" dumpfile=$FILE_NAME.dmp directory=dpdata_dir full=y log=$FILE_NAME.log
#expdp userid="'/ as sysdba'" directory=backup_dir dumpfile=$FILE_NAME.dpdmp full=y logfile=$FILE_NAME.log
##/bin/gzip -f $FILE_NAME.dmp >> /backup/runtime.log
/usr/local/bin/rar m -v8000000 $FILE_NAME $FILE_NAME.dmp  >> /backup/runtime.log
/usr/bin/ftp gsas2 < /backup/ftp_dmp >> /backup/runtime.log
##/usr/bin/ftp twas < /backup/ftp_dmp >> /backup/runtime.log
EOF
chmod 755 /backup/backup_gs.sh
echo rm -r -f /opt/oracle/admin/mis/bdump/* >> /backup/rm_oracle_trc.sh
chmod 755 /backup/rm_oracle_trc.sh

# 自動排程(crontab中添加定时任务)
su - oracle
(crontab -l ; echo "00 23 * * * /backup/backup_gs.sh > /dev/null 2>&1") | crontab -
(crontab -l ; echo "00 03 * * * /backup/rm_oracle_trc.sh > dev/null 2>&1") | crontab -
exit


cat << 'EOF' >> /home/oracle/.netrc
machine dyas login backup password backupoptical
machine twas login backupcn password backupoptical
machine gsas login backup password backupoptical
EOF

# 
su - oracle -c "
echo '
create directory dpdata_dir as '\''/backup'\'';
grant read, write on directory dpdata_dir to public;
create pfile='\''/opt/oracle/admin/MIS/pfile/initMIS.ora'\'' from spfile;
' | 
sqlplus -S / as sysdba
"

# 郵箱SMTP設置
su - oracle -c "
echo '
@$ORACLE_HOME/rdbms/admin/utlmail.sql;
@$ORACLE_HOME/rdbms/admin/prvtmail.plb;
alter system set smtp_out_server = '\''mail.hydron.com.tw'\'' scope=both;
grant execute on utl_mail to public;
' | 
sqlplus -S / as sysdba
"

# 建立表空間
su - oracle -c "
echo '
CREATE SMALLFILE 
    TABLESPACE "MIS_DATA" 
    LOGGING 
    DATAFILE '\''/db/oracle/MIS/MIS_DATA_01.dbf'\'' SIZE 16G,
             '\''/db/oracle/MIS/MIS_DATA_02.dbf'\'' SIZE 16G,
             '\''/db/oracle/MIS/MIS_DATA_03.dbf'\'' SIZE 16G,
             '\''/db/oracle/MIS/MIS_DATA_04.dbf'\'' SIZE 16G,
             '\''/db/oracle/MIS/MIS_DATA_05.dbf'\'' SIZE 16G,
             '\''/db/oracle/MIS/MIS_DATA_06.dbf'\'' SIZE 16G,
             '\''/db/oracle/MIS/MIS_DATA_07.dbf'\'' SIZE 16G,
             '\''/db/oracle/MIS/MIS_DATA_08.dbf'\'' SIZE 16G,
             '\''/db/oracle/MIS/MIS_DATA_09.dbf'\'' SIZE 16G,
             '\''/db/oracle/MIS/MIS_DATA_10.dbf'\'' SIZE 16G
    EXTENT MANAGEMENT LOCAL SEGMENT SPACE MANAGEMENT  AUTO;

CREATE SMALLFILE 
    TABLESPACE "MIS_INDEX" 
    LOGGING 
    DATAFILE '\''/db/oracle/MIS/MIS_INDEX_01.dbf'\'' SIZE 16G,
             '\''/db/oracle/MIS/MIS_INDEX_02.dbf'\'' SIZE 16G,
             '\''/db/oracle/MIS/MIS_INDEX_03.dbf'\'' SIZE 16G,
             '\''/db/oracle/MIS/MIS_INDEX_04.dbf'\'' SIZE 16G,
             '\''/db/oracle/MIS/MIS_INDEX_05.dbf'\'' SIZE 16G,
             '\''/db/oracle/MIS/MIS_INDEX_06.dbf'\'' SIZE 16G,
             '\''/db/oracle/MIS/MIS_INDEX_07.dbf'\'' SIZE 16G,
             '\''/db/oracle/MIS/MIS_INDEX_08.dbf'\'' SIZE 16G
    EXTENT MANAGEMENT LOCAL SEGMENT SPACE MANAGEMENT  AUTO;

CREATE SMALLFILE 
    TABLESPACE "NEW_MIS_DATA" 
    LOGGING 
    DATAFILE '\''/db/oracle/MIS/NEW_MIS_DATA_01.dbf'\'' SIZE 16G,
             '\''/db/oracle/MIS/NEW_MIS_DATA_02.dbf'\'' SIZE 16G,
             '\''/db/oracle/MIS/NEW_MIS_DATA_03.dbf'\'' SIZE 16G,
             '\''/db/oracle/MIS/NEW_MIS_DATA_04.dbf'\'' SIZE 16G
    EXTENT MANAGEMENT LOCAL SEGMENT SPACE MANAGEMENT  AUTO;

CREATE SMALLFILE 
    TABLESPACE "NEW_MIS_INDEX" 
    LOGGING 
    DATAFILE '\''/db/oracle/MIS/NEW_MIS_INDEX_01.dbf'\'' SIZE 16G,
             '\''/db/oracle/MIS/NEW_MIS_INDEX_02.dbf'\'' SIZE 16G,
             '\''/db/oracle/MIS/NEW_MIS_INDEX_03.dbf'\'' SIZE 16G,
             '\''/db/oracle/MIS/NEW_MIS_INDEX_04.dbf'\'' SIZE 16G
    EXTENT MANAGEMENT LOCAL SEGMENT SPACE MANAGEMENT  AUTO;
' | 
sqlplus -S / as sysdba
"

# 權限
su - oracle -c "
	grant all on v_$database to public;
	grant all on v_$session to public;
	alter profile default limit password_life_time unlimited;
"

# rar工具安裝
cd /home/oracle/source
tar zxvf rarlinux-x64-5.5.0.tar.gz -C /usr/local
ln -s /usr/local/rar/rar /usr/local/bin/rar
ln -s /usr/local/rar/unrar /usr/local/bin/unrar

# NTP時間矯正
ntpdate time.windows.com
cat << EOF >> /etc/crontab
10 5 * * * root (/usr/sbin/ntpdate time.windows.com && /sbin/hwclock -w) &> /dev/null
EOF

# 備份還原
su oracle
impdp userid="'/ as sysdba'" file=expdp_gs20240106.dmp directory=dpdata_dir full=y ignore=y log=full.log
exit;

# 編譯無效物件
--check invalid object
col owner for a10;
col object_name for a30;
col object_type for a30;
select owner,object_name,object_type
  from all_objects
 where status = 'INVALID'
 order by 1,2;

--compoile public sysnonym
set pagesize 0
spool c:\temp\compile_public_synonym.sql;
select 'alter public synonym "'||object_name||'" compile;'
  from all_objects
 where owner='PUBLIC'
   and object_type='SYNONYM'
   and status = 'INVALID';
spool off;
@c:\temp\compile_public_synonym.sql

--compoile materialized view
set pagesize 0
spool c:\temp\compile_materialized_view.sql;
select 'alter materialized view '||owner||'.'||object_name||' compile;'
  from all_objects
 where object_type='MATERIALIZED VIEW'
   and status = 'INVALID';
spool off;
@c:\temp\compile_materialized_view.sql;

--analyze all table
set pagesize 0;
spool c:\temp\analyze_all.sql;
select 'analyze table "'||owner||'"."'||object_name||'" compute statistics;'
  from all_objects
 where object_type in ('TABLE','MATERIALIZED VIEW')
   and owner in ('TBM','HRM','CSM','OAM','SDM','WEBUTIL',
								'OLM','WSM','GLM','HYD','UFM','WIP','AGENTFLOW',
								'MIS','IDM','CTM','BKM','IWM','BOM','SDM',
								'ERM','APM','PRM','IWM','CSM',
								'WFM','IVM','BPM','TDM','CMM','ARM','ERM',
								'REPORT','SYS','SYSTEM')
  order by owner,object_name;
spool off;
@c:\temp\analyze_all.sql;
