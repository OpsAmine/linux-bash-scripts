# handy-bash-scripts

Simple Bash scripts to automate common Linux sysadmin tasks. Each script is self-contained, has a documented header, checks its prerequisites before doing anything, and stops on the first error.

## Scripts

| Script | Description |
|--------|-------------|
| [`./scripts/mkdata.sh`](mkdata.sh) | Prepares a dedicated data disk: GPT partition, LVM (PV/VG/LV), XFS filesystem, and a persistent mount on `/data`. |
| [`./scripts/docker.sh`](docker.sh) | Installs Docker Engine from Docker's official repositories, detecting the distro family (Debian/Ubuntu or RHEL/Rocky/Fedora). |
| [`./scripts/mvdocker.sh`](mvdocker.sh) | Moves Docker's data directory from `/var/lib/docker` to `/data/docker` and applies a hardened `daemon.json`. |
| [`./scripts/chrony.sh`](chrony.sh) | Installs and configure chrony, detecting the distro family (Debian/Ubuntu or RHEL/Rocky/CentOS). |

## Quick start

```bash
git clone https://github.com/boursam/linux-bash-scripts.git
cd handy-bash-scripts
cd scripts/
chmod +x *.sh
sudo ./docker.sh
```

> [!WARNING]
> - Review the variables and content of each script and test on a non-production machine first.
