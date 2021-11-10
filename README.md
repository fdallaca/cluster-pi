# Cluster Pi K8S tool
Software tooling to create your K8S Pi cluster.

## Requirements

### Software
  
  Images are builded with Docker. For ansible tasks you can easily build environment with provided instruction [here](#Environment)

### Base image

  Download base image from [here](https://ubuntu.com/download/raspberry-pi/thank-you?version=20.04.3&architecture=server-arm64+raspi).
  Create a stage area and put image inside.

### Hardware
  
  Tested on:
  - Raspberry Pi 4B (>2GB ram) _(Good for controlplane masters as for workers nodes)_
  - Raspberry Pi 3B / Pi 4b (<2GB ram) _(Suggested use: worker nodes)_

  Other Pis wasn't tested.

  Use only fast/good sdcards or better ssd usb with uasp controllers, see later in setup how to set usb disk in images (make sense only for RPI4 hw). For booting usb I follow (and automate) this [guide](https://www.instructables.com/Raspberry-Pi-4-USB-Boot-No-SD-Card/). Firmware update of rpi eeprom is not automated (Please check yourself if needed).
  
### Environment
  
  It is necessary some python packages and Ansible collections. From inside repo directory:
  ```
  make
  ```
  And source:
  ```
  source venv/bin/activate
  ```

## Phase1: Images build
- Decide stage area path (eg.: /tmp/clusterpi/stage) (`stage_dir`)
- Put downloaded image inside (absolute image path in `images_in_path`)
- Source python environment
- Launch ansible tasks:
  
  It's better to create a environment variables file (inside `roles/cluster-pi/vars`) like as [samplecluster.yml](roles/role-clusterpi/vars/samplecluster.yml)
  Alternatively you can pass all variables as external variables on commandline (`-e '{ key: value,... }'`) or with a file (`-e @filename`)
  
  For example if you fill vars in `roles/cluster-pi/vars/yourcluster.yml`:
  ```
  (venv) $ ansible-playbook cluster-pi/pi_images.yml -e '{cluster_environment: "yourcluster"}' --tags prepare_images
  ```
  
  Image produce nodes in storage unpartitioned. For usb and custom partitioning support see [here](./roles/role-clusterpi/README.md#Disk-related-variables)

  At this phase are already prepared an ansible inventory at `stage_dir` root (useful to automate future operations on nodes).

Possible tags (in this phase):
- `prepare_files`
  
  Only files preparation in `stage_dir` (prebuild-actions)

- `build_images`
  
  Launch images build

- `inventory`
  
  Compile ansible inventory file in `stage_dir`

## Phase2: Burn images to storage
Images write to SD (or USB):

**BEWARE! CONTROL AND DOUBLE CHECK SDCARD (or USB) DEVICE WITH: ```lsblk``` COMMAND**

```
sudo dd if=/public/clusterpi/3/clusterpi03.img of=/dev/sda bs=4M conv=fsync status=progress
```

## Phase3: Nodes configuration

When all nodes are ready (cloudinit first boot terminated) can procede with nodes full configuration (use ansible inventory generated on phase 1):
```
ansible-playbook cluster-pi/pi_configure.yml -i /public/clusterpi/inventory.yml -e '{cluster_environment: "yourcluster"}' --tags nodes_prereq
```

Possible tags (in this phase):
- `partitioning`
   
  Automatic storage partitioning (must be [enabled]() on build phase) This tag must be explicitly activate because is not included in `nodes_prereq` tag

- `packages`
   
  Common packages install and requirements (some cleaning actions, upgrade system, install docker and default packages) 

- `kubernetes`
  
  Kubernetes specific requirements (kernel parameter and modules, firewall, kubernets package and holds)
  
- `firewall`
  
  Only firewall tasks (if changed restart also docker.service)

Example: 

- only firewall tasks (tag: `firewall`):

```
ansible-playbook cluster-pi/pi_configure.yml -i /public/clusterpi/inventory.yml -e '{cluster_environment: "yourcluster"}' --tags firewall
```

- act only on one node, or (inventory) groups (playbook: `pi_configure_selective.yml` with extravariable `targets`):
```
ansible-playbook cluster-pi/pi_configure_selective.yml -i /public/clusterpi/inventory.yml -e '{cluster_environment: "yourcluster", targets: "clusterpi03"}' --tags firewall
```
```
ansible-playbook cluster-pi/pi_configure_selective.yml -i /public/clusterpi/inventory.yml -e '{cluster_environment: "yourcluster", targets: "workers"}' --tags firewall
```