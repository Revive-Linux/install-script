#!/bin/bash

set -e

echo "Available drives:"
lsblk -d -o NAME,SIZE,MODEL

read -rp "Enter the drive to install the OS to (e.g., /dev/sdX): " DRIVE

if [[ ! -b "$DRIVE" ]]; then
  echo "Error: $DRIVE is not a valid block device."
  exit 1
fi

read -rp "Are you sure you want to install the OS to $DRIVE? This will erase all data on it! (yes/no): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
  echo "Aborted."
  exit 1
fi

echo "Starting in 5 seconds... Press Ctrl+C to cancel."
for i in {5..1}; do
  echo "$i..."
  sleep 1
done

echo "Wiping $DRIVE..."
wipefs -a "$DRIVE"
sgdisk --zap-all "$DRIVE"

echo "Creating new partition..."
parted -s "$DRIVE" mklabel mbr
parted -s "$DRIVE" mkpart primary ext4 0% 100%

PARTITION="${DRIVE}1"
echo "Waiting for $PARTITION to be available..."
sleep 2

echo "Formatting $PARTITION to ext4..."
mkfs.ext4 "$PARTITION"

echo "Mounting $PARTITION to /mnt..."
mount "$PARTITION" /mnt

echo "Downloading OS tarball to /mnt..."
wget -O /mnt/os.tar.gz "http://example.com/path/to/your/os.tar.gz"

echo "Extracting tarball..."
tar -xzf /mnt/os.tar.gz -C /mnt

echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "Installing Grub"
arch-chroot grub-install --target=i386-pc "$PARTITION"
arch-chroot grub-mkconfig -o /boot/grub/grub.cfg

echo "Finishing Up..."
umount -a

echo "Installation complete. You may now reboot."
