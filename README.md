# 💻 Linux System Administration Scripts

Welcome to the **Linux System Administration Scripts** repository! This repository offers a collection of Bash scripts engineered to automate Linux setup, infrastructure, storage management, container runtime provisioning, monitoring, and routine maintenance across **Debian/Ubuntu** and **RHEL/Rocky/AlmaLinux/Fedora** environments.


## 💡 Key Features

- Each script utilizes `set -euo pipefail` to ensure immediate termination on errors, unhandled unbound variables, or failing pipeline stages.
- Integrated privilege checks (`EUID -ne 0`) prevent partial or unauthorized execution state mutations.
- Dynamically parses `/etc/os-release` to resolve package management dependencies across APT and DNF systems.


## 📚 Directory & Script Index

All utility scripts are organized within the `scripts/` directory following a numerical deployment order:

```text
scripts/
scripts/
├── 01-configure-hostname.sh
├── 02-create-lvm.sh
├── 03-configure-users.sh
├── 04-configure-chrony.sh
├── 05-configure-sysctl.sh
├── 06-configure-firewall.sh
├── 07-configure-kernel.sh
├── 08-install-docker.sh
├── 09-configure-docker.sh
├── 10-configure-docker-registry.sh
├── 11-install-ansible.sh
├── 12-configure-ansible.sh
├── 13-install-zabbix-agent.sh
├── 14-configure-zabbix-agent.sh
├── 15-monitor-system.sh
├── 16-check-connectivity.sh
├── 17-check-docker.sh
├── 18-check-server.sh
├── 19-backup-system.sh
├── 20-backup-file.sh
├── 21-extract-backup.sh
├── 22-clean-system.sh
├── 23-install-linstor-controller.sh
├── 24-install-linstor-satellite.sh
├── 25-configure-linstor-lvm.sh
├── 26-configure-linstor-cluster.sh
└── 27-configure-linstor-docker.sh
```


## 📝 Module Overview

### 1. Base Configuration

| Script                                                         | Purpose & Description                                                                                     |
| :------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------- |
| [`01-configure-hostname.sh`](scripts/01-configure-hostname.sh) | Sets system hostname via `hostnamectl` and updates `/etc/hosts` mappings.                                 |
| [`03-configure-users.sh`](scripts/03-configure-users.sh)       | Provisions administrative system users, configures `sudoers` privileges, and initializes SSH directories. |
| [`04-configure-chrony.sh`](scripts/04-configure-chrony.sh)     | Installs and configures Chrony NTP client for accurate server time synchronization.                       |
| [`05-configure-sysctl.sh`](scripts/05-configure-sysctl.sh)     | Applies kernel network parameters (IP forwarding, SYN cookies, anti-spoofing) via `/etc/sysctl.d/`.       |
| [`06-configure-firewall.sh`](scripts/06-configure-firewall.sh) | Initializes `nftables` framework, sets drop policies, and provisions modular firewall rule templates.     |
| [`07-configure-kernel.sh`](scripts/07-configure-kernel.sh)     | Holds generic kernel packages via `apt-mark` to prevent unintended kernel upgrades during system updates. |

### 2. Storage & Filesystem Management

| Script                                                     | Purpose & Description                                                                                                                                  |
| :--------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`02-create-lvm.sh`](scripts/02-create-lvm.sh)             | Partitions raw disks (GPT), creates LVM Physical Volumes, Volume Groups, Logical Volumes, formats XFS, and persists `/etc/fstab` mounts.               |
| [`09-configure-docker.sh`](scripts/09-configure-docker.sh) | Migrates Docker root data path from `/var/lib/docker` to `/data/docker` using `rsync`, applies security daemon settings, and configures SELinux rules. |

### 3. Container Runtime & Infrastructure Automation

| Script                                                                       | Purpose & Description                                                                                                                    |
| :--------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------- |
| [`08-install-docker.sh`](scripts/08-install-docker.sh)                       | Installs Docker Engine, CLI, Containerd, and Compose plugins from upstream repositories across Debian/RHEL distros.                      |
| [`10-configure-docker-registry.sh`](scripts/10-configure-docker-registry.sh) | Deploys a private local Docker Registry container protected by `htpasswd` basic authentication, Docker networks, and persistent volumes. |
| [`11-install-ansible.sh`](scripts/11-install-ansible.sh)                     | Configures official repositories (EPEL / Ansible PPA) and installs Ansible automation engine.                                            |
| [`12-configure-ansible.sh`](scripts/12-configure-ansible.sh)                 | Generates Ed25519 SSH keypairs for service accounts and deploys public keys to remote target hosts via `ssh-copy-id`.                    |

### 4. Monitoring

