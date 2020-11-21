Смотрим текущее состояние:
```
[root@localhost vagrant]# lsblk
NAME      MAJ:MIN RM  SIZE RO TYPE   MOUNTPOINT
loop0       7:0    0 1000M  0 loop   
`-md0       9:0    0    2G  0 raid10 
  `-md0p1 259:0    0    2G  0 md     /mnt
loop1       7:1    0 1000M  0 loop   
`-md0       9:0    0    2G  0 raid10 
  `-md0p1 259:0    0    2G  0 md     /mnt
loop2       7:2    0 1000M  0 loop   
`-md0       9:0    0    2G  0 raid10 
  `-md0p1 259:0    0    2G  0 md     /mnt
loop3       7:3    0 1000M  0 loop   
`-md0       9:0    0    2G  0 raid10 
  `-md0p1 259:0    0    2G  0 md     /mnt
loop4       7:4    0 1000M  0 loop   
`-md0       9:0    0    2G  0 raid10 
  `-md0p1 259:0    0    2G  0 md     /mnt
sda         8:0    0   10G  0 disk   
`-sda1      8:1    0   10G  0 part   /
[root@localhost vagrant]# lvmdiskscan
  /dev/md0p1 [      <1.95 GiB] 
  /dev/sda1  [     <10.00 GiB] 
  0 disks
  2 partitions
  0 LVM physical volume whole disks
  0 LVM physical volumes
```
Подготовим среду, насоздаем loop девайсов:
```
[root@localhost vagrant]# dd if=/dev/zero of=loopbackfile0.img bs=3M count=1000
1000+0 records in
1000+0 records out
3145728000 bytes (3.1 GB, 2.9 GiB) copied, 7.06127 s, 445 MB/s
[root@localhost vagrant]# dd if=/dev/zero of=loopbackfile1.img bs=2M count=1000
1000+0 records in
1000+0 records out
2097152000 bytes (2.1 GB, 2.0 GiB) copied, 4.53262 s, 463 MB/s
[root@localhost vagrant]# dd if=/dev/zero of=loopbackfile2.img bs=1M count=1000
1000+0 records in
1000+0 records out
1048576000 bytes (1.0 GB, 1000 MiB) copied, 2.74331 s, 382 MB/s
[root@localhost vagrant]# dd if=/dev/zero of=loopbackfile3.img bs=1M count=1000
dd: error writing 'loopbackfile3.img': No space left on device
966+0 records in
965+0 records out
1011875840 bytes (1.0 GB, 965 MiB) copied, 2.15969 s, 469 MB/s
[root@localhost vagrant]# losetup -fP loopbackfile0.img 
[root@localhost vagrant]# losetup -fP loopbackfile1.img 
[root@localhost vagrant]# losetup -fP loopbackfile2.img 
[root@localhost vagrant]# losetup -fP loopbackfile3.img 
```
Добавляем диски как PV:
```
[root@localhost vagrant]# pvcreate /dev/loop0 
  Physical volume "/dev/loop0" successfully created.
[root@localhost vagrant]# pvdisplay
  "/dev/loop0" is a new physical volume of "<2.93 GiB"
  --- NEW Physical volume ---
  PV Name               /dev/loop0
  VG Name               
  PV Size               <2.93 GiB
  Allocatable           NO
  PE Size               0   
  Total PE              0
  Free PE               0
  Allocated PE          0
  PV UUID               9AkFI5-cP7R-mnmZ-HEd7-Kglo-6b0L-HRXSIN
   
[root@localhost vagrant]# lvmdiskscan
  /dev/loop0 [      <2.93 GiB] LVM physical volume
  /dev/loop1 [       1.95 GiB] 
  /dev/sda1  [     <10.00 GiB] 
  /dev/loop2 [    1000.00 MiB] 
  /dev/loop3 [     965.00 MiB] 
  0 disks
  4 partitions
  0 LVM physical volume whole disks
  1 LVM physical volume
[root@localhost vagrant]# pvs
  PV         VG Fmt  Attr PSize  PFree 
  /dev/loop0    lvm2 ---  <2.93g <2.93g
```

Создаём VG на базе PV:
```
[root@localhost vagrant]# vgcreate mai /dev/loop0 
  Volume group "mai" successfully created
