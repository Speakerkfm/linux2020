Подготовим среду
```
[vagrant@localhost ~]$ dd if=/dev/zero of=loopbackfile0.img bs=1M count=1000
1000+0 records in
1000+0 records out
1048576000 bytes (1.0 GB, 1000 MiB) copied, 2.318 s, 452 MB/s
[vagrant@localhost ~]$ dd if=/dev/zero of=loopbackfile1.img bs=1M count=1000
1000+0 records in
1000+0 records out
1048576000 bytes (1.0 GB, 1000 MiB) copied, 2.26926 s, 462 MB/s
[vagrant@localhost ~]$ dd if=/dev/zero of=loopbackfile2.img bs=1M count=1000
1000+0 records in
1000+0 records out
1048576000 bytes (1.0 GB, 1000 MiB) copied, 2.30182 s, 456 MB/s
[vagrant@localhost ~]$ dd if=/dev/zero of=loopbackfile3.img bs=1M count=1000
1000+0 records in
1000+0 records out
1048576000 bytes (1.0 GB, 1000 MiB) copied, 2.24705 s, 467 MB/s
[vagrant@localhost ~]$ dd if=/dev/zero of=loopbackfile4.img bs=1M count=1000
1000+0 records in
1000+0 records out
1048576000 bytes (1.0 GB, 1000 MiB) copied, 2.1865 s, 480 MB/s

[vagrant@localhost ~]$ sudo su
[root@localhost vagrant]# losetup -fP loopbackfile0.img 
[root@localhost vagrant]# losetup -fP loopbackfile1.img
[root@localhost vagrant]# losetup -fP loopbackfile2.img
[root@localhost vagrant]# losetup -fP loopbackfile3.img
[root@localhost vagrant]# losetup -fP loopbackfile4.img
[root@localhost vagrant]# losetup -a
/dev/loop1: [2049]:8929519 (/home/vagrant/loopbackfile1.img)
/dev/loop4: [2049]:8929529 (/home/vagrant/loopbackfile4.img)
/dev/loop2: [2049]:8929522 (/home/vagrant/loopbackfile2.img)
/dev/loop0: [2049]:8929516 (/home/vagrant/loopbackfile0.img)
/dev/loop3: [2049]:8929528 (/home/vagrant/loopbackfile3.img)
[root@localhost vagrant]# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
loop0    7:0    0 1000M  0 loop 
loop1    7:1    0 1000M  0 loop 
loop2    7:2    0 1000M  0 loop 
loop3    7:3    0 1000M  0 loop 
loop4    7:4    0 1000M  0 loop 
sda      8:0    0   10G  0 disk 
`-sda1   8:1    0   10G  0 part /
```

Создаём массив RAID10:
```
[root@localhost vagrant]# mdadm --create /dev/md0 -l 10 -n 4 /dev/loop{0..3}
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.
[root@localhost vagrant]# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE   MOUNTPOINT
loop0    7:0    0 1000M  0 loop   
`-md0    9:0    0    2G  0 raid10 
loop1    7:1    0 1000M  0 loop   
`-md0    9:0    0    2G  0 raid10 
loop2    7:2    0 1000M  0 loop   
`-md0    9:0    0    2G  0 raid10 
loop3    7:3    0 1000M  0 loop   
`-md0    9:0    0    2G  0 raid10 
loop4    7:4    0 1000M  0 loop   
sda      8:0    0   10G  0 disk   
`-sda1   8:1    0   10G  0 part   /
```
Проверяем состояние:
```
[root@localhost vagrant]# cat /proc/mdstat
Personalities : [raid10] 
md0 : active raid10 loop3[3] loop2[2] loop1[1] loop0[0]
      2043904 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]
      
unused devices: <none>

[root@localhost vagrant]# mdadm --detail /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Sun Nov 15 08:39:11 2020
        Raid Level : raid10
        Array Size : 2043904 (1996.00 MiB 2092.96 MB)
     Used Dev Size : 1021952 (998.00 MiB 1046.48 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Sun Nov 15 08:39:22 2020
             State : clean 
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : localhost.localdomain:0  (local to host localhost.localdomain)
              UUID : 27c845e1:fdd86dff:4b02cba6:41c94f33
            Events : 17

    Number   Major   Minor   RaidDevice State
       0       7        0        0      active sync set-A   /dev/loop0
       1       7        1        1      active sync set-B   /dev/loop1
       2       7        2        2      active sync set-A   /dev/loop2
       3       7        3        3      active sync set-B   /dev/loop3
       
```
Пометим диск как сбойный и извлечём его мз массива:
```
 [root@localhost vagrant]# mdadm /dev/md0 --fail /dev/loop0 
 mdadm: set /dev/loop0 faulty in /dev/md0
 [root@localhost vagrant]# mdadm /dev/md0 --remove /dev/loop0
 mdadm: hot removed /dev/loop0 from /dev/md0
 [root@localhost vagrant]# cat /proc/mdstat
 Personalities : [raid10] 
 md0 : active raid10 loop3[3] loop2[2] loop1[1]
       2043904 blocks super 1.2 512K chunks 2 near-copies [4/3] [_UUU]
       
 unused devices: <none>
 
 [root@localhost vagrant]# mdadm --detail /dev/md0
 /dev/md0:
            Version : 1.2
      Creation Time : Sun Nov 15 08:39:11 2020
         Raid Level : raid10
         Array Size : 2043904 (1996.00 MiB 2092.96 MB)
      Used Dev Size : 1021952 (998.00 MiB 1046.48 MB)
       Raid Devices : 4
      Total Devices : 3
        Persistence : Superblock is persistent
 
        Update Time : Sun Nov 15 08:44:22 2020
              State : clean, degraded 
     Active Devices : 3
    Working Devices : 3
     Failed Devices : 0
      Spare Devices : 0
 
             Layout : near=2
         Chunk Size : 512K
 
 Consistency Policy : resync
 
               Name : localhost.localdomain:0  (local to host localhost.localdomain)
               UUID : 27c845e1:fdd86dff:4b02cba6:41c94f33
             Events : 20
 
     Number   Major   Minor   RaidDevice State
        -       0        0        0      removed
        1       7        1        1      active sync set-B   /dev/loop1
        2       7        2        2      active sync set-A   /dev/loop2
        3       7        3        3      active sync set-B   /dev/loop3
        
```
Добавим чистый диск в массив взамен удалённого:
```
[root@localhost vagrant]# mdadm --add /dev/md0 /dev/loop4
mdadm: added /dev/loop4
[root@localhost vagrant]# cat /proc/mdstat
Personalities : [raid10] 
md0 : active raid10 loop4[4] loop3[3] loop2[2] loop1[1]
      2043904 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]
      
unused devices: <none>

[root@localhost vagrant]# mdadm --detail /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Sun Nov 15 08:39:11 2020
        Raid Level : raid10
        Array Size : 2043904 (1996.00 MiB 2092.96 MB)
     Used Dev Size : 1021952 (998.00 MiB 1046.48 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Sun Nov 15 08:46:14 2020
             State : clean 
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : localhost.localdomain:0  (local to host localhost.localdomain)
              UUID : 27c845e1:fdd86dff:4b02cba6:41c94f33
            Events : 39

    Number   Major   Minor   RaidDevice State
       4       7        4        0      active sync set-A   /dev/loop4
       1       7        1        1      active sync set-B   /dev/loop1
       2       7        2        2      active sync set-A   /dev/loop2
       3       7        3        3      active sync set-B   /dev/loop3
  
```
Добавим ещё диск:
```
[root@localhost vagrant]# mdadm --add /dev/md0 /dev/loop0
mdadm: added /dev/loop0
```
Создадим конфигурационный файл:
```
[root@localhost vagrant]# mdadm --detail --scan > /etc/mdadm.conf
```
Остановим и запустим массив:
```
[root@localhost vagrant]# mdadm --stop /dev/md0
mdadm: stopped /dev/md0

[root@localhost vagrant]# mdadm --assemble /dev/md0
mdadm: /dev/md0 has been started with 4 drives and 1 spare.
```
Создаём раздел:
```
[root@localhost vagrant]# fdisk /dev/md0

Command (m for help): n
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p): p
Partition number (1-4, default 1): 1
First sector (2048-4087807, default 2048): 
Last sector, +sectors or +size{K,M,G,T,P} (2048-4087807, default 4087807): 

Created a new partition 1 of type 'Linux' and of size 2 GiB.

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.


[root@localhost vagrant]# lsblk
NAME      MAJ:MIN RM  SIZE RO TYPE   MOUNTPOINT
loop0       7:0    0 1000M  0 loop   
`-md0       9:0    0    2G  0 raid10 
  `-md0p1 259:0    0    2G  0 md     
loop1       7:1    0 1000M  0 loop   
`-md0       9:0    0    2G  0 raid10 
  `-md0p1 259:0    0    2G  0 md     
loop2       7:2    0 1000M  0 loop   
`-md0       9:0    0    2G  0 raid10 
  `-md0p1 259:0    0    2G  0 md     
loop3       7:3    0 1000M  0 loop   
`-md0       9:0    0    2G  0 raid10 
  `-md0p1 259:0    0    2G  0 md     
loop4       7:4    0 1000M  0 loop   
`-md0       9:0    0    2G  0 raid10 
  `-md0p1 259:0    0    2G  0 md     
sda         8:0    0   10G  0 disk   
`-sda1      8:1    0   10G  0 part   /
```
Создаём файловую систему:
```
[root@localhost vagrant]# mkfs.ext4 /dev/md0p1
mke2fs 1.44.3 (10-July-2018)
Discarding device blocks: done                            
Creating filesystem with 510720 4k blocks and 127744 inodes
Filesystem UUID: 5dd70392-74e0-45b3-b56c-d396d847b634
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376, 294912

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done 

