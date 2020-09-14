# Auto Start SSH Tunneling on Mac


<!--more-->

### Prerequisites

**Skip this step if you have it.**

Install Homebrew :
```bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Install SSH-Key using Keygen :
```bash
ssh-keygen -t rsa
```

Add SSH-Key fingerprint into the tunneling :
```bash
ssh -nNt -D port username@host
```

### Step to auto connect SSH Tunneling

1. Install `sshpass` using Homebrew
```bash
brew install hudochenkov/sshpass/sshpass
```

2. Create file `~/scripts/startup/startup.sh` to connect ssh tunneling automatically, and type code like below.
```bash
#!/bin/bash
#Start SSH Tunneling on IST Yogyakarta if is not running
 
echo "Entering SSH Tunneling"
 
sshpass -p "your_password" ssh -nNt -D port username@host
 
echo "Connection closed!"
```

3. Type `chmod +x ~/scripts/startup/startup.sh` on your terminal to change the file can be execute.

4. Create file `~/Library/LaunchAgents/com.startup.plist` to run startup.sh automatically when the laptop is starting, and type code like below.
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>EnvironmentVariables</key>
    <dict>
      <key>PATH</key>
      <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:</string>
    </dict>
    <key>Label</key>
    <string>com.startup</string>
    <key>Program</key>
    <string>/Users/your_username_laptop/scripts/startup/startup.sh</string>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/startup.stdout</string>
    <key>StandardErrorPath</key>
    <string>/tmp/startup.stderr</string>
  </dict>
```

5. Create file `~/reload.sh` to handle when disconnected from tunnel and type code like below.
```bash
#!/bin/bash
#Start SSH Tunneling on IST Yogyakarta if is not running
 
echo "Reloading SSH..."
 
launchctl unload -w ~/Library/LaunchAgents/com.startup.plist
launchctl load -w ~/Library/LaunchAgents/com.startup.plist
 
echo "Done Reload!"
```

6. Type `chmod +x ~/reload.sh` on your terminal to change the file can be executed.

7. Type `launchctl load -w ~/Library/LaunchAgents/com.startup.plist` to run startup agent.

8. Setup your browser with proxy SOCKS port forwarding. If you using Chrome, you can use SOCKS plugin and forward it to tunneling port.

### Thankyou
[Medium](https://medium.com/@fahimhossain_16989/adding-startup-scripts-to-launch-daemon-on-mac-os-x-sierra-10-12-6-7e0318c74de1) - Adding Startup Scripts to Launch Daemon

[SSHPASS](https://www.tecmint.com/sshpass-non-interactive-ssh-login-shell-script-ssh-password/) - SSHPASS non Interactive SSH Login Shell Script SSH Password