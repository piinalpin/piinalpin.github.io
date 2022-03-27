# Bash Script for Lazy People


### What is Bash?

![Bash Script](/images/bash.png)

Bash is a command processor that typically runs in a text window where the user types commands that cause actions. Bash can also read and execute commands from a file, called a shell script. Like most Unix shells, it supports filename globbing (wildcard matching), piping, here documents, command substitution, variables, and control structures for condition-testing and iteration. The keywords, syntax, dynamically scoped variables and other basic features of the language are all copied from sh. Other features, e.g., history, are copied from csh and ksh. Bash is a POSIX-compliant shell, but with a number of extensions.

### Basic Command

Let's start learn basic command line interface.

- `ls` show list content, example `ls Documents`
- `cd` change directory, example `cd Documents`
- `mv` rename or move file, example `mv foo.txt Documents/bar.txt`
- `mkdir` create a new directory, example `mkdir cloudjumper`
- `touch` create a new file, example `touch foo.txt`
- `rm` remove file or directory, example `rm foo.txt` or `rm -f cloudjumper`
- `clear` clear command line screen
- `cp` copy file, example `cp foo.txt Documents`
- `cat` display content of a file to the screen, example `cat foo.txt`
- `chown` change owner file, example `chown foo.txt`
- `chmod` change file permission, example `chmod 777 foo.txt` or `chmod +x foo.txt`
- `sudo` perform task to root permission
- `grep` search file or output particular string or expression, example `grep ssh foo.txt`
- etc.

### Why use Bash Script?

Shell script or bash script can be used to :

- Eliminate repetitive tasks.
- Saving time.
- Presents a structured, modular, and formatted sequence of activities.
- With bash functions, you can supply dynamic values to commands by using command line arguments.
- Simplify complex commands into one active, executable command.
- Used as often as possible by users. One bash function for multiple uses.
- Create a logical flow.
- Used at the start of the server (server start-up) or by adding a scheduled cron job.
- Debug command.
- Create interactive shell commands.

### Using Bash

Create file `hello.sh` and change permission to `777` or `+x` to make it executable.

Every bash script must start with the following line :

```bash
#!/bin/bash
```

**Hello World**

```bash
#!/bin/bash

echo "Hello world!!!"
```

or with function

```bash
#!/bin/bash

hello() {
    echo "Hello world!!!"
}

hello
```

Run file with command `./hello.sh` and we got an output `Hello world!!!`

**Conditions**

_If Conditions_

```bash
#!/bin/bash

var=true

if [ $var == true ]; then
    echo "var value is: $var"
fi
```

Run file with command `./hello.sh` and we got an output `var value is: true`

_Case Conditions_

```bash
#!/bin/bash

var=1

case $var in
1)
    echo "var value is $var"
;;
*)
    echo "Invalid value"
;;
esac
```

Run file with command `./hello.sh` and we got an output `var value is: true`

**Looping**

_While Do_

```bash
#!/bin/bash

isvalid=true
count=1

while [ $isvalid ]; do
echo $count
    if [ $count -eq 5 ]; then
        break
    fi
((count++))
done
```

_For_

```bash
#!/bin/bash

for (( count=10; count>0; count-- )); do
    echo -n "$count "
done
```

### My Bash Script Usage

I use bash script to saving time and eliminate repetitive task. So, I can be more productive for lazy people like me.

**Push into Git**

```bash
#!/bin/bash

# Pull latest code
git pull

# Add to stagged file
git add -A

# Create a new commit message
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"

# Push or upload to Github
git push origin master
```

Run this file with command `./deploy.sh -m "Your message"`

**Running Docker Compose Command**

