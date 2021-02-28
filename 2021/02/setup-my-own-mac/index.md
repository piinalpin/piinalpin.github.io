# Setup My Own Mac


<!--more-->

### Setup Terminal with Oh My Zsh and Powerlevel10k

**Intalling Oh My Zsh**
```bash
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

**Download and Install Nerd Patched Fonts**

Download and install [FuraMono Fonts](https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/FiraMono/Regular/complete/Fura%20Mono%20Regular%20Nerd%20Font%20Complete.otf?raw=true)

**Installing Powerlevel10k**
```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
```

**Change `.zshrc` Configuration**
```bash
vi .zshrc
```

Change `ZSH_THEME` to `ZSH_THEME="powerlevel10k/powerlevel10k"`

Enable auto correction uncomment line `ENABLE_CORRECTION="true"`

Then `restart` your terminal and you will see configuration wizard `powerlevel10k`

If you see `[WARNING]: Console output during zsh initialization detected.` change your `.p10k.zsh` and change this line `typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet`

If you see `[oh-my-zsh] Insecure completion-dependent directories detected:` type command below

```bash
chmod 755 /usr/local/share/zsh
chmod 755 /usr/local/share/zsh/site-functions
```

**Add Plugin Auto Suggestions and Syntax Highlighting**

Download plugins for auto suggestion and syntax highlighting

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
```

Scroll down on `.zshrc` find `plugin=(git)` and change to `plugins=(git zsh-autosuggestions zsh-syntax-highlighting)`

### Configure Multiple JDK with Jenv

**Install Jenv**

Install jenv with brew
```bash
brew install jenv
echo 'export PATH="$HOME/.jenv/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(jenv init -)"' >> ~/.zshrc
```

**Install JDK**

Add brew cask by adding `homebrew/cask`
```bash
brew tap homebrew/cask-versions
```

Install JDK 11 and JDK 8
```bash
brew install java11
brew install openjdk@8
```

Add java11 and java8 into jenv
```bash
jenv add /usr/local/opt/openjdk@11
jenv add /usr/local/opt/openjdk@8
```

See all installed versions java
```bash
jenv versions
```

Configure global version
```bash
jenv global 11.0.9
```

### Configure Multiple Python Version with Pyenv


**Install pyenv**

Install pyenv with brew
```bash
brew install pyenv
```

**Define environment variable `PYENV_ROOT` and add `pyenv init`**

I will use `zsh` so here bash command line

```bash
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc

echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.zshrc

source .zshrc
```

**Install Python**

Configure global environment python
```bash
pyenv install 3.9.1
pyenv global 3.9.1
```

### Configure docker and database with docker

***Installing Docker**

Download [Docker](https://hub.docker.com/editions/community/docker-ce-desktop-mac/) from docker hub

**Install MySQL database on docker**
```bash
docker run -p 3306:3306 --name mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql:latest
```

**Install SQL Server on docker**
```bash
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=<YourStrong@Passw0rd>" -p 1433:1433 --name sqlserver -h sqlserver -d mcr.microsoft.com/mssql/server:2019-latest
```

**Install Postgresql on docker**
```bash
docker run --name postgresql -d -p 5432:5432 -e POSTGRES_PASSWORD=yoursecretpassword postgres
```

### Configuring Auto Connect SSH Tunneling

You can read this step on [Auto Start SSH Tunneling on Mac](https://blog.piinalpin.com/2020/09/auto-start-ssh-tunneling-mac/)

### Configuring RabbitMQ and RabbitMQ Management

Install RabbitMQ with brew
```bash
brew install rabbitmq
```

Export path for RabbitMQ
```bash
export PATH=$PATH:/usr/local/sbin
```

Start service when laptop is started automatically in backgroun
```bash
brew services start rabbitmq
```

Enable management plugin
```bash
rabbitmq-plugins enable rabbitmq_management
```

Try to access `http://localhost:15672`

### References
- [Make your terminal beautiful and fast with ZSH shell and PowerLevel10K](https://medium.com/@shivam1/make-your-terminal-beautiful-and-fast-with-zsh-shell-and-powerlevel10k-6484461c6efb)
- [Terminal Keren dengan Oh My Zsh dan PowerLevel10k](https://belajarinformatika.id/terminal-keren-dengan-oh-my-zsh-dan-powerlevel10k/)
- [Jenv](https://www.jenv.be/)
- [How to install Java JDK on macOS](https://mkyong.com/java/how-to-install-java-on-mac-osx/)
- [Simple Python Version Management: pyenv](https://github.com/pyenv/pyenv)
- [Connecting to a mysql running on a Docker container](https://github.com/docker-library/mysql/issues/95)
- [Quickstart: Run SQL Server container images with Docker](https://docs.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker?view=sql-server-ver15&pivots=cs1-bash)
- [Docker container for Postgres 9.1 not exposing port 5432 to host](https://stackoverflow.com/questions/35928670/docker-container-for-postgres-9-1-not-exposing-port-5432-to-host)
- [The Homebrew RabbitMQ Formula](https://www.rabbitmq.com/install-homebrew.html)
- [RabbitMQ Management Plugin](https://www.rabbitmq.com/management.html)