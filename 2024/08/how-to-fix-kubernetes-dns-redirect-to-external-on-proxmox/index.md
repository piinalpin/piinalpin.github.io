# How to Fix Kubernetes DNS Redirect to External on Proxmox


![Kubernetes FQDN got 302 found](/images/kubernetes-fqdn-302-found.png)
<br><br>

**What Happened?**

I want deploy spring boot microservices and I have services called `dexter` and `enclave` and want communicate to each other using REST. They can communicate if I set service url using container hostname which is `dexter` and `enclave`. But somehow they won't communicate if I use Fully Qualified Domain Name (FQDN) on kubernetes and got `302 Found`. Seems redirect to external domain on public network which should not be registered.<br><br>

**What did you expect to happen?**

Pods should resolve DNS and exposed service should be reachable.<br><br>

**The Environment**

- Cloud Provider: `Proxmox 8.2 (Bare Metal)`
- Kubernetes Cluster Info 
  ```json
  {
    "clientVersion": {
      "major": "1",
      "minor": "25",
      "gitVersion": "v1.25.9",
      "gitCommit": "a1a87a0a2bcd605820920c6b0e618a8ab7d117d4",
      "gitTreeState": "clean",
      "buildDate": "2023-04-12T12:16:51Z",
      "goVersion": "go1.19.8",
      "compiler": "gc",
      "platform": "windows/amd64"
    },
    "kustomizeVersion": "v4.5.7",
    "serverVersion": {
      "major": "1",
      "minor": "30",
      "gitVersion": "v1.30.3",
      "gitCommit": "6fc0a69044f1ac4c13841ec4391224a2df241460",
      "gitTreeState": "clean",
      "buildDate": "2024-07-16T23:48:12Z",
      "goVersion": "go1.22.5",
      "compiler": "gc",
      "platform": "linux/amd64"
    }
  }
  ```
- DNS Lookup
  ```bash
  nslookup google.com
  Server:         192.168.1.1
  Address:        192.168.1.1#53

  Non-authoritative answer:
  google.com      canonical name = forcesafesearch.google.com.
  Name:   forcesafesearch.google.com
  Address: 216.239.38.120
  Name:   forcesafesearch.google.com
  Address: 2001:4860:4802:32::78
  ```
<br>

**Root Cause?**

DNS Resolve `/etc/resolv.conf` on Proxmox VE have registered `search` name because when first install Proxmox that DNS must be filled. Thats why when create new VM from proxmox using cloud init, the dns resolve on VM (kubernetes node) was overrided from Proxmox VE and impacted the DNS resolution on kubernetes cluster.<br><br>

**How to Solve?**

Remove kubernetes cluster and VM. Remove registered `search example.com` on your Proxmox VE bare metal. This example i use my router gateway ip and use google dns also take a note to adjust with your preference.

```bash
nameserver 192.168.1.1
nameserver 8.8.8.8
nameserver 8.8.4.4
```

Create VM and reinstall kubernetes cluster, and that issue should be resolved.
