# SR-IOV config

SR-IOV config has the following format:
```yaml
physicalFunctions:
  0000:01:00.0:               # 1. PCI address of SR-IOV capable NIC that we want to use with Forwarder
    pfKernelDriver: pf-driver # 2. PF kernel driver
    vfKernelDriver: vf-driver # 3. VF kernel driver
    capabilities:             # 4. List of capabilities
      - intel
      - 10G
    serviceDomains:           # 5. List of service domains
      - service.domain.1
  0000:02:00.0:
    ...
```

## 1. PCI address

Here should be all devices you want to be used with this config. If you know only interface name and don't know
PCI address of the device, you can get it with the following command:

```bash
ls -l /sys/class/net/${if_name}/device
```

Example:
```
$ ls -l /sys/class/net/eno1/device
lrwxrwxrwx 1 root root 0 Aug 23 17:38 /sys/class/net/eno1/device -> ../../../0000:03:00.0
```
PCI address is `0000:03:00.0`.

## 2. PF kernel driver

It should be a driver selected when device acts as a kernel interface (it has an entry in `/sys/class/net`), you can get
it with the following command:

```bash
ls -l /sys/class/net/${if_name}/device/driver
```

### Example
```
$ ls -l /sys/class/net/eno1/device/driver
lrwxrwxrwx 1 root root 0 Aug 23 17:39 /sys/class/net/eno1/device/driver -> ../../../../bus/pci/drivers/i40e
```
PF kernel driver is `i40e`.

### Note
This command doesn't work if device doesn't act as a kernel interface with the currently selected driver.\
In such case you need to manually get driver name from the device info.

## 3. VF kernel driver

It should be a driver selected when device VF acts as a kernel interface. If there is no VFs enabled currently, you can
get it with the following commands:
```bash
echo 1 > /sys/class/net/${if_name}/device/sriov_numvfs # enable VFs
ls -l /sys/class/net/${if_name}/device/virtfn0/driver
echo 0 > /sys/class/net/${if_name}/device/sriov_numvfs # disable VFs
```

### Example
```
$ echo 1 > /sys/class/net/eno1/device/sriov_numvfs
$ ls -l /sys/class/net/eno1/device/virtfn0/driver
lrwxrwxrwx 1 root root 0 Aug 23 17:40 /sys/class/net/eno1/device/virtfn0/driver -> ../../../../bus/pci/drivers/iavf
$ echo 0 > /sys/class/net/eno1/device/sriov_numvfs
```
PF kernel driver is `iavf`.

### Note
This command doesn't work if device VF doesn't act as a kernel interface with the default (or currently selected)
driver.\
In such case you need to manually get driver name from the device info.

## 4. Capabilities

There should be device capabilities. Common capabilities are:
1. Device manufacturer (e.g. `intel`, `mellanox`).
2. Device bandwidth (e.g. `1M`, `10G`).

You can add here any other capability that should be used for the device selection.

## 5. Service domains

Service domain is a group of network services accessible from a single L2/L3 connection. Since we are not expecting
every device to be connected to each service domain, the list of the accessible domains should be manually set for each
configured device.
