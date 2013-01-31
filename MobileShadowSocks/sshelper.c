#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

int main(int argc, char **argv) {
    if ((getuid() != 0 && setuid(0) == -1) || seteuid(501) == -1) {
        fprintf(stderr, "%s: must run as root\n", argv[0]);
        exit(1);
    }
    if (argc != 2 || argv[1][0] != '-' || !argv[1][1] || argv[1][2]) {
        fprintf(stderr, "Usage: %s {-1 | -2 | -3 | -4}\n", argv[0]);
        exit(1);
    }
    if (system("chown 0:0 /Applications/MobileShadowSocks.app/com.linusyang.shadowsocks.plist") || \
        system("chmod 644 /Applications/MobileShadowSocks.app/com.linusyang.shadowsocks.plist"))
        exit(1);
    switch (argv[1][1]) {
        case '1':
            return system("launchctl load -w /Applications/MobileShadowSocks.app/com.linusyang.shadowsocks.plist");
        case '2':
            return system("launchctl unload -w /Applications/MobileShadowSocks.app/com.linusyang.shadowsocks.plist");
        case '3':
            return system("python /Applications/MobileShadowSocks.app/proxy.py");
        case '4':
            if (system("chown 501:501 /Applications/MobileShadowSocks.app/proxy.conf") || \
                system("chmod 644 /Applications/MobileShadowSocks.app/proxy.conf"))
                exit(1);
            break;
        default:
            fprintf(stderr, "Usage: %s {-1 | -2 | -3 | -4}\n", argv[0]);
            exit(1);
    }
    return 0;
}