[root@localhost vagrant]# vgdisplay -v mai
  --- Volume group ---
  VG Name               mai
  System ID             
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  1
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                0
  Open LV               0
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <2.93 GiB
  PE Size               4.00 MiB
  Total PE              749
  Alloc PE / Size       0 / 0   
  Free  PE / Size       749 / <2.93 GiB
  VG UUID               f6Ouw2-aQpY-X4TO-yIow-oHLw-tV4U-A2c4qt
   
  --- Physical volumes ---
  PV Name               /dev/loop0     
  PV UUID               9AkFI5-cP7R-mnmZ-HEd7-Kglo-6b0L-HRXSIN
  PV Status             allocatable
  Total PE / Free PE    749 / 749
```

Создаём LV на базе VG:
```
[root@localhost vagrant]# lvcreate -l+100%FREE -n first mai
  Logical volume "first" created.
[root@localhost vagrant]# lvdisplay
  --- Logical volume ---
  LV Path                /dev/mai/first
  LV Name                first
  VG Name                mai
  LV UUID                8gGeEf-wpVc-YU8B-X2KC-67Bl-dPnQ-wrHakM
  LV Write Access        read/write
  LV Creation host, time localhost.localdomain, 2020-11-15 11:10:21 +0000
  LV Status              available
  # open                 0
  LV Size                <2.93 GiB
  Current LE             749
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:0
   
[root@localhost vagrant]# lvs
  LV    VG  Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  first mai -wi-a----- <2.93g 
```

Создаём файловую систему, монтируем её и проверяем:
```
[root@localhost vagrant]# mkfs.ext4 /dev/mai/first
mke2fs 1.44.3 (10-July-2018)
Discarding device blocks: done                            
Creating filesystem with 766976 4k blocks and 192000 inodes
Filesystem UUID: 6dd26693-b29f-4f44-8d85-35947c34451f
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376, 294912

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done 

[root@localhost vagrant]# mount /dev/mai/first /mnt 
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
cgroup on /sys/fs/cgroup/cpu,cpuacct type cgroup (rw,nosuid,nodev,noexec,relatime,seclabel,cpu,cpuacct)
cgroup on /sys/fs/cgroup/devices type cgroup (rw,nosuid,nodev,noexec,relatime,seclabel,devices)
cgroup on /sys/fs/cgroup/hugetlb type cgroup (rw,nosuid,nodev,noexec,relatime,seclabel,hugetlb)
cgroup on /sys/fs/cgroup/memory type cgroup (rw,nosuid,nodev,noexec,relatime,seclabel,memory)
cgroup on /sys/fs/cgroup/net_cls,net_prio type cgroup (rw,nosuid,nodev,noexec,relatime,seclabel,net_cls,net_prio)
cgroup on /sys/fs/cgroup/pids type cgroup (rw,nosuid,nodev,noexec,relatime,seclabel,pids)
cgroup on /sys/fs/cgroup/rdma type cgroup (rw,nosuid,nodev,noexec,relatime,seclabel,rdma)
cgroup on /sys/fs/cgroup/freezer type cgroup (rw,nosuid,nodev,noexec,relatime,seclabel,freezer)
cgroup on /sys/fs/cgroup/blkio type cgroup (rw,nosuid,nodev,noexec,relatime,seclabel,blkio)
cgroup on /sys/fs/cgroup/perf_event type cgroup (rw,nosuid,nodev,noexec,relatime,seclabel,perf_event)
cgroup on /sys/fs/cgroup/cpuset type cgroup (rw,nosuid,nodev,noexec,relatime,seclabel,cpuset)
configfs on /sys/kernel/config type configfs (rw,relatime)
/dev/sda1 on / type xfs (rw,relatime,seclabel,attr2,inode64,noquota)
selinuxfs on /sys/fs/selinux type selinuxfs (rw,relatime)
hugetlbfs on /dev/hugepages type hugetlbfs (rw,relatime,seclabel,pagesize=2M)
systemd-1 on /proc/sys/fs/binfmt_misc type autofs (rw,relatime,fd=41,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=16842)
mqueue on /dev/mqueue type mqueue (rw,relatime,seclabel)
debugfs on /sys/kernel/debug type debugfs (rw,relatime,seclabel)
sunrpc on /var/lib/nfs/rpc_pipefs type rpc_pipefs (rw,relatime)
tmpfs on /run/user/1000 type tmpfs (rw,nosuid,nodev,relatime,seclabel,size=48884k,mode=700,uid=1000,gid=1000)
/dev/mapper/mai-first on /mnt type ext4 (rw,relatime,seclabel)
```

Создаём файл на весь размер точки монтирования:
```
[root@localhost vagrant]# dd if=/dev/zero of=/mnt/test.file bs=1M count=8000 status=progress
2941255680 bytes (2.9 GB, 2.7 GiB) copied, 27 s, 108 MB/s 
dd: error writing '/mnt/test.file': No space left on device
2861+0 records in
2860+0 records out
2999029760 bytes (3.0 GB, 2.8 GiB) copied, 27.5463 s, 109 MB/s
```

Расширяем LV за счёт нового PV в VG:
```
[root@localhost vagrant]# vgextend mai /dev/loop0
  Volume group "mai" successfully extended
