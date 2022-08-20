On host system:

```bash
./cluster-cloudconfig.py | multipass launch 22.04 -c 4 -d 50G -m 32G -n kubebox -vvvv --cloud-init -
multipass mount . kubebox:/kubebox
```

```bash
multipass shell kubebox
cd /kubebox
./kubevirt.sh
```
