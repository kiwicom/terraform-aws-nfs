#cloud-config
ssh_authorized_keys:
 - ssh-rsa //////////////////////// DUMMY_SSH_KEY

package_update: true
package_upgrade: true

packages:
 - unattended-upgrades
 - nfs-kernel-server
 - python-pip
 - awscli
 - zfsutils-linux


# i3 NVMe local SSD used for ZFS cache
disk_setup:
  devnvme0n1:
    table_type: 'gpt'
    layout:
      - 100  # L2ARC (read cache)
    overwrite: True


# Automatic security upgrades
write_files:
- path: etc/apt/apt.conf.d/10periodic
  content: |
    APT::Periodic::Update-Package-Lists "1";
    APT::Periodic::Download-Upgradeable-Packages "1";
    APT::Periodic::AutocleanInterval "7";
    APT::Periodic::Unattended-Upgrade "1";

- path: /usr/local/bin/ddns_route53
  permissions: "0777"
  encoding: "gzip+base64"
  content: |
    ${bin_ddns_route53}

- path: /usr/local/bin/attach_volume
  permissions: "0777"
  encoding: "gzip+base64"
  content: |
    ${bin_attach_volume}

- path: /usr/local/bin/ebs_snapshot
  permissions: "0777"
  encoding: "gzip+base64"
  content: |
    ${bin_ebs_snapshot}

- owner: root:root
  path: /etc/cron.d/ebs-snapshot
  encoding: "gzip+base64"
  content: |
    ${cron_ebs_snapshot}

output:
  all: '| tee -a /var/log/cloud-init-output.log'

runcmd:
 # -e: Exit as soon as any line fails
 # -x: Print each command that is going to be executed
 - set -ex
 # Setup internal DNS record
 - ddns_route53 --zone-id DUMMY_ZONE_ID --record-set DUMMY_RECORD_SET --ttl 30 -i $(hostname -i)
 # Set root SSH keys
 - mkdir -p /root/.ssh/
 - cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/authorized_keys
 - chown root:root -R /root/.ssh/
 - chmod 0700 -R /root/.ssh
 # Network optimizations
 - echo 262144 > /proc/sys/net/core/rmem_default
 - echo 262144 > /proc/sys/net/core/rmem_max
 - echo 262144 > /proc/sys/net/core/wmem_default
 - echo 262144 > /proc/sys/net/core/wmem_max
 # Find and attach the volumes
 - pip install boto3
 - attach_volume --value platform-nfs-data1 --attach_as /dev/xvdh --wait
 - attach_volume --value platform-nfs-data2 --attach_as /dev/xvdi --wait
 # Set up ZFS (and NFS)
 - zpool import -a
 - zfs mount -a
