# Learning Kubernetes


<!--more-->

### What is Kubernetes?

![Kubernetes](/images/k8s.svg)

Kubernetes is a portable, extensible, open-source platform for managing containerized workloads and services, that facilitates both declarative configuration and automation. It has a large, rapidly growing ecosystem. Kubernetes services, support, and tools are widely available.

More information, please follow this link [Kubernetes Overview](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/).

### Why we need Kubernetes

Containers are a good way to bundle and run your applications. In a production environment, you need to manage the containers that run the applications and ensure that there is no downtime. For example, if a container goes down, another container needs to start. Wouldn't it be easier if this behavior was handled by a system?

That's how Kubernetes comes to the rescue! Kubernetes provides you with a framework to run distributed systems resiliently. It takes care of scaling and failover for your application, provides deployment patterns, and more. For example, Kubernetes can easily manage a canary deployment for your system.

Kubernetes can provide with :
- Service discovery and load balancing
- Storage orchestration
- Automated rollouts and rollbacks
- Automatic bin packing
- Self healing
- Secret and configuratio management

For more information please follow this link [Why you Need Kubernetes](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/#why-you-need-kubernetes-and-what-can-it-do).

### Start using Kubernetes

**Getting Start with Kubernetes on Docker Desktop**

[Docker Desktop](https://www.docker.com/products/docker-desktop) is the easiest way to run Kubernetes on your local machine - it gives you a fully certified Kubernetes cluster and manages all the components for you.

In this lab you’ll learn how to set up Kubernetes on Docker Desktop and run a simple demo app. You’ll gain experience of working with Kubernetes and comparing the app definition syntax to Docker Compose.

Install Docker Desktop from official website, please follow this link [Install Docker Desktop](https://www.docker.com/products/docker-desktop). Docker Desktop is freely available in a community edition, for Windows and Mac.

**Enable Kubernetes**

![Enable Kubernetes](/images/enable-k8s.png)

Kubernetes itself runs in containers. When you deploy a Kubenetes cluster you first install Docker (or another container runtime like [containerd](https://containerd.io)) and then use tools like [kubeadm](https://kubernetes.io/docs/reference/setup-tools/kubeadm/) which starts all the Kubernetes components in containers. Docker Desktop does all that for you.

**Verify Kubernetes Cluster**

If you’ve worked with Docker before, you’re used to managing containers with the `docker` and `docker-compose` command lines. Kubernetes uses a different tool called `kubectl` to manage apps - Docker Desktop installs `kubectl` for you too.

The cluster can be interacted with using the kubectl CLI. This is the main approach used for managing Kubernetes and the applications running on top of the cluster.

Details of the cluster and its health status is.

```bash
kubectl cluster-info
```

We should get an output

```bash
Kubernetes control plane is running at https://kubernetes.docker.internal:6443
KubeDNS is running at https://kubernetes.docker.internal:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

To view the nodes in the cluster with.

```bash
kubectl get nodes
```

We shoulkd get an output

```bash
NAME             STATUS   ROLES    AGE     VERSION
docker-desktop   Ready    master   4d22h   v1.19.7
```

If the node is marked as NotReady then it is still starting the components.

This command shows all nodes that can be used to host our applications. Now we have only one node, and we can see that it’s status is ready (it is ready to accept applications for deployment).

**Deploy Container**

With a running Kubernetes cluster, containers can now be deployed.

Using `kubectl run`, it allows containers to be deployed onto the cluster.

```bash
kubectl create deployment hello-world --image=piinalpin/sample-node-web-app
```

To check status of the deployment.

```bash
kubectl get pods
```

We should get an output

```bash
NAME                           READY   STATUS    RESTARTS   AGE
hello-world-6b64556c5b-9pzrp   1/1     Running   0          88s
```

Once the container is running it can be exposed via different networking options, depending on requirements. One possible solution is NodePort, that provides a dynamic port to a container.

```bash
kubectl expose deployment hello-world --port=8080 --type=NodePort
```

The command below finds the allocated port and executes a HTTP request.

```bash
export NODE_PORT=$(kubectl get svc hello-world -o go-template='{{range.spec.ports}}{{if .nodePort}}{{.nodePort}}{{"\n"}}{{end}}{{end}}') 
echo "Accessing http://localhost:$NODE_PORT"  
curl http://localhost:$NODE_PORT
```

We should get an output

```bash
{"status":"success","message":"Hello World! This api from Node.js"}
```

**Kubernetes Dashboard**

Deploy latest kubernetes dashboard, you can deploy the dashboard itself with the following single command.

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml   
```

If your cluster is working correctly, you should see an output confirming the creation of a bunch of Kubernetes components like in the example below.

```bash
namespace/kubernetes-dashboard created
serviceaccount/kubernetes-dashboard created
service/kubernetes-dashboard created
secret/kubernetes-dashboard-certs created
secret/kubernetes-dashboard-csrf created
secret/kubernetes-dashboard-key-holder created
configmap/kubernetes-dashboard-settings created
role.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrole.rbac.authorization.k8s.io/kubernetes-dashboard created
rolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
deployment.apps/kubernetes-dashboard created
service/dashboard-metrics-scraper created
deployment.apps/dashboard-metrics-scraper created
```

Afterwards, you should have two new pods running on your cluster.

```bash
kubectl get pods -A
```

We should get an output

```bash
NAMESPACE              NAME                                         READY   STATUS    RESTARTS   AGE
...
kubernetes-dashboard   dashboard-metrics-scraper-7b59f7d4df-qkztd   1/1     Running   0          30s
kubernetes-dashboard   kubernetes-dashboard-74d688b6bc-s4595        1/1     Running   0          30s
```

Running `kubectl proxy` to accessing the dashbooard, then access this link `http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/`.

If we get an output

![Kubernetes Dashboard Auth](/images/k8s-dashboard-auth.png)

Get token to access dashboard page and paste on authentication page.

```bash
kubectl get secret -n kubernetes-dashboard $(kubectl get serviceaccount default -n kubernetes-dashboard -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode
```

![Kubernetes Dashboard](/images/k8s-dashboard.png)

Detail information dashboard please follow [Kubernetes.io](https://kubernetes.io/id/docs/tasks/access-application-cluster/web-ui-dashboard/)

Stopping Kubernetes, by type following script

```bash
kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml
```

We should get an output

```bash
namespace "kubernetes-dashboard" deleted
serviceaccount "kubernetes-dashboard" deleted
service "kubernetes-dashboard" deleted
secret "kubernetes-dashboard-certs" deleted
secret "kubernetes-dashboard-csrf" deleted
secret "kubernetes-dashboard-key-holder" deleted
configmap "kubernetes-dashboard-settings" deleted
role.rbac.authorization.k8s.io "kubernetes-dashboard" deleted
clusterrole.rbac.authorization.k8s.io "kubernetes-dashboard" deleted
rolebinding.rbac.authorization.k8s.io "kubernetes-dashboard" deleted
clusterrolebinding.rbac.authorization.k8s.io "kubernetes-dashboard" deleted
deployment.apps "kubernetes-dashboard" deleted
service "dashboard-metrics-scraper" deleted
deployment.apps "dashboard-metrics-scraper" deleted
```

**Setting Management Script**

The steps to deploy or delete the dashboard are not complicated but they can be further simplified.

The following script can be used to start, stop or check the dashboard status.

Create file `kubernetes-dashboard.sh`

```bash
nano ~/kubernetes-dashboard.sh
```

```bash
#!/bin/bash
showtoken=1
cmd="kubectl proxy"
count=`ps aux | grep -v "grep" | grep -c "$cmd"`
dashboard_yaml="https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml"
msgstarted="-e Kubernetes Dashboard \e[92mstarted\e[0m"
msgstopped="Kubernetes Dashboard stopped"

case $1 in
start)
   kubectl apply -f $dashboard_yaml >/dev/null 2>&1

   if [ $count = 0 ]; then
      nohup $cmd >/dev/null 2>&1 &
      echo $msgstarted
   else
      echo "Kubernetes Dashboard already running"
   fi
   ;;

stop)
   showtoken=0
   if [ $count -gt 0 ]; then
      kill -9 $(pgrep -f "$cmd")
   fi
   kubectl delete -f $dashboard_yaml >/dev/null 2>&1
   echo $msgstopped
   ;;

status)
   found=`kubectl get serviceaccount default -n kubernetes-dashboard 2>/dev/null`
   if [[ $count = 0 ]] || [[ $found = "" ]]; then
      showtoken=0
      echo $msgstopped
   else
      found=`kubectl get clusterrolebinding default -n kubernetes-dashboard 2>/dev/null`
      if [[ $found = "" ]]; then
         nopermission=" but user has no permissions."
         echo $msgstarted$nopermission
         echo 'Run "dashboard start" to fix it.'
      else
         echo $msgstarted
      fi
   fi
   ;;
esac

# Show full command line # ps -wfC "$cmd"
if [ $showtoken -gt 0 ]; then
   # Show token
   echo "Admin token:"
   kubectl get secret -n kubernetes-dashboard $(kubectl get serviceaccount default -n kubernetes-dashboard -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode
   echo
   echo "Go to:"
   echo "http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
fi
```

Make this script executable

```bash
chmod +x ~/kubernetes-dashboard.sh
```

Start the dashboard

```bash
./kubernetes-dashboard.sh start 
```

Check whether the dashboard is running or not and output the tokens if currently set.

```bash
./kubernetes-dashboard.sh status
```

Stop the dashboard

```bash
./kubernetes-dashboard.sh stop
```

**Deploy Container using YAML**

Create a kubernetes deployment YAML to tell kubernetes to manage a set of replicas of that Pod — literally, a ReplicaSet — to make sure that a certain number of them are always available.  So we might start our Kubernetes Deployment manifest definition YAML `deployment.yaml` like this:

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
  labels:
    app: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: hello-world
          image: piinalpin/sample-node-web-app
          ports:
            - containerPort: 8080
```

- `kubectl` create deployment `hello-world`
- `kubectl` create 3 replica pods, you can change how many replicas you want
- `kubectl` create deployment container from `piinalpin/sample-node-web-app` images and expose container port `8080` to master

Run YAML file by type following code

```bash
kubectl apply -f deployment.yaml
```

Check the deployment list

```bash
kubectl get deployments
```

We should get an output

```bash
NAME          READY   UP-TO-DATE   AVAILABLE   AGE
hello-world   3/3     3            3           20s
```

Check pods running

```bash
kubectl get pods
```

We shoul get an output

```bash
NAME                          READY   STATUS    RESTARTS   AGE
hello-world-f74567869-lsp74   1/1     Running   0          7m7s
hello-world-f74567869-m5vjd   1/1     Running   0          7m7s
hello-world-f74567869-z7pg7   1/1     Running   0          7m7s
```

There are three replicas created from YAML file.

**Create Service using YAML**

Create expose deployment YAML file `service.yaml` like this:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-world
  labels:
    app: web
spec:
  selector:
    app: web
  ports:
    - protocol: TCP
      port: 8080
  type: NodePort
```

- `kubectl` create service name `hello-world`
- `kubectl` expose deployment which is labeled web
- `kubectl` create connection to port `8080` with type is `NodePort`

Execute service YAML file by type following code

```bash
kubectl apply -f service.yaml
```

Check service is running

```bash
kubectl get svc
```

We should get and output

```bash
NAME          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
hello-world   NodePort    10.107.135.246   <none>        8080:31302/TCP   8s
kubernetes    ClusterIP   10.96.0.1        <none>        443/TCP          5d2h
```

Check port is exposed and we can execute http request

```bash
curl http://localhost:<EXPOSED_PORT>
```

We should get an output

```bash
{"status":"success","message":"Hello World! This api from Node.js"}
```

To delete service and deployment

```bash
kubectl delete -f deployment.yaml
kubectl delete -f service.yaml
```

**Create Deployment and Service on YAML**

Create file `hello-world.yaml` and fill like this:

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
  labels:
    app: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: hello-world
          image: piinalpin/sample-node-web-app
          ports:
            - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: hello-world
  labels:
    app: web
spec:
  selector:
    app: web
  ports:
    - protocol: TCP
      port: 8080
  type: NodePort
```

Execute service YAML file by type following code

```bash
kubectl apply -f hello-world.yaml
```

We should get an output

```bash
deployment.apps/hello-world created
service/hello-world created
```

Check deployment and service is running

```bash
kubectl get deployments
kubectl get pods
kubectl get svc
```

Check exposed port with http request

```bash
curl http://localhost:<EXPOSED_PORT>
```

We should get an output

```bash
{"status":"success","message":"Hello World! This api from Node.js"}
```

### Thankyou

[Docker Labs](https://birthday.play-with-docker.com/kubernetes-docker-desktop/) - Getting Started with Kubernetes on Docker Desktop

[kubernetes.io](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/) - What is Kubernetes?

[KataCoda](https://www.katacoda.com/courses/kubernetes/launch-single-node-cluster) - Launch Single Node Kubernetes Cluster

[Mirantis](https://www.mirantis.com/blog/introduction-to-yaml-creating-a-kubernetes-deployment/) - Introduction to YAML: Creating a Kubernetes deployment

[Network Chuck](https://www.youtube.com/watch?v=7bA0gTroJjw&t=909s) - you need to learn Kubernetes RIGHT NOW!!

[kubernetes.io](https://kubernetes.io/docs/tutorials/stateless-application/expose-external-ip-address/) - Exposing an External IP Address to Access an Application in a Cluster
[UpCloud](https://upcloud.com/community/tutorials/deploy-kubernetes-dashboard/) - How to deploy Kubernetes Dashboard quickly and easily