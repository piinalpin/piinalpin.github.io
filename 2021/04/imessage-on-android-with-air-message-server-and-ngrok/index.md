# iMessage on Android With AirMessage Server for macOS and Ngrok


<!--more-->

### How does AirMessage work?

![How does AirMessage work](/images/air-message.png)

As Android phones and web browsers aren’t allowed to connect to iMessage, AirMessage leverages a Mac computer to handle sending and receiving messages instead.

Every message you send from AirMessage is sent to AirMessage Server on your Mac, which is then sent over iMessage. When a new incoming message is received from iMessage, that message is then sent back to your devices.

### What is Ngrok?

Ngrok is a cross-platform application that enables developers to expose a local development server to the Internet with minimal effort. The software makes your locally-hosted web server appear to be hosted on a subdomain of ngrok.com, meaning that no public IP or domain name on the local machine is needed. Similar functionality can be achieved with Reverse SSH Tunneling, but this requires more setup as well as hosting of your own remote server.

Ngrok is able to bypass NAT Mapping and firewall restrictions by creating a long-lived TCP tunnel from a randomly generated subdomain on ngrok.com (e.g. 3gf892ks.ngrok.com) to the local machine. After specifying the port that your web server listens on, the ngrok client program initiates a secure connection to the ngrok server and then anyone can make requests to your local server with the unique ngrok tunnel address. The ngrok developer's guide contains more detailed information on how it works.

### Step to create AirMessage server

**Installing AirMessage Server**

Go to [AirMessage.org](https://airmessage.org) and download AirMessage Server for macOS.

AirMessage Server is a crucial part of the AirMessage experience - it forwards incoming messages to your Android phone or browser, and sends outgoing messages on their behalf.

To get started, simply download the server onto your Mac computer and place it in the Applications folder.

When you open the app, you will be greeted with this welcome message.

![AirMessage Welcome Message](/images/airmessage-welcome.png)

Open the preferences window and click “Edit Password…”, and replace the default password with a password of your choosing. Remember, your messages are only as secure as the password you pick!

**Enabling Messaging Access**

If you are on macOS Mojave 10.14 or later, you will have to allow AirMessage automation access in order to send messages. You will be prompted when first running the software, though if you previously rejected this permission, you can re-enable it later under System Preferences > Security & Privacy > Privacy > Automation.

You will also be prompted to allow AirMessage to read your messages on macOS Mojave 10.14 or later. Under System Preferences > Security & Privacy > Privacy > Full Disk Access, add AirMessage. AirMessage will not read any data other than your Messages data.

![Screenshot Mojave Security](/images/screenshot-mojave-security.png)

**Adjusting Sleep Settings**

As AirMessage functions as a server on your Mac, it will need to be available all the time in order to send and receive messages. For this reason, you will have to disable sleep settings on your Mac. Navigate to System Preferences > Energy Saver to change this setting.

![Screenshot Energy Saver](/images/screenshot-energysaver.png)

If you are running AirMessage on a laptop, the system will freeze all software currently running when the lid is shut, regardless of energy saver settings. If you would like to turn your laptop into a stationary server, we recommend that you use a keep-awake utility such as Amphetamine or Caffeinate (built-in commmand).

**Installing Ngrok Server**

Download ngrok server at [Ngrok.com](https://ngrok.com/download).

On Linux or OSX you can unzip from a terminal with the following command. On Windows, just double click ngrok.zip.

```bash
unzip /path/to/ngrok.zip
```

Sign Up into Ngrok.com if you're not registered. Skip this step if you're already registered.

Connecting an account will list your open tunnels in the dashboard, give you longer tunnel timeouts, and more. Visit the dashboard to get your auth token.

```bash
./ngrok authtoken <CHANGE_TO_YOUR_AUTH_TOKEN>
```

Try running it from the command line

```bash
./ngrok http 8080
```

**Configuring Connection**

By default, AirMessage running on port `1359`, if you changed the default AirMessage server port, enter that number instead of `1359`.

![AirMessage Port](/images/airmessage-port.png)

Run this command line on terminal.

```bash
./ngrok tcp 1359
```

In the new Session Status window that opens, note down the address that is shown after Forwarding, but leave out the `tcp://`, example: `8.tcp.ngrok.io:17418`.

![Ngrok TCP Forwarding](/images/airmessage-ngrok.png)

**Setup AirMessage on Android**

In the AirMessage Android app, go to the Server address and enter the forwarding address, example: `8.tcp.ngrok.io:17418`.

Ensure your password is the same as what you set in the AirMessage preferences on your Mac. Connect.

![AirMessage App](/images/airmessage-app.jpeg)

To continue using AirMessage, do not close the ngrok Session Status window that opened on your Mac; leave it running at all times, as you will with your Mac. Whenever it is closed, the user is logged out, the Mac is restarted, etc., you must repeat Steps forwarding tcp port. This is a limitation of the free version of ngrok, you must upgrade to use a static/permanent forwarding address.

### Thankyou

[Reddit](https://www.reddit.com/r/AirMessage/comments/b8uad7/how_to_use_airmessage_without_port_forwarding_or/) - How to use AirMessage without Port Forwarding or Router Access

[AirMessage About](https://airmessage.org/about) - About AirMessage

[AirMessage Installation](https://airmessage.org/install/) - AirMessage Installation Guide