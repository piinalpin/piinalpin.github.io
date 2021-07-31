# Why Should Learn Ansible - Linux Automation


### Overview

![Ansible](/images/ansible.png)

Ansible is a radically simple IT automation engine that automates cloud provisioning, configuration management, application deployment, intra-service orchestration, and many other IT needs.

Designed for multi-tier deployments since day one, Ansible models your IT infrastructure by describing how all of your systems inter-relate, rather than just managing one system at a time.

It uses no agents and no additional custom security infrastructure, so it's easy to deploy - and most importantly, it uses a very simple language (YAML, in the form of Ansible Playbooks) that allow you to describe your automation jobs in a way that approaches plain English.

### Prerequisites

**Installing Virtual Box**

Install virtual box from [Downloads - Oracle VM Virtualbox](https://www.virtualbox.org/wiki/Downloads) or with [Homebrew](https://formulae.brew.sh/cask/virtualbox).

```bash
brew install virtualbox
```

**Installing Vagrant**

Vagrant is a tool for building and managing virtual machine environments in a single workflow. With an easy-to-use workflow and focus on automation, Vagrant lowers development environment setup time, increases production parity, and makes the "works on my machine" excuse a relic of the past.

We will use `vagrant` for virtualization server on our machine. Install vagrant with `homebrew`.

```bash
brew install vagrant
```

**Setup Host Only Adapter**

Open `virtualbox` and go to `File->Host Network Adapter` and setup private network.

![Host Only Adapter](/images/host-only-adapter.png)

**Installing Ansible**

Install ansible using Homebrew.

```bash
brew install ansible
```

### Create Virtual Machine

Create `Vagrantfile` and fill like following code. We will use `Centos 8` on our virtual machine.

```bash
Vagrant.configure(2) do |config|
    config.vm.box = "bento/centos-8"
  
    config.vm.define "server1" do |server1|
      server1.vm.network "private_network", ip: "192.168.0.1", name: 'vboxnet0'
      server1.vm.hostname = "server1.local"
      server1.vm.network :forwarded_port, guest: 22, host: 2222, id: "ssh", disabled: true
      server1.vm.network :forwarded_port, guest: 22, host: 2230, auto_correct: true
      server1.ssh.port = 2230
      server1.vm.provider "server1" do |vb|
        vb.cpus = 1
        vb.memory = 1024
      end
    end

    config.vm.define "server2" do |server2|
      server2.vm.network "private_network", ip: "192.168.1.1", name: 'vboxnet1'
      server2.vm.hostname = "server2.local"
      server2.vm.network :forwarded_port, guest: 22, host: 2222, id: "ssh", disabled: true
      server2.vm.network :forwarded_port, guest: 22, host: 2231, auto_correct: true
      server2.ssh.port = 2231
      server2.vm.provider "server2" do |vb|
        vb.cpus = 1
        vb.memory = 1024
      end
    end
  end
```

Running up the machine with typing `vagrant up` on terminal. And if all machine are running, we can check the status on our machines with `vagrant status` on terminal. And we get an output like below.

```bash
Current machine states:

server1                   running (virtualbox)
server2                   running (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
```

### Add Ansible Inventory

```
learn-ansible/
└───inventory/
│   │   vagrant.hosts
└───Vagrantfile
```

Create file in `inventory/vagrant.hosts` to register server host to ansible hosts and fill like following code.

```bash
[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[linux]
server1 ansible_ssh_host=192.168.0.1 ansible_ssh_port=2230 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/server1/virtualbox/private_key
server2 ansible_ssh_host=192.168.1.1 ansible_ssh_port=2231 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/server2/virtualbox/private_key
```

### Ansible Simple Usage

**Ping The Servers**

Test to ping the linux server on ansible hosts by command `ansible -i inventory/vagrant.hosts linux -m ping `. And we should get an output. If we get `SUCCESS` response, that means the ping was successful and we can access our servers from ansible.

```bash
server2 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/libexec/platform-python"
    },
    "changed": false,
    "ping": "pong"
}
server1 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/libexec/platform-python"
    },
    "changed": false,
    "ping": "pong"
}
```

**Run Linux Command from Ansible**

We will run a linux command to see the OS Release on our virtual machine using ansible with `ansible -i inventory/vagrant.hosts linux -a "cat /etc/os-release"` and we should get and output.

```bash
server1 | CHANGED | rc=0 >>
NAME="CentOS Linux"
VERSION="8"
ID="centos"
ID_LIKE="rhel fedora"
VERSION_ID="8"
PLATFORM_ID="platform:el8"
PRETTY_NAME="CentOS Linux 8"
ANSI_COLOR="0;31"
CPE_NAME="cpe:/o:centos:centos:8"
HOME_URL="https://centos.org/"
BUG_REPORT_URL="https://bugs.centos.org/"
CENTOS_MANTISBT_PROJECT="CentOS-8"
CENTOS_MANTISBT_PROJECT_VERSION="8"
server2 | CHANGED | rc=0 >>
NAME="CentOS Linux"
VERSION="8"
ID="centos"
ID_LIKE="rhel fedora"
VERSION_ID="8"
PLATFORM_ID="platform:el8"
PRETTY_NAME="CentOS Linux 8"
ANSI_COLOR="0;31"
CPE_NAME="cpe:/o:centos:centos:8"
HOME_URL="https://centos.org/"
BUG_REPORT_URL="https://bugs.centos.org/"
CENTOS_MANTISBT_PROJECT="CentOS-8"
CENTOS_MANTISBT_PROJECT_VERSION="8"
```

So, we know that both of our servers use the CentOS-8 operating system.

### Ansible Playbook

An Ansible playbook is an organized unit of scripts that defines work for a server configuration managed by the automation tool Ansible and create by `YAML` file.

```yaml
---
- name: iloveansible
  hosts: server1
  become: yes
  tasks:
    - name: Ensure nano is there
      yum:
        name: nano
        state: latest
```

That `yaml` file means :
- Playbook have a `PLAY` with name `iloveansible`
- Running at host `server1` and become a `root` access
- Run tasks `Ensure nano is there` will running command `sudo yum install nano`

So, the structure directory should be like below.

```
learn-ansible/
└───inventory/
│   │   vagrant.hosts
└───Vagrantfile
└───ansible-playbook.yml
```

Running playbook by typing `ansible-playbook -i inventory/vagrant.hosts ansible-playbook.yml ` on terminal.

And we get an output.

```bash
PLAY [iloveansible] ************************************************************************************************************************************************************************************************************************

TASK [Gathering Facts] *********************************************************************************************************************************************************************************************************************
ok: [server1]

TASK [Ensure nano is there] ****************************************************************************************************************************************************************************************************************
changed: [server1]

PLAY RECAP *********************************************************************************************************************************************************************************************************************************
server1                    : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 
```

See on `PLAY RECAP` there is an status `changed=1` that mean, `server1` has been changed because just installed `nano` on `server1`.

Because a playbook just running on `server1` that means on `server2` doesn't have a `nano`. So what if we install `nano` on all server group? Here is a `yaml` file. Change hosts to `linux`.

```yaml
---
- name: iloveansible
  hosts: linux
  become: yes
  tasks:
    - name: Ensure nano is there
      yum:
        name: nano
        state: latest
```

Running playbook by typing `ansible-playbook -i inventory/vagrant.hosts ansible-playbook.yml ` on terminal.

And we get an output.

```bash
PLAY [iloveansible] ************************************************************************************************************************************************************************************************************************

TASK [Gathering Facts] *********************************************************************************************************************************************************************************************************************
ok: [server1]
ok: [server2]

TASK [Ensure nano is there] ****************************************************************************************************************************************************************************************************************
ok: [server1]
changed: [server2]

PLAY RECAP *********************************************************************************************************************************************************************************************************************************
server1                    : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
server2                    : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 
```

See on `PLAY RECAP` there is an status `changed=0` on `server1` that mean, `server1` not changed because a `nano` have installed on `server1`. And then there is an status `changed=1` on `server2` that mean, `server2` has been changed because just installed `nano` on `server2`.

Let's go inside our server and check the `nano` have installed using ssh on server1 by typing `ssh -p 2230 vagrant@192.168.0.1 -i .vagrant/machines/server1/virtualbox/private_key` on terminal. Then typing `sudo yum install nano` on `server1` terminal.

And we should get an output

```bash
Last metadata expiration check: 0:21:55 ago on Sat 31 Jul 2021 02:10:15 PM UTC.
Package nano-2.9.8-1.el8.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
```

That mean, a `nano` has been installed on our server.

What if we want to uninstall the nano on all server? Just change `state: latest` to `state: absent` like below.

```yaml
---
- name: iloveansible
  hosts: linux
  become: yes
  tasks:
    - name: Ensure nano is there
      yum:
        name: nano
        state: absent
```

You can see my example on **[Github](https://github.com/piinalpin/learning-ansible/tree/master/basic-learn)**

### References

[RedHat Ansible](https://www.ansible.com/overview/how-ansible-works) - Overview How Ansible Works

[HashiCorp](https://www.vagrantup.com/intro) - Introduction to Vagrant

[HVOPS](https://hvops.com/articles/ansible-mac-osx/) - Install Ansible on Mac OSX

[Youtube](https://www.youtube.com/watch?v=5hycyr-8EKs) - you need to learn Ansible RIGHT NOW!! (Linux Automation)

[TechTarget](https://searchitoperations.techtarget.com/definition/Ansible-playbook) - Ansible playbook