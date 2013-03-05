MobileShadowSocks
=========
Shadowsocks Client for Jailbroken iOS Devices     
By Linus Yang     

------

### Features
* Easy to install and use (the Debian package has no dependencies)
* System-wide proxy
* Proxy settings enabled automatically

### Install
1. Add Cydia source: http://yangapp.googlecode.com/svn
2. Find the package named *ShadowSocks* and install
3. That's it!

(Or you can just find and download the package in the [repo](http://yangapp.googlecode.com/svn/debs/), then install manually using `dpkg -i` command or iFile.)

### Usage
1. After installation, you will find a icon named *Shadow* on your device.
2. Launch the app and set the preferences.
3. Tap the **Start** button on the top left of the screen.
4. Now the shadowsocks service will run in the background **even if you completely exit this app**. Also, **system-wide** proxy settings will be enabled automatically. You don't need to change the proxy settings in the *Settings.app*.    
( **Note** :The proxy setting will not show in the Settings.app. If you want to check it, call `scutil --proxy` in the terminal.)
5. If you want to stop the service, just enter the app again and tap the **Stop** button. The proxy settings will also be disabled.

### Credits
* [Shadowsocks](https://github.com/clowwindy/shadowsocks) project created by @clowwindy
* [Shadowsocks-libev](https://github.com/madeye/shadowsocks-libev) from @madeye
* App icon from [Tunnelblick](https://tunnelblick.googlecode.com) (Too lazy to draw one by myself :P)

### Note for Developers
* You have to self-sign a certificate (or use the official one) named *iPhone Developer*.
* All dependencies are included for making the final Debian package. And the final package will be generated under *release* in the project directory.
* Since the Xcode project uses the *Run Script* to make Debian package which will call **sudo** to set permissions, You have to run **sudo** command such as `sudo date` once in your Terminal **before building this project**.

### License
Licensed under [GPLv3](http://www.gnu.org/licenses/gpl.html)
