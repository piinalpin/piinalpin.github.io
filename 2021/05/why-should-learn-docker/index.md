# Why Should Learn Docker


<!--more-->

### What is Docker?

Docker is an open platform for developing, shipping, and running applications. Docker enables you to separate your applications from your infrastructure so you can deliver software quickly. With Docker, you can manage your infrastructure in the same ways you manage your applications. By taking advantage of Docker’s methodologies for shipping, testing, and deploying code quickly, you can significantly reduce the delay between writing code and running it in production.

### Docker Architecture

Docker uses a client-server architecture. The Docker client talks to the Docker daemon, which does the heavy lifting of building, running, and distributing your Docker containers. The Docker client and daemon can run on the same system, or you can connect a Docker client to a remote Docker daemon. The Docker client and daemon communicate using a REST API, over UNIX sockets or a network interface. Another Docker client is Docker Compose, that lets you work with applications consisting of a set of containers. More information please follow [Docs Docker](https://docs.docker.com/get-started/overview/).

![Docker architecture](/images/docker_architecture.png)

### Start using Docker

**Run Docker Command**

The following command run a `hello_world` container.

```bash
docker run --name hello_world -d piinalpin/sample-node-web-app
```

- If you don't have the `piinalpin/sample-node-web-app` image locally, docker pulls it from your configured registry, as though you had run `docker pull piinalpin/sample-node-web-app` manually.

- Docker create a new container `hello_world` from image `piinalpin/sample-node-web-app`

Let's get into the container.

```bash
docker exec -it hello_world /bin/sh
```

Run a simple command to get list folder in work directory by type the following command.

```bash
ls -l && cat server.js
```

We will get an output.

```bash
total 40
-rw-r--r--    1 root     root           392 May 19 08:30 Dockerfile
drwxr-xr-x   62 root     root          4096 May 19 08:26 node_modules
-rw-r--r--    1 root     root            81 May 19 08:00 package-lock.json
-rw-r--r--    1 root     root           300 May 19 08:08 package.json
-rw-r--r--    1 root     root           343 May 19 08:16 server.js
-rw-r--r--    1 root     root         17266 May 19 08:08 yarn.lock
var express = require('express');
var app = express();
const PORT = 8080;
const HOST = '0.0.0.0';

app.get('/', (req, res, next) => {
    const data = {
        'status': 'success',
        'message': 'Hello World! This api from Node.js'
    };
    res.json(data);
});

app.listen(PORT, HOST);
console.log(`Running on http://${HOST}:${PORT}`);
```

- Inside the container there is a folder `node_modules` and `Dockerfile package-lock.json package.json server.js yarn.lock` files

- The server is using `express.js` and running on port `8080`

**Show linux distribution**

The following command use to show linux distribution inside container.

```bash
cat /etc/os-release
```

We will get an output

```bash
NAME="Alpine Linux"
ID=alpine
VERSION_ID=3.11.11
PRETTY_NAME="Alpine Linux v3.11"
HOME_URL="https://alpinelinux.org/"
BUG_REPORT_URL="https://bugs.alpinelinux.org/"
```

This image use `Linux Alpine` which the operating system is very light. And then let's testing the server API by type the following command

```bash
curl http://localhost:8080
```

We should get an output

```bash
curl: not found
```

Thats mean, on `Linux Alpine` distribution didn't have `curl` command. We should install it by type the following command.

```bash
apk update
apk search curl
apk add curl
```

Then, test again the API server by type a command `curl http://localhost:8080`. And we should get an output.

```bash
{"status":"success","message":"Hello World! This api from Node.js"}
```

**Expose Container PORT to Host PORT**

If we want to access the container from host, we should expose the container port to host port by type a command `docker run -p <HOST_PORT>:<CONTAINER_PORT> --name <CONTAINER_NAME> -d <IMAGE>`

```bash
docker run -p 8001:8080 --name hello_world2 -d piinalpin/sample-node-web-app
```

- Docker create a new container `hello_world2` from image `piinalpin/sample-node-web-app`

- Docker expose port `8080` from container to `8001` host port and we can access from host

Check the container is already running by type following command

```bash
docker ps
```

We should get an output

```bash
CONTAINER ID   IMAGE                           COMMAND                  CREATED              STATUS              PORTS                                       NAMES
ec819086e2a5   piinalpin/sample-node-web-app   "docker-entrypoint.s…"   27 minutes ago       Up 27 minutes       0.0.0.0:8001->8080/tcp, :::8001->8080/tcp  hello_world2
d81a2784edaf   piinalpin/sample-node-web-app   "docker-entrypoint.s…"   About an hour ago    Up About an hour    8080/tcp                                    hello_world
```

Let's test the server API from the host by type following command

```bash
curl http://localhost:8001
```

We should get an output

```bash
{"status":"success","message":"Hello World! This api from Node.js"}%
```

**Build Image**

We will build an image which running a `Node.js` server. If you don't have a `Node.js` install from [Node.js](https://nodejs.org/en/).

Create a simple node application. First we will install the dependencies, we will use an `express.js` module by type a command `npm install express` or `yarn add express`

Then create a `server.js` like following script

```js
var express = require('express');
var app = express();
const PORT = 8080;
const HOST = '0.0.0.0';

app.get('/', (req, res, next) => {
    const data = {
        'status': 'success',
        'message': 'Hello World! This api from Node.js'
    };
    res.json(data);
});

app.listen(PORT, HOST);
console.log(`Running on http://${HOST}:${PORT}`);
```

Try run the server

```bash
node server.js
```

On the new terminal session type command `curl http://localhost:8080`. And we should get an output.

```bash
{"status":"success","message":"Hello World! This api from Node.js"}%
```

And let's create an image using `Dockerfile` like following script

```Dockerfile
FROM node:16-alpine3.11

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)
COPY package*.json ./

RUN npm install
# If you are building your code for production
# RUN npm ci --only=production

# Bundle app source
COPY . .

EXPOSE 8080

CMD ["node", "server.js"]
```

- Dockerfile will pull `node:16-alpine3.11` images
- Dockerfile create a working directory `/usr/src/app`
- Dockerfile copy the `package*.json` into `./` directory, that's mean all of file where file with the prefix `package` and postfix `.json` will copied on working directory
- Dockerfile execute command `npm install` to install all dependencies
- Dockerfile copy all file inside project directory into working directory
- Dockerfile will expose port `8080`
- Dockerfile will run command `node server.js`

Then we can build an image from `Dockerfile` by type the following command

```bash
docker build . -t hello-world-image
```

Then makesure the image success created

```bash
docker images
```

We should get an output

```bash
REPOSITORY                           TAG                                                     IMAGE ID       CREATED          SIZE
hello-world-image                    latest                                                  dd1c9d75c9d6   14 seconds ago   118MB
```

And then try to run container from `hello-world-image` and also expose port to host port

```bash
docker run -p 8002:8080 --name hello_world3 -d hello-world-image
docker ps
```

- Docker create a new container `hello_world3` from image `hello-world-image`

- Docker expose port `8080` from container to `8002` host port and we can access from host

We should get an output

```bash
CONTAINER ID   IMAGE                           COMMAND                  CREATED              STATUS              PORTS                                       NAMES
d92c8b3cf293   hello-world-image               "docker-entrypoint.s…"   About a minute ago   Up About a minute   0.0.0.0:8002->8080/tcp, :::8002->8080/tcp   hello_world3
ec819086e2a5   piinalpin/sample-node-web-app   "docker-entrypoint.s…"   27 minutes ago       Up 27 minutes       0.0.0.0:8001->8080/tcp, :::8001->8080/tcp   hello_world2
d81a2784edaf   piinalpin/sample-node-web-app   "docker-entrypoint.s…"   About an hour ago    Up About an hour    8080/tcp                                    hello_world
```

Let's try the server app by type following command `curl http://localhost:8002` and we should get an output

```bash
{"status":"success","message":"Hello World! This api from Node.js"}%
```

**Stop, Start, Delete Container and Delete Images**

If you want to start, stop, delete container and delete image, type the following command

```bash
docker stop <CONTAINER_NAME>
docker start <CONTAINER_NAME>
docker rm <CONTAINER_NAME>
docker rmi <IMAGE>
```

### Thankyou

[Docs Docker](https://docs.docker.com/get-started/overview/) - Docker Overview