I use shell script to simplified task. For example, I will run RabbitMQ as a container using docker with volume mount. First, I will download `docker compose` configuration file in [here](https://raw.githubusercontent.com/piinalpin/docker-compose-collection/master/rabbitmq.yaml). So, I will execute `cUrl` command like below.

```bash
curl -o rabbitmq.yml https://raw.githubusercontent.com/piinalpin/docker-compose-collection/master/rabbitmq.yaml
```

Then, I should create a `docker network`.

```bash
docker network create my-network
```

Then, I should create a volume `rabbitmq-data` and `rabbitmq-log` to persist data.

```bash
docker volume create rabbitmq-data
docker volume create rabbitmq-log
```

Then, I will execute `rabbitmq.yaml` to run RabbitMQ with `docker compose`

```bash
docker compose -f rabbitmq.yaml up -d
```

And to stop it, I will execute command

```bash
docker compose -f rabbitmq.yaml down -v
```

With bash script, I can simplified all task with one command line. First, I will create file `rabbitmq.sh` and fill code like below.

```bash
#!/bin/bash

FILE=rabbitmq.yaml
NAME=RabbitMQ

if [ $# = 1 ]; then
    # Check if configuration file is not exists will download configuration
    if [[ ! -f "$FILE" ]]; then
        curl -o $FILE https://raw.githubusercontent.com/piinalpin/docker-compose-collection/master/$FILE
    fi

    # Check network if not exists will create a docker network
    net=`docker network ls -q -f name=my-network`
    if [ -z "$net" ];  then
        net=`docker network create my-network`
        echo "Create docker network: $net"
    fi

    # Check volume is not exists will create volume
    rabbitmqData=`docker volume ls -q -f name=rabbitmq-data`
    if [ -z "$rabbitmqData" ];  then
        rabbitmqData=`docker volume create rabbitmq-data`
        echo "Create docker volume: $rabbitmqData"

        rabbitmqLog=`docker volume ls -q -f name=rabbitmq-log`
        
        if [ -z "$rabbitmqLog" ];  then
            rabbitmqLog=`docker volume create rabbitmq-log`
            echo "Create docker volume: $rabbitmqLog"
        fi
    fi

    # If command args start then run docker compose up
    if [ $* = "start" ]; then
        docker compose -f $FILE up -d
        echo "$NAME has started."
    # Or if command args is stop then run docker compose down
    elif [ $* = "stop" ]; then
        docker compose -f $FILE down -v
        echo "$NAME has stopped."
    else
        echo "Invalid command"
        exit 0
    fi
else
    echo "Invalid command"
    exit 0
fi
```

To start RabbitMQ service by typing following command.

```bash
./rabbitmq.sh start
```

![RabbitMQ Start](/images/bash-start.png)

To stop RabbitMQ service by typing following command.

```bash
./rabbitmq.sh stop
```

![RabbitMQ Stop](/images/bash-stop.png)

### My Pouncher.sh

I create shell script file `pouncher.sh` to saving my time for running docker container with `docker compose` like Kafka-CLI, MySQL, PostgreSQL, RabbitMQ, Redis, Sonarqube and SQLServer. I took the `pouncher` name from the baby dragon's name in the How to Train Your Dragon file because it fits the character's energetic and playful nature.

Just download file from my Github [here](https://github.com/piinalpin/docker-compose-collection/blob/master/sh/pouncher.sh) or you can use `cUrl`.

```bash
curl -o pouncher.sh https://raw.githubusercontent.com/piinalpin/docker-compose-collection/master/sh/pouncher.sh
```

Then make file is executable `chmod +x pouncher.sh`.

See help command by typing `./pouncher.sh --help`

![Pouncher.sh](/images/pouncher.png)

For example, I will run MySQL database. I just typing a command `./pouncher.sh -n mysql -c start` or stop service by typing `./pouncher.sh -n mysql -c stop`. See, how it saves my time.

### Reference

[Wikipedia](https://en.wikipedia.org/wiki/Bash_(Unix_shell)) - Bash (Unix Shell)

[Hostinger](https://www.hostinger.co.id/tutorial/bash-script) - Petunjuk Penggunaan Bash Script
