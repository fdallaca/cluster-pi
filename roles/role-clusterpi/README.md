# **role-clusterpi**

Ansible stuff to deploy a set of raspberry Pi as Kubernetes cluster nodes ready.

Two phases:
- Images Building
  - Based on Ansible, Packer (https://github.com/mkaczanowski/packer-builder-arm) (builded on Docker)
  - Tested only with [ubuntu 20.04.3 server aarch64](https://ubuntu.com/download/raspberry-pi/thank-you?version=20.04.3&architecture=server-arm64+raspi)
- Nodes configuration
  - Based on Ansible, Cloudinit (first image boot, customized at build stage)


## Requirements

See [playbook README](../../README.md#Requirements)

## Role Variables

Role has [defaults](defaults/main.yml) for everythings, but some variables must evaluated before:
- `cluster_name`: _string_

  Give name to the cluster and prefixes hostnames of nodes

- `cluster_nodenumber`: _int_

  Number of nodes (master+workers)

- `master_nodenumber`: _int_
  
  Number of master nodes
  
- `cluster_cidr_firstip`: _string_
  
  Mandatory: valid cidr address of first node (numbering of nodes are sequential, please check ip availability in your network)
  
- `cluster_gateway`: _string_
  
  Mandatory: valid gateway address for selected network

- `cluster_adm_user`: _string_
  
  Admin os user name

- `cluster_adm_pwd`: _string_ or _ansible-vault_ encrypted var
  
  Admin user password
  
- `cluster_ssh_auth_keys`: _array_
  
  Array of string. Every item contain your preferred public keys to connect without password to nodes
  
- `images_in_path`: _string_
  
  Absolute path to downloaded base image

- `k8s_version`: _string_
  
  (optional) Mark a particular k8s (kubeadm,kubelet and kubectl) software version to install (eg.: `k8s_version: "1.22.3-00"`)

Example:
---

```
cluster_name: "clusterpi"
cluster_cidr_firstip: 192.168.1.20/24
cluster_nodenumber: 4
master_nodenumber: 1
```
Produces: 
- clusterpi01
  master
  192.168.1.20
- clusterpi02
  worker
  192.168.1.21
- clusterpi03
  worker
  192.168.1.22
- clusterpi04
  worker
  192.168.1.23


### Disk related variables

Following parameter enable usb_storage pi4 support
- `usb_storage`: _bool_
  
  If true enable usb storage (default: `false`) to use in conjunction with `sd_device` setted as `/dev/sda`

- `sd_device`: _string_
  
  Raspberry name of device (default: `/dev/mmcblk0` used for sdcards). Usb first device is `/dev/sda`

To activate usb storage support (put these variables on varfiles):
```
usb_storage: true
sd_device: "/dev/sda"
```

As default is used growpart and resizefs cloudinit module. If you want to do custom partition or using tag `partitioning` (on node configuration phase) and set also `partitioning: true`:

- `partitioning`: _bool_
   
   Custom partioning (manual or automatic with tag `partitioning`). (default: `false`)

Partition (using ansible task with `partitioning` tag) is thinked in a tre-scheme partitions of pi sdcard (or usb):
1. boot partition (derived from ubuntu stock)
2. root partition (derived from ubuntu stock)
3. pv partition

Feel free to skip for manual partitioning if interested in other schemes

- `etcd_size_gib`: _int_
  
  GiB reserved to etcd xfs filesystem on master nodes (default: `10`)

- `pv_size_gib`: _int_
  
  GiB reserved to a partition for phisical volumes on workers nodes (not formatted by tasks) (default: `16`)

Dependencies
===

python packages:
- ansible-core
- docker
- netaddr
- jmespath

collections:
  - community.docker
  - ansible.netcommon
  - community.general
  - ansible.posix


License
-------

Apache License 2.0

Author Information
------------------

f.dallaca@gmail.com