| Script                                                                 | Purpose & Description                                                                                                              |
| :--------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------- |
| [`13-install-zabbix-agent.sh`](scripts/13-install-zabbix-agent.sh)     | Configures official Zabbix repos (handling EPEL exclusions on RHEL) and installs Zabbix Agent 2.                                   |
| [`14-configure-zabbix-agent.sh`](scripts/14-configure-zabbix-agent.sh) | Updates `zabbix_agent2.conf` parameters (Server, ServerActive, Hostname), creates configuration backups, and restarts the service. |

### 5. System Diagnostics & Inspection

| Script                                                         | Purpose & Description                                                                                                                        |
| :------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------- |
| [`15-monitor-system.sh`](scripts/15-monitor-system.sh)         | Generates a performance report containing CPU load, memory breakdown, top CPU processes, block device mappings, and directory sizes.         |
| [`16-check-connectivity.sh`](scripts/16-check-connectivity.sh) | Normalizes user URL inputs and executes non-blocking HTTP/HTTPS HEAD requests via `curl` to evaluate reachability.                           |
| [`17-check-docker.sh`](scripts/17-check-docker.sh)             | Inspects local Docker runtime environment, systemd status, root storage path, container counts, and daemon JSON configuration.               |
| [`18-check-server.sh`](scripts/18-check-server.sh)             | Audits key operating system parameters: system hostname, IPv4 interface bindings, DNS resolv configurations, NTP state, and storage metrics. |

### 6. System Backup & Maintenance

| Script                                               | Purpose & Description                                                                                                                     |
| :--------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------- |
| [`19-backup-system.sh`](scripts/19-backup-system.sh) | Backs up crucial configuration files (`/etc/fstab`, SSH, network, Docker, firewall rules) into a compressed, timestamped tarball archive. |
| [`20-backup-file.sh`](scripts/20-backup-file.sh)     | Takes a target file or folder input path and compresses it into a target backup directory path.                                           |
| [`21-extract-backup.sh`](scripts/21-extract-backup.sh)     | Takes a target backup path and extracts it into a target directory path.                                           |
| [`22-clean-system.sh`](scripts/22-clean-system.sh)   | Cleans package manager caches (APT/DNF), vacuums systemd logs older than 7 days, and purges stale `/tmp` items (supports `--dry-run`).    |

### 7. LINSTOR Cluster (Replicated Storage)

**LINSTOR** and **DRBD** are open-source and software-defined storage **(SDS)** solutions that deliver a high available and replicated block storage across distributed Linux cluster environments.

| Script                                                                                   | Purpose & Description                                                                                                                                                                                       |
| :--------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`23-install-linstor-controller.sh`](scripts/23-install-linstor-controller.sh)           | Adds the LINBIT DRBD9 PPA and installs DRBD, `linstor-controller`, `linstor-satellite` and `linstor-client`, then enables and verifies the services. Run on the controller host only.                       |
| [`24-install-linstor-satellite.sh`](scripts/24-install-linstor-satellite.sh)             | Adds the LINBIT DRBD9 PPA and installs DRBD and `linstor-satellite`, then enables and verifies the service. Run on every satellite (storage) host.                                                         |
| [`25-configure-linstor-lvm.sh`](scripts/25-configure-linstor-lvm.sh)                     | Checks that the target disk exists and is not mounted, then creates the `linstor_vg` volume group on it. Aborts if the group already exists. Run on every host that stores data.                           |
| [`26-configure-linstor-cluster.sh`](scripts/26-configure-linstor-cluster.sh)             | Checks connectivity to all nodes, registers the controller (combined) and satellites, and creates an LVM storage pool on each node. Skips nodes and pools that already exist. Run on the controller only. |
| [`27-configure-linstor-docker.sh`](scripts/27-configure-linstor-docker.sh)               | Verifies the required packages, writes `/etc/linstor/docker-volume.conf` (storage pool, filesystem, size, replica count, controller address) and installs the LINBIT Docker volume plugin.                  |


## 🚩 Getting Started

### 1. Repository Setup

```bash
# Clone repository
git clone https://github.com/OpsAmine/linux-bash-scripts.git
cd linux-bash-scripts/scripts

# Make scripts executable
chmod +x *.sh
```

### 2. Execution Workflow Example

#### Installing Docker Engine & Relocating Data Directory

```bash
# Install Docker Engine
sudo ./08-install-docker.sh

# Relocate Docker Data Root to /data/docker
sudo ./09-configure-docker.sh
```

#### Running Maintenance & System Diagnostics

```bash
# Evaluate overall server performance
sudo ./15-monitor-system.sh

# Run system maintenance in Dry-Run mode
sudo ./22-clean-system.sh --dry-run
```

---

> [!WARNING]
> Always inspect variables (such as target paths, IP ranges, ports, and default usernames) prior to running on production systems. Always test configurations in staging environments before applying for production-destined environments.
