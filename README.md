## ISO文件下載
```
wget https://yum.oracle.com/ISOS/OracleLinux/OL7/u7/x86_64/OracleLinux-R7-U7-Server-x86_64-dvd.iso
```

## 安裝紅色首頁點擊[TAB], 追加下方內容
ks=http://192.168.201.27/ksfiles/ks.cfg ip=192.168.70.121::192.168.70.254:255.255.255.0::ens192:none
#ks=https://raw.githubusercontent.com/utpinfo/OracleDB/refs/heads/main/ks.cfg ip=192.168.70.121::192.168.70.254:255.255.255.0::ens192:none nameserver=114.114.114.114,8.8.8.8



