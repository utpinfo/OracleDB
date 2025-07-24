## ISO文件下載
```
wget https://yum.oracle.com/ISOS/OracleLinux/OL6/u10/x86_64/OracleLinux-R6-U10-Server-x86_64-dvd.iso
```

## 安裝紅色首頁點擊[TAB], 追加下方內容
```
# For Oracle Linux 6
ks=http://192.168.201.27/ksfiles/ks.cfg ip=192.168.70.121::192.168.70.254:255.255.255.0::eth0:none
# For Oracle Linux 7
# ks=http://192.168.201.27/ksfiles/ks.cfg ip=192.168.70.121::192.168.70.254:255.255.255.0::ens192:none
# For Oracle Linux 6 (internat)
# ks=https://raw.githubusercontent.com/utpinfo/OracleDB/main/ksfiles/ks.cfg ip=192.168.70.121::192.168.70.254:255.255.255.0::eth0:none nameserver=114.114.114.114,8.8.8.8
# For Oracle Linux 7
# ks=https://raw.githubusercontent.com/utpinfo/OracleDB/main/ksfiles/ol7ks.cfg ip=192.168.70.121::192.168.70.254:255.255.255.0::eth0:none nameserver=114.114.114.114,8.8.8.8
```
## 安裝ORACLE Database
- 請閱讀DBSETUP.md

## 版本推薦
| Oracle Database 版本 | 適用 OS 版本               | 備註                  |
| ------------------ | ---------------------- | ------------------- |
| 11gR2 11.2.0.4     | Oracle Linux 6.4\~6.10 | 最穩定，官方內部測試環境常用      |
|                    | Oracle Linux 5.8+      | 可安裝，但較舊、已過時         |
|                    | Oracle Linux 7.x       | **可行但不推薦**，需手動修補相容性 |
|                    | Oracle Linux 8/9       | ❌ 不相容（glibc 版本過高）   |