[root@localhost vagrant]# lvextend -l+100%FREE /dev/mai/first
  Size of logical volume mai/first changed from 996.00 MiB (249 extents) to <1.95 GiB (498 extents).
  Logical volume mai/first successfully resized.
[root@localhost vagrant]# lvdisplay
  --- Logical volume ---
  LV Path                /dev/mai/first
  LV Name                first
  VG Name                mai
  LV UUID                UXRYyU-nZZD-z90a-01VG-lRzv-n874-K0mJ62
  LV Write Access        read/write
  LV Creation host, time localhost.localdomain, 2020-11-15 10:02:31 +0000
  LV Status              available
  # open                 1
  LV Size                <1.95 GiB
  Current LE             498
  Segments               2
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:0
   
[root@localhost vagrant]# lvs
  LV    VG  Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  first mai -wi-ao---- <1.95g                                                    
[root@localhost vagrant]# df -h
Filesystem             Size  Used Avail Use% Mounted on
devtmpfs               226M     0  226M   0% /dev
tmpfs                  239M     0  239M   0% /dev/shm
tmpfs                  239M  6.4M  233M   3% /run
tmpfs                  239M     0  239M   0% /sys/fs/cgroup
/dev/sda1               10G  7.2G  2.8G  73% /
tmpfs                   48M     0   48M   0% /run/user/1000
/dev/mapper/mai-first  965M  949M     0 100% /mnt
```

Расширяем файловую систему:
```
[root@localhost vagrant]# resize2fs /dev/mai/first
resize2fs 1.44.3 (10-July-2018)
Filesystem at /dev/mai/first is mounted on /mnt; on-line resizing required
old_desc_blocks = 1, new_desc_blocks = 1
The filesystem on /dev/mai/first is now 509952 (4k) blocks long.

[root@localhost vagrant]# df -h
Filesystem             Size  Used Avail Use% Mounted on
devtmpfs               226M     0  226M   0% /dev
tmpfs                  239M     0  239M   0% /dev/shm
tmpfs                  239M  6.4M  233M   3% /run
tmpfs                  239M     0  239M   0% /sys/fs/cgroup
/dev/sda1               10G  7.2G  2.8G  73% /
tmpfs                   48M     0   48M   0% /run/user/1000
/dev/mapper/mai-first  1.9G  949M  892M  52% /mnt
```

Уменьшаем файловую систему и LV:
```
[root@localhost vagrant]# umount /mnt
[root@localhost vagrant]# e2fsck -fy /dev/mai/first
e2fsck 1.44.3 (10-July-2018)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/mai/first: 11/319488 files (0.0% non-contiguous), 41436/1277952 blocks
[root@localhost vagrant]# resize2fs /dev/mai/first 1100M
resize2fs 1.44.3 (10-July-2018)
Resizing the filesystem on /dev/mai/first to 281600 (4k) blocks.
The filesystem on /dev/mai/first is now 281600 (4k) blocks long.

[root@localhost vagrant]# lvreduce /dev/mai/first -L 1100M
  WARNING: Reducing active logical volume to 1.07 GiB.
  THIS MAY DESTROY YOUR DATA (filesystem etc.)
Do you really want to reduce mai/first? [y/n]: y
  Size of logical volume mai/first changed from <4.88 GiB (1248 extents) to 1.07 GiB (275 extents).
  Logical volume mai/first successfully resized.
