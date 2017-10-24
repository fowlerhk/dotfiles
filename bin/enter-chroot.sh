#!/bin/bash

mount -v --bind /dev $1/dev
mount -vt devpts devpts $1/dev/pts -o gid=5,mode=620
mount -vt proc proc $1/proc
mount -vt sysfs sysfs $1/sys
mount -vt tmpfs tmpfs $1/run

chroot "$1" /usr/bin/env -i \
       HOME=/root TERM="$TERM" PS1='\u:\w\$ ' \
       PATH=/bin:/usr/bin:/sbin:/usr/sbin \
       /bin/bash --login +h

umount $1/run
umount $1/sys
umount $1/proc
umount $1/dev/pts
umount $1/dev
