# How to Run Redis Sentinel


Redis Sentinel is the high-availability solution for open-source Redis server. It provides monitoring of all Redis nodes and automatic failover should the master node become unavailable. This guide provides a sample configuration for a three-node Redis cluster.

Sentinel itself is designed to run in a configuration where there are multiple Sentinel processes cooperating together. The advantage of having multiple Sentinel processes cooperating are the following :

1. Failure detection is performed when multiple Sentinels agree about the fact a given master is no longer available. This lowers the probability of false positives.
2. Sentinel works even if not all the Sentinel processes are working, making the system robust against failures. There is no fun in having a failover system which is itself a single point of failure, after all.

The sum of Sentinels, Redis instances (masters and replicas) and clients connecting to Sentinel and Redis, are also a larger distributed system with specific properties. In this document concepts will be introduced gradually starting from basic information needed in order to understand the basic properties of Sentinel, to more complex information (that are optional) in order to understand how exactly Sentinel works. See the official documentation [here](https://redis.io/docs/manual/sentinel/)

### Redis Sentinel Replication Topology

![Redis Sentinel Topology](/images/redis-sentinel-topology.png)

Redis sentinel simple topology, I will explained with 1 master and 2 slaves. Assume we have 3 instance of Virtual Machine and each instances running `redis-server` and **sentinel mode**. The slaves is replica of redis master.

### Install Redis
You can download Redis latest [here](https://redis.io/download) or you can use `brew` to install redis.

```bash
brew install redis
```

### Run Redis Sentinel
First of all, we have to run redis server properly and we should create configuration file for each redis server.

**Redis Master**
Create configuration file `redis-master.conf`

```conf
port 6379
daemonize yes
dbfilename dump_6379.rdb
```

The configuration file mean running on port `6379`, runing on background process as `daemonized` and set db file name.

Then run `redis-server` with command :
```bash
redis-server redis-master.conf
```

**Redis Slave**

Create configuration file `redis-slave-1.conf` and `redis-slave-2.conf`

*redis-slave-1.conf*
```conf
port 6380
daemonize yes
dbfilename dump_6380.rdb
replicaof localhost 6379
replica-read-only yes
```

*redis-slave-2.conf*
```conf
port 6381
daemonize yes
dbfilename dump_6380.rdb
replicaof localhost 6379
replica-read-only yes
```
Then run `redis-server` with command :
```bash
redis-server redis-slave-1.conf
redis-server redis-slave-2.conf
```

We will have 2 redis server as replica and running on port `6380` and `6381`.

**Redis Sentinel Mode**
Run redis on sentinel mode, and we will create 3 node of sentinels. First of all we will create configuration files `sentinel-1.conf`, `sentinel-2.conf`, and `sentinel-3.conf` to monitoring `redis-master`.

*sentinel-1.conf*
```conf
protected-mode no
port 26379

daemonize yes

sentinel monitor mymaster ::1 6379 2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 10000

sentinel resolve-hostnames yes
```

*sentinel-2.conf*
```conf
protected-mode no
port 26380

daemonize yes

sentinel monitor mymaster ::1 6379 2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 10000

sentinel resolve-hostnames yes
```

*sentinel-3.conf*
```conf
protected-mode no
port 26381

daemonize yes

sentinel monitor mymaster ::1 6379 2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 10000

sentinel resolve-hostnames yes
```

And then run redis server as sentinel mode
```bash
redis-server sentinel-1.conf --sentinel
redis-server sentinel-2.conf --sentinel
redis-server sentinel-3.conf --sentinel
```

Redis sentinel nodes will running on port `26379`, `26380`, and `26381`.

### Redis Sentinel Command
To run sentinel command, we use `redis-cli` with port of sentinel

```bash
redis-cli -h $SENTINEL_HOST -p $SENTINEL_PORT
```
Basic usage redis sentinel command is
- `sentinel get-master-addr-by-name <master_name>` to get master address
- `sentinel ckquorum <master_name>` to get info quorum
For more details, see the official documentation [here](https://redis.io/docs/manual/sentinel/#sentinel-commands).

Redis master info replication

```txt
role:master
connected_slaves:2
slave0:ip=::1,port=6380,state=online,offset=76442,lag=0
slave1:ip=::1,port=6381,state=online,offset=76200,lag=1
master_failover_state:no-failover
master_replid:2fe52acf2b457b936070ae2f86204efc3752f0cf
master_replid2:4252dff2f509b85fcd78b02c763d99a371ebe652
master_repl_offset:76442
second_repl_offset:23098
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:23098
repl_backlog_histlen:53345
```

### Stop Redis Sentinel
To stopping the redis sentinel, use the `redis-cli` command to shutdown the server.

**Stop Redis Sentinel**
```bash
redis-cli -p 26381 shutdown
redis-cli -p 26380 shutdown
redis-cli -p 26379 shutdown
```

**Stop Redis Server**
```bash
redis-cli -p 6381 shutdown
redis-cli -p 6380 shutdown
redis-cli -p 6379 shutdown
```

### Run with Docker
This section I will explain how to run redis sentinel using `docker-compose`. Create `docker-compose.yml` configuration.

```yaml
version: "3.8"

services:

  redis-master:
    hostname: redis-master
    container_name: redis-master
    image: redis:latest
    command: >
      bash -c "echo 'port 26379' > sentinel.conf &&
      echo 'dir /tmp' >> sentinel.conf &&
      echo 'sentinel resolve-hostnames yes' >> sentinel.conf &&
      echo 'sentinel monitor mymaster redis-master 6379 2' >> sentinel.conf &&
      echo 'sentinel down-after-milliseconds mymaster 5000' >> sentinel.conf &&
      echo 'sentinel parallel-syncs mymaster 1' >> sentinel.conf &&
      echo 'sentinel failover-timeout mymaster 5000' >> sentinel.conf &&
      cat sentinel.conf &&
      redis-server sentinel.conf --sentinel & 
      redis-server --maxmemory 256mb --maxmemory-policy allkeys-lru"
    ports:
      - 6379:6379
      - 26379:26379
    networks:
      default:
        ipv4_address: 172.68.0.2

  redis-slave-1:
    hostname: redis-slave-1
    container_name: redis-slave-1
    image: redis:latest
    command: >
      bash -c "echo 'port 26379' > sentinel.conf &&
      echo 'dir /tmp' >> sentinel.conf &&
      echo 'sentinel resolve-hostnames yes' >> sentinel.conf &&
      echo 'sentinel monitor mymaster redis-master 6379 2' >> sentinel.conf &&
      echo 'sentinel down-after-milliseconds mymaster 5000' >> sentinel.conf &&
      echo 'sentinel parallel-syncs mymaster 1' >> sentinel.conf &&
      echo 'sentinel failover-timeout mymaster 5000' >> sentinel.conf &&
      cat sentinel.conf &&
      redis-server sentinel.conf --sentinel & 
      redis-server --port 6380 --slaveof redis-master 6379 --maxmemory 256mb --maxmemory-policy allkeys-lru"
    ports:
      - 6380:6380
      - 26380:26379
    networks:
      default:
        ipv4_address: 172.68.0.3

  redis-slave-2:
    hostname: redis-slave-2
    container_name: redis-slave-2
    image: redis:latest
    command: >
      bash -c "echo 'port 26379' > sentinel.conf &&
      echo 'dir /tmp' >> sentinel.conf &&
      echo 'sentinel resolve-hostnames yes' >> sentinel.conf &&
      echo 'sentinel monitor mymaster redis-master 6379 2' >> sentinel.conf &&
      echo 'sentinel down-after-milliseconds mymaster 5000' >> sentinel.conf &&
      echo 'sentinel parallel-syncs mymaster 1' >> sentinel.conf &&
      echo 'sentinel failover-timeout mymaster 5000' >> sentinel.conf &&
      cat sentinel.conf &&
      redis-server sentinel.conf --sentinel & 
      redis-server --port 6381 --slaveof redis-master 6379 --maxmemory 256mb --maxmemory-policy allkeys-lru"
    ports:
      - 6381:6381
      - 26381:26379
    networks:
      default:
        ipv4_address: 172.68.0.4

networks:
  default:
    driver: bridge
    ipam:
      config:
        - subnet: 172.68.0.0/16
          gateway: 172.68.0.1
```

When we run the docker compose
- It will create a local network with subnet `172.68.0.0/16` and gateway `172.68.0.1`.
- `redis-master` assign to IP `172.68.0.2`
- `redis-slave-1` assign to IP `172.68.0.3`
- `redis-slave-2` assign to IP `172.68.0.4`
- Each container will publish port for redis server and sentinel
- `redis-slave-x` will be slave of `redis-master` using docker network

Before run redis sentinel container, we should configure ip routing on local machine (host device) from docker ip to localhost.

```bash
sudo ifconfig lo0 alias 172.68.0.2
sudo ifconfig lo0 alias 172.68.0.3
sudo ifconfig lo0 alias 172.68.0.4
```

Check if the docker container ip have an alias on local machine with the command `ifconfig lo0`. And we will get an output.

```bash
lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> mtu 16384
	options=1203<RXCSUM,TXCSUM,TXSTATUS,SW_TIMESTAMP>
	inet 127.0.0.1 netmask 0xff000000 
	inet6 ::1 prefixlen 128 
	inet6 fe80::1%lo0 prefixlen 64 scopeid 0x1 
	inet 172.68.0.2 netmask 0xffff0000 
	inet 172.68.0.3 netmask 0xffff0000 
	inet 172.68.0.4 netmask 0xffff0000 
	nd6 options=201<PERFORMNUD,DAD>
```

The `inet 172.68.0.2 netmask 0xffff0000` indicates that the routing is running properly.

Finally, we can run redis sentinel with docker using following commans :

```bash
docker compose up -d
```

It will run 3 container such as `redis-master`, `redis-slave-1` and `redis-slave-2`.

### Reference
- [High availability with Redis Sentinel](https://redis.io/docs/manual/sentinel/)
- [Simple Redis sentinel setup](https://github.com/chrisza4/redis-sentinel-setup)
- [Springboot App with Redis Sentinel, Running in Docker container](https://medium.com/@anshulsharma942528/springboot-app-with-redis-sentinel-running-in-docker-container-3f8f1aadf0c8)
