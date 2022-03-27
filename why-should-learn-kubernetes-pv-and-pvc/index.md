# Persistent Volume and Persistent Volume Claim in Kubernetes


<!--more-->

### What is Persistent Volume and Persistent Volume Claim

![Persistent Volume and Persistent Volume Claim](/images/pv-and-pvc-k8s.png)

**A PersistentVolume (PV)** is a piece of storage in the cluster that has been provisioned by an administrator or dynamically provisioned using Storage Classes. It is a resource in the cluster just like a node is a cluster resource. PVs are volume plugins like Volumes, but have a lifecycle independent of any individual Pod that uses the PV. This API object captures the details of the implementation of the storage, be that NFS, iSCSI, or a cloud-provider-specific storage system.

**A PersistentVolumeClaim (PVC)** is a request for storage by a user. It is similar to a Pod. Pods consume node resources and PVCs consume PV resources. Pods can request specific levels of resources (CPU and Memory). Claims can request specific size and access modes (e.g., they can be mounted ReadWriteOnce, ReadOnlyMany or ReadWriteMany, see AccessModes).

While PersistentVolumeClaims allow a user to consume abstract storage resources, it is common that users need PersistentVolumes with varying properties, such as performance, for different problems. Cluster administrators need to be able to offer a variety of PersistentVolumes that differ in more ways than size and access modes, without exposing users to the details of how those volumes are implemented. For these needs, there is the StorageClass resource.

More detail please see [Configure a Pod to Use a PersistentVolume for Storage](https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/)

### Create a Perstistent Volume

In this exercise, you create a hostPath PersistentVolume. Kubernetes supports hostPath for development and testing on a single-node cluster. A hostPath PersistentVolume uses a file or directory on the Node to emulate network-attached storage.

In a production cluster, you would not use hostPath. Instead a cluster administrator would provision a network resource like a Google Compute Engine persistent disk, an NFS share, or an Amazon Elastic Block Store volume. Cluster administrators can also use StorageClasses to set up dynamic provisioning.

Create a `pv-example.yaml` configuration file for the hostPath PersistentVolume:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-example
  labels:
    app: example
spec:
  storageClassName: manual
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/var/lib/data"
```

- `kubectl` create persistent volume `pv-example` with labels `app:example`
- `kubectl` defines the storage class name `manual`
- `kubetcl` specifies a size of 10 gibibytes and access modes is `ReadWriteOnce` which means the volume can be mounted as read-write by a single node.
- `kubectl` specifies that the volume is at `/var/lib/data` on the cluster node.

Create a persistent volume

```bash
kubectl apply -f pv-example.yaml
```

Get PersistentVolume was created

```bash
kubectl get pv pv-example
```

We should get an output

```bash
NAME         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
pv-example   10Gi       RWO            Retain           Available           manual                  7s
```

### Create a Persistent Volume Claim

Pods use PersistentVolumeClaims to request physical storage. In this exercise, you create a PersistentVolumeClaim that requests a volume of at least three gibibytes that can provide read-write access for at least one Node.

Create a `pvc-example.yaml` configuration file and fill with following code :

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pv-claim-example
  labels:
    app: example
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

Create a persistent volume claim

```bash
kubectl apply -f pvc-example.yaml
```

Get PersistentVolume was created

```bash
kubectl get pvc pv-claim-example
```

We should get an output

```bash
NAME               STATUS   VOLUME       CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pv-claim-example   Bound    pv-example   10Gi       RWO            manual         12s
```

Check if persistent volume was claimed

```bash
kubectl get pv pv-example
```

We should get an output shows a `STATUS` of `Bound` and `CLAIM` of `default/pv-claim-example`

```bash
NAME         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                      STORAGECLASS   REASON   AGE
pv-example   10Gi       RWO            Retain           Bound    default/pv-claim-example   manual                  9m21s
```

### Create a Pod

Create a pod `pod-uses-pvc-example.yaml` configuration file that uses the PersistentVolumeClaim as a volume

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pv-example-pod
spec:
  volumes:
    - name: pv-storage-example
      persistentVolumeClaim:
        claimName: pv-claim-example
  containers:
    - name: pv-example-container
      image: nginx
      ports:
        - containerPort: 80
          name: "http-server"
      volumeMounts:
        - mountPath: "/usr/share/nginx/html"
          name: pv-storage-example
```

