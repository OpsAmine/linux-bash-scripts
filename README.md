# handy-bash-scripts

Simple Bash scripts to automate common Linux sysadmin tasks. Each script is self-contained, has a documented header, checks its prerequisites before doing anything, and stops on the first error.

## Scripts

| Script | Description |
|--------|-------------|
| [`mkdata.sh`](mkdata.sh) | Prepares a dedicated data disk: GPT partition, LVM (PV/VG/LV), XFS filesystem, and a persistent mount on `/data`. |
| [`docker.sh`](docker.sh) | Installs Docker Engine from Docker's official repositories, detecting the distro family (Debian/Ubuntu or RHEL/Rocky/Fedora). |
| [`mvdocker.sh`](mvdocker.sh) | Moves Docker's data directory from `/var/lib/docker` to `/data/docker` and applies a hardened `daemon.json`. |

## Quick start

```bash
git clone https://github.com/<your-username>/linux-bash-scripts.git
cd handy-bash-scripts
cd scripts/
chmod +x *.sh
sudo ./docker.sh
```

Read the header at the top of each script for its options, requirements and exit codes before running it.

> [!WARNING]
> - Review the variables and content of each script and test on a non-production machine first.

## Contributing

Issues and pull requests are welcome. When adding a script, please:

- Start it with a header comment (name, description, usage, requirements, exit codes)
- Use `set -euo pipefail`
- Check for root and for required commands before changing anything
- Add it to the table in this README
