# Build Kubernetes Cluster on Proxmox VE


![Kubernetes Cluster](/images/kubernetes-cluster-architecture.svg)

The documentation is describing the steps required to setup kubernetes cluster on bare metal using command line step by steps. We will need:
- At least 2 ubuntu server instance, can use `18.04` or `22.04`. We will made this using single cluster with 1 instance kubernetes controller and another as node instance.
- Make sure all instance has static IP address, you can use `Terraform` to create instance on this [tutorial](https://piinalpin.com/2024/04/deploy-kubernetes-production-ready-on-proxmox-using-k3s/) on proxmox.
- Controller should have at least 2 cores CPUs and 4GB of memory.
- Node instance should have at least 1 cores CPUs and 2GB of memory.
- Makesure all instance can access from SSH


### Apply in All Instance

The first thing we need to do is update our operating system by execute `apt update` and `apt upgrade`
```bash
sudo apt update && sudo apt upgrade
```

Install `containerd` to manages the complete container lifecycle of its host system, from image transfer and storage to container execution and supervision to low-level storage to network attachments and beyond

```bash
sudo apt install -y containerd
```

Create `containerd` initial configuration
```bash
sudo mkdir /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
```

Update `/etc/containerd/config.toml` configuration to enable `SystemdCgroup` 
```toml
...
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    ...
    SystemdCgroup = true
...
```

Create `/etc/crictl.yaml` to configure `containerd` runtime endpoint
```bash
echo "runtime-endpoint: unix:///var/run/containerd/containerd.sock" | sudo tee /etc/crictl.yaml
```

Ensure `swap` is disabled 
```bash
sudo swapoff -a
```

Update `/etc/sysctl.conf` to enable bridging or ip forwarding with uncomment this line 
```text
net.ipv4.ip_forward=1
```

Enable kubernetes net filter, then **reboot our instances**
```bash
echo "br_netfilter" | sudo tee /etc/modules-load.d/k8s.conf
```

After rebooted then add kubernetes keyrings, create this directory if doesn't exists `/etc/apt/keyrings`
```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

Add kubernetes repository source list
```bash
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
```

Install kubernetes
```bash
sudo apt install -y kubeadm kubectl kubelet
```

### Controller Node

As long we have everything so far then we can initialize the kubernetes cluster with deploy the kubernetes controller node

```bash
sudo kubeadm init --apiserver-advertise-address=<k8s-master-ip> --apiserver-cert-extra-sans=<k8s-master-ip> --control-plane-endpoint=<k8s-master-ip> --node-name <node-name> --pod-network-cidr=10.244.0.0/16
```

**Note:**
- Replace `<k8s-master-ip>` with your master node ip
- Replace `<node-name>` with your preferred name
- `--pod-network-cidr` will use default `calico` network cidr because we will use `calico`

**Calico** is a networking and security solution that enables Kubernetes workloads and non-Kubernetes/legacy workloads to communicate seamlessly and securely.

Three commands will be shown in the output from the previous command, and these commands will give our user account access to manage our cluster. Here are those related commands to save you from having to search the output for them:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Install `calico` network using `kubectl` on controller or master node
```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/tigera-operator.yaml
```

Create `calico` custom resource file `calico-custom-resource.yaml` based on Calico documentation
```yaml
# This section includes base Calico installation configuration.
# For more information, see: https://docs.tigera.io/calico/latest/reference/installation/api#operator.tigera.io/v1.Installation
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  # Configures Calico networking.
  calicoNetwork:
    # Note: The ipPools section cannot be modified post-install.
    ipPools:
    - blockSize: 26
      cidr: 10.244.0.0/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()

---

# This section configures the Calico API server.
# For more information, see: https://docs.tigera.io/calico/latest/reference/installation/api#operator.tigera.io/v1.APIServer
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}
```

**Note** that the `ipPools[].cidr` must match the `--pod-network-cidr` that we defined before which is `10.244.0.0/16`

Install custom resource
```bash
kubectl apply -f calico-custom-resource.yaml
```

Generate join cluster command
```bash
kubeadm token create --print-join-command
```

### Worker Node

For worker node we only need to join to cluster with generated join command from kubernetes controller, for example:
```bash
kubeadm join 192.168.56.10:6443 --token 9ihiei.ocmvmcmrrndvqx15 --discovery-token-ca-cert-hash sha256:0b4f058dc00796282339680f1d97513129800c6b957875093b4f3c7bb10e2ee8
```

Do that join command to all worker node that you preferred. Finally, we already have kubernetes cluster with calico network. 
