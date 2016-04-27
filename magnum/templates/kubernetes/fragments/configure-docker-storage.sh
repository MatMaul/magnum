#!/bin/sh

. /etc/sysconfig/heat-params

attempts=60
while [ ${attempts} -gt 0 ]; do
    device_name=$(ls /dev/disk/by-id | grep ${DOCKER_VOLUME:0:20}$)
    if [ -n "${device_name}" ]; then
        break
    fi
    echo "waiting for disk device"
    sleep 0.5
    udevadm trigger
    let attempts--
done

if [ -z "${device_name}" ]; then
    echo "ERROR: disk device does not exist" >&2
    exit 1
fi

device_path=/dev/disk/by-id/${device_name}

# docker-storage-setup script call docker version, which stalls if the docker daemon is in some kind of weird state
# Stop docker daemon and the current execution of the script before relaunching it
systemctl stop docker docker-storage-setup

rm -rf /var/lib/docker/*

MOUNT_POINT=/mnt/docker-data
mkfs.xfs ${device_path}
mkdir $MOUNT_POINT
echo "${device_path} $MOUNT_POINT xfs defaults 0 0" >> /etc/fstab
mount -a

echo "STORAGE_DRIVER=overlay" > /etc/sysconfig/docker-storage-setup

# selinux is not compatible with overlay driver
# specify the new mounted folder here, if done in docker-storage
# it will be overriden by the next execution of docker-storage-setup
OPTIONS="${OPTIONS/--selinux-enabled/} -g $MOUNT_POINT"
sed -i "/^OPTIONS=/ s#=.*#='$OPTIONS'#" /etc/sysconfig/docker

/usr/bin/docker-storage-setup
