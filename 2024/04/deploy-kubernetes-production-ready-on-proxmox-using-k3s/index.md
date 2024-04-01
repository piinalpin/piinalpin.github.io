# Deploy Kubernetes Production Ready on Proxmox using K3S


![Kubernetes Cluster in Proxmox](/images/kubernetes-cluster.png)

The documentation is describing the steps required to setup kubernetes cluster using K3S and learning automation provisioning using `Terraform` and `Ansible` on Proxmox VE. Before we setup kubernetes cluster, we need some prerequisities below.

- [Proxmox VE](https://www.proxmox.com/en/proxmox-virtual-environment/get-started)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- [Terraform](https://developer.hashicorp.com/terraform/install)

**Disclaimer :** I use WiFi network for my homelab server, you can check this documentation [Setup Proxmox With Wireless Interface - My Homelab](https://piinalpin.com/2024/03/setup-proxmox-with-wireless-interface/).

### Setup Cloud Init Template
This step is describe how to create cloud init template for provide provisioning virtual machine template on proxmox. If you already have VM on proxmox server you can skip.

First, we need to remote on proxmox server using SSH or direct access into proxmox server. And we need to download operating system, I will use Ubuntu server 22.04 as cloud init template. Download the Ubuntu cloud init.
```bash
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
```

Then, we need customize the iso images to enable `qemu agent`. Install `libguestfs-tools` if you don't have it.
```bash
apt install libguestfs-tools
virt-customize -a jammy-server-cloudimg-amd64.img --install qemu-guest-agent,net-tools --truncate /etc/machine-id
```

Create VM follow this command.
```bash
qm create 8000 --name ubuntu-cloud-init --core 2 --memory 2048 --net0 virtio,bridge=vmbr0
```

It will create VM template with VM ID is `8000` and set default processor core is `2`, memory `2GB` and use VM bridge `vmbr0`as network interface.

Then, import disk into cloud init VM. This step is like we have storage but the SATA cable is not connected.
```bash
qm disk import 8000 jammy-server-cloudimg-amd64.img local-lvm
```
 
So, we need to attach disk into VM and setup boot order
```bash
qm set 8000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-8000-disk-0
qm set 8000 --boot c --bootdisk scsi0
```

Then activate qemu agent also set the serial socket vga for console and hotplug.
```bash
qm set 8000 --agent 1
qm set 8000 --serial0 socket
qm set 8000 --vga serial0
qm set 8000 --hotplug network,usb,disk
```

Convert cloud init VM into template
```bash
qm template 8000
```

Create API Token that will be used for `Terraform`. Go to `Data Center` -> `Permissions` -> `API Tokens` then add new API token. **Note :** *Uncheck the `Privilege Separation`* and don't forget to take a note the Token ID and Secret.

### Setup Terraform

Create file `variables.tf` to describe all variable and datatype that used when executing automation script.
```tf
variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
  sensitive = true
}

variable "proxmox_api_token_secret" {
  type = string
  sensitive = true
}

variable "ci_ssh_public_key" {
  type = string
  sensitive = true
}

variable "ci_ssh_private_key" {
  type = string
  sensitive = true
}

variable "ci_user" {
  type = string
  sensitive = true
}

variable "ci_password" {
  type = string
  sensitive = true
}

variable "ci_k8s_master_count" {
  type = number
}

variable "ci_k8s_node_count" {
  type = number
}

variable "ci_k8s_base_master_ip" {
  type = string
}

variable "ci_k8s_base_node_ip" {
  type = string
}

variable "ci_ip_gateway" {
  type = string
}

variable "ci_network_cidr" {
  type = number
}

variable "ci_start_vmid" {
  type = number
}
```

Create `credentials.auto.tfvars`, this file will assign value for each variable.
```tfvars
# Proxmox API
proxmox_api_url             = "https://192.168.56.1:8006/api2/json"
proxmox_api_token_id        = "terraform-prov@pve!terraform"
proxmox_api_token_secret    = "f6d89c4b-693c-47d6-b121-2932e747c75c"

# Cloud init configuration
ci_ssh_public_key       = "../.ssh/homelab.pub"
ci_ssh_private_key      = "../.ssh/homelab"
ci_user                 = "k8s"
ci_password             = "secret"
ci_k8s_master_count     = 1
ci_k8s_node_count       = 2
ci_k8s_base_master_ip   = "192.168.56.1" # Will generate 192.168.56.1X
ci_k8s_base_node_ip     = "192.168.56.2" # Will generate 192.168.56.2X
ci_ip_gateway           = "192.168.56.1"
ci_network_cidr         = 24
ci_start_vmid           = 100
```
**Note :** Please adjust the `ci_ssh_public_key` and `ci_ssh_private_key` to your own SSH keys.

Create `provider.tf` to define what is the provider will be used. I will use `telmate/proxmox 3.0.1-rc1` because my proxmox version is `Proxmox 8.x`.
```tf
terraform {
  required_version = ">= 1.7.4"

  required_providers {
    proxmox = {
        source = "telmate/proxmox"
        version = "3.0.1-rc1"
    }
  }
}

provider "proxmox" {
  pm_api_url = var.proxmox_api_url
  pm_api_token_id = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret

  pm_tls_insecure = true

  pm_log_enable = true
  pm_log_file   = "terraform-plugin-proxmox.log"
  pm_debug      = true
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }

}
```

Then create file `srv-k8s-cluster.tf` to execute automation provisioning creating VM for kubernetes cluster. This script actually execute this flow.
- Clone `ubuntu-cloud-init` template
- Override cores count, memory and boot disk
- Setup network and nameserver
- Setup SSH key

Based on `credentials.auto.tfvars` this script will create 1 master node and 2 worker nodes.

```tf
resource "proxmox_vm_qemu" "srv-k8s-master" {
  count = var.ci_k8s_master_count
  name = "k8s-master"
  desc = "Kubernetes Master Nodes"
  vmid = var.ci_start_vmid + count.index
  target_node = "pve"

  clone = "ubuntu-cloud-init"

  agent = 1
  cores = 2
  sockets = 1
  cpu = "host"
  memory = 4096

  bootdisk = "scsi0"
  scsihw = "virtio-scsi-pci"
  cloudinit_cdrom_storage = "local-lvm"
  onboot = true

  os_type = "cloud-init"
  ipconfig0 = "ip=${var.ci_k8s_base_master_ip}${count.index}/${var.ci_network_cidr},gw=${var.ci_ip_gateway}"
  nameserver = "8.8.8.8 8.8.4.4 192.168.56.1"
  searchdomain = "piinalpin.lab"
  ciuser = var.ci_user
  cipassword = var.ci_password
  sshkeys = <<EOF
  ${file(var.ci_ssh_public_key)}
  EOF

  network {
    bridge = "vmbr0"
    model = "virtio"
  }

  disks {
    scsi {
      scsi0 {
        disk {
          size = 20
          storage = "local-lvm"
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      network
    ]
  }
}

resource "proxmox_vm_qemu" "srv-k8s-nodes" {
  count = var.ci_k8s_node_count
  name = "k8s-node-${count.index + 1}"
  desc = "Kubernetes Node ${count.index + 1}"
  vmid = var.ci_start_vmid + (count.index + var.ci_k8s_master_count)
  target_node = "pve"

  clone = "ubuntu-cloud-init"

  agent = 1
  cores = 2
  sockets = 1
  cpu = "host"
  memory = 4096

  bootdisk = "scsi0"
  scsihw = "virtio-scsi-pci"
  cloudinit_cdrom_storage = "local-lvm"
  onboot = true

  os_type = "cloud-init"
  ipconfig0 = "ip=${var.ci_k8s_base_node_ip}${count.index}/${var.ci_network_cidr},gw=${var.ci_ip_gateway}"
  nameserver = "8.8.8.8 8.8.4.4 192.168.56.1"
  searchdomain = "piinalpin.lab"
  ciuser = var.ci_user
  cipassword = var.ci_password
  sshkeys = <<EOF
  ${file(var.ci_ssh_public_key)}
  EOF

  network {
    bridge = "vmbr0"
    model = "virtio"
  }

  disks {
    scsi {
      scsi0 {
        disk {
          size = 20
          storage = "local-lvm"
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      network
    ]
  }
}
```

### Setup Ansible
For completely information step you can refer this documentation [Deploy Kubernetes Cluster on Vagrant With Ansible](https://piinalpin.com/2024/03/deploy-kubernetes-on-vagrant-with-ansible/) then adjust the inventory. 

**Inventory** 

```bash
[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
k3s_token=secret
k3s_master_ip=192.168.56.10

[master_nodes]
k8s-master ansible_ssh_host=192.168.56.10 ansible_ssh_port=22 ansible_user=k8s ansible_ssh_private_key_file=.ssh/homelab node_ip=192.168.56.10

[master_nodes:vars]
pod_network_cidr=192.168.0.0/16
k3s_config_file=/tmp/k3s-config.yaml

[worker_nodes]
k8s-node-1 ansible_ssh_host=192.168.56.20 ansible_ssh_port=22 ansible_user=k8s ansible_ssh_private_key_file=.ssh/homelab node_ip=192.168.56.20
k8s-node-2 ansible_ssh_host=192.168.56.21 ansible_ssh_port=22 ansible_user=k8s ansible_ssh_private_key_file=.ssh/homelab node_ip=192.168.56.21
```

Download the [**config.toml**](https://raw.githubusercontent.com/piinalpin/home-lab-provisioning/main/playbooks/files/config.toml) and put into `./playbooks/files/config.toml` to update `containerd.sock` runtime to prevent can't start kubelet while dialing `/var/run/containerd/containerd.sock`.

Create ansible playbook template file `./playbooks/templates/k3s-config.yaml.j2`
```
write-kubeconfig-mode: '0644'
tls-san:
  - {{ k3s_master_ip }}
disable:
  - traefik
  - servicelb
  - local-storage
token: {{ k3s_token }}
docker: true
cluster-init: true
```

**Ansible Playbook**

```yaml
- name: Setup Kubernetes Environment
  hosts: all
  become: yes
  become_method: sudo
  gather_facts: yes
  tasks:

    - name: Remove generated ubuntu hosts
      lineinfile:
        path: /etc/hosts
        regexp: "ubuntu-*"
        state: absent
        backup: yes

    - name: Remove generated hosts
      lineinfile:
        path: /etc/hosts
        regexp: ".* {{ hostvars[item]['ansible_hostname']}} {{ hostvars[item]['ansible_hostname']}}"
        state: absent
        backup: yes
      with_items: "{{ ansible_play_batch }}"

    - name: Update hosts
      lineinfile:
        path: /etc/hosts
        regexp: ".*\t{{ hostvars[item]['ansible_hostname']}}\t{{ hostvars[item]['ansible_hostname']}}"
        line: "{{ hostvars[item]['ansible_ssh_host'] }}\t{{ hostvars[item]['ansible_hostname']}}\t{{ hostvars[item]['ansible_hostname']}}.local"
        state: present
        backup: yes
      with_items: "{{ ansible_play_batch }}"

    - name: Install packages that allow apt to be used over HTTPS
      apt:
        name:
          - apt-transport-https
          - ca-certificates
          - curl
          - gnupg-agent
          - software-properties-common
        state: present
        update_cache: yes

    - name: Add an apt signing key for Docker
      apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    - name: Add apt repository for stable version
      apt_repository:
        repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_lsb.codename }} stable
        state: present
        filename: docker
        update_cache: yes

    - name: Install docker and dependecies
      apt: 
        name:
          - docker-ce 
          - docker-ce-cli 
          - containerd.io
        state: present
        update_cache: yes
      notify: Check docker status

    - name: Configure containerd config
      copy:
        src: "{{ item.src }}"
        dest: "{{ item.dest }}"
      with_items:
        - { src: config.toml, dest: /etc/containerd/config.toml }

    - name: Reload systemd daemon
      command: systemctl daemon-reload

    - name: Enable and start containerd
      service:
        name: containerd
        state: restarted
        enabled: yes

    - name: Add current user to docker group
      user:
        name: "{{ ansible_user }}"
        groups: docker
        append: yes

  handlers:
    - name: Check docker status
      service:
        name: docker
        state: started
        enabled: yes

- name: Master Node Setup
  hosts: master_nodes
  become: yes
  become_method: sudo
  gather_facts: yes
  tasks:

    - name: Copy k3s cluster config
      template:
        src: k3s-config.yaml.j2
        dest: "{{ k3s_config_file }}"

    - name: Initialize kubernetes cluster
      shell: curl -sfL https://get.k3s.io | K3S_CONFIG_FILE={{ k3s_config_file }} sh -s -

    - name: Setup kubeconfig for {{ ansible_user }} user
      command: "{{ item }}"
      with_items:
      - rm -rf /home/{{ ansible_user }}/.kube
      - mkdir -p /home/{{ ansible_user }}/.kube
      - cp -i /etc/rancher/k3s/k3s.yaml /home/{{ ansible_user }}/.kube/config
      - chown {{ ansible_user }}:{{ ansible_user }} /home/{{ ansible_user }}/.kube/config
  
  handlers:
    - name: Check k3s.service status
      service:
        name: k3s.service
        state: started
        enabled: yes

- name: Worker Node Setup
  hosts: worker_nodes
  become: yes
  become_method: sudo
  gather_facts: yes
  tasks:
    
    - name: Join the node to cluster
      shell: curl -sfL https://get.k3s.io | K3S_TOKEN={{ k3s_token }} K3S_URL=https://{{ k3s_master_ip }}:6443 sh -s - --docker
    
  handlers:
  - name: Check k3s-agent.service status
    service:
      name: k3s-agent.service
      state: started
      enabled: yes

```

### Execute Automation

Execute terraform and ansible
```bash
terraform init
terraform plan
terraform apply --auto-approve
ansible-playbook -i inventory/homelab.hosts playbooks/k3s-playbook.yaml
```

Install some requirements
- [Helm](https://helm.sh/docs/intro/install/)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)

Download kube config for kubernetes cluster, I usually using scp.
```bash
scp -i .ssh/homelab -o StrictHostKeyChecking=no k8s@192.168.56.1:~/.kube/config ~/.kube/config
```

**Installing Load Balancer**

Add helm repository
```bash
helm repo add metallb https://metallb.github.io/metallb
```

Install `MetalLB`
```bash
helm install metallb metallb/metallb -n metallb-system --create-namespace
```

Create manifest `ipaddresspool.yaml` for ip address pool that kubernetes pod IP.
```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.56.101-192.168.56.254
```

Apply ip address pool manifest
```bash
kubectl apply -f ipaddresspool.yaml
```

Create advertisement `l2advertisement.yaml` to announce the node IP
```yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - default-pool
```

Applu the L2 advertisement manifest
```bash
kubectl apply -f .cluster/metallb/l2advertisement.yaml
```

**Install Ingress Controller**

Add `nginx-ingress` repository
```bash
helm repo add nginx-stable https://helm.nginx.com/stable
```

Check and pull nginx ingress repository
```bash
helm search repo nginx
helm pull nginx-stable/nginx-ingress -d .helm --untar
```

Modify `.helm/nginx-ingress/values.yaml` set `setAsDefaultIngress` to true

```yaml
...
ingressClass:
  ## A class of the Ingress Controller.

  ## IngressClass resource with the name equal to the class must be deployed. Otherwise,
  ## the Ingress Controller will fail to start.
  ## The Ingress Controller only processes resources that belong to its class - i.e. have the "ingressClassName" field resource equal to the class.

  ## The Ingress Controller processes all the resources that do not have the "ingressClassName" field for all versions of kubernetes.
  name: nginx

  ## Creates a new IngressClass object with the name "controller.ingressClass.name". Set to false to use an existing IngressClass with the same name. If you use helm upgrade, do not change the values from the previous release as helm will delete IngressClass objects managed by helm. If you are upgrading from a release earlier than 3.3.0, do not set the value to false.
  create: true

  ## New Ingresses without an ingressClassName field specified will be assigned the class specified in `controller.ingressClass`. Requires "controller.ingressClass.create".
  setAsDefaultIngress: true
...
```

Run helm chart to install ingress into kubernetes cluster
```bash
helm -n ingress install nginx-ingress -f .helm/nginx-ingress/values.yaml .helm/nginx-ingress/ --debug --create-namespace
```

### References
- [Perfect Proxmox Template with Cloud Image and Cloud Init](https://www.youtube.com/watch?v=shiIi38cJe4)
- [Automate Homelab Deployment With Terraform & Proxmox](https://www.youtube.com/watch?v=ZGWn6xREdDE&t=576s&pp=ygURdGVycmFmb3JtIHByb3htb3g%3D)
- [Tutorial Terraform Proxmox Untuk PEMULA](https://www.youtube.com/watch?v=RehsezEP2-E)
- [K3S: Setup dan Konfigurasi Mudah untuk Kubernetes Cluster](https://www.youtube.com/watch?v=w7qoTksCQow&t=2325s)