Create the pod

```bash
kubectl apply -f pod-uses-pvc-example.yaml
```

Check pod is running

```bash
kubectl get pods pv-example-pod
```

Get cluster where pods is running

```bash
kubectl describe pods pv-example-pod
```

We should get an output

```bash
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  10m   default-scheduler  Successfully assigned default/pv-example-pod to gke-rattlesnake-cluster-default-pool-5da13591-6wb4
  Normal  Pulling    10m   kubelet            Pulling image "nginx"
  Normal  Pulled     10m   kubelet            Successfully pulled image "nginx" in 2.156978426s
  Normal  Created    10m   kubelet            Created container pv-example-container
  Normal  Started    10m   kubelet            Started container pv-example-container
```

Get external IP for `gke-rattlesnake-cluster-default-pool-5da13591-6wb4` node pool

```bash
kubectl get nodes gke-rattlesnake-cluster-default-pool-5da13591-6wb4 --output wide
```

Then, ssh into cluster node, then create directory `/var/lib/data` and create file `index.html`

```bash
sudo mkdir /var/lib/data/ && sudo sh -c "echo 'Hello from Kubernetes storage' > /var/lib/data/index.html"
```

Go to a shell to the container running in your Pod :

```bash
kubectl exec -it pv-example-pod  -- /bin/bash
```

In your shell, verify that nginx is serving the index.html file from the hostPath volume :

```bash
curl http://localhost/
```

We should get an output `Hello from Kubernetes storage`

### Implement Node App Web Service and Database using MySQL with Persistent Volume

We continue from [Learning Kubernetes](https://blog.piinalpin.com/2021/05/why-should-learn-kubernetes/) with example Node.js app with MySQL database.

Create configuration file `app-and-database.yml` then fill code like following below :

- Create Persistent Volume and Persistent Volume Claim

```yaml
---
# DB PERSISTENCE VOLUME
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-learn-nodejs
  labels:
    app: mysql
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/var/lib/data"
---
# DB PERSISTENCE VOLUME CLAIM
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pv-claim-learn-nodejs
  labels:
    app: mysql
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
---
```

- Create Node.js app deployment

```yaml
---
# APP DEPLOYMENT
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-learn-nodejs
  labels:
    app: app
    tier: learn-nodejs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: app
      tier: learn-nodejs
  template:
    metadata:
      labels:
        app: app
        tier: learn-nodejs
    spec:
      containers:
        - name: learn-nodejs
          image: piinalpin/learn-nodejs
          env:
          - name: "PORT"
            value: "8080"
          - name: "DB_HOST"
            value: "db-learn-nodejs-svc"
          - name: "DB_USERNAME"
            value: "root"
          - name: "DB_PASSWORD"
            value: "p@s5w0rD"
          - name: "DB_NAME"
            value: "learn_nodejs"
          - name: "DB_PORT"
            value: "3306"
---
```

- Create database MySQL deployment with PersistentVolumeClaim

```yaml
---
# DB DEPLOYMENT
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db-learn-nodejs
  labels:
    app: db
    tier: learn-nodejs
spec:
  selector:
    matchLabels:
      app: db
      tier: learn-nodejs
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: db
        tier: learn-nodejs
    spec:
      containers:
      - image: mysql:latest
        name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: p@s5w0rD
        - name: "PORT"
          value: "3306"
        volumeMounts:
        - name: pv-learn-nodejs
          mountPath: /var/lib/mysql
      volumes:
      - name: pv-learn-nodejs
        persistentVolumeClaim:
          claimName: pv-claim-learn-nodejs
---
```

- Expose App and DB with Service

```yaml
---
# APP SERVICE
apiVersion: v1
kind: Service
metadata:
  name: app-learn-nodejs-svc
  labels:
    app: app
    tier: learn-nodejs
spec:
  selector:
    app: app
    tier: learn-nodejs
  ports:
    - name: app-port
      protocol: TCP
      port: 8001
      targetPort: 8080
  type: LoadBalancer
---
# DB SERVICE
apiVersion: v1
kind: Service
metadata:
  name: db-learn-nodejs-svc
  labels:
    app: db
    tier: learn-nodejs
spec:
  selector:
    app: db
    tier: learn-nodejs
  ports:
    - name: db-port
      protocol: TCP
      port: 3306
      targetPort: 3306
  type: LoadBalancer
---
```

- Create Ingress for App

```yaml
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-learn-nodejs-ingress
spec:
  rules:
    - http:
        paths:
        - path: /programming-languages
          pathType: Prefix
          backend:
            service:
              name: app-learn-nodejs-svc
              port: 
                number: 8001
```

Apply configuration file

```bash
kubectl apply -f app-and-database.yaml
```

**Create database and table on running container**

Run container with creating a pod

```bash
kubectl run -it --rm --image=mysql:latest --restart=Never mysql-client -- mysql -h <DB_SVC_NAME> -p<YOUR_MYSQL_PASSWORD>
```

Create database, table and insert value

```sql
CREATE TABLE `programming_languages`
(
  `id`            INT(11) NOT NULL auto_increment ,
  `name`          VARCHAR(255) NOT NULL ,
  `released_year` INT NOT NULL ,
  `github_rank`   INT NULL ,
  `pypl_rank`     INT NULL ,
  `tiobe_rank`    INT NULL ,
  `created_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ,
  `updated_at`    DATETIME on UPDATE CURRENT_TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ,
  PRIMARY KEY (`id`),
  UNIQUE `idx_name_unique` (`name`(255))
)
engine = innodb charset=utf8mb4 COLLATE utf8mb4_general_ci;