```
Узнаем uuid:
```
[root@localhost vagrant]# blkid
/dev/sda1: UUID="d5f5b677-6350-416d-b1d3-47d723d94d88" TYPE="xfs" PARTUUID="615169d8-01"
/dev/loop0: UUID="8e6eceb3-af52-5999-e5b9-ae4216d7c8cf" UUID_SUB="cc1fde17-4712-9c2c-9776-d2b916a4bb02" LABEL="localhost.localdomain:0" TYPE="linux_raid_member"
/dev/loop1: UUID="8e6eceb3-af52-5999-e5b9-ae4216d7c8cf" UUID_SUB="b60fb7c8-9d73-b077-45ab-00183c3a96ff" LABEL="localhost.localdomain:0" TYPE="linux_raid_member"
/dev/loop2: UUID="8e6eceb3-af52-5999-e5b9-ae4216d7c8cf" UUID_SUB="8aecb965-f1a3-92ca-0f35-f5eaae012d09" LABEL="localhost.localdomain:0" TYPE="linux_raid_member"
/dev/loop3: UUID="8e6eceb3-af52-5999-e5b9-ae4216d7c8cf" UUID_SUB="3d0f7470-9de0-dc38-d34f-a2c9b95c5704" LABEL="localhost.localdomain:0" TYPE="linux_raid_member"
/dev/loop4: UUID="8e6eceb3-af52-5999-e5b9-ae4216d7c8cf" UUID_SUB="b72bae89-b0af-c1dc-5650-66700fcebdf9" LABEL="localhost.localdomain:0" TYPE="linux_raid_member"
/dev/md0: PTUUID="66a547c2" PTTYPE="dos"
/dev/md0p1: UUID="5dd70392-74e0-45b3-b56c-d396d847b634" TYPE="ext4" PARTUUID="66a547c2-01"
```
Редактируем файл fstab по образу того, что там есть (man fstab):
```
[root@localhost vagrant]# vi /etc/fstab

