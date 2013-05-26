MobileShadowSocks
=========
Shadowsocks Client for Jailbroken iOS Devices     
By Linus Yang     

------

### Features
* Fast, efficient and easy to use
* System-wide proxy supporting Wi-Fi and Celluar networks
* **NEW:** On-demand proxy, no need to start manually 
* **NEW:** Pre-installed PAC file using white-list
* **NEW:** AES cipher mode for strong encryption

### Installation
1. Open Cydia.app and refresh sources
2. Search the package named *ShadowSocks* and install it
3. That's it!

### Usage
1. After installation, you will find a icon named *Shadow* on your device.
2. Launch the app and set up *server information* and *proxy settings*.
3. Tap to turn on the first "Enable Proxy" switch.
4. That's all folks!

### FAQ
#### 1. Can I exit the *Shadow* app completely after turning on the switch?
Yes, you can. This app is only for setting proxy options. The real shadowsocks services will start up on demand in the background.

#### 2. How can I disable the proxy?
Just open the *Shadow* app again and switch off "Enable Proxy".

#### 3. Is the proxy still available when network status is changed, or even device is rebooted?
Yes, it is always available if the proxy settings are enabled. The icon badge of Shadow.app will also show "On" to indicate that proxy is available.

#### 4. Is the shadowsocks daemon always running in the background and consuming my battery?
No. The daemon uses the " **On Demand** " mechanism of `launchd`, which means it is battery-friendly. It starts up only when receiving proxy requests and will exit automatically if there is no request for about 60 seconds. So, don't worry for battery life, **just leave it there**. :)

#### 5. I cannot find any proxy settings in *Settings.app*. Is the proxy actually enabled? And where are the proxy settings?
The proxy settings are **indeed** set successfully if you don't see any alert views when turning on the switch. They just don't show in the Settings.app. If you want to check it, call `scutil --proxy` in terminal.

### Credits
* [Shadowsocks](https://github.com/clowwindy/shadowsocks) project created by @[clowwindy](https://github.com/clowwindy)
* Based on [Shadowsocks-libev](https://github.com/linusyang/shadowsocks-libev) from @[madeye](https://github.com/madeye)
* App icon from [Tunnelblick](https://tunnelblick.googlecode.com) (Too lazy to draw one by myself :P)

### Note for Developers
* You have to create a self-signed code-signing certificate named *iPhone Developer* ([turtorial](https://developer.apple.com/library/mac/#documentation/Security/Conceptual/CodeSigningGuide/Procedures/Procedures.html)).
* In order to build armv6 binary, you have to install iOS **5.1** SDK ([turtorial](http://blog.chpwn.com/post/31824877081)).
* The final Debian package will be generated under **release** directory in the project directory.

### License
Licensed under [GPLv3](http://www.gnu.org/licenses/gpl.html)
