# Install Jenkins on Centos7


### Overview

![Jenkins.io](/images/jenkins.png)

Jenkins is a self-contained, open source automation server which can be used to automate all sorts of tasks related to building, testing, and delivering or deploying software.

Jenkins can be installed through native system packages, Docker, or even run standalone by any machine with a Java Runtime Environment (JRE) installed ([Jenkins.io](https://www.jenkins.io/doc/)).

### Prerequisites

- Vagrant, see how to install Vagrant **[here](https://blog.piinalpin.com/2021/07/why-should-learn-ansible/#prerequisites)**
- Add the following host entries on local device `/etc/hosts` :
    ```bash
    192.168.0.1 jenkins.local
    192.168.1.1 agent.local
    ```

**Startup Vagrant**

Create Vagrantfile and fill the following code.

```bash
Vagrant.configure(2) do |config|
    config.vm.box = "bento/centos-7"
  
    config.vm.define "jenkins" do |jenkins|
      jenkins.vm.network "private_network", ip: "192.168.0.1", name: 'vboxnet0'
      jenkins.vm.hostname = "jenkins.local"
      jenkins.vm.network :forwarded_port, guest: 22, host: 2222, id: "ssh", disabled: true
      jenkins.vm.network :forwarded_port, guest: 22, host: 2230, auto_correct: true
      jenkins.vm.network :forwarded_port, guest: 8080, host: 8080, auto_correct: true
      jenkins.ssh.port = 2230
      jenkins.vm.provider "jenkins" do |vb|
        vb.cpus = 1
        vb.memory = 1024
      end
    end

    config.vm.define "agent" do |agent|
      agent.vm.network "private_network", ip: "192.168.1.1", name: 'vboxnet1'
      agent.vm.hostname = "agent.local"
      agent.vm.network :forwarded_port, guest: 22, host: 2222, id: "ssh", disabled: true
      agent.vm.network :forwarded_port, guest: 22, host: 2231, auto_correct: true
      agent.ssh.port = 2231
      agent.vm.provider "agent" do |vb|
        vb.cpus = 1
        vb.memory = 1024
      end
    end
  end
```

And start vagrant by typing `vagrant up` on your terminal.

### Install Jenkins

SSH into jenkins machine, you can use `vagrant ssh jenkins` or ssh from host `ssh -p 2230 vagrant@jenkins.local -i .vagrant/machines/jenkins/virtualbox/private_key`

Login as root `sudo su -`

Install wget `yum install -y wget`

Create jenkins limit file `/etc/security/limits.d/30-jenkins.conf`

```bash
jenkins soft core unlimited
jenkins hard core unlimited
jenkins soft fsize unlimited
jenkins hard fsize unlimited
jenkins soft nofile 4096
jenkins hard nofile 8192
jenkins soft nproc 30654
jenkins hard nproc 30654
```

Setup firewall

```bash
systemctl start firewalld

firewall-cmd --permanent --add-port=22/tcp
firewall-cmd --permanent --add-port=8080/tcp

firewall-cmd --reload
firewall-cmd --list-all
```

We should get an outuput

```bash
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: eth0 eth1
  sources: 
  services: dhcpv6-client ssh
  ports: 22/tcp 8080/tcp
  protocols: 
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules:
```

Add the following entries to `/etc/hosts`

```bash
192.168.0.1 jenkins.local
192.168.1.1 agent.local
```

Add AdoptOpenJDK repository

```bash
cat <<'EOF' > /etc/yum.repos.d/adoptopenjdk.repo
[AdoptOpenJDK]
name=AdoptOpenJDK
baseurl=http://adoptopenjdk.jfrog.io/adoptopenjdk/rpm/centos/$releasever/$basearch
enabled=1
gpgcheck=1
gpgkey=https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public
EOF
```

Add repository to get latest Git

```bash
yum -y install https://packages.endpoint.com/rhel/7/os/x86_64/endpoint-repo-1.9-1.x86_64.rpm
```

Add jenkins repository

```bash
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
```

Create directory

```bash
mkdir -p /var/cache/jenkins/tmp
mkdir -p /var/cache/jenkins/heapdumps
```

Uninstall old Git by typing `yum remove git*` on your terminal

Install AdoptOpenJDK, Git, Jenkins and Fontconfig

```bash
yum -y install adoptopenjdk-11-hotspot git jenkins fontconfig
```

Edit the `/etc/sysconfig/jenkins` file

```bash
JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true -Djava.io.tmpdir=/var/cache/jenkins/tmp -Dorg.apache.commons.jelly.tags.fmt.timeZone=Asia/Jakarta -Duser.timezone=Asia/Jakarta"

JENKINS_ARGS="--pluginroot=/var/cache/jenkins/plugins"
```

Change owner jenkins config file `chown -R jenkins:jenkins /var/cache/jenkins`

Start jenkins by typing `systemctl start jenkins` and get status `systemctl -l status jenkins`

We should get an output status.

```bash
● jenkins.service - LSB: Jenkins Automation Server
   Loaded: loaded (/etc/rc.d/init.d/jenkins; bad; vendor preset: disabled)
   Active: active (running) since Sun 2021-08-01 01:06:57 UTC; 16s ago
     Docs: man:systemd-sysv-generator(8)
  Process: 3697 ExecStart=/etc/rc.d/init.d/jenkins start (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/jenkins.service
           └─3718 /etc/alternatives/java -Dcom.sun.akuma.Daemon=daemonized -Djava.awt.headless=true -Djava.io.tmpdir=/var/cache/jenkins/tmp -Dorg.apache.commons.jelly.tags.fmt.timeZone=Asia/Jakarta -Duser.timezone=Asia/Jakarta -DJENKINS_HOME=/var/lib/jenkins -jar /usr/lib/jenkins/jenkins.war --logfile=/var/log/jenkins/jenkins.log --webroot=/var/cache/jenkins/war --daemon --httpPort=8080 --debug=5 --handlerCountMax=100 --handlerCountMaxIdle=20 --pluginroot=/var/cache/jenkins/plugins
```

### Setup Jenkins UI

Access `http://jenkins.local:8080` on your host and should be like below.

![Unlock Jenkins](/images/jenkins.local-ui-1.png)

Type `sudo cat /var/lib/jenkins/secrets/initialAdminPassword` to get password and paste it on field then continue.

Install **suggested plugin**

![Suggested Plugin Jenkins](/images/jenkins.local-ui-2.png)

Create first admin user.

![Admin User Jenkins](/images/jenkins.local-ui-3.png)

Setup jenkins url and click start using jenkins.

![Jenkins URL](/images/jenkins.local-ui-4.png)

And restart jenkins then login with admin user `http://jenkins.local:8080/restart`

### Agent Installation

SSH into jenkins machine, you can use `vagrant ssh agent` or ssh from host `ssh -p 2231 vagrant@agent.local -i .vagrant/machines/agent/virtualbox/private_key`

Login as root `sudo su -`

Setup firewall

```bash
systemctl start firewalld

firewall-cmd --permanent --add-port=22/tcp

firewall-cmd --reload
firewall-cmd --list-all
```

We should get an outuput

```bash
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: eth0 eth1
  sources: 
  services: dhcpv6-client ssh
  ports: 22/tcp 8080/tcp
  protocols: 
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules:
```

Add the following entries to `/etc/hosts`

```bash
192.168.0.1 jenkins.local
192.168.1.1 agent.local
```

Add AdoptOpenJDK repository

```bash
cat <<'EOF' > /etc/yum.repos.d/adoptopenjdk.repo
[AdoptOpenJDK]
name=AdoptOpenJDK
baseurl=http://adoptopenjdk.jfrog.io/adoptopenjdk/rpm/centos/$releasever/$basearch
enabled=1
gpgcheck=1
gpgkey=https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public
EOF
```

Add repository to get latest Git

```bash
yum -y install https://packages.endpoint.com/rhel/7/os/x86_64/endpoint-repo-1.9-1.x86_64.rpm
```

Uninstall old Git by typing `yum remove git*` on your terminal

Install AdoptOpenJDK, Git, Fontconfig and Wget

```bash
yum -y install adoptopenjdk-11-hotspot git fontconfig wget
```

Install docker and unzip from [Install Docker Engine on CentOS](https://docs.docker.com/engine/install/centos/)

- Remove old docker if any `yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine`
- `yum -y install yum-utils`
- `yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo`
- `yum -y install docker-ce docker-ce-cli containerd.io unzip`
- `systemctl enable docker`
- `systemctl start docker`
- `groupadd docker`
- `systemctl -l status docker`
- `exit`
- `sudo usermod -aG docker $USER`
- `exit`

SSH again to vagrant agent 
```bash
ssh -p 2231 vagrant@agent.local -i .vagrant/machines/agent/virtualbox/private_key
```

Try running container by typing `docker run hello-world` on your terminal.

Installing maven

- `sudo su -`
- `mkdir -p /opt/tools/maven`
- `cd /opt/tools/maven`
- `wget https://downloads.apache.org/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz`
- `tar zxvf apache-maven-3.6.3-bin.tar.gz`
- `rm -f apache-maven-3.6.3-bin.tar.gz `
- `ln -s apache-maven-3.6.3 latest`

Installing gradle

- `mkdir -p /opt/tools/gradle`
- `cd /opt/tools/gradle`
- `wget https://services.gradle.org/distributions/gradle-7.1.1-bin.zip`
- `unzip gradle-7.1.1-bin.zip`
- `rm -f gradle-7.1.1-bin.zip`
- `ln -s gradle-7.1.1 latest`

Export maven and gradle to profile

- `echo "PATH=/opt/tools/gradle/latest/bin:\$PATH" > /etc/profile.d/gradle.sh`
- `echo "PATH=/opt/tools/maven/latest/bin:\$PATH" > /etc/profile.d/maven.sh`
- `chown -R vagrant:vagrant /opt/tools`
- `exit`
- `exit`

Verify that maven and gradle has already installed on your machine.

- `ssh -p 2231 vagrant@agent.local -i .vagrant/machines/agent/virtualbox/private_key`
- `mvn --version`
- `gradle --version`

### Connect Agent to Jenkins

Manage jenkins at system configuration.

![Jenkins System Configuration](/images/jenkins.local-ui-5.png)

And fill field like below

![Jenkins Configuration](/images/jenkins.local-ui-6.png)

Add nodes and fill like below

![Jenkins Nodes 1](/images/jenkins.local-ui-7.png)

![Jenkins Nodes 2](/images/jenkins.local-ui-8.png)

Add credential

![Jenkins Nodes Credential](/images/jenkins.local-ui-9.png)

Click advanced and set port to `2231` then click save.

![Jenkins SSH Port](/images/jenkins.local-ui-10.png)

### Create Test Job (Pipeline)

Create new pipeline then save

![Jenkins Pipeline](/images/jenkins.local-ui-11.png)

Create build script to running jobs.

```bash
pipeline {
  agent {label "linux"}
  stages {
    stage("Hello") {
      steps {
        sh """
          mvn --version
          gradle --version
          docker info
        """
      }
    }
  }
}
```

You can see my example on **[Github](https://github.com/piinalpin/learning-ansible/tree/master/02-install-jenkins-centos8)**

### References

[Jenkins.io](https://www.jenkins.io/doc/) - Jenkins User Documentation

[CloudBeesTV](https://www.youtube.com/watch?v=g7CnQnDQwuU) - How To Install Jenkins on CentOS 7

[RedHat](https://www.redhat.com/en/blog/continuous-delivery-jboss-eap-and-openshift-cloudbees-jenkins-platform) - Continuous Delivery to JBoss EAP and OpenShift with the CloudBees Jenkins Platform

[CloudBees](https://support.cloudbees.com/hc/en-us/articles/222446987-Prepare-Jenkins-for-Support) - Prepare Jenkins for Support

[Jenkins](https://pkg.jenkins.io/redhat-stable/) - Jenkins Redhat Packages

[Docker](https://docs.docker.com/engine/install/centos/) - Install Docker Engine on CentOS

[Docker](https://docs.docker.com/engine/install/linux-postinstall/) - Post-installation steps for Linux