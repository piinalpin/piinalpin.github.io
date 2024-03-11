# Deploy Kubernetes Cluster on Vagrant With Ansible


![Kubernetes Cluster in Vagrant](/images/vagrant-vm.png)

The objective is describes the steps required to setup a multi node Kubernetes cluster for development purposes. This setup provides a production-like cluster that can be setup on your local machine. And we will use VirtualBox as the virtualization engine, Vagrant and Ansible for provisioning in our local environment. Before we setup kubernetes cluster, we need some prerequisities on our local machine below.

- [Oracle VM VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- [Vagrant](https://developer.hashicorp.com/vagrant/install?product_intent=vagrant)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- Makesure you have setup network `Host Only Adapter` on your VirtualBox

### Why use Vagrant and Ansible?
Vagrant is a tool that will allow us to create a virtual environment easily and it eliminates pitfalls that cause the works-on-my-machine phenomenon. It can be used with multiple providers such as Oracle VirtualBox, VMware, Docker, and so on. It allows us to create a disposable environment by making use of configuration files.

Ansible is an infrastructure automation engine that automates software configuration management. It is agentless and allows us to use SSH keys for connecting to remote machines. Ansible playbooks are written in yaml and offer inventory management in simple text files.

### Setup Kubernetes Cluster
We will be setting up a Kubernetes cluster that will consist of one master and two worker nodes. All the nodes will run Ubuntu Xenial 64-bit OS and Ansible playbooks will be used for provisioning.

#### Creating Project Structure

We will create project structure like below.

```txt
.
├── ...
├── inventory/                
│   ├── vagrant.hosts                       # Define host target and variables to setup using ansible
├── playbooks/
│   ├── files/
│   │   └── config.toml                     # Containerd configuration
│   ├── templates/
│   │   ├── calico-custom-resource.yaml.j2  # Setup kubernetes pod network j2 template
│   │   └── joincluster.j2                  # Join kubernetes node to cluster command
│   └── ansible-playbook.yaml               # Ansible playbook file
├── vagrant-chmod-ssh.sh                    # Set read only generated ssh private key
├── Vagrantfile                             # Vagrant provisioning file
└── ...
```

#### Creating Vagrantfile

Using your favourite IDE and create file `Vagrantfile` and inserting code below. For `WORKER_NODES_IPS` indicates how many worker or slave nodes present in the cluster. And this Vagrantfile configuration will be disable default port 22 for ssh and replace with incremental master ssh forwarded port.

```Vagrantfile
IMAGE_NAME = "ubuntu/focal64"
MASTER_NODE_IP = "192.168.56.2"
MASTER_SSH_FORWARDED_PORT = 2722
WORKER_NODE_IPS = ["192.168.56.3", "192.168.56.4"]

Vagrant.configure(2) do |config|
    # Configure box
    config.vm.box = IMAGE_NAME
    config.vm.box_check_update = false
    config.vm.network :forwarded_port, guest: 22, host: 2222, id: "ssh", disabled: true

    # Provision Master Node
    config.vm.define "master" do |master|
        master.vm.provider "virtualbox" do |v|
            v.memory = 4096
            v.cpus = 2
            v.name = "k8s-master"
        end

        master.vm.hostname = "master"
        master.vm.network "private_network", ip: MASTER_NODE_IP
        master.vm.network "forwarded_port", guest: 22, host: MASTER_SSH_FORWARDED_PORT, auto_correct: true
        master.vm.network "forwarded_port", guest: 6443, host: 6443, auto_correct: true
    end

    # Provision worker nodes
    WORKER_NODE_IPS.each_with_index do |node_ip, index|
        hostname = "worker-#{'%02d' % (index + 1)}"
        forwarded_port = MASTER_SSH_FORWARDED_PORT + index + 1
        config.vm.define "#{hostname}" do |worker|
            worker.vm.provider "virtualbox" do |v|
                v.memory = 2048
                v.cpus = 2
                v.name = "k8s-#{hostname}"
            end
            worker.vm.hostname = "#{hostname}"
            worker.vm.network "private_network", ip: node_ip
            worker.vm.network "forwarded_port", guest: 22, host: forwarded_port, auto_correct: true
        end
    end
end
```

#### Create Additional Configuration

Create `vagrant.hosts` at `./inventory/vagrant.hosts` to define which machine will be provision. Define the `ansible_ssh_host` using actual IP address on `Vagrantfile`.

```bash
[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[master_nodes]
master ansible_ssh_host=192.168.56.2 ansible_ssh_port=22 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/master/virtualbox/private_key node_ip=192.168.56.2

[worker_nodes]
worker-01 ansible_ssh_host=192.168.56.3 ansible_ssh_port=22 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/worker-01/virtualbox/private_key node_ip=192.168.56.3
worker-02 ansible_ssh_host=192.168.56.4 ansible_ssh_port=22 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/worker-02/virtualbox/private_key node_ip=192.168.56.4
```

Download the [**config.toml**](https://raw.githubusercontent.com/piinalpin/home-lab-provisioning/main/playbooks/files/config.toml) and put into `./playbooks/files/config.toml` to update `containerd.sock` runtime to prevent can't start kubelet while dialing `/var/run/containerd/containerd.sock`. 

**Note:** This based on my experience because I'm facing this issue, so I override the address of `containerd.sock`.

#### Create an Ansible Playbook for Kubernetes Cluster

Create `ansible-playbook.yaml` at `./playbooks/ansible-playbook.yaml` and we will use single playbook file but we can define for all host, master and nodes hosts. 

**Update hosts and Install some Required Packages**

We will update `/etc/hosts` on each remote target to register all of hostname and IP in ansible vars in this case is on `vagrant.hosts`. And install some packages below:
- `apt-transport-https`
- `ca-certificates`
- `curl`
- `gnupg-agent`
- `software-properties-common`

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
```
&nbsp;

**Install docker and required dependency**

We will installing the following packages and adding user into the docker group.

```yaml
- name: Add an apt signing key for Docker
  apt_key:
    url: https://download.docker.com/linux/ubuntu/gpg
    state: present

- name: Add apt repository for stable version
  apt_repository:
    repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_lsb.codename }} stable
    state: present

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

- name: Add vagrant user to docker group
  user:
    name: "{{ ansible_user }}"
    groups: docker
    append: yes
```

Don't forget to add handlers below 
```yaml
handlers:
  - name: Check docker status
    service:
      name: docker
      state: started
      enabled: yes
```
&nbsp;

**Disabling system swap**

Kubelet will not start if system has swap enabled, so we are disabling swap using below code.

```yaml
- name: Remove swapfile from /etc/fstab
  mount:
    name: "{{ item }}"
    fstype: swap
    state: absent
  with_items:
    - swap
    - none

- name: Disable swap
  command: swapoff -a
  when: ansible_swaptotal_mb > 0
```
&nbsp;

**Install kubelet, kubeadm and kubectl**

In this code we will check if kubernetes keyrings has been registered we will remove first before installing kubernetes. This is aimed at enabling automatic handling of provisioning errors post Kubernetes installation, as registered keyrings cannot be re-registered.

```yaml
- name: Ensure apt keyrings directory exists
  file:
    path: /etc/apt/keyrings
    state: directory

- name: Delete kubernetes keyrings if exists
  file:
    path: /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    state: absent

- name: Add kubernetes APT repository key
  shell: >
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

- name: Add kubernetes repository to sources list
  apt_repository:
    repo: deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /
    state: present
    filename: kubernetes
    update_cache: yes

- name: Install Kubernetes binaries
  apt: 
    name:
      - kubelet=1.29.*
      - kubeadm=1.29.*
      - kubectl=1.29.*
    state: present
    update_cache: yes

- name: Ensure /etc/default/kubelet exists
  file:
    path: /etc/default/kubelet
    state: touch

- name: Configure node ip
  lineinfile:
    path: /etc/default/kubelet
    line: KUBELET_EXTRA_ARGS=--node-ip={{ node_ip }}
    state: present

- name: Restart kubelet
  service:
    name: kubelet
    state: restarted
    daemon_reload: yes
    enabled: yes
```

#### Setup Kubernetes Master

Initialize kubernetes cluster on master node with `kubeadm` using below code. This will applicable only on Master node.

```yaml
- name: Master Node Setup
  hosts: master_nodes
  become: yes
  become_method: sudo
  gather_facts: yes
  vars:
    pod_network_cidr: 192.168.0.0/16
    custom_resource_remote_src: /tmp/calico-custom-resource.yaml
    join_cluster_remote_src: /tmp/joincluster
  tasks:

    - name: Initialize kubernetes cluster
      command: kubeadm init --apiserver-advertise-address="{{ ansible_ssh_host }}" --apiserver-cert-extra-sans="{{ ansible_ssh_host }}" --node-name {{ ansible_hostname }} --pod-network-cidr={{ pod_network_cidr }}
```
&nbsp;

**Setup the kube config file**

Setup the `KUBE_CONFIG` file for `kubectl` command that allow user non root to accerss the Kubernetes cluster.

```yaml
- name: Setup kubeconfig for {{ ansible_user }} user
  command: "{{ item }}"
  with_items:
  - mkdir -p /home/{{ ansible_user }}/.kube
  - cp -i /etc/kubernetes/admin.conf /home/{{ ansible_user }}/.kube/config
  - chown {{ ansible_user }}:{{ ansible_user }} /home/{{ ansible_user }}/.kube/config
```
&nbsp;

**Setup pod networking provider**

We will use `calico` network as a provider for pod networking and network policy engine, so will use `tigera-operator`. Download the [**calico-custom-resource.yaml.j2**](https://raw.githubusercontent.com/piinalpin/home-lab-provisioning/main/playbooks/templates/calico-custom-resource.yaml.j2) ansible templates for customizing calico resource then put into `./playbooks/templates/calico-custom-resource.yaml.j2`.

```yaml
- name: Install calico pod network
  become: false
  command: kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/tigera-operator.yaml
  register: install_calico_pod_network

- name: Copy calico custom resource
  template:
    src: calico-custom-resource.yaml.j2
    dest: "{{ custom_resource_remote_src }}"

- name: Install custom resource pod network
  become: false
  command: kubectl create -f {{ custom_resource_remote_src }}
  register: install_calico_custom_resource
  when: install_calico_pod_network is succeeded
```
&nbsp;

**Generate kube join command**

This step will generate join command for kubernetes nodes into master node. First, we are creating file `./playbooks/templates/joincluster.j2` and fill with code below.

```bash
#!/bin/bash

{{ join_cluster_command.stdout }}
```

Create ansible to generate join command and save the command in the file named `joincluster` that will be executed on kubernetes nodes.

```yaml
- name: Generate and save cluster join command
  command: kubeadm token create --print-join-command
  register: join_cluster_command
  when: install_calico_custom_resource is succeeded

- name: Save join command to file
  template:
    src: joincluster.j2
    dest: "{{ join_cluster_remote_src }}"
  when: join_cluster_command is succeeded

- name: Fetch joincluster into local file
  fetch:
    src: "{{ join_cluster_remote_src }}"
    dest: files/joincluster
    flat: yes
```

#### Setup Kubernetes Nodes

In the same ansible playbook we added configuration to setup kubernetes node to join cluster using generated join cluster that we store before.

```yaml
- name: Worker Node Setup
  hosts: worker_nodes
  become: yes
  become_method: sudo
  gather_facts: yes
  vars:
    join_cluster_remote_src: /tmp/joincluster
  tasks:
    
    - name: Copy the join command to server location
      copy:
        src: joincluster
        dest: "{{ join_cluster_remote_src }}"
        mode: 0777
        owner: "{{ ansible_user }}"
        group: "{{ ansible_user }}"
    
    - name: Join the node to cluster
      command: sh {{ join_cluster_remote_src }}
```

#### Execute provisioning

Upon completing the `Vagrantfile` and playbooks we can start to execute provisioning. Run vagrant by following command below.

```bash
$ vagrant up
```

And after all machine started we can execute provisioning using ansible playbook by following command below.

```bash
ansible-playbook -i inventory/vagrant.hosts playbooks/ansible-playbook.yaml
```

After all step and task completed, the kubernetes cluster should be up and running. We can login into the master or worker nodes using Vagrant or using host. I usually using host so it can be assumed as like run `kubectl` into remote server.

```bash
$ export KUBECONFIG=config.yaml
$ kubectl get nodes
NAME         STATUS   ROLES    AGE     VERSION
k8s-master   Ready    master   18m     v1.29.2
worker-01    Ready    <none>   12m     v1.29.2
worker-02    Ready    <none>   6m22s   v1.29.2
```

You can see all configuration files on my [**Github**](https://github.com/piinalpin/home-lab-provisioning)

### References
- [Kubernetes Setup Using Ansible and Vagrant](https://kubernetes.io/blog/2019/03/15/kubernetes-setup-using-ansible-and-vagrant/#step-3-1-start-adding-the-code-from-steps-2-1-till-2-3)
- [Install Kubernetes | 3 Node Cluster | v1.22.2 using Kubeadm | Vagrant | Vitrualbox | CKA](https://www.youtube.com/watch?v=JJbUNRGoxmk&t=75s)
- [Setup Kubernetes Cluster using Kubeadm using automated script v1.22.0](https://github.com/ImaginCloud/kubernetes/tree/main/setup-k8s/vagrant-kubeadm)
- [Kubernetes Vagrant Ubuntu](https://github.com/akyriako/kubernetes-vagrant-ubuntu)
- [Quickstart for Calico on Kubernetes](https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart)