---------------------------------

INSERT INTO programming_languages(id, name, released_year, github_rank, pypl_rank, tiobe_rank) 
VALUES 
(1,'JavaScript',1995,1,3,7),
(2,'Python',1991,2,1,3),
(3,'Java',1995,3,2,2),
(4,'TypeScript',2012,7,10,42),
(5,'C#',2000,9,4,5),
(6,'PHP',1995,8,6,8),
(7,'C++',1985,5,5,4),
(8,'C',1972,10,5,1),
(9,'Ruby',1995,6,15,15),
(10,'R',1993,33,7,9),
(11,'Objective-C',1984,18,8,18),
(12,'Swift',2015,16,9,13),
(13,'Kotlin',2011,15,12,40),
(14,'Go',2009,4,13,14),
(15,'Rust',2010,14,16,26),
(16,'Scala',2004,11,17,34);
```

Get exposed address `Ingress`

```bash
kubectl get ingress
```

We should get an output

```bash
NAME                       CLASS    HOSTS   ADDRESS          PORTS   AGE
app-learn-nodejs-ingress   <none>   *       XXX.XXX.XXX.XXX    80      26h
```

Test deployment by hitting with `curl` to ingress address

```bash
curl <INGRESS_ADDRESS>/programming-languages
```

We should get an output

```bash
[{"id":1,"name":"JavaScript","releasedYear":1995,"githutRank":1,"pyplRank":3,"tiobeRank":7,"createdAt":"2021-05-27T02:15:37.000Z","updatedAt":"2021-05-27T02:15:37.000Z"},{"id":2,"name":"Python","releasedYear":1991,"githutRank":2,"pyplRank":1,"tiobeRank":3,"createdAt":"2021-05-27T02:15:37.000Z","updatedAt":"2021-05-27T02:15:37.000Z"},{"id":3,"name":"Java","releasedYear":1995,"githutRank":3,"pyplRank":2,"tiobeRank":2,"createdAt":"2021-05-27T02:15:37.000Z","updatedAt":"2021-05-27T02:15:37.000Z"},{"id":4,"name":"TypeScript","releasedYear":2012,"githutRank":7,"pyplRank":10,"tiobeRank":42,"createdAt":"2021-05-27T02:15:37.000Z","updatedAt":"2021-05-27T02:15:37.000Z"},{"id":5,"name":"C#","releasedYear":2000,"githutRank":9,"pyplRank":4,"tiobeRank":5,"createdAt":"2021-05-27T02:15:37.000Z","updatedAt":"2021-05-27T02:15:37.000Z"},{"id":6,"name":"PHP","releasedYear":1995,"githutRank":8,"pyplRank":6,"tiobeRank":8,"createdAt":"2021-05-27T02:15:37.000Z","updatedAt":"2021-05-27T02:15:37.000Z"},{"id":7,"name":"C++","releasedYear":1985,"githutRank":5,"pyplRank":5,"tiobeRank":4,"createdAt":"2021-05-27T02:15:37.000Z","updatedAt":"2021-05-27T02:15:37.000Z"},{"id":8,"name":"C","releasedYear":1972,"githutRank":10,"pyplRank":5,"tiobeRank":1,"createdAt":"2021-05-27T02:15:37.000Z","updatedAt":"2021-05-27T02:15:37.000Z"},{"id":9,"name":"Ruby","releasedYear":1995,"githutRank":6,"pyplRank":15,"tiobeRank":15,"createdAt":"2021-05-27T02:15:37.000Z","updatedAt":"2021-05-27T02:15:37.000Z"},{"id":10,"name":"R","releasedYear":1993,"githutRank":33,"pyplRank":7,"tiobeRank":9,"createdAt":"2021-05-27T02:15:37.000Z","updatedAt":"2021-05-27T02:15:37.000Z"},{"id":11,"name":"Objective-C","releasedYear":1984,"githutRank":18,"pyplRank":8,"tiobeRank":18,"createdAt":"2021-05-27T02:15:37.000Z","updatedAt":"2021-05-27T02:15:37.000Z"},{"id":12,"name":"Swift","releasedYear":2015,"githutRank":16,"pyplRank":9,"tiobeRank":13,"createdAt":"2021-05-27T02:15:37.000Z","updatedAt":"2021-05-27T02:15:37.000Z"},{"id":13,"name":"Kotlin","releasedYear":2011,"githutRank":15,"pyplRank":12,"tiobeRank":40,"createdAt":"2021-05-27T02:15:37.000Z","updatedAt":"2021-05-27T02:15:37.000Z"},{"id":14,"name":"Go","releasedYear":2009,"githutRank":4,"pyplRank":13,"tiobeRank":14,"createdAt":"2021-05-27T02:15:37.000Z","updatedAt":"2021-05-27T02:15:37.000Z"},{"id":15,"name":"Rust","releasedYear":2010,"githutRank":14,"pyplRank":16,"tiobeRank":26,"createdAt":"2021-05-27T02:15:37.000Z","updatedAt":"2021-05-27T02:15:37.000Z"},{"id":16,"name":"Scala","releasedYear":2004,"githutRank":11,"pyplRank":17,"tiobeRank":34,"createdAt":"2021-05-27T02:15:37.000Z","updatedAt":"2021-05-27T02:15:37.000Z"}]
```

### Full Example Code

You can see my example here

```
https://github.com/piinalpin/learning-kubernetes.git
```

### Thankyou

[LogRocket](https://blog.logrocket.com/node-js-express-js-mysql-rest-api-example/) - Node.js, Express.js, and MySQL: A step-by-step REST API example

[SQLHack](https://www.sqlshack.com/sql-database-on-kubernetes-considerations-and-best-practices/) - SQL Database on Kubernetes: Considerations and Best Practices

[kubernetes.io](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) - Persistent Volumes

[kubernetes.io](https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/) - Configure a Pod to Use a PersistentVolume for Storage
