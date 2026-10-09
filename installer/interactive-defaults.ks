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

# Anaconda also writes a "/" line to fstab. On bootc the root is mounted from
# the kernel command line (root=, rootflags=), and systemd-remount-fs fails
# trying to remount it from fstab, so drop that line.
for fstab in /mnt/sysimage/ostree/deploy/*/deploy/*/etc/fstab; do
    sed -i -E '/^[^#[:space:]]+[[:space:]]+\/[[:space:]]/d' "$fstab"
    cat "$fstab"
done
%end
