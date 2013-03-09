MobileShadowSocks
=========
Shadowsocks Client for Jailbroken iOS Devices     
By Linus Yang     

------

### Features
* Fast, efficient and easy to use
* System-wide proxy supporting Wi-Fi and Celluar networks
* Proxy set up automatically when service running

### Installation
1. Open Cydia.app and refresh sources
2. Search the package named *ShadowSocks* and install it
3. That's it!

(Or you can download the latest beta version [here](http://yangapp.googlecode.com/svn/debs/ShadowSocks-iOS-linusyang.deb) from my private repository, then install manually using `dpkg -i` command or iFile.)

### Usage
1. After installation, you will find a icon named *Shadow* on your device.
2. Launch the app and set up *server information* and *proxy options*.
3. Tap the **Start** button on the top left of the screen.
4. Now the shadowsocks service will run in the background **even if you completely exit this app**. Also, **system-wide** proxy settings will be enabled automatically. You don't need to change the proxy settings in the *Settings.app*.    
( **Note** : The proxy settings **will not show** in the Preferences. If you want to check it, call `scutil --proxy` in terminal.)
5. If you want to stop the service, just enter the app again and tap the **Stop** button, and proxy settings will also be disabled.

### Credits
* [Shadowsocks](https://github.com/clowwindy/shadowsocks) project created by @clowwindy
* [Shadowsocks-libev](https://github.com/madeye/shadowsocks-libev) from @madeye
* App icon from [Tunnelblick](https://tunnelblick.googlecode.com) (Too lazy to draw one by myself :P)

### Note for Developers
* You have to self-sign a certificate (or use the official one) named *iPhone Developer*.
* The *Run Script* in project will call **sudo** to set permissions, so you may need to run **sudo** command such as `sudo date` once **before building this project** in the terminal.
* The final Debian package will be generated under **release** directory in the project directory.

### License
Licensed under [GPLv3](http://www.gnu.org/licenses/gpl.html)
