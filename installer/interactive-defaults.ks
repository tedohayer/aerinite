# Aerinite installer defaults. The Aerinite image is embedded in the ISO
# (image-builder --bootc-installer-payload-ref), so installs work offline.
bootc --source-imgref containers-storage:ghcr.io/tedohayer/aerinite:latest --target-imgref ghcr.io/tedohayer/aerinite:latest

# Fedora's default btrfs layout adds a separate "home" subvolume mounted over
# /home. On bootc, /home is /var/home (already persistent), and Anaconda
# creates users' home directories there, so the empty subvolume hid them.
autopart --type=btrfs --nohome

# --target-imgref records the image as ostree-unverified-registry. Make the
# installed system verify updates against the key it ships
# (/etc/pki/containers/aerinite.pub) by switching the deployment's origin to
# the signed form. This is the same edit "bootc switch --mutate-in-place"
# makes; bootc itself fails here ("Switching: No such file or directory"),
# so edit the origin file on the target directly.
%post --nochroot --erroronfail
set -euo pipefail
origins=$(ls /mnt/sysimage/ostree/deploy/*/deploy/*.origin)
sed -i 's|^container-image-reference=.*|container-image-reference=ostree-image-signed:docker://ghcr.io/tedohayer/aerinite:latest|' $origins
grep -H '^container-image-reference=' $origins

# Anaconda puts the root's btrfs compression (compress=zstd:1) on the fstab
# "/" line, which composefs systems ignore: the root is mounted from rootflags=
# alone, and btrfs takes compression from that first mount, so it stays off
# everywhere (Fedora bug 2332319). Carry it over to rootflags= in the boot
# entries, where ostree keeps the kernel arguments. Does nothing if rootflags=
# already has compress= or the root isn't btrfs.
compress=$(awk '$2 == "/" && $3 == "btrfs" {
    n = split($4, o, ","); for (i = 1; i <= n; i++) if (o[i] ~ /^compress(-force)?=/) { print o[i]; exit }
}' /mnt/sysimage/ostree/deploy/*/deploy/*/etc/fstab)
for entry in /mnt/sysimage/boot/loader/entries/*.conf; do
    if [ -n "$compress" ] && grep -Eq '^options (.* )?rootflags=' "$entry" \
        && ! grep -Eq '^options (.* )?rootflags=[^ ]*compress' "$entry"; then
        sed -i --follow-symlinks -E "/^options /s/ (rootflags=[^ ]*)/ \1,${compress}/" "$entry"
    fi
    grep -H '^options ' "$entry"
done

# Anaconda also writes a "/" line to fstab. On bootc the root is mounted from
# the kernel command line (root=, rootflags=), and systemd-remount-fs fails
# trying to remount it from fstab, so drop that line.
for fstab in /mnt/sysimage/ostree/deploy/*/deploy/*/etc/fstab; do
    sed -i -E '/^[^#[:space:]]+[[:space:]]+\/[[:space:]]/d' "$fstab"
    cat "$fstab"
done
%end