[root@localhost vagrant]# e2fsck -fy /dev/mai/first
e2fsck 1.44.3 (10-July-2018)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/mai/first: 11/73728 files (0.0% non-contiguous), 24141/281600 blocks
[root@localhost vagrant]# mount /dev/mai/first /mnt
[root@localhost vagrant]# df -h
Filesystem             Size   Used Avail Use% Mounted on
devtmpfs               226M      0  226M   0% /dev
tmpfs                  239M      0  239M   0% /dev/shm
tmpfs                  239M   6.4M  233M   3% /run
tmpfs                  239M      0  239M   0% /sys/fs/cgroup
/dev/sda1               10G   5.3G  4.8G  53% /
tmpfs                   48M      0   48M   0% /run/user/1000
/dev/mapper/mai-first 1018M   949M   13M  93% /mnt
```

Создаём несколько файлов и делаем снимок:
```
[root@localhost vagrant]# touch /mnt/file{1..5}
[root@localhost vagrant]# lvcreate -L 100M -s -n snapsh /dev/mai/first
  Logical volume "snapsh" created.
[root@localhost vagrant]# lvs

  LV     VG  Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  first  mai owi-aos---   1.07g                                                    
  snapsh mai swi-a-s--- 100.00m      first  0.01                                   
[root@localhost vagrant]# lsblk
NAME             MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
loop0              7:0    0    3G  0 loop 
|-mai-first-real 253:1    0  1.1G  0 lvm  
| |-mai-first    253:0    0  1.1G  0 lvm  /mnt
| `-mai-snapsh   253:3    0  1.1G  0 lvm  
`-mai-snapsh-cow 253:2    0  100M  0 lvm  
  `-mai-snapsh   253:3    0  1.1G  0 lvm  
loop1              7:1    0    2G  0 loop 
loop2              7:2    0 1000M  0 loop 
loop3              7:3    0  965M  0 loop 
sda                8:0    0   10G  0 disk 
`-sda1             8:1    0   10G  0 part /
```

Удаляем несколько файлов:
```
[root@localhost vagrant]# rm -f /mnt/file{1..3}
[root@localhost vagrant]# ls /mnt
file4  file5  lost+found
```

Монтируем снимок и проверяем, что файлы там есть:
```
[root@localhost vagrant]# mkdir /snap
[root@localhost vagrant]# mount /dev/mai/snapsh /snap
[root@localhost vagrant]# ls /snap
file1  file2  file3  file4  file5  lost+found
```
Отмонтируем:
```
[root@localhost vagrant]# umount /snap
```
Отмонтируем файловую систему и производим слияние:
```
[root@localhost vagrant]# umount /mnt
[root@localhost vagrant]# lvconvert --merge /dev/mai/snapsh
  Merging of volume mai/snapsh started.
  mai/first: Merged: 100.00%
```
Проверяем, что файлы на месте:
```
[root@localhost vagrant]# mount /dev/mai/first /mnt
[root@localhost vagrant]# ls /mnt
file1  file2  file3  file4  file5  lost+found
```
Добавляем ещё PV, VG и создаём LV-зеркало:
```
[root@localhost vagrant]# pvcreate /dev/loop{2,3}
  Physical volume "/dev/loop2" successfully created.
  Physical volume "/dev/loop3" successfully created.
[root@localhost vagrant]# vgcreate vgmirror /dev/loop{2,3}
  Volume group "vgmirror" successfully created
[root@localhost vagrant]# lvcreate -l+80%FREE -m1 -n mirror1 vgmirror
  Logical volume "mirror1" created.
```
Наблюдаем синхронизацию:
```
[root@localhost vagrant]# lvs
  LV      VG       Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  first   mai      -wi-ao----   1.07g                                                    
  mirror1 vgmirror rwi-a-r--- 784.00m                                    100.00          
[root@localhost vagrant]# lsblk
NAME                        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
loop0                         7:0    0    3G  0 loop 
`-mai-first                 253:0    0  1.1G  0 lvm  /mnt
loop1                         7:1    0    2G  0 loop 
loop2                         7:2    0 1000M  0 loop 
|-vgmirror-mirror1_rmeta_0  253:1    0    4M  0 lvm  
| `-vgmirror-mirror1        253:5    0  784M  0 lvm  
`-vgmirror-mirror1_rimage_0 253:2    0  784M  0 lvm  
  `-vgmirror-mirror1        253:5    0  784M  0 lvm  
loop3                         7:3    0  965M  0 loop 
|-vgmirror-mirror1_rmeta_1  253:3    0    4M  0 lvm  
| `-vgmirror-mirror1        253:5    0  784M  0 lvm  
`-vgmirror-mirror1_rimage_1 253:4    0  784M  0 lvm  
  `-vgmirror-mirror1        253:5    0  784M  0 lvm  
sda                           8:0    0   10G  0 disk 
`-sda1                        8:1    0   10G  0 part /
```