# /etc/fstab
# Created by anaconda on Fri Oct 25 18:37:15 2019
#
# Accessible filesystems, by reference, are maintained under '/dev/disk/'.
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info.
#
# After editing this file, run 'systemctl daemon-reload' to update systemd
# units generated from this file.
#
UUID=d5f5b677-6350-416d-b1d3-47d723d94d88 /                       xfs     defaults        0 0
/swapfile none swap defaults 0 0
UUID=5dd70392-74e0-45b3-b56c-d396d847b634   /mnt    ext4    defaults    0   0
```
Выполним монтирование:
```
[root@localhost vagrant]# mount -a
```
Проверим, что все выполнилось корректно:
```
[root@localhost vagrant]# mount
sysfs on /sys type sysfs (rw,nosuid,nodev,noexec,relatime,seclabel)
proc on /proc type proc (rw,nosuid,nodev,noexec,relatime)
devtmpfs on /dev type devtmpfs (rw,nosuid,seclabel,size=230596k,nr_inodes=57649,mode=755)
securityfs on /sys/kernel/security type securityfs (rw,nosuid,nodev,noexec,relatime)
tmpfs on /dev/shm type tmpfs (rw,nosuid,nodev,seclabel)
devpts on /dev/pts type devpts (rw,nosuid,noexec,relatime,seclabel,gid=5,mode=620,ptmxmode=000)
tmpfs on /run type tmpfs (rw,nosuid,nodev,seclabel,mode=755)
tmpfs on /sys/fs/cgroup type tmpfs (ro,nosuid,nodev,noexec,seclabel,mode=755)
cgroup on /sys/fs/cgroup/systemd type cgroup (rw,nosuid,nodev,noexec,relatime,seclabel,xattr,release_agent=/usr/lib/systemd/systemd-cgroups-agent,name=systemd)
pstore on /sys/fs/pstore type pstore (rw,nosuid,nodev,noexec,relatime,seclabel)
bpf on /sys/fs/bpf type bpf (rw,nosuid,nodev,noexec,relatime,mode=700)
cgroup on /sys/fs/cgroup/blkio type cgroup (rw,nosuid,nodev,noexec,relatime,seclabel,blkio)
cgroup on /sys/fs/cgroup/cpu,cpuacct type cgroup (rw,nosuid,nodev,noexec,relatime,seclabel,cpu,cpuacct)
cgroup on /sys/fs/cgroup/rdma type cgroup (rw,nosuid,nodev,noexec,relatime,seclabel,rdma)
cgroup on /sys/fs/cgroup/perf_event type cgroup (rw,nosuid,nodev,noexec,relatime,seclabel,perf_event)
cgroup on /sys/fs/cgroup/net_cls,net_prio type cgroup (rw,nosuid,nodev,noexec,relatime,seclabel,net_cls,net_prio)
cgroup on /sys/fs/cgroup/memory type cgroup (rw,nosuid,nodev,noexec,relatime,seclabel,memory)
cgroup on /sys/fs/cgroup/hugetlb type cgroup (rw,nosuid,nodev,noexec,relatime,seclabel,hugetlb)
cgroup on /sys/fs/cgroup/freezer type cgroup (rw,nosuid,nodev,noexec,relatime,seclabel,freezer)
cgroup on /sys/fs/cgroup/cpuset type cgroup (rw,nosuid,nodev,noexec,relatime,seclabel,cpuset)
cgroup on /sys/fs/cgroup/pids type cgroup (rw,nosuid,nodev,noexec,relatime,seclabel,pids)
cgroup on /sys/fs/cgroup/devices type cgroup (rw,nosuid,nodev,noexec,relatime,seclabel,devices)
configfs on /sys/kernel/config type configfs (rw,relatime)
/dev/sda1 on / type xfs (rw,relatime,seclabel,attr2,inode64,noquota)
selinuxfs on /sys/fs/selinux type selinuxfs (rw,relatime)
systemd-1 on /proc/sys/fs/binfmt_misc type autofs (rw,relatime,fd=32,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=16641)
hugetlbfs on /dev/hugepages type hugetlbfs (rw,relatime,seclabel,pagesize=2M)
debugfs on /sys/kernel/debug type debugfs (rw,relatime,seclabel)
mqueue on /dev/mqueue type mqueue (rw,relatime,seclabel)
sunrpc on /var/lib/nfs/rpc_pipefs type rpc_pipefs (rw,relatime)
tmpfs on /run/user/1000 type tmpfs (rw,nosuid,nodev,relatime,seclabel,size=48884k,mode=700,uid=1000,gid=1000)
/dev/md0p1 on /mnt type ext4 (rw,relatime,seclabel,stripe=256)
```
