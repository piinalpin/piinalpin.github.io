# Make Terminal Powerfull Using Oh-My-Posh

Programmers use a command-line interface (CLI) to issue text-commands to the Operating System (OS), instead of clicking on a Graphical User Interface (GUI). This is because command-line inerface is much more powerful and flexible than the graphical user interface.

The Terminal application is a command-line Interface (or shell). By default, the Terminal in Ubuntu and macOS runs the so-called bash shell, which supports a set of commands and utilities; and has its own programming language for writing shell scripts.

### Oh My Posh
<p class="">
  <img src="/images/oh-my-posh.png" alt="Oh My Posh"/>
</p>
Oh My Posh is a custom prompt engine for any shell that has the ability to adjust the prompt string with a function or variable. 

- **Colors:** Oh My Posh enables you to use the full color set of your terminal by using colors to define and render the prompt. 
- **Customizable:** Easily adjust existing themes or create your own. From standard segments all the way to custom implementations. 
- **Portable:** No matter which shell you're using, or even how many, you can carry the configuration from one shell and/or machine to another for the same prompt everywhere you work.

### Installation
**Windows**

Need have `powershell 7`, download at Microsoft Store or install on official website.

Install `oh-my-posh` from winget.
```bash
winget install JanDeDobbeleer.OhMyPosh -s winget
```

or Manual installation
```bash
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://ohmyposh.dev/install.ps1'))
```

This installs a couple of things:

- `oh-my-posh.exe` - Windows executable
- `themes` - The latest Oh My Posh [themes](https://ohmyposh.dev/docs/themes)

**Linux**

Recommend using `zsh` shell instead of `bash`. Install `oh-my-posh` by manual download.

```bash
curl -s https://ohmyposh.dev/install.sh | bash -s
```

or using `Homebrew`
```bash
brew install jandedobbeleer/oh-my-posh/oh-my-posh
```

**Font Installation**

Install `nerd fonts` from [official website](https://www.nerdfonts.com/). And set `nerd fonts` on terminal profile.

### Configuration

**Windows**

Create powershell user profile `$PROFILE`.
```bash
echo $PROFILE
```

We will be got an output `C:\Users\user\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`. This is our `$PROFILE` location to be edited.

Create new file on `C:\Users\user\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`. For my device i like use `1_shell` theme.

```powershell
# Prompt Init
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/1_shell.omp.json" | Invoke-Expression
```

**Linux**

Add this below line on `.zshrc` file to load `oh-my-posh` theme engine. Because i use `WSL` i can directly load from powershell at `/mnt/c/Users/Maverick/AppData/Local/Programs/oh-my-posh/themes` directory. If not have themes yet can download first from [GitHub here](https://github.com/JanDeDobbeleer/oh-my-posh/tree/main/themes).

```bash
export TERM=x-term-256color
export PATH=$HOME/bin:/usr/local/bin:/snap/bin:$PATH

# Plugins
eval "$(oh-my-posh init zsh --config /mnt/c/Users/Maverick/AppData/Local/Programs/oh-my-posh/themes/1_shell.omp.json)"
```

Usually i don't like use `transient prompt` so i need to remove this line.
```json
{
  ...
  "transient_prompt": {
    "background": "transparent",
    "foreground": "#FEF5ED",
    "template": "\ue285 "
  },
  ...
}
```

Then execute `source .zshrc` or just close and reopen terminal. Oh My Posh already installed if looks like

<p class="">
  <img src="/images/terminal-linux.png" alt="Terminal Linux"/>
</p>

### Powerful Plugin

#### Windows

Install `Terminal-Icons` Module to show if directory or files

```powershell
Install-Module -Name Terminal-Icons -Repository PSGallery -Force
```

Install `z` module, it can be used directly jump in some folder.

```powershell
Install-Module -Name z -Force
```

Install `PSReadLine` to auto suggestion or auto completion from history command line.
```powershell
Install-Module -Name PSReadLine -AllowPrerelease -Scope CurrentUser -Force -SkipPublisherCheck
```

Update powershell profile `C:\Users\user\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`. I added function `which` like on Linux command line to find where the program directory.
```powershell
# Aliases
Set-Alias ll ls
Set-Alias j z

# Prompt Init
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/1_shell.omp.json" | Invoke-Expression

# Import Module & Configuration
Import-Module Terminal-Icons
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView

# Function
function which($command) {
  Get-Command -Name $command -ErrorAction SilentlyContinue |
  Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}
```

<p class="">
  <img src="/images/powershell-psreadline.png" alt="Powershell PSReadLine"/>
</p>
<p class="">
  <img src="/images/powershell-ll.png" alt="Powershell List Directory"/>
</p>
<p class="">
  <img src="/images/powershell-z.png" alt="Powershell Jump Directory"/>
</p>

#### Linux

Clone `zsh-autosuggestions` and `zsh-syntax-highlightings`
```bash
mkdir .zsh
git clone https://github.com/zsh-users/zsh-autosuggestions.git .zsh/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git .zsh/zsh-syntax-highlightings
```

Install `jump shell` from `snap`, on my case I use `Ubuntu-20.04`. Jump integrates with your shell and learns about your navigational habits by keeping track of the directories you visit. It gives you the most visited directory for the shortest search term you type.
```bash
sudo snap install jump
```

Install `ruby gem` and `colorls` to beautify list directory.

```bash
sudo apt install ruby-full
sudo gem install colorls
```

Finally, update `.zshrc` profile to load configuration.
```bash
# Set up the prompt
export TERM=xterm-256colorexport
PATH=$HOME/bin:/usr/local/bin:/snap/bin:$PATH

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history

# Aliases command line
alias ls='colorls -l --sort-dirs'
alias la='colorls -A --sort-dirs'
alias ll='colorls -lA --sort-dirs'
alias tree='colorls --tree --sort-dirs'
alias gs='colorls --git-status --tree --sort-dirs'
alias vim='nvim'

# Plugins
eval "$(jump shell)"
eval "$(oh-my-posh init zsh --config /mnt/c/Users/maverick/AppData/Local/Programs/oh-my-posh/themes/1_shell.omp.json)"
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlightings/zsh-syntax-highlighting.zsh
```

<p class="">
  <img src="/images/terminal-ubuntu-autosuggestions.png" alt="Terminal Ubuntu Auto Suggestions"/>
</p>
<p class="">
  <img src="/images/terminal-ubuntu-ll.png" alt="ColorLS List Directory"/>
</p>
<p class="">
  <img src="/images/terminal-ubuntu-jump.png" alt="Terminal Jump Directory"/>
</p>


### Reference
- [OhMyPosh Docs](https://ohmyposh.dev/docs)
- [ASMR Set Up PowerShell with Oh-My-Posh on Windows 11 + Neovim Setup + Terminal Icons - No Talking](https://www.youtube.com/watch?v=fviSilPKIhs)
- [jump](https://snapcraft.io/jump)
- [Color LS](https://github.com/athityakumar/colorls)
