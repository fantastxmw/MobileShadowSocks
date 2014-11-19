MobileShadowSocks
=========
Shadowsocks Client for Jailbroken iOS Devices     
By Linus Yang     

------

### Features
* __Fast__: Light-weight proxy protocol by @[clowwindy](https://github.com/clowwindy).
* __Secure__: Support plenty of ciphers, including AES, Blowfish and Camellia.
* __Efficient__: Proxy services are triggered on demand.
* __User-friendly__: Easy to set and use. Built-in __auto-proxy__ feature.
* __Per-App Proxy Support__: Enable or disable proxy app by app. (_Support by extra plugin_)
* __QR Code Support__: Share your profiles easily via QR Code.
* __Universal__: System-wide proxy for either Wi-Fi or cellular network.
* __All-in-one__: No extra dependency. No Cydia Substrate stuff (_except plugins_ :P).
* __Compatibility__: All iDevices with iOS 3.0 and above (Some features need iOS 5 or above).

### Installation
1. Open Cydia.app and refresh sources
2. Search the package named *ShadowSocks* and install it
3. That's it!

__Note__: Latest packages are also available [here](http://apt.thebigboss.org/onepackage.php?bundleid=com.linusyang.shadowsocks) for manual installation.

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
No. The daemon uses the "__On Demand__" mechanism of `launchd`, which means it is battery-friendly. It starts up only when receiving proxy requests. So, don't worry for battery life, __just leave it there__. :)

#### 5. I cannot find any proxy settings in *Settings*. Is the proxy actually enabled? And where are the proxy settings?
The proxy settings are **indeed** set successfully if you don't see any alert views when turning on the switch. Sometimes they just don't show in the Settings (or wrongly show in the proxy for VPN). If you want to check the status, call `scutil --proxy` in terminal.

#### 6. I've uninstalled the app but forgotten to turn off the proxy. And my device cannot connect to the Internet any more? HALP!
Don't panic. Just reset your network settings in Preferences and everything will be OK. Or you can re-install the app, disable the proxy and uninstall it again.

### Credits
* [Shadowsocks](https://github.com/clowwindy/shadowsocks) project created by @[clowwindy](https://github.com/clowwindy)
* Based on [Shadowsocks-libev](https://github.com/linusyang/shadowsocks-libev) from @[madeye](https://github.com/madeye)
* App icon by @[madeye](https://github.com/madeye) from [Shadowsocks Android](https://github.com/shadowsocks/shadowsocks-android) (Too lazy to draw one by myself :P)
* QR Code encoding and decoding by [ZXingObjC](https://github.com/TheLevelUp/ZXingObjC)

### Development

#### Prerequisites
* Xcode 4 or above (using latest version is recommended)

* Install dkpg if not installed already

```bash
brew install dkpg
```

* Code-signing certificate named *iPhone Developer* (either self-signed or official is OK)

#### Build
Use the following command to download the project and build the main app:

```bash
git clone --recursive https://github.com/linusyang/MobileShadowSocks.git
cd MobileShadowSocks
make
```

All built Debian packages will be generated under `release` folder in the project directory.

### License
Licensed under [GPLv3](http://www.gnu.org/licenses/gpl.html).
