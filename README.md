# Kubebox

A quick experiment to get some kubevirt managed qemu VMs running, as part of prototyping the "metabox" testing framework for integration testing checkbox.

## Running instructions with multipass

```bash
./cluster-cloudconfig.py | multipass launch 22.04 -c 4 -d 50G -m 32G -n kubebox -vvvv --cloud-init -
multipass mount . kubebox:/kubebox
multipass shell kubebox
cd /kubebox
./kubevirt.sh
```
